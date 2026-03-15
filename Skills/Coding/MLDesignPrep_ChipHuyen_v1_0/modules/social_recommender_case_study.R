# modules/social_recommender_case_study.R
# Case Study: Large-Scale Social Media Recommender System (Meta-style)
# Applies Chip Huyen's ML lifecycle to Facebook/Instagram-scale recommendation

social_recommender_case_study_ui <- function(id) {
  ns <- NS(id)

  css <- "
  .sm-selector {
    display:flex; gap:5px; flex-wrap:wrap; margin-bottom:14px;
  }
  .sm-btn {
    padding:5px 15px; border-radius:18px; border:2px solid #b2dfdb;
    background:#fff; color:#008A82; font-size:11px; font-weight:700;
    cursor:pointer; transition:all 0.16s; letter-spacing:0.3px; white-space:nowrap;
  }
  .sm-btn:hover  { background:#e0f4f2; border-color:#008A82; }
  .sm-btn.active { background:#002C3C; border-color:#002C3C; color:#fff; }
  .sm-panel { display:none; animation:smFade 0.18s ease; }
  .sm-panel.show { display:block; }
  @keyframes smFade { from{opacity:0;transform:translateY(-5px)} to{opacity:1;transform:translateY(0)} }
  .sm-arch-node {
    display:inline-block; padding:7px 14px; border-radius:7px; margin:3px;
    font-size:11px; font-weight:700; border:2px solid;
  }
  .sm-arch-arr { color:#008A82; font-size:18px; font-weight:700; vertical-align:middle; margin:0 4px; }
  .sm-kpi-card {
    background:linear-gradient(135deg,#002C3C,#008A82);
    border-radius:10px; padding:14px; text-align:center; color:#fff; margin-bottom:10px;
  }
  .sm-kpi-val { font-size:1.8em; font-weight:800; display:block; font-family:'JetBrains Mono',monospace; }
  .sm-kpi-lbl { font-size:10px; text-transform:uppercase; letter-spacing:1px; opacity:0.75; margin-top:4px; }
  "

  js <- "
<script>
function smShow(boxId, panelId) {
  document.querySelectorAll('#' + boxId + ' .sm-panel').forEach(function(p){
    p.classList.remove('show');
  });
  document.querySelectorAll('#' + boxId + ' .sm-btn').forEach(function(b){
    b.classList.remove('active');
  });
  var panel = document.getElementById(panelId);
  if (panel) panel.classList.add('show');
  var btn = document.querySelector('#' + boxId + ' [data-panel=\"' + panelId + '\"]');
  if (btn) btn.classList.add('active');
}
(function(){
  function init(){
    ['sm-box1','sm-box2','sm-box3','sm-box4','sm-box5'].forEach(function(boxId){
      var firstBtn = document.querySelector('#' + boxId + ' .sm-btn');
      if (firstBtn) firstBtn.click();
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else setTimeout(init, 120);
})();
</script>
"

  smBtn <- function(boxId, panelId, label, active=FALSE) {
    tags$button(
      class=paste0("sm-btn", if(active)" active"else""),
      `data-panel`=panelId,
      onclick=sprintf("smShow('%s','%s')", boxId, panelId),
      label
    )
  }
  smPanel <- function(panelId, ...) div(id=panelId, class="sm-panel", ...)

  tagList(
    tags$head(tags$style(HTML(css))),
    HTML(js),

    # ── Hero ────────────────────────────────────────────────────────────────
    div(class="meta-hero",
      tags$h1("Case Study — Social Media Recommender System"),
      tags$h2("Large-scale personalisation for billions of users: Meta Facebook/Instagram-style architecture"),
      div(
        span(class="hero-badge","Candidate Generation"),
        span(class="hero-badge","Two-Tower Ranking"),
        span(class="hero-badge","Graph Neural Networks"),
        span(class="hero-badge","Multi-Objective"),
        span(class="hero-badge","Billions of Events/Day"),
        span(class="hero-badge","Real Production Scale")
      ),
      tags$p(style="color:rgba(255,255,255,0.75);font-size:12px;margin-top:10px;",
        "Every section maps directly to Chip Huyen's ML lifecycle. Scale: billions of users, petabytes of daily interactions, sub-100ms feed serving.")
    ),

    # ── Architecture Overview ─────────────────────────────────────────────
    fluidRow(
      box(title="🏗️ System Architecture Overview", status="primary", solidHeader=TRUE, width=12,
        div(style="text-align:center;padding:16px;",
          div(style="margin-bottom:8px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","EVENT STREAMS  (billions/day)"),
          div(
            span(class="sm-arch-node",style="background:#fff3e0;border-color:#e67e22;color:#e67e22;","Likes / Comments"),
            span(class="sm-arch-node",style="background:#fff3e0;border-color:#e67e22;color:#e67e22;","Video Watch Time"),
            span(class="sm-arch-node",style="background:#fff3e0;border-color:#e67e22;color:#e67e22;","Shares / Saves"),
            span(class="sm-arch-node",style="background:#fff3e0;border-color:#e67e22;color:#e67e22;","Scrolls / Skips"),
            span(class="sm-arch-node",style="background:#e3f2fd;border-color:#2980b9;color:#2980b9;","Social Graph Events"),
            span(class="sm-arch-node",style="background:#e3f2fd;border-color:#2980b9;color:#2980b9;","Ad Clicks")
          ),
          div(style="font-size:22px;color:#008A82;margin:5px 0;","↓"),
          div(style="margin-bottom:6px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","INGESTION  (Kafka-style streaming + batch)"),
          div(
            span(class="sm-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Distributed Event Log"),
            span(class="sm-arch-arr","→"),
            span(class="sm-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Feature Store"),
            span(class="sm-arch-arr","→"),
            span(class="sm-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Training Datasets (petabytes)")
          ),
          div(style="font-size:22px;color:#008A82;margin:5px 0;","↓"),
          div(style="margin-bottom:6px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","TWO-STAGE RECOMMENDATION PIPELINE"),
          div(
            span(class="sm-arch-node",style="background:#e8f5e9;border-color:#1a9b6b;color:#1a9b6b;","Candidate Generation"),
            span(class="sm-arch-arr","→"),
            span(class="sm-arch-node",style="background:#e8f5e9;border-color:#1a9b6b;color:#1a9b6b;","Ranking Models"),
            span(class="sm-arch-arr","→"),
            span(class="sm-arch-node",style="background:#e8f5e9;border-color:#1a9b6b;color:#1a9b6b;","Multi-objective Scoring"),
            span(class="sm-arch-arr","→"),
            span(class="sm-arch-node",style="background:#e8f5e9;border-color:#1a9b6b;color:#1a9b6b;","Feed Assembly")
          ),
          div(style="font-size:22px;color:#008A82;margin:5px 0;","↓"),
          div(style="margin-bottom:6px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","SERVING  (<100ms end-to-end)"),
          div(
            span(class="sm-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","Distributed Model Servers"),
            span(class="sm-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","GPU/CPU Inference Clusters"),
            span(class="sm-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","Caching Layers"),
            span(class="sm-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","Feed API")
          ),
          div(style="font-size:22px;color:#e67e22;margin:5px 0;","↺"),
          div(style="font-size:11px;color:#546e7a;font-weight:700;letter-spacing:1px;","FEEDBACK LOOP → USER INTERACTIONS → NEW TRAINING DATA"),
          br(),
          fluidRow(
            column(3, div(class="sm-kpi-card", span(class="sm-kpi-val","3B+"),  span(class="sm-kpi-lbl","Daily Active Users"))),
            column(3, div(class="sm-kpi-card", span(class="sm-kpi-val","100B+"),span(class="sm-kpi-lbl","Events per Day"))),
            column(3, div(class="sm-kpi-card", span(class="sm-kpi-val","<100ms"),span(class="sm-kpi-lbl","Feed Serving SLO"))),
            column(3, div(class="sm-kpi-card", span(class="sm-kpi-val","500+"), span(class="sm-kpi-lbl","Candidate Items Ranked")))
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 1: Ch.1-2 — Problem Definition & System Design
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="📋 Box 1 — Ch.1-2: Problem Definition & System Design",
          status="primary", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 1 & 2 applied:</strong> At Meta scale, defining the problem precisely matters enormously — optimising the wrong metric has caused real-world harm. This box covers framing, ML task decomposition, metric design, and constraints.")),
        br(),
        div(id="sm-box1",
          div(class="sm-selector",
            smBtn("sm-box1","sm1-framing","Business → ML Framing", TRUE),
            smBtn("sm-box1","sm1-tasks","ML Task Decomposition"),
            smBtn("sm-box1","sm1-metrics","Metrics & Objectives"),
            smBtn("sm-box1","sm1-constraints","Scale Constraints"),
            smBtn("sm-box1","sm1-loop","Iterative Design Loop")
          ),

          smPanel("sm1-framing",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Business Goal → ML Objective Translation (Ch.1)"),
                  tags$p("The platform's business goal is deceptively simple: keep users engaged. But naive ML framing creates well-documented problems:"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Business Goal"),tags$th("Naive ML Objective"),tags$th("Problem"),tags$th("Better Framing"))),
                    tags$tbody(
                      tags$tr(tags$td("Engagement"),  tags$td("Maximise clicks"),      tags$td("Clickbait, outrage content"),   tags$td("Maximise meaningful interactions")),
                      tags$tr(tags$td("Retention"),   tags$td("Maximise session time"), tags$td("Addictive, low-quality loops"), tags$td("Long-term user value (LTV)")),
                      tags$tr(tags$td("Growth"),      tags$td("Maximise friend requests"),tags$td("Spam connections"),          tags$td("Meaningful social graph density")),
                      tags$tr(tags$td("Creator rev."),tags$td("Maximise ad impressions"),tags$td("Ad overload, user flight"),  tags$td("Ad relevance + user experience balance"))
                    )
                  ),
                  div(class="warn-box", HTML("<strong>Huyen Ch.1 warning:</strong> The ML objective must align with the true business goal, not a proxy that can be gamed. At Meta scale, misaligned objectives affect billions of people."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Content Types as Separate ML Problems"),
                  tags$p("Each content type is a distinct ML sub-problem with different label types, data distributions, and serving constraints:"),
                  tags$ul(
                    tags$li(tags$b("Short-form video:"), " watch completion rate (continuous), re-watch probability, sound-on rate"),
                    tags$li(tags$b("Photos:"), " P(like), P(comment), P(save), P(share)"),
                    tags$li(tags$b("Text posts:"), " P(click read more), P(comment), P(share)"),
                    tags$li(tags$b("Friend suggestions:"), " P(send request), P(accept), P(meaningful interaction in 30 days)"),
                    tags$li(tags$b("Group suggestions:"), " P(join), P(post in group within 7 days)"),
                    tags$li(tags$b("Live streams:"), " P(join), expected watch duration"),
                    tags$li(tags$b("Ads:"), " P(click), P(conversion) — separate billing and auction system")
                  )
                )
              )
            )
          ),

          smPanel("sm1-tasks",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Retrieval — Finding Candidates"),
                  tags$p(tags$b("Task type:"), " approximate nearest neighbour search in embedding space. Not a classification task."),
                  tags$p(tags$b("Input:"), " user embedding vector at query time."),
                  tags$p(tags$b("Output:"), " top-K most similar content items from a corpus of billions."),
                  tags$p(tags$b("Scale:"), " must search billions of items in <10ms. Exact search impossible — use ANN (FAISS, ScaNN, HNSW)."),
                  tags$p(tags$b("Why a separate stage:"), " ranking models are too expensive (deep neural nets) to run on billions of candidates. Retrieval reduces to ~500 items for ranking.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Ranking — Scoring Candidates"),
                  tags$p(tags$b("Task type:"), " multi-label binary classification (predict multiple engagement signals simultaneously) + regression (watch time)."),
                  tags$p(tags$b("Input:"), " user features + content features + social graph features + context."),
                  tags$p(tags$b("Output:"), " vector of engagement probabilities per item: [P(like), P(comment), P(share), E(watch_time)]."),
                  tags$p(tags$b("Multi-task learning:"), " one shared representation with separate prediction heads per engagement type. More efficient than separate models.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Final Scoring & Diversity"),
                  tags$p(tags$b("Task type:"), " constrained optimisation. Combine engagement scores with diversity, freshness, and safety constraints."),
                  tags$p(tags$b("Scoring function:"),),
                  tags$p(style="font-family:monospace;background:#f8fffe;padding:8px;border-radius:6px;font-size:11px;",
                    "score = w1*P(like) + w2*P(comment)*4 + w3*E(watch_time) + w4*P(share)*3 - w5*P(hide) - w6*P(report)"),
                  tags$p(tags$b("Weights tuned:"), " offline by engagement team, validated by A/B test. Comments weighted more than likes (stronger signal of meaningful engagement).")
                )
              )
            )
          ),

          smPanel("sm1-metrics",
            fluidRow(
              column(5,
                div(class="framework-card",
                  tags$h5("The Metric Selection Problem (Ch.2)"),
                  tags$p("At social media scale, metric selection has enormous consequences. Huyen's framework: choose metrics that genuinely reflect the business goal, not just what's easy to measure."),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Metric"),tags$th("Easy to Optimise"),tags$th("Problem"),tags$th("Better"))),
                    tags$tbody(
                      tags$tr(tags$td("Clicks"),          tags$td("Yes"), tags$td("Clickbait"),         tags$td("Click + dwell > 15s")),
                      tags$tr(tags$td("Likes"),           tags$td("Yes"), tags$td("Shallow engagement"), tags$td("Comments + shares")),
                      tags$tr(tags$td("Session time"),    tags$td("Yes"), tags$td("Doom-scrolling"),     tags$td("Satisfaction survey")),
                      tags$tr(tags$td("DAU"),             tags$td("Medium"),tags$td("Compulsive use"),   tags$td("Meaningful session rate")),
                      tags$tr(tags$td("Friend count"),    tags$td("Yes"), tags$td("Spam connections"),   tags$td("Interaction with friends")),
                      tags$tr(tags$td("Creator reach"),   tags$td("Yes"), tags$td("Homogenisation"),     tags$td("Creator diversity index"))
                    )
                  )
                )
              ),
              column(7,
                div(class="framework-card",
                  tags$h5("Multi-Objective Optimisation — Balancing Competing Metrics"),
                  tags$p("The system must simultaneously optimise for many objectives that trade off against each other:"),
                  tags$ul(
                    tags$li(tags$b("Relevance:"), " show content the user is most likely to engage with"),
                    tags$li(tags$b("Freshness:"), " prioritise recent content; stale feed is frustrating"),
                    tags$li(tags$b("Diversity:"), " avoid filter bubbles; expose users to new creators and topics"),
                    tags$li(tags$b("Safety:"), " demote harmful, misleading, or policy-violating content"),
                    tags$li(tags$b("Fairness:"), " equal opportunity for creators regardless of follower count"),
                    tags$li(tags$b("Business:"), " ad slot allocation without destroying user experience")
                  ),
                  div(class="tip-box", HTML("<strong>Huyen Ch.2 principle:</strong> When objectives conflict, the resolution is a value judgment, not a technical decision. The weights in the scoring function encode the company's values about what matters more."))
                ),
                div(class="framework-card",
                  tags$h5("Guardrail Metrics"),
                  tags$p("Every A/B test of a new recommendation model must not violate these:"),
                  tags$ul(
                    tags$li("User report rate (must not increase)"),
                    tags$li("Harmful content impression rate (must not increase)"),
                    tags$li("Creator diversity score (must not decrease)"),
                    tags$li("p99 feed load latency (must stay <100ms)")
                  )
                )
              )
            )
          ),

          smPanel("sm1-constraints",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Scale Constraints — Unlike Any Other ML System"),
                  tags$p("The system design is dominated by scale constraints that simply don't exist at smaller systems:"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Constraint"),tags$th("Value"),tags$th("Design Implication"))),
                    tags$tbody(
                      tags$tr(tags$td("Users"),            tags$td("3B+ DAU"),       tags$td("Cannot store per-user model")),
                      tags$tr(tags$td("Content pool"),     tags$td("Billions items"), tags$td("Two-stage retrieval mandatory")),
                      tags$tr(tags$td("Feed serving SLO"), tags$td("<100ms"),         tags$td("Ranking model must be fast")),
                      tags$tr(tags$td("Events/day"),       tags$td("100B+"),          tags$td("Streaming ingestion only")),
                      tags$tr(tags$td("Model size"),       tags$td("Billions params"),tags$td("Distributed training required")),
                      tags$tr(tags$td("Inference QPS"),    tags$td("Millions/sec"),   tags$td("GPU clusters + caching")),
                      tags$tr(tags$td("Training data"),    tags$td("Petabytes"),      tags$td("Distributed storage + compute"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Latency Budget Breakdown (Ch.7)"),
                  tags$p("Every millisecond matters at this scale. A single feed request involves:"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Stage"),tags$th("Budget"),tags$th("Technique"))),
                    tags$tbody(
                      tags$tr(tags$td("User context fetch"),      tags$td("5ms"),  tags$td("In-memory cache")),
                      tags$tr(tags$td("Candidate generation"),    tags$td("20ms"), tags$td("ANN search (FAISS)")),
                      tags$tr(tags$td("Feature assembly"),        tags$td("15ms"), tags$td("Online feature store")),
                      tags$tr(tags$td("Ranking model inference"), tags$td("30ms"), tags$td("GPU + INT8 quantisation")),
                      tags$tr(tags$td("Post-ranking / diversity"),tags$td("10ms"), tags$td("Rule-based + lightweight")),
                      tags$tr(tags$td("Feed assembly + API"),     tags$td("10ms"), tags$td("—")),
                      tags$tr(tags$td(tags$b("Total")),           tags$td(tags$b("~90ms")), tags$td(tags$b("SLO: 100ms ✓")))
                    )
                  )
                )
              )
            )
          ),

          smPanel("sm1-loop",
            fluidRow(
              column(12,
                div(class="framework-card",
                  tags$h5("Huyen's 6-Step Iterative Loop Applied to Social Recommendation (Ch.2)"),
                  fluidRow(
                    column(6,
                      timeline_entry("1","Project Scoping","Define: feed ranking for video + photos + posts. North-star metric: meaningful engagement rate (comments + shares > likes). Latency SLO: <100ms. Safety: content policy integration required."),
                      timeline_entry("2","Data Engineering","Event streaming pipeline ingesting 100B+ events/day. Kafka-style distributed log. Two pipelines: real-time (feature updates) + batch (training data). Feature store with online (Redis) + offline (distributed columnar) tiers."),
                      timeline_entry("3","Model Development","Start with LightGBM baseline on structured features. Iterate to Two-Tower Neural Net for candidate generation, Deep learning ranking model. Add GNN for social graph signals.")
                    ),
                    column(6,
                      timeline_entry("4","Evaluation","Offline: AUC per engagement type, NDCG@K for ranking, MAP for retrieval. Online: A/B test meaningful engagement rate, creator diversity, report rate. Sliced evaluation by content type, creator tier, geography."),
                      timeline_entry("5","Deployment","Two-stage serving: ANN retrieval service + GPU ranking cluster. Continuous model updates. Shadow deployment before canary. Model registry with 100+ concurrent model versions (different user segments get different models)."),
                      timeline_entry("6","Monitoring","Real-time dashboard: engagement rates, latency, content diversity. Drift detection on feature distributions. Degenerate feedback loop detection — key risk unique to recommendation systems.")
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
    # BOX 2: Ch.3-4-5 — Data Engineering, Training Data & Feature Engineering
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🗄️ Box 2 — Ch.3-4-5: Data Engineering, Training Data & Features",
          status="warning", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 3, 4 & 5 applied:</strong> At petabyte scale, data engineering is not a support function — it is the core bottleneck. Labelling strategy, class imbalance, feedback loops, and feature store design are all more complex than at smaller scales.")),
        br(),
        div(id="sm-box2",
          div(class="sm-selector",
            smBtn("sm-box2","sm2-ingestion","Event Ingestion (Ch.3)", TRUE),
            smBtn("sm-box2","sm2-labels","Labels & Imbalance (Ch.4)"),
            smBtn("sm-box2","sm2-features","Feature Categories (Ch.5)"),
            smBtn("sm-box2","sm2-featurestore","Feature Store at Scale"),
            smBtn("sm-box2","sm2-loops","Degenerate Feedback Loops")
          ),

          smPanel("sm2-ingestion",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Batch vs Streaming (Ch.3)"),
                  tags$p("Both pipelines run in parallel with different purposes:"),
                  tags$p(tags$b("Real-time streaming pipeline:")),
                  tags$ul(
                    tags$li("Captures events within seconds of occurrence"),
                    tags$li("Feeds online feature store (e.g., user's last 5 clicks)"),
                    tags$li("Powers session-level recommendations"),
                    tags$li("Infrastructure: Kafka-style distributed log, Flink processing")
                  ),
                  tags$p(tags$b("Batch pipeline:")),
                  tags$ul(
                    tags$li("Processes historical interaction logs"),
                    tags$li("Generates training datasets daily/weekly"),
                    tags$li("Computes long-term behavioural features (30/90/365d windows)"),
                    tags$li("Infrastructure: distributed columnar storage, Spark/MapReduce")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Data Formats at Petabyte Scale (Ch.3)"),
                  tags$p(tags$b("Training data format choice is critical:"),),
                  tags$ul(
                    tags$li(tags$b("Columnar (Parquet/ORC):"), " fast reads for feature generation SQL queries. Default for training dataset creation."),
                    tags$li(tags$b("Row-oriented (TFRecord/Arrow):"), " fast sequential reads for training loops. Convert from Parquet before training."),
                    tags$li(tags$b("HDF5:"), " embedding storage. User/item embedding matrices too large for standard formats."),
                    tags$li(tags$b("Delta/Iceberg:"), " time-travel queries for point-in-time correct training sets. ACID transactions on data lake.")
                  ),
                  div(class="tip-box", HTML("<strong>Scale reality:</strong> At Meta scale, simply reading a training dataset takes hours. Format choice can mean the difference between a 2-hour training job and a 6-hour one."))
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Sampling Strategy (Ch.4)"),
                  tags$p("Cannot train on 100% of events — too expensive. Sampling strategy matters:"),
                  tags$ul(
                    tags$li(tags$b("Negative sampling:"), " most content is never shown to most users. Need to sample unshown items as negatives. Random negative sampling ≠ hard negatives."),
                    tags$li(tags$b("Stratified sampling:"), " ensure rare engagement types (shares, comments) are not underrepresented in training batches"),
                    tags$li(tags$b("Temporal sampling:"), " recent data weighted more heavily. Exponential decay on event timestamps."),
                    tags$li(tags$b("Impression bias:"), " only items shown can be trained on — creates systematic bias toward already-popular content. Correction: importance-weighted loss.")
                  )
                )
              )
            )
          ),

          smPanel("sm2-labels",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Natural Labels and Their Delays (Ch.4)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Engagement Type"),tags$th("Label"),tags$th("Delay"),tags$th("Noise Level"))),
                    tags$tbody(
                      tags$tr(tags$td("Like"),          tags$td("Binary (liked/not)"),    tags$td("Seconds"),    tags$td("Low")),
                      tags$tr(tags$td("Comment"),       tags$td("Binary"),                tags$td("Minutes"),    tags$td("Low")),
                      tags$tr(tags$td("Share"),         tags$td("Binary"),                tags$td("Minutes"),    tags$td("Low")),
                      tags$tr(tags$td("Watch time"),    tags$td("Continuous (seconds)"), tags$td("Real-time"),   tags$td("Medium (background play)")),
                      tags$tr(tags$td("Friend request"),tags$td("Binary (sent)"),         tags$td("Immediate"),  tags$td("Medium (spam)")),
                      tags$tr(tags$td("Friend accept"), tags$td("Binary"),                tags$td("Days"),       tags$td("Low")),
                      tags$tr(tags$td("Group join"),    tags$td("Binary"),                tags$td("Immediate"),  tags$td("Low")),
                      tags$tr(tags$td("Hide/Report"),   tags$td("Binary (negative)"),     tags$td("Immediate"),  tags$td("Low"))
                    )
                  ),
                  div(class="warn-box", HTML("<strong>Watch time noise:</strong> Video autoplays in background counts as watch time but is not meaningful engagement. Must filter: sound-on + scroll stopped + >50% viewport visible = genuine watch signal."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Class Imbalance at Social Scale (Ch.4)"),
                  tags$p("Engagement is extremely rare relative to impressions:"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Action"),tags$th("Rate vs Impressions"),tags$th("Implication"))),
                    tags$tbody(
                      tags$tr(tags$td("Like"),       tags$td("~5-8%"),    tags$td("Manageable with class weights")),
                      tags$tr(tags$td("Comment"),    tags$td("~0.5-1%"),  tags$td("Significant imbalance: focal loss")),
                      tags$tr(tags$td("Share"),      tags$td("~0.1-0.3%"),tags$td("Severe imbalance: upsample, focal loss")),
                      tags$tr(tags$td("Report"),     tags$td("~0.01%"),   tags$td("Extreme imbalance: separate safety model"))
                    )
                  ),
                  tags$p(tags$b("Solution:"), " multi-task model with task-specific loss weighting. Comments and shares upweighted 4-8× because they are stronger quality signals despite rarity.")
                )
              )
            )
          ),

          smPanel("sm2-features",
            fluidRow(
              column(3,
                div(class="framework-card",
                  tags$h5("User Features (Ch.5)"),
                  tags$ul(
                    tags$li("Account age, device, language, location"),
                    tags$li("Engagement rate history (30/90d)"),
                    tags$li("Content type preferences"),
                    tags$li("Creator affinity scores"),
                    tags$li("Topic interest embeddings"),
                    tags$li("Session context: time, device, network quality"),
                    tags$li("Recently viewed content IDs (real-time)"),
                    tags$li("User embedding vector (dense, 256-512 dim)")
                  )
                )
              ),
              column(3,
                div(class="framework-card",
                  tags$h5("Content Features (Ch.5)"),
                  tags$ul(
                    tags$li("Content type (video/photo/text)"),
                    tags$li("Creator ID + creator popularity score"),
                    tags$li("Topic classification (multi-label)"),
                    tags$li("Media embedding (visual/audio/text)"),
                    tags$li("Post age (freshness decay)"),
                    tags$li("Engagement velocity (likes in last hour)"),
                    tags$li("Language and region tags"),
                    tags$li("Content embedding vector (dense, 256 dim)")
                  )
                )
              ),
              column(3,
                div(class="framework-card",
                  tags$h5("Social Graph Features (Ch.5)"),
                  tags$p(tags$b("Critical for Facebook/Instagram — unique to social platforms:")),
                  tags$ul(
                    tags$li("Mutual friend count between user and creator"),
                    tags$li("Interaction frequency (messages, comments)"),
                    tags$li("Group membership overlap"),
                    tags$li("Second-degree connection score"),
                    tags$li("Social proximity embedding (node2vec / GraphSAGE)"),
                    tags$li("Creator: does user follow them?"),
                    tags$li("Has user engaged with this creator in last 30 days?")
                  )
                )
              ),
              column(3,
                div(class="framework-card",
                  tags$h5("Cross Features & Embeddings (Ch.5)"),
                  tags$p(tags$b("User × Item interaction features:")),
                  tags$ul(
                    tags$li("User topic interest × content topic match score"),
                    tags$li("User's historical CTR for this content type"),
                    tags$li("Creator affinity: weighted avg of past engagements"),
                    tags$li("Collaborative signal: users similar to me liked this")
                  ),
                  div(class="tip-box", HTML("<strong>Feature crossing:</strong> Wide-and-Deep networks learn feature crosses automatically, removing need for hand-engineered cross features. DLRM architecture (Meta) uses product interactions between sparse embeddings."))
                )
              )
            )
          ),

          smPanel("sm2-featurestore",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Feature Store at Social Scale (Ch.5)"),
                  tags$p("Two-tier feature store pattern — same as banking but at 1000× scale:"),
                  tags$ul(
                    tags$li(tags$b("Online store (Redis / custom in-memory):"), " user session features, real-time engagement signals. Must serve <5ms. Stores: last N viewed items, current session engagement, real-time creator engagement velocity."),
                    tags$li(tags$b("Offline store (distributed columnar):"), " historical features for training. Point-in-time joins on petabyte datasets. Spark-based feature computation.")
                  ),
                  tags$p(tags$b("Train-serve skew at scale (Ch.5 — Huyen #1 failure):"), " At this scale, skew is almost guaranteed if not architecturally prevented:"),
                  tags$ul(
                    tags$li("Real-time features computed differently in Flink (serving) vs Spark (training)"),
                    tags$li("Session features available at serving time not reproducible at training time"),
                    tags$li("Feature store ensures exact same computation graph for both paths")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Embedding Storage Challenge"),
                  tags$p("User and content embeddings are a special storage challenge:"),
                  tags$ul(
                    tags$li(tags$b("3B users × 256 dims × float32:"), " = ~3TB embedding table. Cannot fit in single machine memory."),
                    tags$li(tags$b("Distributed embedding tables:"), " sharded across hundreds of machines. Each lookup requires network round-trip."),
                    tags$li(tags$b("Embedding compression:"), " product quantisation reduces from 256×4 bytes = 1KB per user to ~64 bytes. 16× compression with minimal accuracy loss."),
                    tags$li(tags$b("Cache strategy:"), " hot user embeddings (active users) cached in high-memory servers. Long-tail users computed on demand.")
                  ),
                  div(class="success-box", HTML("<strong>Key insight:</strong> At billion-user scale, embedding table lookup latency dominates over model inference latency. Optimising embedding storage and retrieval is more impactful than optimising the neural net."))
                )
              )
            )
          ),

          smPanel("sm2-loops",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Degenerate Feedback Loops (Ch.4 — Critical for Recommenders)"),
                  tags$p("Huyen dedicates specific attention to feedback loops in recommendation. Social media is the canonical example:"),
                  div(class="warn-box", HTML("<strong>Popularity bias loop:</strong> Model recommends popular content → popular content gets more impressions → more engagement data → model trains on this data → popular content ranked higher → loop amplifies. Result: content homogenisation, creator inequality.")),
                  br(),
                  tags$p(tags$b("How it manifests:"),),
                  tags$ul(
                    tags$li("New creators cannot break through — no impressions, no data, no ranking"),
                    tags$li("Content diversity drops over time as popular content dominates"),
                    tags$li("User interest bubbles form — model shows what users clicked before, reinforcing existing interests"),
                    tags$li("Outrage and extreme content gets more engagement → model learns to recommend it")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Mitigating Degenerate Feedback Loops"),
                  tags$p(tags$b("Exploration strategies (Ch.4 + Ch.9):"),),
                  tags$ul(
                    tags$li(tags$b("Epsilon-greedy exploration:"), " reserve 10-20% of feed slots for exploration — show content the model is uncertain about"),
                    tags$li(tags$b("Inverse propensity scoring:"), " correct for exposure bias by weighting training examples by inverse probability of being shown"),
                    tags$li(tags$b("Counterfactual training:"), " train on what would have happened if different content was shown (using logged exploration data)"),
                    tags$li(tags$b("Diversity constraints:"), " post-ranking: enforce minimum creator diversity, topic diversity in each feed"),
                    tags$li(tags$b("New creator boost:"), " artificially increase impression rate for new creators to collect data, accept short-term metric cost")
                  ),
                  div(class="tip-box", HTML("<strong>Huyen's principle:</strong> Degenerate feedback loops are not a bug — they are a structural property of recommendation systems trained on their own outputs. Must be architected against from day one."))
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 3: Ch.6 — Model Development: Retrieval, Ranking & Graph Models
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🧠 Box 3 — Ch.6: Model Development — Retrieval, Ranking & Graph Models",
          status="success", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapter 6 applied:</strong> Baseline hierarchy, Two-Tower retrieval, deep ranking architectures, GNNs for social graph, multi-task learning, HPO at scale, and offline evaluation strategy.")),
        br(),
        div(id="sm-box3",
          div(class="sm-selector",
            smBtn("sm-box3","sm3-baselines","Baseline Hierarchy", TRUE),
            smBtn("sm-box3","sm3-retrieval","Two-Tower Retrieval"),
            smBtn("sm-box3","sm3-ranking","Deep Ranking Model"),
            smBtn("sm-box3","sm3-gnn","Graph Neural Networks"),
            smBtn("sm-box3","sm3-eval","Offline Evaluation")
          ),

          smPanel("sm3-baselines",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Huyen's Baseline Hierarchy Applied"),
                  div(class="framework-card", style="border-left-color:#c0392b;",
                    tags$h5("Tier 1 — Random / Chronological"),
                    tags$p("Show most recent posts from followed accounts in reverse chronological order. No ML. Engagement rate: ~3%. This is the baseline every ML model must beat.")
                  ),
                  div(class="framework-card", style="border-left-color:#e67e22;",
                    tags$h5("Tier 2 — Rule-Based Heuristics"),
                    tags$p("Boost posts with high early engagement (likes in first 30 minutes). Penalise posts from accounts user hasn't interacted with in 90 days. Engagement rate: ~7%.")
                  ),
                  div(class="framework-card", style="border-left-color:#f39c12;",
                    tags$h5("Tier 3 — LightGBM on Structured Features"),
                    tags$p("GBDTs on user features + content features + social features. Fast to train, interpretable, strong baseline. Engagement rate: ~12%. Production baseline.")
                  ),
                  div(class="framework-card", style="border-left-color:#27ae60;",
                    tags$h5("Tier 4 — Deep Neural Net + Embeddings"),
                    tags$p("Two-Tower retrieval + deep ranking. Learns complex user-content interactions. Engagement rate: ~18%. Current production system.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("HPO at Scale (Ch.6)"),
                  tags$p("Standard HPO (Optuna, Vizier) is too expensive at this scale — a single training run takes days. Adapted HPO strategies:"),
                  tags$ul(
                    tags$li(tags$b("Progressive training:"), " train on 1% of data first; only promote promising configs to full training"),
                    tags$li(tags$b("Hyperband:"), " early-stopping of poor configurations based on validation performance at intermediate checkpoints"),
                    tags$li(tags$b("Population-based training:"), " evolve a population of model configs in parallel; copy weights from better performers"),
                    tags$li(tags$b("Architecture search is expensive:"), " major architecture decisions (Two-Tower vs Cross-Net) A/B tested in production, not just offline validation")
                  ),
                  div(class="tip-box", HTML("<strong>Meta practice:</strong> Embedding size is the highest-impact hyperparameter at scale. Increasing user embedding from 64 to 256 dims can improve NDCG more than any other single change."))
                )
              )
            )
          ),

          smPanel("sm3-retrieval",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Two-Tower Neural Network for Candidate Retrieval"),
                  tags$p(tags$b("Architecture:"), " Two separate neural network towers — one for users, one for items. Both towers project to the same embedding space. Similarity = dot product."),
                  tags$p(tags$b("Training objective:"), " contrastive loss — push user embedding close to items they engaged with, away from items they skipped. Sampled softmax over all items."),
                  tags$p(tags$b("Inference:"), " compute user embedding at query time. Find K nearest item embeddings using ANN search (FAISS, ScaNN). No need to score all items — just nearest neighbours in embedding space."),
                  tags$p(tags$b("Scale:"), " item tower embeddings pre-computed and indexed offline. User tower computed in real-time (~5ms). ANN search over billions of items: ~15ms with ScaNN."),
                  div(class="success-box", HTML("<strong>Why two-tower works at scale:</strong> Item embeddings only need to be computed once and indexed. User embedding is computed per request. Dot product similarity enables ANN search — cannot do this with cross-attention models."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("ANN Search — Approximate Nearest Neighbour"),
                  tags$p("Exact nearest neighbour search over billions of items is O(N×d) — impossible at real-time latency. ANN trades tiny accuracy loss for dramatic speed:"),
                  tags$ul(
                    tags$li(tags$b("FAISS (Facebook AI Similarity Search):"), " index types: IVF (inverted file), HNSW (hierarchical navigable small world), PQ (product quantisation). IVF-PQ achieves 100× speedup with <5% accuracy loss."),
                    tags$li(tags$b("ScaNN (Google):"), " anisotropic quantisation. Better recall than FAISS at same latency budget."),
                    tags$li(tags$b("HNSW:"), " graph-based. Best recall at low latency. High memory cost. Used for smaller indices (<100M items).")
                  ),
                  tags$p(tags$b("Multiple retrieval sources:"), " Two-Tower ANN is one of several retrieval sources. Also: social graph traversal (posts from friends), trending content, creator following list. Results merged and deduplicated before ranking.")
                )
              )
            )
          ),

          smPanel("sm3-ranking",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Deep Neural Net Ranking Model"),
                  tags$p(tags$b("Architecture:"), " Wide-and-Deep or DLRM (Deep Learning Recommendation Model, Meta)."),
                  tags$p(tags$b("Wide component:"), " memorisation — sparse cross features via linear model (handles exact feature combinations seen in training)."),
                  tags$p(tags$b("Deep component:"), " generalisation — dense embeddings through deep MLP (handles unseen feature combinations)."),
                  tags$p(tags$b("Input:"), " concatenated dense features (numeric) + sparse embeddings (user ID, item ID, creator ID looked up from embedding tables)."),
                  tags$p(tags$b("Multi-task output heads:"), " separate sigmoid heads per engagement type (like, comment, share, watch time). Shared bottom layers, task-specific towers at the top.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Multi-Task Learning for Engagement"),
                  tags$p("Rather than training separate models per engagement type, a single model predicts all simultaneously:"),
                  tags$ul(
                    tags$li("Shared representation captures common patterns"),
                    tags$li("Task-specific heads specialise for each signal"),
                    tags$li("Jointly trained: total loss = Σ(task_weight × task_loss)"),
                    tags$li(tags$b("Benefit:"), " rare labels (shares, comments) benefit from gradient signal from common labels (likes). Effectively increases training data for rare tasks.")
                  ),
                  tags$p(tags$b("Task weighting:"), " comment and share losses upweighted 4-8× vs like loss. Tuned to reflect business importance of 'meaningful engagement' vs shallow engagement.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Embedding Tables at Model Scale"),
                  tags$p("The largest component of a social recommender model is not the neural net — it is the embedding lookup tables:"),
                  tags$ul(
                    tags$li(tags$b("User embedding:"), " 3B rows × 256 dims ≈ 3TB"),
                    tags$li(tags$b("Item embedding:"), " billions of items, rotated daily"),
                    tags$li(tags$b("Creator embedding:"), " hundreds of millions × 128 dims")
                  ),
                  tags$p(tags$b("Distributed training:"), " model parallelism for embedding tables (sharded across GPUs). Data parallelism for MLP layers. ZeRO optimiser for memory efficiency."),
                  tags$p(tags$b("Sparse gradient:"), " most embedding rows receive zero gradient per batch. Sparse Adam optimiser essential for convergence.")
                )
              )
            )
          ),

          smPanel("sm3-gnn",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Graph Neural Networks for Social Signals (Ch.6)"),
                  tags$p("Social networks are graphs — friendship, interaction, and group membership form rich graph structures. Standard ML treats users independently; GNNs capture relational context."),
                  tags$p(tags$b("What GNNs capture that standard models miss:"),),
                  tags$ul(
                    tags$li("Second-degree connections: friend-of-friend content has strong relevance signal"),
                    tags$li("Community structure: users in same interest group respond similarly to new content"),
                    tags$li("Interaction patterns: bidirectional vs one-directional interactions have different signal strength"),
                    tags$li("Temporal graph evolution: new friendships are stronger signals than old ones")
                  ),
                  tags$p(tags$b("GraphSAGE:"), " learns node embeddings by aggregating features from local neighbourhood. Scalable — samples fixed-size neighbourhood at each hop, not full graph traversal.")
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("GNN Applications in the System"),
                  tags$ul(
                    tags$li(tags$b("Friend recommendation:"), " GNN over social graph predicts P(two users will form meaningful friendship). Features: mutual friends, shared groups, interaction history with mutuals, shared interests."),
                    tags$li(tags$b("Group recommendation:"), " GNN identifies communities of users with high group membership overlap. Suggests groups based on community embedding similarity."),
                    tags$li(tags$b("Content ranking augmentation:"), " GNN-computed social proximity embedding added as input feature to ranking model. 'How close is this user to the creator in the social graph?'"),
                    tags$li(tags$b("Creator discovery:"), " identify emerging creators whose content is spreading rapidly through a specific social cluster — precursor to viral growth.")
                  ),
                  div(class="warn-box", HTML("<strong>Scale challenge:</strong> Full GNN training on billions of nodes is infeasible. Mini-batch training with neighbourhood sampling (GraphSAGE) reduces to manageable scale. Recompute node embeddings daily."))
                )
              )
            )
          ),

          smPanel("sm3-eval",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Offline Evaluation Strategy (Ch.6)"),
                  tags$p(tags$b("Temporal split — mandatory:"), " train on events before date T; evaluate on T to T+7; test on T+7 to T+14. Random split would leak future engagement signals."),
                  tags$p(tags$b("Metrics by stage:"),),
                  tags$ul(
                    tags$li(tags$b("Retrieval:"), " Recall@K — what fraction of items the user engaged with are in the retrieved set? Target: Recall@500 > 0.90."),
                    tags$li(tags$b("Ranking:"), " NDCG@K, AUC per engagement type, MRR. K = typical visible feed length."),
                    tags$li(tags$b("Calibration:"), " predicted P(like)=0.05 should mean 5% of items at that score are liked. Critical for scoring function weight tuning.")
                  ),
                  tags$p(tags$b("Sliced evaluation — Huyen's non-negotiable:"),),
                  tags$ul(
                    tags$li("By content type (video vs photo vs text)"),
                    tags$li("By creator tier (mega / large / mid / micro / new)"),
                    tags$li("By user activity level (heavy / medium / light / new)"),
                    tags$li("By geography and language"),
                    tags$li("By device (mobile vs desktop)")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("The Offline-Online Metric Gap (Ch.6)"),
                  tags$p("At social scale, this gap is large and well-documented:"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Change"),tags$th("Offline NDCG"),tags$th("Online Eng."),tags$th("Explanation"))),
                    tags$tbody(
                      tags$tr(tags$td("GNN social features"),  tags$td("+2.1%"), tags$td("+8.3%"), tags$td("Offline data doesn't capture social network effect")),
                      tags$tr(tags$td("Add diversity penalty"), tags$td("-1.5%"), tags$td("+3.2%"), tags$td("Diversity improves retention not session engagement")),
                      tags$tr(tags$td("Video weight boost"),    tags$td("+0.8%"), tags$td("+11%"), tags$td("Video engagement not captured in click label")),
                      tags$tr(tags$td("Freshness boost"),       tags$td("-0.3%"), tags$td("+5.1%"), tags$td("Offline eval uses historical data; freshness unmeasurable offline"))
                    )
                  ),
                  div(class="warn-box", HTML("<strong>Huyen's lesson:</strong> At social scale, offline metrics are necessary for filtering obviously bad models but insufficient for selecting between good models. Every major architecture decision requires an online A/B test."))
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 4: Ch.7-9 — Deployment, Serving & Continual Learning
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🚀 Box 4 — Ch.7-9: Deployment, Serving & Continual Learning",
          status="danger", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 7, 8 & 9 applied:</strong> Two-stage serving pipeline, model compression for real-time inference, shadow and canary deployments, A/B testing at scale, and why social recommenders require near-continuous retraining.")),
        br(),
        div(id="sm-box4",
          div(class="sm-selector",
            smBtn("sm-box4","sm4-serving","Two-Stage Serving (Ch.7)", TRUE),
            smBtn("sm-box4","sm4-compression","Compression & Optimisation"),
            smBtn("sm-box4","sm4-deployment","Deployment Strategies (Ch.9)"),
            smBtn("sm-box4","sm4-abtesting","A/B Testing at Scale"),
            smBtn("sm-box4","sm4-continual","Continual Learning (Ch.9)")
          ),

          smPanel("sm4-serving",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Two-Stage Serving Pipeline (Ch.7)"),
                  tags$p("The serving pipeline mirrors the two-stage model architecture:"),
                  tags$p(tags$b("Stage 1 — Candidate Retrieval (<20ms):"),),
                  tags$ul(
                    tags$li("Compute user embedding: user tower inference (~5ms)"),
                    tags$li("ANN search over pre-indexed item embeddings (FAISS IVF-PQ): ~10ms"),
                    tags$li("Merge with rule-based sources: friend posts, following list, trending"),
                    tags$li("Output: ~500 candidate items with retrieval scores")
                  ),
                  tags$p(tags$b("Stage 2 — Ranking (<30ms):"),),
                  tags$ul(
                    tags$li("Feature assembly: pull user + content features from online feature store (~15ms)"),
                    tags$li("Batch ranking model inference on all 500 candidates simultaneously (GPU): ~15ms"),
                    tags$li("Apply diversity and freshness post-processing"),
                    tags$li("Final feed assembly: top N items ordered by composite score")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Batch vs Online Prediction (Ch.7)"),
                  tags$p("Pure online prediction at social scale is impossible — feed must respond in milliseconds. Hybrid approach:"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Component"),tags$th("Mode"),tags$th("Update Frequency"))),
                    tags$tbody(
                      tags$tr(tags$td("Item embeddings (ANN index)"), tags$td("Batch"),  tags$td("Hourly rebuild")),
                      tags$tr(tags$td("User long-term features"),     tags$td("Batch"),  tags$td("Daily")),
                      tags$tr(tags$td("User session features"),       tags$td("Streaming"),tags$td("Real-time")),
                      tags$tr(tags$td("User embedding (tower)"),      tags$td("Online"), tags$td("Per request")),
                      tags$tr(tags$td("Content engagement velocity"), tags$td("Streaming"),tags$td("Per event")),
                      tags$tr(tags$td("Ranking model inference"),     tags$td("Online"), tags$td("Per request"))
                    )
                  ),
                  div(class="tip-box", HTML("<strong>Key design:</strong> Item embeddings rebuilt hourly (not per request) enables ANN index caching. The index is the most expensive component — pre-building it batch is essential for sub-100ms serving."))
                )
              )
            )
          ),

          smPanel("sm4-compression",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Model Compression for Real-Time Inference (Ch.7)"),
                  tags$p("Ranking model is a deep neural net that must score 500 candidates in <30ms. Compression is not optional:"),
                  tags$ul(
                    tags$li(tags$b("INT8 quantisation (TensorRT):"), " ranking model inference 4× faster. <0.5% engagement loss. Used in production for all large neural ranking models."),
                    tags$li(tags$b("Embedding compression (Product Quantisation):"), " compress 256-dim float32 embeddings to 64-byte codes. 16× smaller index, 8× faster ANN search. Critical for billion-item index."),
                    tags$li(tags$b("Knowledge distillation:"), " train small 'student' ranking model on soft labels from large 'teacher'. Production model 3× smaller, 2.5× faster, 97% of teacher engagement quality."),
                    tags$li(tags$b("Batch inference:"), " rank all 500 candidates as a single batched GPU inference call. 10× more efficient than sequential scoring.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Caching Strategy"),
                  tags$p("At millions of requests per second, caching is essential:"),
                  tags$ul(
                    tags$li(tags$b("User embedding cache:"), " active user embeddings cached in memory. Cache hit rate ~80% (most users visit multiple times per day). TTL: 1 hour."),
                    tags$li(tags$b("Item score cache:"), " for frequently recommended items, pre-compute and cache ranking scores. Stale-while-revalidate pattern."),
                    tags$li(tags$b("Feed cache:"), " for returning users, cache the partially-assembled feed. Append new content to top rather than full recompute."),
                    tags$li(tags$b("Feature cache:"), " slow-changing user features (demographics, long-term preferences) cached 24 hours.")
                  )
                )
              )
            )
          ),

          smPanel("sm4-deployment",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Deployment Strategies at Social Scale (Ch.9)"),
                  tags$p("Deploying to billions of users requires extreme caution. Staged rollout:"),
                  tags$ol(
                    tags$li(tags$b("Shadow deployment:"), " new model runs alongside production, predictions logged but not served. Validate infrastructure, compare output distributions, catch regressions before any user sees it."),
                    tags$li(tags$b("1% canary:"), " 1% of users see new model recommendations. Monitor engagement rate, report rate, latency for 24-48 hours. Automated rollback if any guardrail violated."),
                    tags$li(tags$b("A/B test (10-50%):"), " proper controlled experiment to measure business metric impact with statistical significance."),
                    tags$li(tags$b("Gradual ramp (50-100%):"), " ramp traffic weekly if A/B test positive. Monitor for novelty effects."),
                    tags$li(tags$b("1% holdout retained:"), " permanently keep 1% of users on old model as continuous regression test for all future deployments.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Model Versioning Complexity"),
                  tags$p("Unlike most ML systems, a social recommender must serve many model versions simultaneously:"),
                  tags$ul(
                    tags$li(tags$b("A/B test users:"), " experimental cohort sees model v_new"),
                    tags$li(tags$b("Control users:"), " control cohort sees model v_current"),
                    tags$li(tags$b("Holdout users:"), " 1% see model v_baseline"),
                    tags$li(tags$b("Segment variants:"), " different user segments may run different architectures simultaneously"),
                    tags$li(tags$b("Geography variants:"), " models localised for different languages/regions")
                  ),
                  tags$p("At peak, 20-50 model variants may be serving simultaneously in a single ranking system. Model registry with traffic split configuration is essential infrastructure.")
                )
              )
            )
          ),

          smPanel("sm4-abtesting",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("A/B Testing at Billion-User Scale (Ch.9)"),
                  tags$p("Social platform A/B testing is fundamentally different from standard A/B tests:"),
                  tags$p(tags$b("Network interference — the biggest challenge:"),),
                  tags$p("Standard A/B tests assume treatment and control units are independent. On social networks, they are not: if Alice (treatment) sees better content and shares it, Bob (control) sees that shared content. Treatment bleeds into control."),
                  tags$p(tags$b("Solutions:"),),
                  tags$ul(
                    tags$li(tags$b("Graph-based randomisation:"), " assign entire social clusters (connected components) to treatment or control, not individual users"),
                    tags$li(tags$b("Ego-network isolation:"), " treatment user and all their friends assigned to same group"),
                    tags$li(tags$b("Geographic isolation:"), " different cities/regions assigned to different variants (but loses scale)"),
                    tags$li(tags$b("Accept the bias:"), " for small effects, network interference is negligible. Only matters for viral content experiments.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Interleaving and Bandits (Ch.9)"),
                  tags$p(tags$b("Interleaving:"), " instead of assigning users to variants, show a single user a feed assembled from both model A and model B (interleaved). Model whose items get more engagement wins. 100× more statistically efficient than A/B testing. Used extensively at Netflix and YouTube for ranking evaluation."),
                  tags$p(tags$b("Multi-armed bandits for model selection:"), " across dozens of model variants, Thompson Sampling dynamically allocates more traffic to better-performing models. Reduces regret vs fixed A/B split."),
                  tags$p(tags$b("Contextual bandits for content types:"), " bandit decides for each session whether to show more video, photos, or text based on user context and current session signals. Better than static content-type mix per user segment.")
                )
              )
            )
          ),

          smPanel("sm4-continual",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Why Social Recommenders Need Frequent Retraining (Ch.9)"),
                  tags$p("Social media data distribution shifts faster than almost any other domain:"),
                  tags$ul(
                    tags$li(tags$b("Viral content:"), " a post can go from 0 to 10M impressions in 6 hours. A model trained yesterday has no signal on it."),
                    tags$li(tags$b("Trending topics:"), " news events, memes, cultural moments create sudden new interest categories."),
                    tags$li(tags$b("New users:"), " millions of new users onboard weekly — cold start users have no history."),
                    tags$li(tags$b("Creator behaviour:"), " creators change content style, post frequency, topic. Historical embeddings go stale."),
                    tags$li(tags$b("Seasonal shifts:"), " holidays, sports seasons, elections create recurring distribution shifts.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Retraining Strategy (Ch.9)"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Model"),tags$th("Update Freq."),tags$th("Method"))),
                    tags$tbody(
                      tags$tr(tags$td("Item embeddings (ANN index)"),tags$td("Hourly"),    tags$td("Stateful: update new items only")),
                      tags$tr(tags$td("User embeddings"),            tags$td("Daily"),     tags$td("Stateful fine-tune on new events")),
                      tags$tr(tags$td("Ranking model MLP"),          tags$td("Daily"),     tags$td("Stateless retrain on rolling 14-day window")),
                      tags$tr(tags$td("GNN social embeddings"),      tags$td("Daily"),     tags$td("Stateless on updated graph snapshot")),
                      tags$tr(tags$td("Send-time / session bandit"), tags$td("Continuous"),tags$td("Online: update per interaction"))
                    )
                  ),
                  div(class="success-box", HTML("<strong>Key insight (Ch.9 — Huyen):</strong> For embedding models, stateful retraining (fine-tuning existing embeddings on new data) is far more efficient than stateless retraining. Item embeddings can be updated incrementally as new content is created. Full retraining only needed when model architecture changes."))
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
        div(class="info-box-plain", HTML("<strong>Chapters 8, 10 & 11 applied:</strong> Distribution shift detection in recommendation, MLOps at petabyte scale, fairness for creators and users, and the unique responsible AI challenges of social media recommendation.")),
        br(),
        div(id="sm-box5",
          div(class="sm-selector",
            smBtn("sm-box5","sm5-monitoring","Monitoring (Ch.8)", TRUE),
            smBtn("sm-box5","sm5-drift","Drift in Recommenders"),
            smBtn("sm-box5","sm5-infra","MLOps at Scale (Ch.10)"),
            smBtn("sm-box5","sm5-fairness","Creator & User Fairness"),
            smBtn("sm-box5","sm5-responsible","Responsible AI (Ch.11)")
          ),

          smPanel("sm5-monitoring",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("What to Monitor (Ch.8)"),
                  tags$p(tags$b("Model metrics:")),
                  tags$ul(
                    tags$li("Retrieval recall@500 — daily"),
                    tags$li("Ranking NDCG@10 — daily on held-out evaluation set"),
                    tags$li("Prediction calibration by engagement type"),
                    tags$li("Score distribution histogram per content type"),
                    tags$li("Embedding space: user-item distance distribution")
                  ),
                  tags$p(tags$b("Product metrics:")),
                  tags$ul(
                    tags$li("Engagement rate by content type"),
                    tags$li("Content diversity score (unique creators per session)"),
                    tags$li("Creator reach distribution (Gini coefficient)"),
                    tags$li("User satisfaction signal (survey-based, weekly)")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Infrastructure Metrics"),
                  tags$ul(
                    tags$li("Feed serving latency p50/p95/p99 — continuous"),
                    tags$li("ANN search latency by index type"),
                    tags$li("Embedding table lookup latency"),
                    tags$li("Ranking model GPU utilisation and throughput"),
                    tags$li("Feature store read latency (online store)"),
                    tags$li("Training pipeline: data freshness lag"),
                    tags$li("Model update deployment frequency"),
                    tags$li("Cache hit rate for user embeddings")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Alerting for Recommendation Systems"),
                  tags$p("Unique alerting challenges vs standard ML systems:"),
                  tags$ul(
                    tags$li(tags$b("Slow degradation:"), " recommender quality degrades gradually — hard to detect with threshold-based alerts. Use rolling 7-day trend, not point comparison."),
                    tags$li(tags$b("Diversity collapse alert:"), " creator Gini coefficient rising > 2σ above baseline → feedback loop forming"),
                    tags$li(tags$b("Cold content alert:"), " new items not appearing in feeds within 2 hours of posting → ANN index issue"),
                    tags$li(tags$b("Safety spike:"), " report rate doubling → harmful content entering retrieval")
                  )
                )
              )
            )
          ),

          smPanel("sm5-drift",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Distribution Shift Types in Recommendation (Ch.8)"),
                  tags$p(tags$b("Covariate shift — most common:")),
                  tags$ul(
                    tags$li("New content types emerge (e.g., Reels launched on Instagram). Input distribution shifts as video features appear in 30% of impressions."),
                    tags$li("User demographics shift as platform grows internationally. Language distribution in feature space changes."),
                    tags$li(tags$b("Detection:"), " PSI on content-type feature; KS test on embedding cosine similarity distributions.")
                  ),
                  tags$p(tags$b("Concept drift — unique to social media:")),
                  tags$ul(
                    tags$li("Cultural context changes: 'sick' (negative) → 'sick' (positive slang). Text embedding model assigns wrong sentiment."),
                    tags$li("Trend reversal: previously engaging content type (e.g., long-form video) becomes less appealing as user behaviour shifts to short-form."),
                    tags$li(tags$b("Detection:"), " requires ground truth — monitor post-event: does clicking this type of post still correlate with longer session time?")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Degenerate Feedback Loop Detection (Ch.4 + Ch.8)"),
                  tags$p("The most dangerous drift in recommendation is not external — it is the system creating its own distribution shift:"),
                  tags$ul(
                    tags$li(tags$b("Popularity concentration metric:"), " if top 0.1% of creators receive > 50% of impressions (Gini > 0.85), feedback loop is active"),
                    tags$li(tags$b("Topic homogenisation:"), " measure entropy of topic distribution across all served content. Declining entropy = narrowing diversity."),
                    tags$li(tags$b("Engagement inflation:"), " if aggregate engagement rate rises every week without model changes, it is likely that distribution shift (not model improvement) is the cause")
                  ),
                  div(class="warn-box", HTML("<strong>Huyen's warning:</strong> A recommendation model that looks like it is improving (rising engagement metrics) may actually be creating a feedback loop that harms long-term user satisfaction and creator diversity. Monitoring must include leading indicators of feedback loop formation, not just engagement KPIs."))
                )
              )
            )
          ),

          smPanel("sm5-infra",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("MLOps at Petabyte Scale (Ch.10)"),
                  tags$p("Standard MLOps tools do not scale to social media data volumes. Custom infrastructure required:"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Component"),tags$th("Standard ML"),tags$th("Social Scale"))),
                    tags$tbody(
                      tags$tr(tags$td("Training data"),   tags$td("GBs-TBs"),    tags$td("Petabytes — custom distributed columnar storage")),
                      tags$tr(tags$td("Feature store"),   tags$td("Single Redis"),tags$td("Distributed sharded; custom embedding store")),
                      tags$tr(tags$td("Model training"),  tags$td("Single GPU"),  tags$td("Thousands of GPUs; pipeline + model parallelism")),
                      tags$tr(tags$td("HPO"),             tags$td("Optuna"),      tags$td("Hyperband + progressive training; custom infra")),
                      tags$tr(tags$td("Experiment track"),tags$td("MLflow/W&B"),  tags$td("Custom platform (FBLearner at Meta)")),
                      tags$tr(tags$td("Serving"),         tags$td("Triton"),      tags$td("Custom inference clusters; thousands of GPUs"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Build vs Buy at Social Scale (Ch.10)"),
                  tags$p("Huyen's framework: build when it is a core differentiator. At Meta scale, almost everything is built:"),
                  tags$ul(
                    tags$li(tags$b("Build:"), " feature store (Zeitgeist), experiment platform (FBLearner), ANN search (FAISS), distributed training (PyTorch), model serving (TorchServe + custom)"),
                    tags$li(tags$b("Why build all:"), " scale requirements exceed what commercial vendors can handle. Google, Meta, TikTok all run custom ML infrastructure because off-the-shelf solutions cannot handle petabyte-scale, billion-user workloads.")
                  ),
                  div(class="tip-box", HTML("<strong>Huyen's Ch.10 nuance:</strong> The build vs buy decision at Meta is not the same as at a startup. At 3B users, even a 1% latency improvement is worth an entire team. The calculus completely reverses at scale."))
                )
              )
            )
          ),

          smPanel("sm5-fairness",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Creator Fairness (Ch.11)"),
                  tags$p("Recommendation systems create winner-take-all dynamics. Huyen's responsible AI framework applied:"),
                  tags$p(tags$b("The problem:"), " new and small creators are systematically disadvantaged. No impressions → no engagement data → no ranking signal → no impressions. Cold start problem compounds into permanent structural inequality."),
                  tags$p(tags$b("Types of bias (Ch.11):")),
                  tags$ul(
                    tags$li(tags$b("Historical bias:"), " models trained on past data perpetuate past popularity distributions"),
                    tags$li(tags$b("Representation bias:"), " creators from smaller countries/languages underrepresented in training data"),
                    tags$li(tags$b("Measurement bias:"), " watch time proxy penalises shorter content from mid-tier creators vs long-form from large creators")
                  ),
                  tags$p(tags$b("Interventions:")),
                  tags$ul(
                    tags$li("New creator boost: 10-15% impression uplift for accounts < 6 months old"),
                    tags$li("Diversity constraints: maximum % of any single creator's content in a single feed"),
                    tags$li("Long-tail content quota: floor for small-creator content in discovery surfaces")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("User Fairness and Safety (Ch.11)"),
                  tags$p(tags$b("Filter bubbles and echo chambers:")),
                  tags$p("Optimising for engagement without diversity constraints creates information silos. Users who engage with one political viewpoint receive progressively more of the same. This is a fairness issue (equal access to information), a safety issue (radicalisation pathway), and a regulatory issue (EU DSA requirements)."),
                  tags$p(tags$b("Technical interventions:")),
                  tags$ul(
                    tags$li("Topic diversity constraint: entropy of topic distribution per feed session > threshold"),
                    tags$li("Cross-cutting content: actively recommend content that bridges different interest communities"),
                    tags$li("Content exposure audits: equal impression rates for content about different political topics")
                  ),
                  div(class="warn-box", HTML("<strong>Responsibility gap:</strong> At social media scale, ML systems affect public discourse, elections, and mental health. Huyen argues responsible AI is not optional goodwill — it is a core system requirement that must be built into the ML lifecycle from problem definition."))
                )
              )
            )
          ),

          smPanel("sm5-responsible",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Content Safety and Moderation (Ch.11)"),
                  tags$p("Safety is a first-class ML problem, not a post-hoc filter:"),
                  tags$ul(
                    tags$li(tags$b("Harmful content classifier:"), " separate ML model scores all content for policy violations before it enters the recommendation pipeline. Not part of ranking — a hard gate."),
                    tags$li(tags$b("Engagement penalty:"), " content that users report or hide is penalised in the ranking model. Report signal is a negative engagement label."),
                    tags$li(tags$b("Borderline content:"), " the hardest category. Does not violate policy but is harmful (misinformation, health myths). Handled via engagement downranking, not removal."),
                    tags$li(tags$b("Adversarial creators:"), " some creators learn to optimise content for the recommendation algorithm. Requires adversarial testing in evaluation.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("EU Digital Services Act (DSA) Compliance"),
                  tags$p("As of 2024, the DSA imposes obligations directly relevant to the ML lifecycle:"),
                  tags$ul(
                    tags$li(tags$b("Recommender system transparency:"), " must offer users a non-personalised feed option. Requires A/B test infrastructure for a pure chronological feed as a serving variant."),
                    tags$li(tags$b("Systemic risk assessments:"), " annual audit of how the recommendation system amplifies harmful content. Requires dedicated evaluation datasets for harmful content exposure measurement."),
                    tags$li(tags$b("Opt-out from profiling:"), " users must be able to opt out of personalisation based on sensitive categories. Requires sensitive attribute removal from feature store for opted-out users."),
                    tags$li(tags$b("Ad transparency:"), " why was this ad shown? Requires SHAP/LIME explanations stored per ad impression.")
                  ),
                  div(class="success-box", HTML("<strong>Huyen alignment:</strong> Huyen's model cards, sliced evaluation, and audit trails directly satisfy DSA systemic risk assessment requirements. Responsible AI is becoming legally mandatory."))
                )
              )
            )
          )
        )
      )
    ),

    # ── Self-assessment ─────────────────────────────────────────────────────
    fluidRow(
      box(title="📊 Self-Assessment: Social Media Recommender Case Study",
          status="success", solidHeader=TRUE, width=12,
        fluidRow(
          column(4,
            sliderInput(ns("sc_sm1"), "Problem framing & multi-objective",   0,10,5),
            sliderInput(ns("sc_sm2"), "Data engineering & feedback loops",   0,10,5),
            sliderInput(ns("sc_sm3"), "Retrieval, ranking & GNN models",     0,10,5),
            sliderInput(ns("sc_sm4"), "Deployment & continual learning",     0,10,5),
            sliderInput(ns("sc_sm5"), "Monitoring & responsible AI",         0,10,5),
            actionButton(ns("save_sm"), "Save Assessment", class="btn-meta", width="100%")
          ),
          column(8, br(), uiOutput(ns("sm_result")))
        )
      )
    )
  )
}

social_recommender_case_study_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_sm, {
      avg <- mean(c(input$sc_sm1, input$sc_sm2, input$sc_sm3, input$sc_sm4, input$sc_sm5))
      pct <- round(avg * 10)
      prep_manager$update_progress("social_recommender_case_study", pct)
      output$sm_result <- renderUI({
        div(class=if(pct>=70)"success-box"else"tip-box",
          tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
          if(pct>=80) tags$p("Strong recommender knowledge. In interviews: lead with the two-stage architecture, name degenerate feedback loops as a key risk, and propose diversity constraints alongside engagement metrics.")
          else tags$p("Review: Two-Tower retrieval + ANN search, multi-task ranking, degenerate feedback loops, and the network interference problem in A/B testing.")
        )
      })
      showNotification(paste0("Social Recommender: ",pct,"% saved"), type="message")
    })
  })
}
