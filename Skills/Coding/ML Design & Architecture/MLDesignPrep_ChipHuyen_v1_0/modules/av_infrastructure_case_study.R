# modules/av_infrastructure_case_study.R
# Case Study: Autonomous Vehicle Infrastructure Assessment for Deployment
# Atera Analytics — Innovate UK 10153306 — CAM Pathfinder One
# Applies Chip Huyen's full ML lifecycle to AV route risk assessment & deployment

av_infrastructure_case_study_ui <- function(id) {
  ns <- NS(id)

  css <- "
  .av-selector {
    display:flex; gap:5px; flex-wrap:wrap; margin-bottom:14px;
  }
  .av-btn {
    padding:5px 15px; border-radius:18px; border:2px solid #b2dfdb;
    background:#fff; color:#008A82; font-size:11px; font-weight:700;
    cursor:pointer; transition:all 0.16s; letter-spacing:0.3px; white-space:nowrap;
  }
  .av-btn:hover  { background:#e0f4f2; border-color:#008A82; }
  .av-btn.active { background:#002C3C; border-color:#002C3C; color:#fff; }
  .av-panel { display:none; animation:avFade 0.18s ease; }
  .av-panel.show { display:block; }
  @keyframes avFade { from{opacity:0;transform:translateY(-5px)} to{opacity:1;transform:translateY(0)} }
  .av-arch-node {
    display:inline-block; padding:7px 14px; border-radius:7px; margin:3px;
    font-size:11px; font-weight:700; border:2px solid;
  }
  .av-arch-arr { color:#008A82; font-size:18px; font-weight:700; vertical-align:middle; margin:0 4px; }
  .av-kpi-card {
    background:linear-gradient(135deg,#002C3C,#008A82);
    border-radius:10px; padding:14px; text-align:center; color:#fff; margin-bottom:10px;
  }
  .av-kpi-val { font-size:1.8em; font-weight:800; display:block; font-family:'JetBrains Mono',monospace; }
  .av-kpi-lbl { font-size:10px; text-transform:uppercase; letter-spacing:1px; opacity:0.75; margin-top:4px; }
  .risk-pill {
    display:inline-block; border-radius:5px; padding:2px 10px;
    font-size:10px; font-weight:800; margin:2px; letter-spacing:0.5px;
  }
  .risk-crit { background:#ffebee; color:#c0392b; border:1px solid #e57373; }
  .risk-med  { background:#fff8e1; color:#e65100; border:1px solid #ffcc80; }
  .risk-low  { background:#e8f5e9; color:#1b5e20; border:1px solid #a5d6a7; }
  "

  js <- "
<script>
function avShow(boxId, panelId) {
  document.querySelectorAll('#' + boxId + ' .av-panel').forEach(function(p){ p.classList.remove('show'); });
  document.querySelectorAll('#' + boxId + ' .av-btn').forEach(function(b){ b.classList.remove('active'); });
  var panel = document.getElementById(panelId);
  if (panel) panel.classList.add('show');
  var btn = document.querySelector('#' + boxId + ' [data-panel=\"' + panelId + '\"]');
  if (btn) btn.classList.add('active');
}
(function(){
  function init(){
    ['av-box1','av-box2','av-box3','av-box4','av-box5'].forEach(function(boxId){
      var firstBtn = document.querySelector('#' + boxId + ' .av-btn');
      if (firstBtn) firstBtn.click();
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else setTimeout(init, 120);
})();
</script>
"

  avBtn <- function(boxId, panelId, label, active=FALSE) {
    tags$button(
      class=paste0("av-btn", if(active)" active"else""),
      `data-panel`=panelId,
      onclick=sprintf("avShow('%s','%s')", boxId, panelId),
      label
    )
  }
  avPanel <- function(panelId, ...) div(id=panelId, class="av-panel", ...)

  tagList(
    tags$head(tags$style(HTML(css))),
    HTML(js),

    # ── Hero ────────────────────────────────────────────────────────────────
    div(class="meta-hero",
      tags$h1("Case Study — AV Infrastructure Assessment"),
      tags$h2("ML-driven route risk scoring, computer vision hazard detection, and phased AV deployment — Atera Analytics / Innovate UK"),
      div(
        span(class="hero-badge","YOLOv8 Detection"),
        span(class="hero-badge","OSM + Street View"),
        span(class="hero-badge","AV Readiness Score"),
        span(class="hero-badge","Isaac Sim PhysX"),
        span(class="hero-badge","ODD Boundary"),
        span(class="hero-badge","Innovate UK 10153306")
      ),
      tags$p(style="color:rgba(255,255,255,0.75);font-size:12px;margin-top:10px;",
        "Five-source data intelligence platform: OSM infrastructure, Google Street View imagery, YOLOv8 object detection, Isaac Sim physics simulation, and live EV fleet telemetry. Every section maps to Huyen's ML lifecycle.")
    ),

    # ── Architecture Overview ─────────────────────────────────────────────
    fluidRow(
      box(title="🏗️ AteraSuite — Five-Source Architecture Overview", status="primary", solidHeader=TRUE, width=12,
        div(style="text-align:center;padding:16px;",
          div(style="margin-bottom:8px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","FIVE DATA SOURCES"),
          div(
            span(class="av-arch-node",style="background:#e3f2fd;border-color:#2980b9;color:#2980b9;","SOURCE 1: OpenStreetMap"),
            span(class="av-arch-node",style="background:#fff3e0;border-color:#e67e22;color:#e67e22;","SOURCE 2: Google Maps + Street View"),
            span(class="av-arch-node",style="background:#e8f5e9;border-color:#27ae60;color:#27ae60;","SOURCE 3: COCO + YOLOv8"),
            span(class="av-arch-node",style="background:#f3e5f5;border-color:#8e44ad;color:#8e44ad;","SOURCE 4: Isaac Sim PhysX"),
            span(class="av-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","SOURCE 5: Volvo/Renault EV API")
          ),
          div(style="font-size:22px;color:#008A82;margin:5px 0;","↓"),
          div(style="margin-bottom:6px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","R SHINY PIPELINE  (CAV Route Optimizer + AteraSuite)"),
          div(
            span(class="av-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Route Sampler"),
            span(class="av-arch-arr","→"),
            span(class="av-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Feature Detector"),
            span(class="av-arch-arr","→"),
            span(class="av-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Street View Capture"),
            span(class="av-arch-arr","→"),
            span(class="av-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","YOLO Inference"),
            span(class="av-arch-arr","→"),
            span(class="av-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Risk Map")
          ),
          div(style="font-size:22px;color:#008A82;margin:5px 0;","↓"),
          div(style="margin-bottom:6px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","OUTPUT PRODUCTS"),
          div(
            span(class="av-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","AV Readiness Score"),
            span(class="av-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","ODD Boundary Map"),
            span(class="av-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","Phased Deployment Plan"),
            span(class="av-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","Safety Case Evidence"),
            span(class="av-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","WP5-WP7 Deliverables")
          ),
          br(),
          fluidRow(
            column(3, div(class="av-kpi-card", span(class="av-kpi-val","5"),    span(class="av-kpi-lbl","Data Sources"))),
            column(3, div(class="av-kpi-card", span(class="av-kpi-val","10+"),  span(class="av-kpi-lbl","Hazard Classes"))),
            column(3, div(class="av-kpi-card", span(class="av-kpi-val","<1s"),  span(class="av-kpi-lbl","GPU Inference/Image"))),
            column(3, div(class="av-kpi-card", span(class="av-kpi-val","AV Act"), span(class="av-kpi-lbl","2024 Compliant")))
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 1: Ch.1-2 — Problem Definition & System Design
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="📋 Box 1 — Ch.1-2: Problem Definition & AV System Design",
          status="primary", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 1 & 2 applied:</strong> Before deploying a single AV, the infrastructure assessment system must have precisely defined objectives, measurable ML tasks, constraints from the AV Act 2024 and Innovate UK deliverables, and a structured iterative design loop.")),
        br(),
        div(id="av-box1",
          div(class="av-selector",
            avBtn("av-box1","av1-framing","Business → ML Framing", TRUE),
            avBtn("av-box1","av1-tasks","ML Task Decomposition"),
            avBtn("av-box1","av1-metrics","AV Readiness Metrics"),
            avBtn("av-box1","av1-constraints","Regulatory Constraints"),
            avBtn("av-box1","av1-loop","Iterative Design Loop")
          ),

          avPanel("av1-framing",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Business Goal → ML Objective (Ch.1)"),
                  tags$p("The Innovate UK CAM Pathfinder One project has a deceptively simple goal: safely deploy Connected Autonomous Vehicles on UK public roads. This decomposes into precise ML objectives:"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Business Goal"),tags$th("ML Objective"),tags$th("Metric"))),
                    tags$tbody(
                      tags$tr(tags$td("Safe AV deployment"), tags$td("Per-segment AV readiness score"), tags$td("R² > 0.85 vs expert rating")),
                      tags$tr(tags$td("Hazard identification"), tags$td("YOLOv8 object detection"), tags$td("mAP@0.5 on AV hazard classes")),
                      tags$tr(tags$td("Route selection"), tags$td("Multi-criteria risk routing"), tags$td("Cumulative risk score minimised")),
                      tags$tr(tags$td("Phased deployment"), tags$td("ODD boundary classification"), tags$td("CRITICAL/MEDIUM/LOW per segment")),
                      tags$tr(tags$td("Physics validation"), tags$td("Isaac Sim energy + dynamics"), tags$td("RMSE: sim vs real EV telemetry")),
                      tags$tr(tags$td("WP deliverables"), tags$td("Safety case evidence generation"), tags$td("Zenzic / AV Act 2024 compliance"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("The AV Infrastructure Assessment Problem"),
                  tags$p("Unlike most ML systems, AV infrastructure assessment operates in a safety-critical domain where errors have physical consequences. Huyen's framing is directly applicable:"),
                  tags$ul(
                    tags$li(tags$b("Wrong metric choice:"), " optimising only for low-risk route length ignores that a longer low-risk route may be safer than a short high-risk one"),
                    tags$li(tags$b("Label definition matters:"), " what counts as 'AV-ready'? A roundabout is CRITICAL for autonomous navigation due to complex right-of-way, but is navigable by Level 4 systems in controlled ODD"),
                    tags$li(tags$b("Silent failures are catastrophic:"), " unlike a recommendation system, a missed CRITICAL road feature (tunnel, blind junction) does not just reduce engagement — it creates collision risk"),
                    tags$li(tags$b("System boundary:"), " the ML system scores infrastructure; the AV's own perception handles real-time dynamic objects. These are separate ML problems with different requirements.")
                  ),
                  div(class="warn-box", HTML("<strong>Huyen Ch.1 warning applied:</strong> The infrastructure assessment system must not be optimised for recall alone — a model that flags everything as CRITICAL is useless for planning. Precision on CRITICAL segments matters most."))
                )
              )
            )
          ),

          avPanel("av1-tasks",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Task 1 — Object Detection (Ch.6)"),
                  tags$p(tags$b("Model:"), " YOLOv8 (Ultralytics). Fine-tuned from COCO pretrained weights on AV-specific hazard classes."),
                  tags$p(tags$b("Input:"), " 640×640 Street View images at each waypoint."),
                  tags$p(tags$b("Output:"), " bounding boxes + confidence scores per detection class."),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Class"),tags$th("Risk"),tags$th("ID"))),
                    tags$tbody(
                      tags$tr(tags$td("Roundabout"),   tags$td(span(class="risk-pill risk-crit","CRITICAL")),tags$td("0")),
                      tags$tr(tags$td("Tunnel"),        tags$td(span(class="risk-pill risk-crit","CRITICAL")),tags$td("1")),
                      tags$tr(tags$td("Construction"),  tags$td(span(class="risk-pill risk-crit","CRITICAL")),tags$td("6")),
                      tags$tr(tags$td("Junction"),      tags$td(span(class="risk-pill risk-med","MEDIUM")),  tags$td("2")),
                      tags$tr(tags$td("Lane Merge"),    tags$td(span(class="risk-pill risk-med","MEDIUM")),  tags$td("3")),
                      tags$tr(tags$td("Curve"),         tags$td(span(class="risk-pill risk-med","MEDIUM")),  tags$td("4")),
                      tags$tr(tags$td("Traffic Signal"),tags$td(span(class="risk-pill risk-low","LOW")),     tags$td("7")),
                      tags$tr(tags$td("Ped. Crossing"), tags$td(span(class="risk-pill risk-low","LOW")),     tags$td("5"))
                    )
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Task 2 — AV Readiness Regression (Ch.6)"),
                  tags$p(tags$b("Model:"), " XGBoost regressor on ~50 engineered features per route segment."),
                  tags$p(tags$b("Input features:"), " YOLO detection counts, OSM infrastructure tags, curvature profile, elevation gradient, lane marking quality, sight distance, traffic signal density, surface quality (IRI proxy)."),
                  tags$p(tags$b("Output:"), " AV readiness score 0.0–1.0 per 200m segment. 0.0 = not deployable; 1.0 = ideal ODD conditions."),
                  tags$p(tags$b("Training approach:"), " collect 500+ route segments; manually score with domain experts (CCAV specialists). XGBoost target: R² > 0.85 on held-out segments."),
                  div(class="tip-box", HTML("<strong>Huyen Ch.6:</strong> Start with logistic regression baseline on 5 core features. Only move to XGBoost once baseline is well-characterised. Expert label agreement (kappa) must be > 0.7 before training."))
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Task 3 — Physics Simulation (Ch.6)"),
                  tags$p(tags$b("Model:"), " Isaac Sim PhysX vehicle dynamics (Kia Niro EV + Renault E-Tech 42t HGV)."),
                  tags$p(tags$b("Purpose:"), " validate that ML-selected routes are physically feasible for the specific vehicle configuration. Physics model is not ML — it is a deterministic simulation used to generate training labels for the energy consumption regression."),
                  tags$p(tags$b("Outputs:"), " energy consumption per segment (kWh), lateral acceleration at curves, braking distance on gradients, SoC at each waypoint."),
                  tags$p(tags$b("ML integration:"), " Isaac Sim outputs feed into XGBoost AV readiness score as 'physics difficulty' features. SoC trajectory validates route feasibility for Renault 540kWh battery.")
                )
              )
            )
          ),

          avPanel("av1-metrics",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Offline ML Metrics (Ch.6)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Model"),tags$th("Primary Metric"),tags$th("Target"),tags$th("Why"))),
                    tags$tbody(
                      tags$tr(tags$td("YOLO detection"),  tags$td("mAP@0.5"),       tags$td("> 0.75"), tags$td("Standard COCO benchmark adapted for AV classes")),
                      tags$tr(tags$td("YOLO CRITICAL recall"),tags$td("Recall@0.3"), tags$td("> 0.90"), tags$td("Missing a tunnel/roundabout is catastrophic")),
                      tags$tr(tags$td("AV readiness"),    tags$td("R² (regression)"),tags$td("> 0.85"), tags$td("Expert-scored validation segments")),
                      tags$tr(tags$td("Risk routing"),    tags$td("Cumulative risk"), tags$td("Minimised"),tags$td("Sum of segment scores on chosen path")),
                      tags$tr(tags$td("Isaac Sim RMSE"),  tags$td("kWh vs real"),    tags$td("< 5%"),   tags$td("Sim-to-real gap on Volvo/Renault telemetry")),
                      tags$tr(tags$td("ODD classification"),tags$td("F1 CRITICAL"),  tags$td("> 0.92"), tags$td("Safety-critical class must not be missed"))
                    )
                  )
                ),
                div(class="warn-box", HTML("<strong>Key asymmetry:</strong> For safety-critical systems, Huyen's principle applies: false negatives (missed CRITICAL hazards) are far more costly than false positives (over-flagging). Set confidence threshold at 0.3, not 0.5, for CRITICAL classes."))
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Operational / Business Metrics"),
                  tags$ul(
                    tags$li(tags$b("WP deliverables:"), " Innovate UK requires quantitative AV readiness evidence for WP5 (Architecture), WP6 (CCAV Integration), WP7 (Final Delivery)"),
                    tags$li(tags$b("Deployment planning:"), " % of total route flagged CRITICAL vs MEDIUM vs LOW. Target: identify routes where > 80% of segments are LOW/MEDIUM for initial deployment"),
                    tags$li(tags$b("Safety case:"), " number of identified hazards documented per route, with Street View evidence. Compliant with Zenzic UK CAV Safety Framework"),
                    tags$li(tags$b("Energy efficiency:"), " Isaac Sim predicted kWh per km vs observed from Renault E-Tech API. < 5% RMSE validates simulation fidelity"),
                    tags$li(tags$b("Route quality:"), " 40-60% improvement in AV-suitable route identification vs manual assessment (baseline = existing PEGA-equivalent rule-based scoring)")
                  )
                ),
                div(class="framework-card",
                  tags$h5("AV Readiness Score KPIs"),
                  fluidRow(
                    column(4, div(class="av-kpi-card", span(class="av-kpi-val","0.85+"), span(class="av-kpi-lbl","Target R²"))),
                    column(4, div(class="av-kpi-card", span(class="av-kpi-val","0.90+"), span(class="av-kpi-lbl","CRITICAL recall"))),
                    column(4, div(class="av-kpi-card", span(class="av-kpi-val","<5%"),   span(class="av-kpi-lbl","Sim-to-real RMSE")))
                  )
                )
              )
            )
          ),

          avPanel("av1-constraints",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Regulatory Constraints — AV Act 2024 & Zenzic UK"),
                  tags$ul(
                    tags$li(tags$b("AV Act 2024:"), " autonomous vehicles must have defined Operational Design Domain (ODD). The ML system's primary output is the ODD boundary — the set of conditions under which the AV may operate unsupervised."),
                    tags$li(tags$b("Safety case requirement:"), " evidence of proactive hazard identification is required before public road testing. The route risk assessment IS the safety case artefact."),
                    tags$li(tags$b("Zenzic CAV Safety Framework:"), " structured risk assessments must document: hazard identification method, evidence quality, confidence level, and mitigation strategy."),
                    tags$li(tags$b("Data protection:"), " Street View images may capture people and vehicle plates. GDPR applies to stored imagery. Google Street View API terms require images not be used for training facial recognition."),
                    tags$li(tags$b("Innovate UK deliverables:"), " WP5 (Data & Architecture), WP6 (CCAV Integration & Testing), WP7 (Final Delivery Q1 2026) create hard deadlines that constrain model iteration cycles.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Technical & Latency Constraints"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Component"),tags$th("Constraint"),tags$th("Implication"))),
                    tags$tbody(
                      tags$tr(tags$td("YOLO inference"),   tags$td("GPU: 0.05s/img, CPU: 0.5-1s"), tags$td("400 images: 20s GPU vs 400s CPU. T500 GPU required.")),
                      tags$tr(tags$td("Street View API"),  tags$td("$0.007/image"),               tags$td("Cost-aware sampling: sample_rate=5 reduces cost 80%")),
                      tags$tr(tags$td("Google Maps API"),  tags$td("$0.005/request"),              tags$td("100km route: ~$2.81 total at 50m spacing, sample=5")),
                      tags$tr(tags$td("Isaac Sim"),        tags$td("T500 4GB VRAM (no RT cores)"), tags$td("PhysX works; RTX features unavailable. Turing sm_75.")),
                      tags$tr(tags$td("R-Python bridge"),  tags$td("reticulate + system2()"),      tags$td("JSON via stdout — must use HTTP Flask, not WebSocket")),
                      tags$tr(tags$td("OSM Overpass API"), tags$td("Timeout on large routes"),     tags$td("Bounding box queries only; segment into sub-routes >100km"))
                    )
                  )
                )
              )
            )
          ),

          avPanel("av1-loop",
            fluidRow(
              column(12,
                div(class="framework-card",
                  tags$h5("Huyen's 6-Step Iterative Loop Applied to AV Infrastructure Assessment (Ch.2)"),
                  fluidRow(
                    column(6,
                      timeline_entry("1","Project Scoping","Define: AV readiness score per route segment for Cambridge-region roads (Innovate UK project area). Stakeholders: Atera Analytics, Zenzic UK, Innovate UK evaluators. Success metric: WP5-WP7 deliverables + expert-validated AV readiness scores."),
                      timeline_entry("2","Data Engineering","Five-source pipeline: OSM (ground truth infrastructure), Google Maps routing (waypoints + Street View imagery), YOLOv8 (object detections), Isaac Sim (physics labels), Volvo/Renault API (real EV telemetry). BigQuery-equivalent: api_manager reactiveValues in R Shiny."),
                      timeline_entry("3","Model Development","Start: rule-based risk classification (roundabout=CRITICAL, junction=MEDIUM). Baseline 2: logistic regression on OSM features only. Target: XGBoost on 50 features including YOLO detections. Physics: Isaac Sim for energy consumption validation.")
                    ),
                    column(6,
                      timeline_entry("4","Evaluation","Offline: R² on expert-scored segments, YOLO mAP@0.5. Sliced: by road class (motorway/A-road/urban), by ODD type (open road/urban/mixed). Sim-to-real: Isaac Sim RMSE vs Renault/Kia telemetry. Huyen principle: always compare against rule-based baseline before claiming ML improvement."),
                      timeline_entry("5","Deployment","R Shiny app (CAV Route Optimizer) serves as the deployment interface. Python backend (YOLOv8 + Flask) handles inference. Isaac Sim runs as a persistent HTTP server. No real-time latency requirement — this is pre-deployment analysis, not live inference."),
                      timeline_entry("6","Monitoring","Track: model performance on new route segments added over time. Drift signal: new road features not in training distribution (e.g., when new motorway junction opens). Re-annotation trigger: YOLO confidence < 0.3 on > 20% of images on a new route.")
                    )
                  )
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 2: Ch.3-4-5 — Five-Source Data Engineering & Feature Engineering
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🗄️ Box 2 — Ch.3-4-5: Five-Source Data Pipeline & Feature Engineering",
          status="warning", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 3, 4 & 5 applied:</strong> The AteraSuite Five-Source Data Intelligence Platform directly maps to Huyen's data engineering principles. Each source introduces different labelling challenges, class imbalance problems, and feature engineering requirements.")),
        br(),
        div(id="av-box2",
          div(class="av-selector",
            avBtn("av-box2","av2-sources","Five Data Sources (Ch.3)", TRUE),
            avBtn("av-box2","av2-labels","Labels & Class Imbalance (Ch.4)"),
            avBtn("av-box2","av2-features","Feature Engineering (Ch.5)"),
            avBtn("av-box2","av2-pipeline","Data Pipeline Architecture"),
            avBtn("av-box2","av2-skew","Train-Serve Skew Risks")
          ),

          avPanel("av2-sources",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Source 1: OpenStreetMap (Ground Truth Infrastructure)"),
                  tags$p(tags$b("What it provides:"), " foundational spatial reference. Every other source is georeferenced against OSM road geometry."),
                  tags$p(tags$b("Active features:"), " Nominatim geocoding, Geo3JSON polyline (25-200m waypoint sampling), highway=osmdata graph (routing + EV charging proximity), junction=roundabout + highway=traffic_signals via Overpass."),
                  tags$p(tags$b("Accuracy:"), " OSM ±5m vs Ordnance Survey MasterMap ±10cm. Sufficient for route-level risk scoring; insufficient for lane-level AV control."),
                  tags$p(tags$b("Huyen Ch.3 — Data Formats:"), " OSM via Overpass API returns JSON. R osmdata package converts to sf spatial objects. dodgr converts road network to routing graph. Columnar storage for feature tables.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Source 2: Google Maps + Street View"),
                  tags$p(tags$b("What it provides:"), " photographic ground truth of the physical road environment. The only source providing visual context of actual road conditions."),
                  tags$p(tags$b("Current status:"), " routing active; heading bug present (compute_heading() needs 15-min fix — bearing per WP pair)."),
                  tags$p(tags$b("Street View Static API:"), " 640×640 JPEG per waypoint. Batch downloader with 0.1s rate limiting. sample_rate slider reduces cost: sample_rate=5 → 20% of waypoints → 80% cost reduction."),
                  tags$p(tags$b("Multi-angle sweep:"), " 0/90/180/360 degrees per WP for full infrastructure scan. Critical for detecting occlusion zones and blind spots at junctions."),
                  div(class="tip-box", HTML("<strong>Ch.3 — Data Collection:</strong> Street View images are the most expensive data source ($0.007/image). Intelligent sampling — higher density at CRITICAL features, lower at straight segments — follows Huyen's principle of collecting data where it matters most."))
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Sources 3-5: Detection, Simulation & Telemetry"),
                  tags$p(tags$b("Source 3 — COCO + YOLOv8:"), " CLASS_MAP currently broken (maps IDs 0-9 to roundabout/tunnel using COCO-pretrained classes). Fix: replace CLASS_MAP with model.names + CAV_RISK_MAP. Provides per-image bounding boxes, confidence scores, hazard density per km."),
                  tags$p(tags$b("Source 4 — Isaac Sim PhysX:"), " physics-grounded synthetic sensor data. Persistent server (solves T500 startup cost). 13 physics features: aerodrag, suspension, braking force, drivetrain friction, inertia tensor. Statistical camera, LiDAR, IMU for time-of-day degradation."),
                  tags$p(tags$b("Source 5 — Volvo/Renault API (not yet connected):"), " highest WP5 priority. 2 Cambridgeshire EVs with logged routes. REST at api.renault-trucks.com. GET /vehicles (VIN, brand, gearbox), GET /vehiclepositions (real GPS), GET /vehiclestatuses (wheelBasedSpeed, hrTotalVehicleDistance, EnergyPropulsion kWh).")
                )
              )
            )
          ),

          avPanel("av2-labels",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Labelling Strategy for AV Infrastructure (Ch.4)"),
                  tags$p(tags$b("Natural labels where available:"), " OSM tags (junction=roundabout, highway=traffic_signals) provide free, scalable labels for infrastructure features. These are the Tier 1 labels — no annotation cost."),
                  tags$p(tags$b("Expert annotation for AV readiness score:"), " no natural label exists for 'AV readiness'. Requires domain expert scoring of 500+ route segments. Inter-annotator agreement (Cohen's kappa) target > 0.7 before training."),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Label Type"),tags$th("Source"),tags$th("Cost"),tags$th("Delay"))),
                    tags$tbody(
                      tags$tr(tags$td("Infrastructure class"), tags$td("OSM tags"),          tags$td("Free"),       tags$td("Immediate")),
                      tags$tr(tags$td("YOLO detection class"), tags$td("COCO pretrained"),   tags$td("Low (FT)"),   tags$td("Training time")),
                      tags$tr(tags$td("AV readiness score"),   tags$td("CCAV experts"),      tags$td("High"),       tags$td("Days per segment")),
                      tags$tr(tags$td("Energy consumption"),   tags$td("Isaac Sim / EV API"),tags$td("Med (GPU)"),  tags$td("Sim: minutes")),
                      tags$tr(tags$td("Road surface quality"), tags$td("Street View CNN"),   tags$td("Med"),        tags$td("Batch inference"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Class Imbalance in AV Hazard Detection (Ch.4)"),
                  tags$p("Road infrastructure is massively imbalanced toward normal (LOW risk) segments:"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Class"),tags$th("Estimated Rate"),tags$th("Implication"))),
                    tags$tbody(
                      tags$tr(tags$td("Normal road"),     tags$td("~75%"),   tags$td("Majority class — must not dominate")),
                      tags$tr(tags$td("LOW risk feature"),tags$td("~15%"),   tags$td("Traffic signals, crossings — easy")),
                      tags$tr(tags$td("MEDIUM risk"),     tags$td("~8%"),    tags$td("Junctions, curves — class weight needed")),
                      tags$tr(tags$td("CRITICAL risk"),   tags$td("~2%"),    tags$td("Roundabouts, tunnels — focal loss essential"))
                    )
                  ),
                  tags$p(tags$b("Huyen Ch.4 solutions applied:")),
                  tags$ul(
                    tags$li(tags$b("Focal loss:"), " gamma=2 for YOLO fine-tuning on AV classes. Reduces weight on easy normal-road examples."),
                    tags$li(tags$b("Class weights:"), " CRITICAL class upweighted 5× in XGBoost AV readiness model."),
                    tags$li(tags$b("Oversample CRITICAL:"), " during route sampling, oversample waypoints near known CRITICAL features (roundabout centroids from OSM) to ensure training coverage."),
                    tags$li(tags$b("Metric choice:"), " use PR-AUC not ROC-AUC. At 2% positive rate, ROC-AUC is misleadingly high even for poor models.")
                  )
                )
              )
            )
          ),

          avPanel("av2-features",
            fluidRow(
              column(3,
                div(class="framework-card",
                  tags$h5("Infrastructure Features (Ch.5)"),
                  tags$ul(
                    tags$li("Curvature profile (radians/m via spline)"),
                    tags$li("Bearing change per 25m segment"),
                    tags$li("Junction node degree (graph-theoretic)"),
                    tags$li("Roundabout within 100m (binary)"),
                    tags$li("Traffic signal density (/km)"),
                    tags$li("Lane count from OSM"),
                    tags$li("Speed limit (OSM maxspeed tag)"),
                    tags$li("Road class (motorway/A/B/urban)"),
                    tags$li("Elevation gradient (SRTM %)")
                  )
                )
              ),
              column(3,
                div(class="framework-card",
                  tags$h5("YOLO Detection Features (Ch.5)"),
                  tags$ul(
                    tags$li("CRITICAL detection count per segment"),
                    tags$li("MEDIUM detection count per segment"),
                    tags$li("Max confidence per class per segment"),
                    tags$li("Pedestrian/cyclist density (/image)"),
                    tags$li("Construction zone binary flag"),
                    tags$li("Lane marking quality score (CNN)"),
                    tags$li("Occlusion score (junction blind spot)"),
                    tags$li("Signage presence (binary)"),
                    tags$li("Unified AV score: 0.4*sensor_conf + 0.4*(1-infra_risk) + 0.2*surface_quality")
                  )
                )
              ),
              column(3,
                div(class="framework-card",
                  tags$h5("Physics Features (Ch.5)"),
                  tags$ul(
                    tags$li("Lateral acceleration at curve apex"),
                    tags$li("Braking distance on max gradient"),
                    tags$li("Energy consumption kWh/km (Isaac Sim)"),
                    tags$li("Suspension force at road roughness"),
                    tags$li("ABS trigger probability (wet road)"),
                    tags$li("SoC at segment end"),
                    tags$li("Time-of-day degradation factor (LiDAR)"),
                    tags$li("GPS accuracy proxy (urban canyon flag)")
                  )
                )
              ),
              column(3,
                div(class="framework-card",
                  tags$h5("Temporal & Context Features (Ch.5)"),
                  tags$ul(
                    tags$li("Time of day (peak/off-peak)"),
                    tags$li("Weather condition (rain/fog/ice)"),
                    tags$li("Season (winter = reduced traction)"),
                    tags$li("Roadworks flag (Highways England API)"),
                    tags$li("INRIX traffic speed vs posted limit"),
                    tags$li("V2X infrastructure availability"),
                    tags$li("Distance from nearest charging point"),
                    tags$li("maxspeed* compliance: AV speed vs OSM limit")
                  )
                )
              )
            )
          ),

          avPanel("av2-pipeline",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Batch vs Streaming Pipeline (Ch.3)"),
                  tags$p("AV infrastructure assessment is primarily a batch pipeline — routes are assessed before deployment, not in real-time:"),
                  tags$p(tags$b("Batch pipeline (pre-deployment):"),),
                  tags$ul(
                    tags$li("1. Route Sampler: Google Maps API → waypoints at 25-200m spacing"),
                    tags$li("2. Feature Detector: OSM Overpass API → infrastructure features"),
                    tags$li("3. Street View Capture: Batch download at sample_rate=5 with rate limiting"),
                    tags$li("4. YOLO Inference: Batch process all images → detection JSON"),
                    tags$li("5. Feature assembly: merge OSM + YOLO + physics features per segment"),
                    tags$li("6. XGBoost scoring: AV readiness score per segment"),
                    tags$li("7. Risk Map: visualise in Leaflet, export CSV for safety case")
                  ),
                  tags$p(tags$b("Near real-time (during AV operation — future):"),),
                  tags$ul(
                    tags$li("Volvo/Renault REST API: poll /vehiclepositions every 5 min"),
                    tags$li("Triggered route re-assessment on roadworks or weather alerts"),
                    tags$li("Dynamic ODD boundary update based on live conditions")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Inter-Module Data Flow (api_manager)"),
                  tags$p("The api_manager reactiveValues object is the R Shiny equivalent of a feature store — shared state accessible to all modules without tight coupling:"),
                  tags$ul(
                    tags$li(tags$b("cav_waypoints:"), " lat/lng dataframe from Route Sampler → used by Feature Detector, Street View, YOLO"),
                    tags$li(tags$b("cav_features:"), " OSM-detected features from Feature Detector → merged into Risk Map"),
                    tags$li(tags$b("cav_images:"), " Street View metadata (path, lat, lng, heading) → consumed by YOLO Detector"),
                    tags$li(tags$b("cav_detections:"), " YOLO results with confidence scores → Risk Map + AV readiness scoring"),
                    tags$li(tags$b("omniverse_scenarios:"), " Isaac Sim physics results → Scenario Manager, Route Preview, Advanced Viz"),
                    tags$li(tags$b("vehicle_config:"), " Kia Niro EV / Renault HGV parameters → physics model + energy estimation")
                  ),
                  div(class="success-box", HTML("<strong>Huyen Ch.5 — Feature Store pattern:</strong> api_manager ensures the same data transformations are applied consistently across all downstream modules. Prevents train-serve skew between the R analysis pipeline and any future real-time serving component."))
                )
              )
            )
          ),

          avPanel("av2-skew",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Skew 1: CLASS_MAP Bug (Active Issue)"),
                  tags$p(tags$b("Problem (currently broken):"), " YOLO CLASS_MAP maps IDs 0-9 to AV hazard names, but the pretrained COCO model uses different class IDs. Class 0 in COCO = 'person', not 'roundabout'."),
                  tags$p(tags$b("Training:"), " model trained with CLASS_MAP: {0: 'roundabout', 1: 'tunnel', ...}"),
                  tags$p(tags$b("Serving:"), " COCO-pretrained model returns {0: 'person', 2: 'car', ...}"),
                  tags$p(tags$b("Effect:"), " all detections mislabelled. Pedestrians flagged as roundabouts (CRITICAL). Risk map is entirely wrong."),
                  tags$p(tags$b("Fix:"), " replace CLASS_MAP with model.names dictionary from the loaded YOLO model object, then apply CAV_RISK_MAP on top."),
                  div(class="warn-box", HTML("<strong>Huyen Ch.5:</strong> This is the canonical train-serve skew failure — different label encoding at training vs serving time."))
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Skew 2: Heading Computation Bug"),
                  tags$p(tags$b("Problem:"), " Street View images downloaded without correct heading (camera direction). Images face arbitrary direction, not aligned with road direction of travel."),
                  tags$p(tags$b("Training:"), " YOLO fine-tuned on direction-aligned images (correct heading to road)."),
                  tags$p(tags$b("Serving:"), " heading defaults to 0 (North) for all waypoints. Images may face walls, buildings, or away from road."),
                  tags$p(tags$b("Effect:"), " YOLO sees non-road content. Detection confidence drops. False positives increase. AV readiness score systematically underestimates safety."),
                  tags$p(tags$b("Fix:"), " compute_heading() — bearing between consecutive waypoints. 15-minute fix. Critical for Source 2 data quality.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Skew 3: Isaac Sim Coordinate Mismatch"),
                  tags$p(tags$b("Problem:"), " Isaac Sim server generating straight-line coordinates between origin/destination instead of real road routes."),
                  tags$p(tags$b("Training:"), " physics model validated on real road curvature (lateral acceleration, braking distance on real gradients)."),
                  tags$p(tags$b("Serving:"), " Isaac Sim receives fake straight-line waypoints → physics simulation on wrong geometry → energy predictions are incorrect → route feasibility check is wrong."),
                  tags$p(tags$b("Fix:"), " use OSRM API for real driving routes in get_route() function. Code exists in isaac_sim_flask_api_DUAL_VEHICLE.py (working reference)."),
                  div(class="tip-box", HTML("<strong>Huyen Ch.5:</strong> Feature consistency between training data and production inputs is non-negotiable. At minimum, re-run validation on real routes before any WP6 deliverable submission."))
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 3: Ch.6 — Model Development: YOLOv8, XGBoost & Physics Baseline
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🧠 Box 3 — Ch.6: Model Development — YOLO, XGBoost & Physics Baselines",
          status="success", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapter 6 applied:</strong> Huyen's baseline hierarchy, YOLO fine-tuning strategy, XGBoost AV readiness model, HPO, offline evaluation strategy, and sliced evaluation across road types — all applied to the AteraSuite pipeline.")),
        br(),
        div(id="av-box3",
          div(class="av-selector",
            avBtn("av-box3","av3-baselines","Baseline Hierarchy", TRUE),
            avBtn("av-box3","av3-yolo","YOLOv8 Fine-Tuning"),
            avBtn("av-box3","av3-xgboost","XGBoost AV Readiness"),
            avBtn("av-box3","av3-physics","Physics Model (Isaac Sim)"),
            avBtn("av-box3","av3-eval","Evaluation Strategy")
          ),

          avPanel("av3-baselines",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Huyen's Baseline Hierarchy Applied to AV Risk Assessment"),
                  div(class="framework-card", style="border-left-color:#c0392b;",
                    tags$h5("Tier 1 — Random / Constant Baseline"),
                    tags$p("Classify every segment as MEDIUM risk. No features, no model. This is the absolute floor. Any ML model must beat this. On a typical UK A-road: ~65% accuracy (since most segments actually are LOW-MEDIUM). Shows why accuracy is the wrong metric here.")
                  ),
                  div(class="framework-card", style="border-left-color:#e67e22;",
                    tags$h5("Tier 2 — Rule-Based (Current Production System)"),
                    tags$p("Existing CAV Route Optimizer rules: roundabout=CRITICAL, tunnel=CRITICAL, junction=MEDIUM, curve(>45deg)=CRITICAL, traffic_signal=LOW. OSM tags only. The current deployed system. ML must demonstrably beat this for Innovate UK WP6 evidence.")
                  ),
                  div(class="framework-card", style="border-left-color:#f39c12;",
                    tags$h5("Tier 3 — Logistic Regression on 5 OSM Features"),
                    tags$p("Bearing change, junction_count/km, roundabout_binary, elevation_gradient, speed_limit. Fast, interpretable, passes safety case requirements. R² ~ 0.60 expected on expert-scored segments.")
                  ),
                  div(class="framework-card", style="border-left-color:#27ae60;",
                    tags$h5("Tier 4 — XGBoost on All 50 Features"),
                    tags$p("Full feature set including YOLO detections + physics features. Target R² > 0.85. Requires 500+ expert-annotated segments for training. SHAP values required for safety case explainability.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("HPO Strategy (Ch.6 — Vertex AI / Optuna applied to XGBoost)"),
                  tags$p("AV readiness XGBoost HPO with Optuna (equivalent to Vertex AI Vizier on local hardware):"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Parameter"),tags$th("Search Range"),tags$th("Optimise For"))),
                    tags$tbody(
                      tags$tr(tags$td("n_estimators"),  tags$td("50-500"),       tags$td("R² on validation segments")),
                      tags$tr(tags$td("max_depth"),     tags$td("3-8"),           tags$td("R² on validation")),
                      tags$tr(tags$td("learning_rate"), tags$td("0.01-0.3"),      tags$td("R² on validation")),
                      tags$tr(tags$td("scale_pos_weight"),tags$td("1-20 (CRITICAL class)"),tags$td("CRITICAL F1")),
                      tags$tr(tags$td("subsample"),     tags$td("0.6-1.0"),       tags$td("Generalisation")),
                      tags$tr(tags$td("reg_lambda"),    tags$td("0.1-10"),        tags$td("Prevent overfitting on small dataset"))
                    )
                  ),
                  div(class="warn-box", HTML("<strong>Small dataset challenge:</strong> 500 expert-annotated segments is small for XGBoost. Use cross-validation (k=5), not a single train/test split. SHAP feature importance helps identify when model is overfitting to noise features."))
                )
              )
            )
          ),

          avPanel("av3-yolo",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("YOLOv8 Fine-Tuning Strategy (Ch.6)"),
                  tags$p(tags$b("Starting point:"), " YOLOv8n (nano, ~6MB) pretrained on COCO 80 classes. COCO contains relevant objects: person, car, bicycle, traffic light, stop sign, fire hydrant."),
                  tags$p(tags$b("Fine-tuning approach (transfer learning):"),),
                  tags$ol(
                    tags$li("Freeze backbone (DarkNet feature extractor). Unfreeze detection head only."),
                    tags$li("Collect AV-specific training images: roundabouts, tunnels, construction zones from Street View + public AV datasets (Waymo Open, nuScenes)."),
                    tags$li("Annotate with LabelImg or Roboflow. Target: 500+ images per CRITICAL class, 200+ per MEDIUM class."),
                    tags$li("Fine-tune 50 epochs on AV classes. Monitor mAP@0.5 on held-out Cambridge-region images."),
                    tags$li("Calibration: Platt scaling on confidence scores. Score of 0.3 should mean 30% of detections are correct.")
                  ),
                  div(class="tip-box", HTML("<strong>Hardware constraint:</strong> T500 4GB VRAM. YOLOv8n (nano) is the right choice — fits in 4GB with batch_size=8. YOLOv8s (small) requires 8GB. Inference: ~0.05s/image on T500."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("COCO Classes Relevant to AV Infrastructure"),
                  tags$p("Before fine-tuning, COCO-pretrained YOLOv8 already detects useful AV-relevant objects:"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("COCO Class"),tags$th("AV Relevance"),tags$th("Risk Proxy"))),
                    tags$tbody(
                      tags$tr(tags$td("Person"),          tags$td("Pedestrian proximity"),  tags$td("LOW-MEDIUM")),
                      tags$tr(tags$td("Bicycle"),         tags$td("Vulnerable road user"),  tags$td("MEDIUM")),
                      tags$tr(tags$td("Car / Bus"),       tags$td("Traffic density proxy"), tags$td("LOW")),
                      tags$tr(tags$td("Traffic light"),   tags$td("Controlled junction"),   tags$td("LOW")),
                      tags$tr(tags$td("Stop sign"),       tags$td("Priority junction"),     tags$td("MEDIUM")),
                      tags$tr(tags$td("Truck"),           tags$td("HGV route assessment"),  tags$td("MEDIUM")),
                      tags$tr(tags$td("Construction sign"),tags$td("Temporary hazard"),     tags$td("CRITICAL"))
                    )
                  ),
                  tags$p(tags$b("Key message:"), " even without fine-tuning, COCO detections provide useful AV safety proxies. Fine-tuning adds UK-specific road infrastructure classes (roundabouts, UK traffic signs, road markings).")
                )
              )
            )
          ),

          avPanel("av3-xgboost",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("XGBoost AV Readiness Score Model"),
                  tags$p(tags$b("Training data collection:"), " Route segments scored by CCAV domain experts on 0.0-1.0 scale. Scoring rubric:"),
                  tags$ul(
                    tags$li("1.0: Ideal ODD — dual carriageway, clear markings, no complex junctions"),
                    tags$li("0.7-0.9: Good ODD — urban arterial, traffic signals, pedestrian crossings"),
                    tags$li("0.4-0.7: Challenging — roundabouts, tight junctions, poor markings"),
                    tags$li("0.1-0.4: Not recommended — tunnels, complex interchanges, construction"),
                    tags$li("0.0: Not deployable — missing road markings, extreme gradient, no GPS signal")
                  ),
                  tags$p(tags$b("SHAP explainability (Innovate UK requirement):"), " SHAP values per prediction stored in safety case evidence. Top 3 features shown per segment: 'This segment scored 0.35 because: roundabout present (-0.22), CRITICAL YOLO detection (-0.18), heading change >45deg (-0.12).'")
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Multi-Criteria Route Scoring"),
                  tags$p("The AV readiness score feeds into the multi-criteria routing algorithm (Ch.6 — ranking problem):"),
                  tags$p(style="font-family:monospace;background:#f8fffe;padding:8px;border-radius:6px;font-size:11px;",
"segment_cost = w1*(1-av_readiness) +\n  w2*energy_kWh_per_km +\n  w3*critical_count +\n  w4*time_minutes"),
                  tags$p(tags$b("Weight tuning:"), " w1=0.5 (safety dominant), w2=0.3 (energy), w3=0.15 (explicit critical features), w4=0.05 (time). Weights validated against expert route preference in A/B comparison."),
                  tags$p(tags$b("Pareto routing (Ch.6 — multi-objective):"), " generate 3-5 Pareto-optimal routes trading off: lowest risk vs shortest time vs minimum energy. User selects based on mission profile (prototype testing vs routine operation vs delivery HGV)."),
                  div(class="success-box", HTML("<strong>Huyen Ch.6 — scoring function:</strong> The weight assignment is a value judgment about what matters more — safety vs efficiency. For early AV deployment, w1=0.5 is correct. As operational confidence grows, weights can shift toward efficiency."))
                )
              )
            )
          ),

          avPanel("av3-physics",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Isaac Sim PhysX — Not ML, But Feeds ML (Ch.6)"),
                  tags$p("Isaac Sim is a deterministic physics simulator, not a machine learning model. Its role in the ML lifecycle:"),
                  tags$ul(
                    tags$li(tags$b("Training data generator:"), " produces synthetic physics labels (energy, forces, ABS triggers) that would be expensive to collect from real vehicles at scale"),
                    tags$li(tags$b("Sim-to-real validation:"), " once Volvo/Renault API connected, RMSE between Isaac Sim kWh prediction and actual EV telemetry validates simulation fidelity"),
                    tags$li(tags$b("Safety case evidence:"), " WP5.3 EV Validation, WP5.4 Digital Twin — Innovate UK requires simulation evidence before on-road testing"),
                    tags$li(tags$b("Feature generator:"), " 13 physics features per waypoint become inputs to XGBoost AV readiness model")
                  ),
                  tags$p(tags$b("Vehicle configurations:"),),
                  tags$ul(
                    tags$li(tags$b("Kia Niro EV:"), " 1,739kg, 150kW, 64.8kWh. Personal AV. Energy budget critical on longer routes."),
                    tags$li(tags$b("Renault E-Tech 42t HGV:"), " 8,500-42,000kg, 490kW, 540kWh. Commercial AV. Braking distance and lateral stability are primary constraints.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Sim-to-Real Gap (Huyen Ch.6 — Offline-Online Metric Gap Applied)"),
                  tags$p("The sim-to-real gap in physics simulation is analogous to Huyen's offline-online metric gap:"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Metric"),tags$th("Simulated"),tags$th("Real-World Target"),tags$th("Gap Cause"))),
                    tags$tbody(
                      tags$tr(tags$td("Energy kWh/km (Kia)"),   tags$td("~18 kWh/100km"), tags$td("<5% RMSE"),   tags$td("Tyre hysteresis, HVAC load")),
                      tags$tr(tags$td("Braking distance"),       tags$td("PhysX model"),   tags$td("±10% vs real"),tags$td("Road surface texture, tyre temp")),
                      tags$tr(tags$td("Lateral acceleration"),   tags$td("Ideal surface"),  tags$td("±15%"),       tags$td("Surface quality (IRI), weather")),
                      tags$tr(tags$td("GPS accuracy proxy"),     tags$td("Perfect GPS"),    tags$td("Urban canyon"),tags$td("Building occlusion not modelled"))
                    )
                  ),
                  div(class="warn-box", HTML("<strong>Key lesson:</strong> Isaac Sim produces the best physics simulation available without real telemetry, but the sim-to-real gap is non-trivial. The WP5.3 EV Validation deliverable exists specifically to measure and document this gap before commercial claims are made."))
                )
              )
            )
          ),

          avPanel("av3-eval",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Offline Evaluation Strategy (Ch.6)"),
                  tags$p(tags$b("Spatial train-test split (mandatory):"), " do NOT split randomly — adjacent segments have correlated features (a roundabout affects 3-4 consecutive segments). Use geographic hold-out: train on route A-G, test on route H-K."),
                  tags$p(tags$b("Sliced evaluation — AV-specific (Huyen's non-negotiable):"),),
                  tags$ul(
                    tags$li(tags$b("By road class:"), " motorway / A-road / B-road / urban. Model may perform well on motorways but poorly on urban micro-junctions."),
                    tags$li(tags$b("By ODD type:"), " open rural / suburban / dense urban. Each requires different feature importance profile."),
                    tags$li(tags$b("By vehicle type:"), " Kia Niro vs Renault HGV. Same roundabout may be MEDIUM for car but CRITICAL for 42t truck (turning radius, braking)."),
                    tags$li(tags$b("By time of day:"), " rush hour pedestrian density changes risk profile. Model trained on daytime images may underperform at night (Street View is daytime only)."),
                    tags$li(tags$b("By Innovate UK WP:"), " WP5 requires route-level scores; WP6 requires per-segment evidence for CCAV integration testing.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Calibration for Safety-Critical Applications"),
                  tags$p("Calibration is more important in AV infrastructure assessment than in most ML applications:"),
                  tags$p(tags$b("Why:"), " a confidence score of 0.7 on a CRITICAL roundabout detection must mean there is genuinely a 70% chance of a roundabout — not that the model is 'fairly confident'. Uncalibrated scores mislead route planners about actual risk."),
                  tags$p(tags$b("Method:"), " Platt scaling (post-hoc logistic regression on validation set). Apply to both YOLO confidence scores and XGBoost AV readiness probabilities."),
                  tags$p(tags$b("Reliability diagram:"), " plot predicted confidence vs actual correctness rate in 10 bins. For safety case: include reliability diagram in WP7 evidence showing model is well-calibrated."),
                  div(class="success-box", HTML("<strong>Regulatory significance:</strong> The AV Act 2024 and Zenzic Safety Framework implicitly require calibrated risk scores — a 'CRITICAL' flag must represent genuine risk, not an artifact of model overconfidence."))
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 4: Ch.7-9 — Deployment, Phased Rollout & Continual Learning
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🚀 Box 4 — Ch.7-9: Deployment, Phased AV Rollout & Continual Learning",
          status="danger", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 7, 8 & 9 applied:</strong> R-Python serving architecture, phased deployment strategy mapped to ODD risk levels, model compression for edge deployment, continual learning as new route data is collected, and A/B testing for route recommendation validation.")),
        br(),
        div(id="av-box4",
          div(class="av-selector",
            avBtn("av-box4","av4-serving","Serving Architecture (Ch.7)", TRUE),
            avBtn("av-box4","av4-phased","Phased AV Deployment"),
            avBtn("av-box4","av4-compression","Model Compression (Ch.7)"),
            avBtn("av-box4","av4-testing","A/B Testing Routes (Ch.9)"),
            avBtn("av-box4","av4-continual","Continual Learning (Ch.9)")
          ),

          avPanel("av4-serving",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("R-Python Hybrid Serving Architecture (Ch.7)"),
                  tags$p("Unlike social or banking ML systems, AV infrastructure assessment is a batch serving system — routes are assessed before deployment, not in real-time. The architecture reflects this:"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Component"),tags$th("Mode"),tags$th("Latency"),tags$th("Technology"))),
                    tags$tbody(
                      tags$tr(tags$td("Route extraction"),     tags$td("Batch"),     tags$td("Seconds"), tags$td("Google Maps API via Python")),
                      tags$tr(tags$td("OSM feature detection"),tags$td("Batch"),     tags$td("Seconds"), tags$td("Overpass API via R osmdata")),
                      tags$tr(tags$td("Street View download"),  tags$td("Batch"),     tags$td("Minutes"), tags$td("Street View Static API via Python")),
                      tags$tr(tags$td("YOLO inference"),        tags$td("Batch GPU"), tags$td("Minutes"), tags$td("PyTorch/Ultralytics via Python")),
                      tags$tr(tags$td("XGBoost scoring"),       tags$td("Batch"),     tags$td("Seconds"), tags$td("R or Python, all waypoints at once")),
                      tags$tr(tags$td("Isaac Sim physics"),     tags$td("Batch"),     tags$td("Minutes"), tags$td("HTTP Flask API (NOT WebSocket)")),
                      tags$tr(tags$td("EV API polling"),        tags$td("Periodic"),  tags$td("5 min"),   tags$td("Renault REST API (future)")),
                      tags$tr(tags$td("Risk map serving"),      tags$td("Interactive"),tags$td("<1s"),    tags$td("R Shiny + Leaflet"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Flask HTTP Architecture (Fix Required)"),
                  tags$p(tags$b("Current problem:"), " isaac_sim_server.py uses WebSocket. R Shiny cannot handle WebSockets natively. Connection always fails."),
                  tags$p(tags$b("Fix:"), " convert to HTTP REST API using Flask (isaac_sim_flask_api_DUAL_VEHICLE.py exists as working reference):"),
                  tags$ul(
                    tags$li("POST /run_scenario — start Isaac Sim with route + vehicle config"),
                    tags$li("GET /scenario_status/<job_id> — poll for completion"),
                    tags$li("GET /scenario_result/<job_id> — retrieve physics results JSON"),
                    tags$li("GET /vehicles — list available vehicle configurations"),
                    tags$li("POST /compare/<job_id> — RMSE: simulated vs Volvo API real speed + energy")
                  ),
                  tags$p(tags$b("R Shiny side:"), " httr::POST() to Flask endpoint. Poll status every 2 seconds. Display real-time progress from Flask response stream."),
                  div(class="warn-box", HTML("<strong>Huyen Ch.7 — serving architecture:</strong> The right serving mode depends on latency requirements. AV pre-deployment analysis has no real-time requirement — batch HTTP is correct. Do not over-engineer to streaming for a batch use case."))
                )
              )
            )
          ),

          avPanel("av4-phased",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Phased AV Deployment Strategy — Huyen Ch.9 Applied"),
                  tags$p("The AV readiness score directly drives a phased deployment roadmap:"),
                  div(class="framework-card", style="border-left-color:#27ae60;",
                    tags$h5("Phase 1 — LOW Risk Routes Only (Score > 0.75)"),
                    tags$p("Deploy on dual carriageways, motorways, clear A-roads with no roundabouts or complex junctions. All segments must be LOW. Shadow mode: AV operates but human driver overrides. Collect real telemetry from Kia Niro to validate Isaac Sim predictions.")
                  ),
                  div(class="framework-card", style="border-left-color:#f39c12;",
                    tags$h5("Phase 2 — LOW + MEDIUM Routes (Score > 0.50)"),
                    tags$p("Expand to urban arterial roads with traffic signals and mild junctions. MEDIUM segments allowed if flanked by LOW segments. Canary deployment: AV handles 50% of decisions, human monitors. A/B test: AV-selected route vs human-selected route.")
                  ),
                  div(class="framework-card", style="border-left-color:#c0392b;",
                    tags$h5("Phase 3 — Full ODD (Score > 0.30)"),
                    tags$p("Include challenging urban environments with roundabouts and complex junctions. Only after phases 1-2 accumulate 10,000+ km of real-world validation data. Requires formal ODD boundary submission to DVSA under AV Act 2024.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("ODD Boundary as an ML Output"),
                  tags$p("The Operational Design Domain (ODD) is a formal specification of conditions under which the AV may operate unsupervised. In this system, the ODD boundary is computed from the AV readiness score:"),
                  tags$ul(
                    tags$li(tags$b("ODD-In (score > 0.65):"), " AV may operate autonomously"),
                    tags$li(tags$b("ODD-Boundary (0.35-0.65):"), " AV must alert driver, prepare for handover"),
                    tags$li(tags$b("ODD-Out (score < 0.35):"), " AV must request immediate human takeover")
                  ),
                  tags$p(tags$b("Human handover zone identification (Expansion Roadmap):"), " automatically detect segments where handover should be requested: construction zones, missing road markings, extreme weather, new infrastructure not in training data."),
                  tags$p(tags$b("Regulatory requirement:"), " AV Act 2024 requires the ODD to be formally declared and the system to be able to detect when it is leaving the ODD. This ML system provides the pre-deployment ODD boundary map; the AV's on-board perception handles real-time ODD monitoring."),
                  div(class="success-box", HTML("<strong>Huyen Ch.9 — continual deployment:</strong> The phased strategy IS Huyen's shadow → canary → full rollout pattern, applied to physical AV deployment rather than software model deployment."))
                )
              )
            )
          ),

          avPanel("av4-compression",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Model Compression for Edge Deployment (Ch.7)"),
                  tags$p("The current system runs batch pre-deployment analysis. Future deployment (Phase 3) requires on-board real-time inference:"),
                  tags$ul(
                    tags$li(tags$b("YOLOv8n is already optimised:"), " nano variant (~6MB). INT8 quantisation via TensorRT reduces to ~2MB with <1% mAP loss on T500. GPU inference: 0.05s/frame."),
                    tags$li(tags$b("TensorRT for Jetson Xavier:"), " WP6.7 Xavier Deploy deliverable. Export YOLOv8n to ONNX → TensorRT INT8 on Jetson Xavier NX (NVIDIA edge device). 30 FPS real-time inference at 15W power budget."),
                    tags$li(tags$b("Knowledge distillation:"), " distil YOLOv8s (small) teacher into YOLOv8n (nano) student for AV-specific classes only. 97% of teacher mAP at 40% model size."),
                    tags$li(tags$b("ONNX export:"), " all models exported to ONNX for framework-agnostic serving. Required for Xavier deployment and cross-platform validation.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Pre-Deployment vs On-Board Inference"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Mode"),tags$th("Hardware"),tags$th("Latency SLO"),tags$th("Model"))),
                    tags$tbody(
                      tags$tr(tags$td("Pre-deployment (now)"),  tags$td("T500 GPU workstation"),  tags$td("Minutes"),  tags$td("YOLOv8n + XGBoost batch")),
                      tags$tr(tags$td("Phase 2 edge assist"),   tags$td("Jetson Xavier NX"),       tags$td("<100ms"),   tags$td("YOLOv8n TensorRT INT8")),
                      tags$tr(tags$td("Phase 3 real-time"),     tags$td("Orin NX / Drive AGX"),    tags$td("<33ms"),    tags$td("YOLOv8s TensorRT FP16")),
                      tags$tr(tags$td("Route planning API"),    tags$td("Cloud or edge server"),   tags$td("<2s"),      tags$td("XGBoost + routing algorithm"))
                    )
                  ),
                  div(class="tip-box", HTML("<strong>Hardware constraint reality:</strong> The T500 has no RT cores — TensorRT INT8 quantisation works but RTX-specific features (DLSS, RT shadows) are unavailable. Xavier deployment (WP6.7) requires GPU upgrade beyond T500 4GB for YOLOv8s real-time inference."))
                )
              )
            )
          ),

          avPanel("av4-testing",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("A/B Testing Route Recommendations (Ch.9)"),
                  tags$p("Unlike social media A/B testing, AV route A/B tests compare:"),
                  tags$p(tags$b("Control:"), " rule-based risk route (existing CAV Route Optimizer: roundabout=CRITICAL heuristics)"),
                  tags$p(tags$b("Treatment:"), " ML-scored route (XGBoost AV readiness score + multi-criteria optimisation)"),
                  tags$p(tags$b("Evaluation metrics:"),),
                  tags$ul(
                    tags$li("Actual energy consumption (kWh) vs predicted — validates Isaac Sim + XGBoost"),
                    tags$li("Expert safety rating of chosen route vs unchosen route"),
                    tags$li("Incident-free km per route type (Phase 1-2 deployment data)"),
                    tags$li("ODD boundary violation rate (how often AV requests handover on ML-chosen route)")
                  ),
                  tags$p(tags$b("No network interference:"), " unlike social media, AV routes are independent. User A's route does not affect User B's route risk profile. Standard A/B test is valid.")
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Interleaving for Route Ranking (Ch.9)"),
                  tags$p("For evaluating which of two multi-criteria route options is preferable, interleaving can be adapted:"),
                  tags$p("Rather than showing user A route-A and user B route-B, present both routes on the Leaflet risk map simultaneously, colour-coded. Expert evaluator selects preferred route. This is 100× more statistically efficient than sequential comparison."),
                  tags$p(tags$b("Innovate UK relevance:"), " WP6.6 Model Validation requires evidence of comparative route quality. Interleaved expert evaluation of ML vs rule-based routes provides this evidence efficiently with limited expert time budget."),
                  div(class="success-box", HTML("<strong>Huyen Ch.9 applied:</strong> The route interleaving approach eliminates between-evaluator variance — same expert evaluates both routes simultaneously, making the comparison fair and the evidence stronger for WP deliverables."))
                )
              )
            )
          ),

          avPanel("av4-continual",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Continual Learning Strategy (Ch.9)"),
                  tags$p("AV infrastructure data distribution shifts for predictable and unpredictable reasons:"),
                  tags$p(tags$b("Predictable shifts (scheduled retraining):"),),
                  tags$ul(
                    tags$li("Construction season (spring): new road works appear. OSM update lag means YOLO sees construction before OSM tags it."),
                    tags$li("Road resurfacing: lane marking quality changes. IRI features shift for resurfaced segments."),
                    tags$li("New infrastructure: bypasses, roundabout conversions, signal installations. Annual re-survey of project routes.")
                  ),
                  tags$p(tags$b("Unpredictable shifts (drift-triggered retraining):"),),
                  tags$ul(
                    tags$li("Accident damage: barriers, signs, road surface. YOLO detects anomalies not in training distribution → flag for review."),
                    tags$li("Flooding: road segments temporarily impassable. Real-time risk score should be overridden by live alert."),
                    tags$li("Weather events: major snow/ice changes risk profile of all segments simultaneously.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Retraining Schedule (Ch.9)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Model"),tags$th("Frequency"),tags$th("Trigger"),tags$th("Method"))),
                    tags$tbody(
                      tags$tr(tags$td("YOLO detection"),    tags$td("Quarterly"),tags$td("Scheduled + new imagery"), tags$td("Stateless fine-tune from COCO base")),
                      tags$tr(tags$td("XGBoost AV score"),  tags$td("Quarterly"),tags$td("New expert annotations"),  tags$td("Stateless retrain on full dataset")),
                      tags$tr(tags$td("Isaac Sim model"),   tags$td("On vehicle update"),tags$td("New vehicle config"),tags$td("Re-parameterise physics model")),
                      tags$tr(tags$td("Routing weights"),   tags$td("Post Phase 1"),tags$td("Real telemetry available"),tags$td("Reweight based on observed performance")),
                      tags$tr(tags$td("OSM feature rules"), tags$td("As needed"),  tags$td("New UK road features"),   tags$td("Rule update + re-classify existing routes"))
                    )
                  ),
                  div(class="tip-box", HTML("<strong>Ch.9 key insight:</strong> Stateless retraining (from scratch) is correct here. The AV readiness training set is small (500 segments). Stateful fine-tuning risks catastrophic forgetting on the CRITICAL segments that are rare but most important."))
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 5: Ch.8-10-11 — Monitoring, MLOps Infrastructure & Responsible AV AI
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🔍 Box 5 — Ch.8-10-11: Monitoring, Infrastructure & Responsible AV AI",
          status="info", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 8, 10 & 11 applied:</strong> Distribution shift detection for road infrastructure data, the AteraSuite MLOps stack mapped to Huyen's Ch.10 platform framework, and the unique responsible AI challenges of safety-critical autonomous vehicle systems.")),
        br(),
        div(id="av-box5",
          div(class="av-selector",
            avBtn("av-box5","av5-monitoring","Monitoring (Ch.8)", TRUE),
            avBtn("av-box5","av5-drift","Distribution Shift in AV"),
            avBtn("av-box5","av5-infra","MLOps Stack (Ch.10)"),
            avBtn("av-box5","av5-responsible","Responsible AV AI (Ch.11)"),
            avBtn("av-box5","av5-buildvsbuy","Build vs Buy (Ch.10)")
          ),

          avPanel("av5-monitoring",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("ML Model Monitoring (Ch.8)"),
                  tags$ul(
                    tags$li(tags$b("YOLO confidence distribution:"), " daily histogram of detection confidence scores on new route segments. Sudden drop below 0.4 mean → model out of distribution"),
                    tags$li(tags$b("CRITICAL recall monitoring:"), " track fraction of OSM-tagged roundabouts/tunnels that YOLO correctly detects on new routes. Target > 0.90."),
                    tags$li(tags$b("XGBoost score distribution:"), " monthly PSI on AV readiness score distribution. PSI > 0.20 triggers expert re-annotation campaign."),
                    tags$li(tags$b("Sim-to-real RMSE:"), " once Volvo API connected, weekly RMSE between Isaac Sim energy prediction and actual kWh from EV telemetry")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Infrastructure Monitoring"),
                  tags$ul(
                    tags$li(tags$b("OSM data freshness:"), " weekly check — have any route segments changed classification in OSM? New roundabouts, signal installations, road closures."),
                    tags$li(tags$b("API availability:"), " Google Maps, Street View, Overpass API uptime. Automated retry logic with exponential backoff."),
                    tags$li(tags$b("Isaac Sim server:"), " Flask HTTP health endpoint GET /health. Alert if >3 failures in 24h."),
                    tags$li(tags$b("Street View coverage:"), " some UK rural routes have no Street View coverage. Monitor fraction of waypoints with valid images returned.")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("AV Operational Monitoring (Phase 1-2)"),
                  tags$ul(
                    tags$li(tags$b("ODD violation rate:"), " how often does the AV request human handover on segments scored as LOW risk? Rising rate = model miscalibrated."),
                    tags$li(tags$b("Energy vs prediction:"), " actual kWh/km vs Isaac Sim prediction per route. Divergence > 10% triggers physics model review."),
                    tags$li(tags$b("New hazard detection:"), " YOLO detects high-confidence objects not in training distribution. Flag for expert review and potential dataset addition."),
                    tags$li(tags$b("Route compliance:"), " does AV actually follow ML-recommended route? Deviations indicate planning system integration issues.")
                  )
                )
              )
            )
          ),

          avPanel("av5-drift",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Distribution Shift Types in AV Infrastructure (Ch.8)"),
                  tags$p(tags$b("Covariate shift — seasonal and geographic:"),),
                  tags$ul(
                    tags$li("Winter: snow coverage changes road markings visibility. YOLO detects fewer lane markings → features shift out of training distribution."),
                    tags$li("Night: Street View is daytime only. AV operates 24h. YOLO trained on daytime images has lower recall on night-time sensor inputs."),
                    tags$li("Regional expansion: training data from Cambridge region. Deploying in Manchester (different road layouts, UK road sign variants)."),
                    tags$li(tags$b("Detection:"), " KS test on YOLO confidence distributions comparing Cambridge test routes vs new routes.")
                  ),
                  tags$p(tags$b("Concept drift — AV-specific:"),),
                  tags$ul(
                    tags$li("New road type: mini-roundabouts (common in UK) have different YOLO signature than full roundabouts. Model may classify as junction (MEDIUM) instead of roundabout (CRITICAL)."),
                    tags$li("Infrastructure upgrades: signalised junction → roundabout conversion changes risk class of a known segment."),
                    tags$li("V2X infrastructure: as CAV corridors are deployed (Cambridgeshire), some segments shift from HIGH to LOW risk due to V2X assistance.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Degenerate Feedback Loops in AV Systems (Ch.4 + Ch.8)"),
                  tags$p("Unlike recommendation systems, AV feedback loops have safety implications:"),
                  tags$ul(
                    tags$li(tags$b("Data collection bias:"), " AV is deployed only on LOW risk routes (Phase 1). Training data accumulates only from easy routes. Model never sees hard examples in production. When Phase 2 routes are attempted, model is miscalibrated."),
                    tags$li(tags$b("Route avoidance loop:"), " ML scores roundabout routes as HIGH → AVs avoid them → no real-world validation data for roundabout handling → model confidence remains low → roundabouts never validated → loop prevents deployment expansion."),
                    tags$li(tags$b("Mitigation:"), " Isaac Sim provides synthetic data for CRITICAL scenarios that the AV cannot safely encounter in real-world Phase 1 deployment. This is the primary justification for the physics simulation component of the five-source platform."),
                    tags$li(tags$b("Exploration budget:"), " reserve 5-10% of test routes for MEDIUM risk segments even in Phase 1, with human supervision, to accumulate real-world CRITICAL feature data.")
                  ),
                  div(class="warn-box", HTML("<strong>Huyen Ch.4 + Ch.8 applied:</strong> The sim-to-real pipeline (Isaac Sim → real EV telemetry validation) is the architectural solution to degenerate feedback loops in safety-critical AV deployment. Without synthetic data, the system cannot escape the catch-22 of needing CRITICAL data to validate CRITICAL scenarios."))
                )
              )
            )
          ),

          avPanel("av5-infra",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("AteraSuite MLOps Stack Mapped to Huyen Ch.10"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Huyen Layer"),tags$th("AteraSuite Component"),tags$th("Technology"))),
                    tags$tbody(
                      tags$tr(tags$td("Data Storage"),     tags$td("Route data + images"),          tags$td("Local filesystem + GCS (BigQuery connector present)")),
                      tags$tr(tags$td("Feature Store"),    tags$td("api_manager reactiveValues"),   tags$td("R Shiny reactive shared state (not persistent)")),
                      tags$tr(tags$td("Experiment Track."),tags$td("None yet"),                      tags$td("Recommend: MLflow or W&B for XGBoost HPO runs")),
                      tags$tr(tags$td("Model Registry"),   tags$td("models/ directory"),            tags$td("File-based. Recommend: MLflow Registry for versioning")),
                      tags$tr(tags$td("Training"),         tags$td("Python (YOLOv8 fine-tune)"),    tags$td("Ultralytics CLI + PyTorch on T500 GPU")),
                      tags$tr(tags$td("Serving"),          tags$td("Flask HTTP + R Shiny"),          tags$td("isaac_sim_flask_api + R Shiny frontend")),
                      tags$tr(tags$td("Orchestration"),    tags$td("Manual / R Shiny buttons"),     tags$td("Recommend: Prefect for pipeline DAG automation")),
                      tags$tr(tags$td("Monitoring"),       tags$td("Evidently AI (future)"),        tags$td("Custom R dashboard + Prometheus metrics endpoint")),
                      tags$tr(tags$td("Compute"),          tags$td("T500 GPU workstation"),         tags$td("Local + GCP (BigQuery connector for scale-out)"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Development Environment Best Practices (Ch.10)"),
                  tags$p(tags$b("Current architecture (CAM Pathfinder One):"),),
                  tags$ul(
                    tags$li(tags$b("R Shiny frontend:"), " shinydashboard, leaflet, DT, reactiveValues. Orchestration layer for all modules."),
                    tags$li(tags$b("Python backend:"), " virtual environment isolation. RETICULATE_PYTHON set in global.R before reticulate loads. PyTorch, Ultralytics, googlemaps, geopy, polyline, opencv-python."),
                    tags$li(tags$b("R-Python bridge:"), " system2() calls with shQuote() argument handling. JSON serialisation via stdout for data exchange. HTTP Flask for Isaac Sim (not WebSocket)."),
                    tags$li(tags$b("Config management:"), " .env file for API keys (GOOGLE_MAPS_API_KEY). Loaded by both Flask and R Shiny. Never committed to git.")
                  ),
                  div(class="success-box", HTML("<strong>Huyen Ch.10 build vs buy:</strong> The R-Python hybrid architecture is correct for this team's expertise profile. Building on existing R geospatial ecosystem (osmdata, leaflet, sf) and Python ML ecosystem (PyTorch, Ultralytics) avoids rebuilding commodity capabilities."))
                )
              )
            )
          ),

          avPanel("av5-responsible",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Responsible AI for Autonomous Vehicles (Ch.11)"),
                  tags$p(tags$b("The stakes are uniquely high:"), " a miscalibrated AV readiness score that incorrectly classifies a CRITICAL segment as LOW could lead to an AV attempting an unsupervised manoeuvre it cannot safely execute. This is qualitatively different from a bad film recommendation."),
                  tags$p(tags$b("Fairness — geographic and accessibility:"),),
                  tags$ul(
                    tags$li(tags$b("Urban/rural bias:"), " training data concentrated on Cambridge urban routes. Rural road risk assessment may be systematically underweighted. Model trained on cities may score narrow rural lanes as LOW (no detected features) when they are actually challenging for AV sensors."),
                    tags$li(tags$b("Accessibility:"), " if AV deployment is limited to HIGH readiness routes, rural communities may be systematically excluded from AV mobility benefits."),
                    tags$li(tags$b("Huyen Ch.11 — sliced evaluation:"), " mandatory evaluation by rural/urban/suburban. Do not aggregate AV readiness scores across route types — the model may be well-calibrated for urban and uncalibrated for rural.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Regulatory Compliance as ML Design Constraint (Ch.11)"),
                  tags$p(tags$b("AV Act 2024 requirements that directly shape ML system design:"),),
                  tags$ul(
                    tags$li(tags$b("ODD declaration:"), " the ML system's output (AV readiness score + ODD boundary map) must be formally declarable. This requires calibrated, explainable scores — not just a black-box number."),
                    tags$li(tags$b("Safety case:"), " structured argument that the system is safe enough. SHAP feature importance + calibration plots + sliced evaluation ARE the safety case evidence."),
                    tags$li(tags$b("Incident reporting:"), " if an AV encounters an unexpected scenario on a LOW-scored segment, this must be reported and trigger model review. The ML system must support incident attribution."),
                    tags$li(tags$b("Data protection:"), " Street View imagery is used for ML training. GDPR applies. Images of identifiable people stored for >30 days require privacy impact assessment."),
                    tags$li(tags$b("Model cards:"), " Zenzic requires documentation of: model intended use, training data sources, evaluation results, known limitations. Huyen's model card format satisfies this.")
                  ),
                  div(class="success-box", HTML("<strong>Huyen Ch.11 + AV Act alignment:</strong> The AV Act 2024 essentially mandates Huyen's responsible ML practices — calibration, sliced evaluation, explainability, model documentation. Building these into the ML lifecycle from the start satisfies both engineering best practice AND regulatory compliance."))
                )
              )
            )
          ),

          avPanel("av5-buildvsbuy",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Build vs Buy Decisions (Ch.10)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Component"),tags$th("Decision"),tags$th("Rationale"))),
                    tags$tbody(
                      tags$tr(tags$td("YOLOv8 model"),       tags$td("Buy (pretrained) + Build (fine-tune)"), tags$td("COCO weights are commodity; AV classes are differentiating")),
                      tags$tr(tags$td("OSM routing"),         tags$td("Buy (osmdata/dodgr)"),                 tags$td("Commodity geospatial capability")),
                      tags$tr(tags$td("Google Maps API"),     tags$td("Buy"),                                  tags$td("No alternative for route polylines + Street View")),
                      tags$tr(tags$td("Isaac Sim PhysX"),     tags$td("Buy (NVIDIA)",  ),                     tags$td("Physics engine is commodity; vehicle configs are custom")),
                      tags$tr(tags$td("AV readiness model"),  tags$td("Build"),                               tags$td("Core IP — unique domain knowledge + expert labels")),
                      tags$tr(tags$td("Risk classification"), tags$td("Build"),                               tags$td("UK-specific road features; regulatory requirements")),
                      tags$tr(tags$td("R Shiny interface"),   tags$td("Build"),                               tags$td("Bespoke workflow; multi-module integration")),
                      tags$tr(tags$td("HD Maps (future)"),    tags$td("Buy (OS MasterMap)"),                  tags$td("Lane-level accuracy beyond OSM capability")  )
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("The Five-Source Platform as Competitive Advantage"),
                  tags$p("From a Huyen Ch.10 perspective, the AteraSuite five-source platform's value is not in any individual component — all five sources are available to competitors. The competitive advantage is:"),
                  tags$ul(
                    tags$li(tags$b("Integration:"), " no other platform fuses all five sources into a single AV readiness score with physics validation"),
                    tags$li(tags$b("Innovate UK credibility:"), " the five-source framework was designed specifically to satisfy WP5-WP7 evidence requirements — a bespoke capability"),
                    tags$li(tags$b("Domain expertise:"), " the labelling rubric, CLASS_MAP for UK roads, and routing constraints encode CCAV domain knowledge that cannot be replicated without the same expertise"),
                    tags$li(tags$b("End-to-end pipeline:"), " from OSM query to Leaflet risk map with one click — the integration is the product, not any single model")
                  ),
                  div(class="tip-box", HTML("<strong>Huyen Ch.10 principle:</strong> Build when it is a core differentiator. For Atera Analytics, the integration and domain knowledge ARE the differentiator. The individual models (YOLOv8, XGBoost) are commodities that any team could build. The configured, validated, Innovate UK-evidenced pipeline cannot be replicated quickly."))
                )
              )
            )
          )
        )
      )
    ),

    # ── Self-Assessment ────────────────────────────────────────────────────
    fluidRow(
      box(title="📊 Self-Assessment: AV Infrastructure Case Study",
          status="success", solidHeader=TRUE, width=12,
        fluidRow(
          column(4,
            sliderInput(ns("sc_av1"), "Problem framing & ODD design",       0,10,5),
            sliderInput(ns("sc_av2"), "Five-source data pipeline",          0,10,5),
            sliderInput(ns("sc_av3"), "YOLO + XGBoost model development",   0,10,5),
            sliderInput(ns("sc_av4"), "Phased deployment & continual learn",0,10,5),
            sliderInput(ns("sc_av5"), "Monitoring & responsible AV AI",     0,10,5),
            actionButton(ns("save_av"), "Save Assessment", class="btn-meta", width="100%")
          ),
          column(8, br(), uiOutput(ns("av_result")))
        )
      )
    )
  )
}

av_infrastructure_case_study_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_av, {
      avg <- mean(c(input$sc_av1, input$sc_av2, input$sc_av3, input$sc_av4, input$sc_av5))
      pct <- round(avg * 10)
      prep_manager$update_progress("av_infrastructure_case_study", pct)
      output$av_result <- renderUI({
        div(class=if(pct>=70)"success-box"else"tip-box",
          tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
          if(pct>=80) tags$p("Strong AV infrastructure knowledge. In interviews: lead with the two-stage assessment pipeline (pre-deployment batch vs on-board real-time), name the sim-to-real gap as a key validation challenge, and frame the ODD boundary as an ML output — not just a business requirement.")
          else tags$p("Review: CLASS_MAP train-serve skew fix, phased ODD deployment mapped to Huyen's shadow/canary rollout, and why degenerate feedback loops are the critical safety risk in AV data collection strategy.")
        )
      })
      showNotification(paste0("AV Case Study: ",pct,"% saved"), type="message")
    })
  })
}
