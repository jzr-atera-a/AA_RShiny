# modules/social_recommender_case_study.R
# Use Case: Social Media Recommender (Meta-scale) — K&B Manning 2025 Framework
# JS namespace: srShow(), .sr-btn, .sr-panel

social_recommender_case_study_ui <- function(id) {
  ns <- NS(id)

  js <- "
<script>
function srShow(boxId, panelId) {
  var box = document.getElementById(boxId);
  if (!box) return;
  box.querySelectorAll('.sr-panel').forEach(function(p){ p.style.display='none'; });
  box.querySelectorAll('.sr-btn').forEach(function(b){ b.classList.remove('active'); });
  var panel = document.getElementById(panelId);
  if (panel) panel.style.display='block';
  event.target.classList.add('active');
}
window.addEventListener('load', function(){
  ['sr-box1','sr-box2','sr-box3','sr-box4','sr-box5','sr-box6','sr-box7'].forEach(function(boxId){
    var box = document.getElementById(boxId);
    if (!box) return;
    var btn = box.querySelector('.sr-btn');
    var pnl = box.querySelector('.sr-panel');
    if (btn) btn.classList.add('active');
    if (pnl) pnl.style.display='block';
  });
});
</script>"

  srBtn <- function(boxId, panelId, label) {
    tags$button(class="sr-btn",
      style="margin:2px 4px 2px 0;padding:5px 12px;border:none;border-radius:4px;cursor:pointer;font-size:12px;background:#1a2332;color:#cdd6e0;transition:all .2s;",
      onclick=paste0("srShow('",boxId,"','",panelId,"')"), label)
  }
  srPanel <- function(panelId, ...) {
    div(id=panelId, class="sr-panel", style="display:none;padding-top:10px;", ...)
  }

  tagList(
    HTML(js),

    # ── Hero ──
    div(class="meta-hero",
        tags$h1("Social Media Recommender System"),
        tags$h2("Meta-Scale Two-Tower + DLRM — K&B Manning 2025 Framework"),
        div(span(class="hero-badge","3B+ Users"),
            span(class="hero-badge","100B+ Events/Day"),
            span(class="hero-badge","Two-Tower Retrieval"),
            span(class="hero-badge","Multi-Task DLRM"),
            span(class="hero-badge","100ms SLO"))),

    # ── Architecture Overview ──
    fluidRow(
      box(title="System Architecture — Two-Stage Recommendation Pipeline", status="primary", solidHeader=TRUE, width=12,
          div(style="overflow-x:auto;",
              HTML('
<svg viewBox="0 0 900 200" xmlns="http://www.w3.org/2000/svg" style="width:100%;max-width:900px;font-family:Inter,sans-serif;">
  <defs>
    <marker id="sr-arr" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0,8 3,0 6" fill="#e8410a"/>
    </marker>
  </defs>
  <!-- User Request -->
  <rect x="10" y="75" width="100" height="40" rx="5" fill="#1a2332" stroke="#6b7280" stroke-width="1.5"/>
  <text x="60" y="92" text-anchor="middle" fill="#d1d5db" font-size="9">User Request</text>
  <text x="60" y="105" text-anchor="middle" fill="#6b7280" font-size="8">3B DAU</text>
  <line x1="110" y1="95" x2="155" y2="95" stroke="#e8410a" stroke-width="1.5" marker-end="url(#sr-arr)"/>
  <!-- Stage 1 Retrieval -->
  <rect x="155" y="55" width="155" height="80" rx="6" fill="#0c1f3a" stroke="#3b82f6" stroke-width="2"/>
  <text x="232" y="78" text-anchor="middle" fill="#93c5fd" font-size="11" font-weight="bold">Stage 1: Retrieval</text>
  <text x="232" y="93" text-anchor="middle" fill="#9ca3af" font-size="9">Two-Tower ANN</text>
  <text x="232" y="106" text-anchor="middle" fill="#9ca3af" font-size="8">User Tower + Item Tower</text>
  <text x="232" y="118" text-anchor="middle" fill="#6b7280" font-size="8">10B items → 1,000 candidates  10ms</text>
  <line x1="310" y1="95" x2="355" y2="95" stroke="#e8410a" stroke-width="1.5" marker-end="url(#sr-arr)"/>
  <!-- Stage 2 Ranking -->
  <rect x="355" y="55" width="165" height="80" rx="6" fill="#0c1f3a" stroke="#f59e0b" stroke-width="2"/>
  <text x="437" y="78" text-anchor="middle" fill="#fcd34d" font-size="11" font-weight="bold">Stage 2: Ranking</text>
  <text x="437" y="93" text-anchor="middle" fill="#9ca3af" font-size="9">Wide-and-Deep DLRM</text>
  <text x="437" y="106" text-anchor="middle" fill="#9ca3af" font-size="8">Multi-task: engage + safety</text>
  <text x="437" y="118" text-anchor="middle" fill="#6b7280" font-size="8">1,000 → 100 items  50ms</text>
  <line x1="520" y1="95" x2="565" y2="95" stroke="#e8410a" stroke-width="1.5" marker-end="url(#sr-arr)"/>
  <!-- Stage 3 Re-ranking -->
  <rect x="565" y="55" width="165" height="80" rx="6" fill="#0c1f3a" stroke="#10b981" stroke-width="2"/>
  <text x="647" y="78" text-anchor="middle" fill="#6ee7b7" font-size="11" font-weight="bold">Stage 3: Re-ranking</text>
  <text x="647" y="93" text-anchor="middle" fill="#9ca3af" font-size="9">Diversity + Safety Rules</text>
  <text x="647" y="106" text-anchor="middle" fill="#9ca3af" font-size="8">Freshness + Creator Fairness</text>
  <text x="647" y="118" text-anchor="middle" fill="#6b7280" font-size="8">100 → 20 final items  20ms</text>
  <line x1="730" y1="95" x2="775" y2="95" stroke="#e8410a" stroke-width="1.5" marker-end="url(#sr-arr)"/>
  <!-- Feed -->
  <rect x="775" y="70" width="115" height="50" rx="6" fill="#1a2332" stroke="#e8410a" stroke-width="2"/>
  <text x="832" y="91" text-anchor="middle" fill="#fca5a5" font-size="11" font-weight="bold">User Feed</text>
  <text x="832" y="104" text-anchor="middle" fill="#9ca3af" font-size="8">20 items, 100ms total</text>
  <!-- Feedback loop -->
  <path d="M 832 120 Q 832 170 500 170 Q 168 170 168 135" stroke="#374151" stroke-width="1" fill="none" stroke-dasharray="5,3" marker-end="url(#sr-arr)"/>
  <text x="500" y="185" text-anchor="middle" fill="#6b7280" font-size="8">Engagement signals feed back into embedding updates (hourly)</text>
  <!-- Latency labels -->
  <text x="232" y="148" text-anchor="middle" fill="#3b82f6" font-size="8">10ms budget</text>
  <text x="437" y="148" text-anchor="middle" fill="#f59e0b" font-size="8">50ms budget</text>
  <text x="647" y="148" text-anchor="middle" fill="#10b981" font-size="8">20ms budget</text>
</svg>'
              ))
      )
    ),

    # ── BOX 1: Ch.1-2 Requirements ──
    fluidRow(
      box(title="Box 1 — Ch.1–2: Requirements & Multi-Objective Scoping (K&B)", status="primary", solidHeader=TRUE, width=12,
          id="sr-box1",
          div(srBtn("sr-box1","sr1p1","Multi-Objective Framing"),
              srBtn("sr-box1","sr1p2","Scale & SLOs"),
              srBtn("sr-box1","sr1p3","K&B 6-Step Applied"),
              srBtn("sr-box1","sr1p4","Regulatory Constraints")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          srPanel("sr1p1",
            div(class="warn-box", HTML("<strong>K&B Ch.1 — The Multi-Objective Trap:</strong> A naive recommender optimising only for watch-time drives radicalisation funnels, diversity collapse, and creator monopolies. K&B treat this as the canonical example of why business-ML alignment is a safety issue, not just a performance issue.")),
            br(),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Business Objectives → ML Objectives"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Business Goal"), tags$th("ML Signal"), tags$th("Risk if Over-Optimised"))),
                    tags$tbody(
                      tags$tr(tags$td("User engagement"), tags$td("Clicks, watch-time, shares"), tags$td("Sensationalism, rabbit holes")),
                      tags$tr(tags$td("Content diversity"), tags$td("ILD (Intra-List Diversity)"), tags$td("Filter bubbles")),
                      tags$tr(tags$td("Platform safety"), tags$td("Safety classifier score"), tags$td("Missing edge cases in new content types")),
                      tags$tr(tags$td("Creator fairness"), tags$td("Impression share Gini coefficient"), tags$td("Rich-get-richer feedback loop")),
                      tags$tr(tags$td("Long-term retention"), tags$td("28-day return rate"), tags$td("Conflicts with short-term CTR")),
                      tags$tr(tags$td("User satisfaction"), tags$td("Surveyed CSAT (sampled)"), tags$td("Costly at scale; low coverage"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Metric Conflict Resolution — K&B Constrained Optimisation"),
                  tags$p("K&B recommend treating as a constrained optimisation problem:"),
                  div(style="background:#0a0d0f;padding:10px;border-radius:4px;font-family:'JetBrains Mono',monospace;font-size:11px;color:#6ee7b7;",
                    HTML("maximise: watch_time + share_rate<br>subject to:<br>&nbsp;&nbsp;safety_score &gt; 0.95 (guardrail)<br>&nbsp;&nbsp;creator_gini &lt; 0.60 (fairness floor)<br>&nbsp;&nbsp;fresh_item_ratio &ge; 15% (freshness floor)<br>&nbsp;&nbsp;diversity_ILD &gt; 0.40 (diversity floor)")
                  ),
                  br(),
                  div(class="tip-box", tags$small(HTML("<strong>K&B insight:</strong> In interviews, showing you understand metric conflicts — and have a principled resolution strategy — immediately signals senior-level ML thinking.")))
                )
              )
            )
          ),

          srPanel("sr1p2",
            div(class="section-heading-dark", "Scale Requirements & SLO Breakdown — K&B Ch.2"),
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Scale Parameters"),
                  tags$table(class="table table-sm",
                    tags$tbody(
                      tags$tr(tags$td("Daily Active Users"), tags$td(tags$b("3B+"))),
                      tags$tr(tags$td("Item corpus"), tags$td(tags$b("10B+ posts/videos"))),
                      tags$tr(tags$td("Events per day"), tags$td(tags$b("100B+ interactions"))),
                      tags$tr(tags$td("Feed opens/day"), tags$td(tags$b("~5B requests"))),
                      tags$tr(tags$td("New items/day"), tags$td(tags$b("~500M new posts"))),
                      tags$tr(tags$td("Item embeddings"), tags$td(tags$b("10B × 256d ~ 10TB")))
                    )
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Latency Budget (100ms p99)"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Component"), tags$th("Budget"))),
                    tags$tbody(
                      tags$tr(tags$td("User embedding lookup"), tags$td("2ms")),
                      tags$tr(tags$td("ANN retrieval (FAISS)"), tags$td("8ms")),
                      tags$tr(tags$td("Feature assembly (1k items)"), tags$td("10ms")),
                      tags$tr(tags$td("DLRM ranking inference"), tags$td("40ms")),
                      tags$tr(tags$td("Re-ranking + diversity"), tags$td("20ms")),
                      tags$tr(tags$td("Network + serialisation"), tags$td("20ms")),
                      tags$tr(tags$td(tags$b("Total p99 SLO"), style="color:#10b981;"), tags$td(tags$b("100ms", style="color:#10b981;")))
                    )
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Freshness SLOs"),
                  tags$ul(
                    tags$li(tags$b("User embeddings:"), " Updated hourly — captures session signals"),
                    tags$li(tags$b("Item embeddings:"), " Updated hourly — new viral content must enter index"),
                    tags$li(tags$b("Safety scores:"), " <1 min for new posts (async pipeline)"),
                    tags$li(tags$b("Cold start items:"), " Must enter retrieval within 5 min of publish"),
                    tags$li(tags$b("Trending signals:"), " Real-time velocity counter (Kafka stream)")
                  )
                )
              )
            )
          ),

          srPanel("sr1p3",
            div(class="framework-card",
              tags$h5("K&B 6-Step Loop Applied — Social Recommender"),
              tags$p(tags$b("1. Clarify requirements:"), " Maximise long-session engagement (watch-time + 28-day return visits). Guardrails: safety > 0.95, creator Gini < 0.60, freshness ≥ 15%. Non-functional: 100ms p99, 5B QPS peak, EU DSA compliance."),
              tags$p(tags$b("2. Data pipeline:"), " 100B events/day via Kafka → Flink processing. Critical: negative sampling (99.99% of user-item pairs are unobserved — not negative). Petabyte-scale feature storage in HDFS/S3 + Redis online store."),
              tags$p(tags$b("3. Feature engineering:"), " User tower: interaction history embeddings, social graph GNN, device/time context. Item tower: CLIP image embeddings, text encoder, engagement velocity. Cross features in ranking only (not retrieval — too slow)."),
              tags$p(tags$b("4. Model architecture:"), " Two-Tower DNN for retrieval — user and item towers independent at inference, enabling ANN index. Wide-and-Deep DLRM for ranking — wide (memorisation of specific patterns) + deep (generalisation). Multi-task heads."),
              tags$p(tags$b("5. Evaluation:"), " Offline: NDCG@10, AUC per task (engagement/safety/diversity). Online: A/B test with graph-based randomisation to handle network interference. Primary: watch-time + 28d retention. Guardrail: Gini coefficient."),
              tags$p(tags$b("6. Serving & monitoring:"), " Two-stage pipeline with separate SLOs per stage. Hourly stateful embedding updates. Drift: Gini collapse detection, engagement distribution shift, safety recall degradation on emerging content types.")
            )
          ),

          srPanel("sr1p4",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("EU DSA & Platform Regulatory Constraints"),
                  tags$ul(
                    tags$li(tags$b("DSA Art.27:"), " Users must receive explanations for algorithmic recommendations"),
                    tags$li(tags$b("DSA Art.38:"), " Right to opt out of personalisation entirely — fallback to chronological feed"),
                    tags$li(tags$b("GDPR Art.9:"), " Cannot use political opinions, religion, health as ranking features without explicit consent"),
                    tags$li(tags$b("Age-gating:"), " Content classification for minors; separate ranking model for under-18 users"),
                    tags$li(tags$b("CSAM:"), " Mandatory reporting, immediate removal pipeline; PhotoDNA integration")
                  )
                )
              ),
              column(6,
                div(class="warn-box", HTML("<strong>K&B Interview Point:</strong> The Facebook emotional contagion study (2014) is K&B's case study for why A/B testing on social platforms requires ethics review. Any experiment that could alter emotional state must go through IRB-equivalent review. Mentioning this in an interview shows awareness of responsible AI at scale.")),
                div(class="framework-card",
                  tags$h5("Platform-Specific Constraints"),
                  tags$ul(
                    tags$li("Max creator exposure: ≤ 30% of feed from single creator"),
                    tags$li("News recirculation cap: political content >7 days old deprioritised"),
                    tags$li("Engagement bait classifier: 'comment below' patterns detected and penalised"),
                    tags$li("Coordinated inauthentic behaviour detection feeds into item score penalty")
                  )
                )
              )
            )
          )
      )
    ),

    # ── BOX 2: Ch.3 Data Pipeline ──
    fluidRow(
      box(title="Box 2 — Ch.3: Petabyte-Scale Data Pipeline (K&B)", status="warning", solidHeader=TRUE, width=12,
          id="sr-box2",
          div(srBtn("sr-box2","sr2p1","Event Ingestion"),
              srBtn("sr-box2","sr2p2","Negative Sampling"),
              srBtn("sr-box2","sr2p3","Class Imbalance & Labels"),
              srBtn("sr-box2","sr2p4","Pipeline SVG")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          srPanel("sr2p1",
            fluidRow(
              column(6,
                div(class="section-heading-dark", "Event Types & Ingestion"),
                tags$table(class="table table-sm",
                  tags$thead(tags$tr(tags$th("Event"), tags$th("Volume/Day"), tags$th("Freshness"), tags$th("Pipeline"))),
                  tags$tbody(
                    tags$tr(tags$td("Impression"), tags$td("50B"), tags$td("Batch OK"), tags$td("Kafka → Flink → HDFS")),
                    tags$tr(tags$td("Click"), tags$td("5B"), tags$td("Real-time"), tags$td("Kafka → Redis + HDFS")),
                    tags$tr(tags$td("Watch-time (video)"), tags$td("20B"), tags$td("Session-end"), tags$td("Kafka → Flink aggregation")),
                    tags$tr(tags$td("Share / Save"), tags$td("500M"), tags$td("Real-time"), tags$td("Kafka → Redis")),
                    tags$tr(tags$td("Comment"), tags$td("2B"), tags$td("Near real-time"), tags$td("Kafka → Flink → HDFS")),
                    tags$tr(tags$td("Dwell time"), tags$td("50B"), tags$td("Session"), tags$td("Client-side aggregation"))
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("K&B Streaming Architecture — Flink on Kafka"),
                  tags$ul(
                    tags$li(tags$b("Exactly-once semantics:"), " Critical — a share event counted twice inflates training labels"),
                    tags$li(tags$b("Event time vs processing time:"), " Flink watermarks handle late-arriving events (mobile offline → sync)"),
                    tags$li(tags$b("Partitioning:"), " Kafka topics partitioned by user_id for ordered processing; item_id for embedding updates"),
                    tags$li(tags$b("Retention:"), " 7 days hot in Kafka; 2 years cold in S3/HDFS Parquet; aggregated features in offline store forever"),
                    tags$li(tags$b("Schema registry:"), " Confluent Schema Registry with Avro; breaking changes require dual-write period")
                  )
                ),
                div(class="tip-box", tags$small(HTML("<strong>K&B Ch.3 Interview Point:</strong> At 100B events/day (~1.2M events/second), even Kafka requires careful capacity planning: partition count, consumer group lag monitoring, backpressure handling.")))
              )
            )
          ),

          srPanel("sr2p2",
            div(class="warn-box", HTML("<strong>K&B Ch.3 Critical Issue — Negative Sampling:</strong> 99.99% of (user, item) pairs are unobserved. A non-impression is NOT a negative — it may mean the item was never shown, not that the user dislikes it. Treating all non-interactions as negatives creates a catastrophically biased training set.")),
            br(),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Negative Sampling Strategies"),
                  tags$ul(
                    tags$li(tags$b("Random negatives:"), " Sample uniformly from item corpus. Simple but biased toward popular items (popular items appear as negatives less often → overestimate their quality)"),
                    tags$li(tags$b("In-batch negatives:"), " Other items in the same training batch are negatives. Efficient but creates false negatives (item shown to user earlier in batch)"),
                    tags$li(tags$b("Hard negatives:"), " Items the model currently ranks highly for this user but were not clicked. Most informative but expensive to mine"),
                    tags$li(tags$b("Popularity-corrected:"), " Sample proportional to sqrt(item_frequency) to reduce popularity bias"),
                    tags$li(tags$b("K&B recommendation:"), " Mix: 70% random + 20% popularity-corrected + 10% hard negatives")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Watch-Time Label Noise"),
                  tags$ul(
                    tags$li(tags$b("Autoplay contamination:"), " Video autoplays → 2s watch-time recorded even if user did not intend to watch"),
                    tags$li(tags$b("Background tab:"), " Desktop users leave tab open; watch-time accumulated but no genuine engagement"),
                    tags$li(tags$b("Fix:"), " Use active watch-time (mouse/touch activity detected during playback) not raw duration"),
                    tags$li(tags$b("Normalisation:"), " Divide watch-time by video duration to get completion rate — more comparable across lengths")
                  )
                ),
                div(class="framework-card",
                  tags$h5("Degenerate Feedback Loop"),
                  tags$p("The recommender only shows high-scoring items → only high-scoring items get engagement data → model never learns about low-scored items → distribution narrows over time."),
                  div(class="warn-box", tags$small("K&B fix: Exploration budget — reserve 5-10% of impressions for random/exploratory recommendations. Collect unbiased data. Use IPS (Inverse Propensity Scoring) to debias training."))
                )
              )
            )
          ),

          srPanel("sr2p3",
            div(class="section-heading-dark", "Class Imbalance at Social Scale — K&B Ch.3"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Engagement Signal Sparsity"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Signal"), tags$th("Rate"), tags$th("Challenge"))),
                    tags$tbody(
                      tags$tr(tags$td("Impression"), tags$td("100%"), tags$td("All items shown")),
                      tags$tr(tags$td("Click"), tags$td("~2-5%"), tags$td("Sparse positive")),
                      tags$tr(tags$td("Watch >30s"), tags$td("~15%"), tags$td("Moderate")),
                      tags$tr(tags$td("Like"), tags$td("~3%"), tags$td("Sparse")),
                      tags$tr(tags$td("Comment"), tags$td("~0.5%"), tags$td("Very sparse")),
                      tags$tr(tags$td("Share"), tags$td("~0.1%"), tags$td("Extremely sparse — most valuable")),
                      tags$tr(tags$td("Save"), tags$td("~0.2%"), tags$td("High intent signal"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("K&B Handling Strategy"),
                  tags$ul(
                    tags$li(tags$b("Multi-task learning:"), " Separate head per signal — share model avoids over-weighting rare signals"),
                    tags$li(tags$b("Upsampling rare signals:"), " 10x oversample share/save events in training batches"),
                    tags$li(tags$b("Weighted loss:"), " Higher loss weight for shares (0.1%) vs clicks (5%) to prevent click-optimised model"),
                    tags$li(tags$b("Embedding storage at 3B-user scale:"), " 3B users × 256d × 4 bytes = ~3TB for user embeddings alone. Solution: quantise to INT8 (768GB), shard across 50 Redis nodes")
                  )
                )
              )
            )
          ),

          srPanel("sr2p4",
            div(style="overflow-x:auto;",
              HTML('
<svg viewBox="0 0 820 260" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <text x="410" y="18" text-anchor="middle" fill="#e8410a" font-size="12" font-weight="bold">Social Recommender Data Pipeline — K&B Ch.3</text>
  <!-- Sources -->
  <rect x="10" y="35" width="110" height="28" rx="4" fill="#1a2332" stroke="#10b981" stroke-width="1.5"/>
  <text x="65" y="53" text-anchor="middle" fill="#6ee7b7" font-size="9">User Events (app)</text>
  <rect x="10" y="75" width="110" height="28" rx="4" fill="#1a2332" stroke="#10b981" stroke-width="1.5"/>
  <text x="65" y="93" text-anchor="middle" fill="#6ee7b7" font-size="9">Video Signals</text>
  <rect x="10" y="115" width="110" height="28" rx="4" fill="#1a2332" stroke="#6b7280" stroke-width="1.5"/>
  <text x="65" y="133" text-anchor="middle" fill="#d1d5db" font-size="9">Content Metadata</text>
  <rect x="10" y="155" width="110" height="28" rx="4" fill="#1a2332" stroke="#6b7280" stroke-width="1.5"/>
  <text x="65" y="173" text-anchor="middle" fill="#d1d5db" font-size="9">Social Graph (edges)</text>
  <!-- Arrows to Kafka -->
  <line x1="120" y1="49" x2="165" y2="85" stroke="#10b981" stroke-width="1.2" marker-end="url(#sr-arr)"/>
  <line x1="120" y1="89" x2="165" y2="95" stroke="#10b981" stroke-width="1.2" marker-end="url(#sr-arr)"/>
  <line x1="120" y1="129" x2="165" y2="105" stroke="#6b7280" stroke-width="1.2" marker-end="url(#sr-arr)"/>
  <line x1="120" y1="169" x2="165" y2="115" stroke="#6b7280" stroke-width="1.2" marker-end="url(#sr-arr)"/>
  <!-- Kafka -->
  <rect x="165" y="65" width="110" height="70" rx="5" fill="#0f2444" stroke="#3b82f6" stroke-width="2"/>
  <text x="220" y="88" text-anchor="middle" fill="#93c5fd" font-size="10" font-weight="bold">Kafka</text>
  <text x="220" y="102" text-anchor="middle" fill="#9ca3af" font-size="8">100B events/day</text>
  <text x="220" y="114" text-anchor="middle" fill="#9ca3af" font-size="8">~1.2M events/sec</text>
  <text x="220" y="126" text-anchor="middle" fill="#6b7280" font-size="8">Avro + Schema Registry</text>
  <!-- Flink -->
  <line x1="275" y1="100" x2="320" y2="100" stroke="#3b82f6" stroke-width="1.5" marker-end="url(#sr-arr)"/>
  <rect x="320" y="65" width="110" height="70" rx="5" fill="#0f2444" stroke="#f59e0b" stroke-width="2"/>
  <text x="375" y="88" text-anchor="middle" fill="#fcd34d" font-size="10" font-weight="bold">Flink</text>
  <text x="375" y="102" text-anchor="middle" fill="#9ca3af" font-size="8">Exactly-once</text>
  <text x="375" y="114" text-anchor="middle" fill="#9ca3af" font-size="8">Event-time watermarks</text>
  <text x="375" y="126" text-anchor="middle" fill="#6b7280" font-size="8">Windowed aggregation</text>
  <!-- HDFS and Redis -->
  <line x1="430" y1="85" x2="475" y2="65" stroke="#f59e0b" stroke-width="1.5" marker-end="url(#sr-arr)"/>
  <line x1="430" y1="115" x2="475" y2="135" stroke="#f59e0b" stroke-width="1.5" marker-end="url(#sr-arr)"/>
  <rect x="475" y="40" width="120" height="50" rx="5" fill="#0c1f3a" stroke="#6b7280" stroke-width="1.5"/>
  <text x="535" y="62" text-anchor="middle" fill="#d1d5db" font-size="10" font-weight="bold">HDFS / S3</text>
  <text x="535" y="75" text-anchor="middle" fill="#9ca3af" font-size="8">Offline Feature Store</text>
  <text x="535" y="87" text-anchor="middle" fill="#6b7280" font-size="8">Parquet, 2yr retention</text>
  <rect x="475" y="115" width="120" height="50" rx="5" fill="#0c1f3a" stroke="#10b981" stroke-width="1.5"/>
  <text x="535" y="137" text-anchor="middle" fill="#6ee7b7" font-size="10" font-weight="bold">Redis Cluster</text>
  <text x="535" y="150" text-anchor="middle" fill="#9ca3af" font-size="8">Online Feature Store</text>
  <text x="535" y="162" text-anchor="middle" fill="#6b7280" font-size="8">50 shards, INT8 embeddings</text>
  <!-- Training and Serving -->
  <line x1="595" y1="65" x2="645" y2="75" stroke="#6b7280" stroke-width="1.2" marker-end="url(#sr-arr)"/>
  <line x1="595" y1="140" x2="645" y2="130" stroke="#6b7280" stroke-width="1.2" marker-end="url(#sr-arr)"/>
  <rect x="645" y="55" width="150" height="110" rx="6" fill="#0c1f3a" stroke="#e8410a" stroke-width="2"/>
  <text x="720" y="78" text-anchor="middle" fill="#fca5a5" font-size="10" font-weight="bold">ML Training + Serving</text>
  <text x="720" y="93" text-anchor="middle" fill="#9ca3af" font-size="9">Two-Tower (PyTorch)</text>
  <text x="720" y="107" text-anchor="middle" fill="#9ca3af" font-size="9">DLRM Ranking</text>
  <text x="720" y="121" text-anchor="middle" fill="#9ca3af" font-size="8">ANN Index (FAISS)</text>
  <text x="720" y="133" text-anchor="middle" fill="#9ca3af" font-size="8">Embedding updates: hourly</text>
  <text x="720" y="147" text-anchor="middle" fill="#9ca3af" font-size="8">Model retrain: weekly</text>
  <!-- Neg sampling note -->
  <rect x="165" y="175" width="300" height="40" rx="4" fill="#1a2332" stroke="#ef4444" stroke-width="1" stroke-dasharray="4,3"/>
  <text x="315" y="193" text-anchor="middle" fill="#fca5a5" font-size="9" font-weight="bold">Negative Sampling Layer</text>
  <text x="315" y="207" text-anchor="middle" fill="#9ca3af" font-size="8">70% random + 20% popularity-corrected + 10% hard negatives</text>
  <line x1="315" y1="135" x2="315" y2="175" stroke="#ef4444" stroke-width="1" stroke-dasharray="3,3"/>
</svg>'
            ))
          )
      )
    ),

    # ── BOX 3: Ch.4 Feature Engineering ──
    fluidRow(
      box(title="Box 3 — Ch.4: Feature Engineering & Two-Tower Design (K&B)", status="success", solidHeader=TRUE, width=12,
          id="sr-box3",
          div(srBtn("sr-box3","sr3p1","User Tower Features"),
              srBtn("sr-box3","sr3p2","Item Tower Features"),
              srBtn("sr-box3","sr3p3","Feature Store Pattern"),
              srBtn("sr-box3","sr3p4","Train-Serve Skew")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          srPanel("sr3p1",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("User Tower Feature Groups"),
                  tags$ul(
                    tags$li(tags$b("Interaction history:"), " Last 100 interacted items → average pooled embeddings (256d)"),
                    tags$li(tags$b("Social graph:"), " GNN-computed embedding from 2-hop social graph. Friends' recent engagements as implicit signal."),
                    tags$li(tags$b("Engagement patterns:"), " CTR by content type, watch-time distribution, share/save ratio, active hours heatmap"),
                    tags$li(tags$b("Session context:"), " Device type, time-of-day, session length so far, scroll velocity"),
                    tags$li(tags$b("Demographic proxies:"), " Age bucket, inferred interests (NOT protected characteristics — GDPR)"),
                    tags$li(tags$b("Notification state:"), " Push opt-in status, last notification engagement")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("User Tower Architecture"),
                  HTML('
<svg viewBox="0 0 300 200" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <text x="150" y="15" text-anchor="middle" fill="#e8410a" font-size="10" font-weight="bold">User Tower (at inference time)</text>
  <rect x="20" y="25" width="80" height="22" rx="3" fill="#1a2332" stroke="#3b82f6" stroke-width="1"/>
  <text x="60" y="40" text-anchor="middle" fill="#93c5fd" font-size="8">History Embeddings</text>
  <rect x="20" y="55" width="80" height="22" rx="3" fill="#1a2332" stroke="#3b82f6" stroke-width="1"/>
  <text x="60" y="70" text-anchor="middle" fill="#93c5fd" font-size="8">GNN Social Embedding</text>
  <rect x="20" y="85" width="80" height="22" rx="3" fill="#1a2332" stroke="#3b82f6" stroke-width="1"/>
  <text x="60" y="100" text-anchor="middle" fill="#93c5fd" font-size="8">Session Context</text>
  <rect x="20" y="115" width="80" height="22" rx="3" fill="#1a2332" stroke="#3b82f6" stroke-width="1"/>
  <text x="60" y="130" text-anchor="middle" fill="#93c5fd" font-size="8">Dense Features</text>
  <line x1="100" y1="60" x2="130" y2="90" stroke="#3b82f6" stroke-width="1"/>
  <line x1="100" y1="90" x2="130" y2="95" stroke="#3b82f6" stroke-width="1"/>
  <line x1="100" y1="96" x2="130" y2="100" stroke="#3b82f6" stroke-width="1"/>
  <line x1="100" y1="126" x2="130" y2="110" stroke="#3b82f6" stroke-width="1"/>
  <rect x="130" y="70" width="60" height="60" rx="4" fill="#0f2444" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="160" y="97" text-anchor="middle" fill="#93c5fd" font-size="8">MLP</text>
  <text x="160" y="110" text-anchor="middle" fill="#9ca3af" font-size="7">3 layers</text>
  <text x="160" y="122" text-anchor="middle" fill="#9ca3af" font-size="7">ReLU</text>
  <line x1="190" y1="100" x2="225" y2="100" stroke="#3b82f6" stroke-width="1.5" marker-end="url(#sr-arr)"/>
  <rect x="225" y="82" width="65" height="36" rx="4" fill="#0c1f3a" stroke="#10b981" stroke-width="1.5"/>
  <text x="257" y="100" text-anchor="middle" fill="#6ee7b7" font-size="9">User</text>
  <text x="257" y="112" text-anchor="middle" fill="#6ee7b7" font-size="9">Emb 256d</text>
  <text x="150" y="165" text-anchor="middle" fill="#9ca3af" font-size="8">Computed independently — cached in Redis</text>
  <text x="150" y="178" text-anchor="middle" fill="#6b7280" font-size="8">Updated hourly via Flink embedding job</text>
</svg>'
                  )
                )
              )
            )
          ),

          srPanel("sr3p2",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Item Tower Feature Groups"),
                  tags$ul(
                    tags$li(tags$b("Content embedding:"), " CLIP (image/video frame), text encoder (caption/hashtags) → 256d content embedding"),
                    tags$li(tags$b("Engagement velocity:"), " Shares/hr in first 60 min (strong freshness/virality signal)"),
                    tags$li(tags$b("Creator features:"), " Author follower count, creator embedding (their content style), verified status"),
                    tags$li(tags$b("Structural features:"), " Content type (video/image/text/link), duration, aspect ratio"),
                    tags$li(tags$b("Safety scores:"), " Safety classifier output (computed async — available within 1 min of publish)"),
                    tags$li(tags$b("Categorical:"), " Topic category, language, geographic relevance")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Cold Start for New Items"),
                  div(class="warn-box", tags$small(HTML("<strong>K&B Ch.4 Cold Start Problem:</strong> A new post has no engagement history. Without engagement features, the item tower produces a generic embedding that the ANN retrieval will not surface."))),
                  br(),
                  tags$ul(
                    tags$li(tags$b("Content-only embedding:"), " CLIP + text encoder available immediately — ensures item enters retrieval even with zero engagement"),
                    tags$li(tags$b("Freshness boost:"), " New items get a time-decayed additive score bonus for first 2 hours"),
                    tags$li(tags$b("Creator prior:"), " New items inherit their creator's historical engagement distribution as prior"),
                    tags$li(tags$b("Exploration injection:"), " 5% of retrieved candidates are randomly sampled fresh items (cold start exploration budget)")
                  )
                )
              )
            )
          ),

          srPanel("sr3p3",
            div(class="section-heading-dark", "Feature Store Pattern — Offline + Online at 3B-User Scale"),
            fluidRow(
              column(6,
                div(class="framework-card", style="border-left:3px solid #3b82f6;",
                  tags$h5("Offline Store (HDFS/S3)"),
                  tags$ul(
                    tags$li(tags$b("Purpose:"), " Training data generation — historical features + labels"),
                    tags$li(tags$b("Format:"), " Parquet, partitioned by date + user_id range"),
                    tags$li(tags$b("Point-in-time join:"), " When building training batch for a (user, item) impression at time T, use only features computed at T"),
                    tags$li(tags$b("Scale:"), " 100B impressions/day × 30 days training window = 3T rows. Use columnar Parquet with predicate pushdown."),
                    tags$li(tags$b("K&B warning:"), " Point-in-time join is expensive at this scale. Pre-join during nightly Spark job, not at training time.")
                  )
                )
              ),
              column(6,
                div(class="framework-card", style="border-left:3px solid #10b981;",
                  tags$h5("Online Store (Redis Cluster)"),
                  tags$ul(
                    tags$li(tags$b("Purpose:"), " Real-time feature serving during 100ms request window"),
                    tags$li(tags$b("User embeddings:"), " 3B users × 256d × INT8 = 768GB, sharded across 50 Redis nodes"),
                    tags$li(tags$b("Item embeddings:"), " FAISS index in-memory on retrieval servers — not Redis"),
                    tags$li(tags$b("Session features:"), " Computed on-the-fly from last 10 actions in current session (Kafka consumer per user)"),
                    tags$li(tags$b("Consistency:"), " Hourly batch update from HDFS → Redis. Accept 1-hour staleness for user embeddings.")
                  )
                )
              )
            )
          ),

          srPanel("sr3p4",
            div(class="warn-box", HTML("<strong>K&B Ch.4 — Train-Serve Skew at Social Scale:</strong> The two-tower model is trained on (user_features_at_T, item_features_at_T, label). At serving time, user features come from Redis (up to 1hr stale), item features from FAISS index (updated hourly). Any divergence = train-serve skew.")),
            br(),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("Skew Source"), tags$th("Root Cause"), tags$th("Detection"), tags$th("Fix"))),
              tags$tbody(
                tags$tr(tags$td("Embedding staleness"), tags$td("Redis update lag vs training snapshot"), tags$td("Log timestamp of embedding used at serving; compare to training timestamps"), tags$td("Accept up to 1hr staleness as SLO; alert if lag > 2hr")),
                tags$tr(tags$td("Negative sampling distribution"), tags$td("Training uses 70/20/10 mix; serving candidates are biased by prior model"), tags$td("Compare score distribution on random sample vs ANN-retrieved sample"), tags$td("Use IPS (Inverse Propensity Scoring) to correct for ANN retrieval bias")),
                tags$tr(tags$td("Safety score freshness"), tags$td("Safety score computed async; may not be available for very new items"), tags$td("Log rate of items served with null safety score"), tags$td("Default to conservative safety score (0.5) if unavailable; exclude from retrieval until scored")),
                tags$tr(tags$td("GNN social graph"), tags$td("Social graph updated daily; new follows not captured until tomorrow"), tags$td("Log new-follow rate vs graph update lag"), tags$td("Real-time edge updates to GNN embedding for high-follower accounts"))
              )
            )
          )
      )
    ),

    # ── BOX 4: Ch.5 Modelling ──
    fluidRow(
      box(title="Box 4 — Ch.5: Modelling — Two-Tower + DLRM Architecture (K&B)", status="info", solidHeader=TRUE, width=12,
          id="sr-box4",
          div(srBtn("sr-box4","sr4p1","Two-Tower Retrieval"),
              srBtn("sr-box4","sr4p2","DLRM Ranking"),
              srBtn("sr-box4","sr4p3","Multi-Task Learning"),
              srBtn("sr-box4","sr4p4","Training Strategy")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          srPanel("sr4p1",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Why Two-Tower? — K&B Ch.5"),
                  tags$p("The core insight: if user and item representations are computed independently, the item embeddings can be pre-indexed in an ANN structure, enabling sub-linear search over 10B items in milliseconds."),
                  tags$ul(
                    tags$li(tags$b("User tower:"), " Encodes user context into a 256d vector"),
                    tags$li(tags$b("Item tower:"), " Encodes item content + engagement into a 256d vector"),
                    tags$li(tags$b("Similarity:"), " Inner product (dot product) at retrieval time"),
                    tags$li(tags$b("Training objective:"), " Softmax with in-batch negatives; maximise similarity for positive pairs"),
                    tags$li(tags$b("ANN index:"), " FAISS HNSW — approximate nearest neighbours in 8ms for 10B items"),
                    tags$li(tags$b("Limitation:"), " Cannot use cross features (user × item interactions) — these must go in the ranking model")
                  )
                )
              ),
              column(6,
                HTML('
<svg viewBox="0 0 340 220" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <text x="170" y="15" text-anchor="middle" fill="#e8410a" font-size="10" font-weight="bold">Two-Tower Architecture</text>
  <!-- User Tower -->
  <rect x="10" y="25" width="130" height="130" rx="6" fill="#0c1f3a" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="75" y="45" text-anchor="middle" fill="#93c5fd" font-size="10" font-weight="bold">User Tower</text>
  <rect x="20" y="55" width="110" height="18" rx="3" fill="#1a2332" stroke="#3b82f6" stroke-width="1"/>
  <text x="75" y="68" text-anchor="middle" fill="#d1d5db" font-size="8">History + Social Embedding</text>
  <rect x="20" y="78" width="110" height="18" rx="3" fill="#1a2332" stroke="#3b82f6" stroke-width="1"/>
  <text x="75" y="91" text-anchor="middle" fill="#d1d5db" font-size="8">Session Context</text>
  <rect x="20" y="101" width="110" height="18" rx="3" fill="#1a2332" stroke="#3b82f6" stroke-width="1"/>
  <text x="75" y="114" text-anchor="middle" fill="#d1d5db" font-size="8">Dense MLP (3 layers)</text>
  <rect x="35" y="128" width="80" height="18" rx="3" fill="#0f2444" stroke="#10b981" stroke-width="1.5"/>
  <text x="75" y="141" text-anchor="middle" fill="#6ee7b7" font-size="9" font-weight="bold">User Emb (256d)</text>
  <!-- Item Tower -->
  <rect x="200" y="25" width="130" height="130" rx="6" fill="#0c1f3a" stroke="#f59e0b" stroke-width="1.5"/>
  <text x="265" y="45" text-anchor="middle" fill="#fcd34d" font-size="10" font-weight="bold">Item Tower</text>
  <rect x="210" y="55" width="110" height="18" rx="3" fill="#1a2332" stroke="#f59e0b" stroke-width="1"/>
  <text x="265" y="68" text-anchor="middle" fill="#d1d5db" font-size="8">CLIP + Text Encoder</text>
  <rect x="210" y="78" width="110" height="18" rx="3" fill="#1a2332" stroke="#f59e0b" stroke-width="1"/>
  <text x="265" y="91" text-anchor="middle" fill="#d1d5db" font-size="8">Engagement Velocity</text>
  <rect x="210" y="101" width="110" height="18" rx="3" fill="#1a2332" stroke="#f59e0b" stroke-width="1"/>
  <text x="265" y="114" text-anchor="middle" fill="#d1d5db" font-size="8">Dense MLP (3 layers)</text>
  <rect x="225" y="128" width="80" height="18" rx="3" fill="#0f2444" stroke="#10b981" stroke-width="1.5"/>
  <text x="265" y="141" text-anchor="middle" fill="#6ee7b7" font-size="9" font-weight="bold">Item Emb (256d)</text>
  <!-- Dot product -->
  <line x1="115" y1="137" x2="155" y2="167" stroke="#10b981" stroke-width="1.5"/>
  <line x1="225" y1="137" x2="185" y2="167" stroke="#10b981" stroke-width="1.5"/>
  <circle cx="170" cy="173" r="14" fill="#0f2444" stroke="#10b981" stroke-width="2"/>
  <text x="170" y="177" text-anchor="middle" fill="#6ee7b7" font-size="14">&#183;</text>
  <line x1="170" y1="187" x2="170" y2="205" stroke="#10b981" stroke-width="1.5" marker-end="url(#sr-arr)"/>
  <rect x="130" y="205" width="80" height="15" rx="3" fill="#0c1f3a" stroke="#e8410a" stroke-width="1"/>
  <text x="170" y="217" text-anchor="middle" fill="#fca5a5" font-size="8">Similarity Score</text>
  <!-- FAISS note -->
  <text x="170" y="168" text-anchor="middle" fill="#6b7280" font-size="7">dot product</text>
  <text x="265" y="175" text-anchor="middle" fill="#6b7280" font-size="7">Pre-indexed in FAISS</text>
  <text x="265" y="185" text-anchor="middle" fill="#6b7280" font-size="7">ANN search: 8ms / 10B items</text>
</svg>'
                )
              )
            )
          ),

          srPanel("sr4p2",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Wide-and-Deep DLRM — Ranking Model"),
                  tags$p("K&B explain Wide-and-Deep as the dominant architecture for ranking tasks requiring both memorisation of specific patterns and generalisation."),
                  tags$ul(
                    tags$li(tags$b("Wide component:"), " Linear model over crossed features — memorises specific (user_segment, creator_id) patterns. Trained with L1 regularisation."),
                    tags$li(tags$b("Deep component:"), " DNN over dense + sparse embeddings — generalises to unseen combinations. Embeddings for user, item, creator."),
                    tags$li(tags$b("Input:"), " User embedding (from Two-Tower) + Item embedding + Cross features (user × item interactions)"),
                    tags$li(tags$b("Output:"), " Multi-task heads — one per engagement signal + safety score"),
                    tags$li(tags$b("Scale:"), " ~100B parameters for Meta-scale; INT8 quantisation for serving")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Ranking Score Composition"),
                  div(style="background:#0a0d0f;padding:10px;border-radius:4px;font-family:'JetBrains Mono',monospace;font-size:10px;color:#6ee7b7;",
                    HTML("final_score =<br>&nbsp;&nbsp;w1 * P(click) +<br>&nbsp;&nbsp;w2 * P(watch_30s) +<br>&nbsp;&nbsp;w3 * P(share) * 10 +<br>&nbsp;&nbsp;w4 * P(save) * 8 +<br>&nbsp;&nbsp;w5 * P(comment) * 5<br><br>if P(unsafe) &gt; 0.05: score = 0  # hard guardrail<br>score *= diversity_penalty(creator_exposure)")
                  ),
                  br(),
                  div(class="tip-box", tags$small(HTML("<strong>K&B key:</strong> The weights w1-w5 are tuned to reflect business value, not just frequency. Shares are 10× weighted vs clicks — they are far rarer but far more valuable as engagement quality signals.")))
                )
              )
            )
          ),

          srPanel("sr4p3",
            div(class="section-heading-dark", "Multi-Task Learning — K&B Ch.5"),
            div(class="tip-box", HTML("<strong>K&B principle:</strong> Multi-task learning is essential for social recommenders. A single-task model optimising only clicks will ignore safety, diversity, and long-term retention. Multi-task allows the model to learn shared representations while predicting each signal.")),
            br(),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Shared Bottom + Task-Specific Heads"),
                  HTML('
<svg viewBox="0 0 300 200" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <rect x="90" y="10" width="120" height="35" rx="5" fill="#0f2444" stroke="#e8410a" stroke-width="1.5"/>
  <text x="150" y="30" text-anchor="middle" fill="#fca5a5" font-size="9" font-weight="bold">Shared Bottom Layers</text>
  <text x="150" y="42" text-anchor="middle" fill="#9ca3af" font-size="7">User + Item Embeddings → MLP</text>
  <line x1="110" y1="45" x2="40" y2="90" stroke="#e8410a" stroke-width="1"/>
  <line x1="130" y1="45" x2="100" y2="90" stroke="#e8410a" stroke-width="1"/>
  <line x1="150" y1="45" x2="160" y2="90" stroke="#e8410a" stroke-width="1"/>
  <line x1="170" y1="45" x2="220" y2="90" stroke="#e8410a" stroke-width="1"/>
  <line x1="190" y1="45" x2="270" y2="90" stroke="#e8410a" stroke-width="1"/>
  <!-- Task heads -->
  <rect x="10" y="90" width="60" height="30" rx="3" fill="#1a2332" stroke="#3b82f6" stroke-width="1"/>
  <text x="40" y="108" text-anchor="middle" fill="#93c5fd" font-size="7">P(click)</text>
  <rect x="75" y="90" width="60" height="30" rx="3" fill="#1a2332" stroke="#3b82f6" stroke-width="1"/>
  <text x="105" y="108" text-anchor="middle" fill="#93c5fd" font-size="7">P(watch30s)</text>
  <rect x="140" y="90" width="55" height="30" rx="3" fill="#1a2332" stroke="#10b981" stroke-width="1"/>
  <text x="167" y="108" text-anchor="middle" fill="#6ee7b7" font-size="7">P(share)</text>
  <rect x="200" y="90" width="50" height="30" rx="3" fill="#1a2332" stroke="#f59e0b" stroke-width="1"/>
  <text x="225" y="108" text-anchor="middle" fill="#fcd34d" font-size="7">P(save)</text>
  <rect x="255" y="90" width="40" height="30" rx="3" fill="#1a2332" stroke="#ef4444" stroke-width="1"/>
  <text x="275" y="108" text-anchor="middle" fill="#fca5a5" font-size="7">P(unsafe)</text>
  <!-- Weighted sum -->
  <line x1="40" y1="120" x2="120" y2="155" stroke="#6b7280" stroke-width="1"/>
  <line x1="105" y1="120" x2="132" y2="155" stroke="#6b7280" stroke-width="1"/>
  <line x1="167" y1="120" x2="150" y2="155" stroke="#6b7280" stroke-width="1"/>
  <line x1="225" y1="120" x2="165" y2="155" stroke="#6b7280" stroke-width="1"/>
  <rect x="100" y="155" width="100" height="28" rx="4" fill="#0c1f3a" stroke="#e8410a" stroke-width="1.5"/>
  <text x="150" y="170" text-anchor="middle" fill="#fca5a5" font-size="9" font-weight="bold">Weighted Score</text>
  <text x="150" y="182" text-anchor="middle" fill="#9ca3af" font-size="7">(P_unsafe guardrail applied)</text>
</svg>'
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Task Interference — K&B Warning"),
                  tags$p("Multi-task models can suffer from task interference: gradients from one task harm another task's performance."),
                  tags$ul(
                    tags$li(tags$b("Problem:"), " Safety task gradient may conflict with engagement gradient — they point in opposite directions for borderline content"),
                    tags$li(tags$b("Solution 1 — Gradient surgery:"), " Project conflicting gradients to remove harmful components"),
                    tags$li(tags$b("Solution 2 — Mixture of Experts (MoE):"), " Different expert networks per task; gating network decides which expert to use"),
                    tags$li(tags$b("Solution 3 — Hard parameter sharing only at bottom:"), " Shared embedding layers only; independent MLP towers per task"),
                    tags$li(tags$b("K&B recommendation:"), " Start with soft parameter sharing, add task weights to loss, monitor per-task validation metrics separately")
                  )
                )
              )
            )
          ),

          srPanel("sr4p4",
            div(class="section-heading-dark", "Training Strategy — K&B Ch.5"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Distributed Training at Scale"),
                  tags$ul(
                    tags$li(tags$b("Framework:"), " PyTorch + TorchRec (Meta's DLRM-specific distributed training framework)"),
                    tags$li(tags$b("Data parallelism:"), " Features (dense) sharded across GPUs via DDP"),
                    tags$li(tags$b("Model parallelism:"), " Embedding tables too large for single GPU — sharded across machines via RPC"),
                    tags$li(tags$b("Batch size:"), " 64k (larger batch = better in-batch negative quality)"),
                    tags$li(tags$b("Training frequency:"), " Two-Tower weekly full retrain; daily incremental update on new data"),
                    tags$li(tags$b("Infrastructure:"), " ~2,000 A100 GPUs for full training run; 24-hour wall-clock time")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Experiment Tracking — MLflow + Custom Dashboard"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Run"), tags$th("Model"), tags$th("NDCG@10"), tags$th("Safety AUC"), tags$th("Status"))),
                    tags$tbody(
                      tags$tr(style="color:#6b7280;", tags$td("R-01"), tags$td("Matrix Factorisation baseline"), tags$td("0.41"), tags$td("—"), tags$td("Baseline")),
                      tags$tr(tags$td("R-02"), tags$td("Two-Tower (no social graph)"), tags$td("0.58"), tags$td("0.82"), tags$td("+")),
                      tags$tr(tags$td("R-03"), tags$td("Two-Tower + GNN social"), tags$td("0.63"), tags$td("0.84"), tags$td("+")),
                      tags$tr(tags$td("R-04"), tags$td("DLRM ranking added"), tags$td("0.71"), tags$td("0.89"), tags$td("+")),
                      tags$tr(style="background:rgba(16,185,129,0.1);font-weight:bold;",
                        tags$td("R-05"), tags$td("Multi-task DLRM + re-rank"), tags$td("0.74"), tags$td("0.93"), tags$td("\U0001F3C6 Champion"))
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
      box(title="Box 5 — Ch.6: Evaluation, A/B Testing & Network Interference (K&B)", status="danger", solidHeader=TRUE, width=12,
          id="sr-box5",
          div(srBtn("sr-box5","sr5p1","Offline Metrics"),
              srBtn("sr-box5","sr5p2","Sliced Evaluation"),
              srBtn("sr-box5","sr5p3","A/B Testing & Network Interference"),
              srBtn("sr-box5","sr5p4","Offline-Online Gap")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          srPanel("sr5p1",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Offline Metric Selection — K&B Ch.6"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Task"), tags$th("Offline Metric"), tags$th("Why This Metric?"))),
                    tags$tbody(
                      tags$tr(tags$td("Retrieval quality"), tags$td("Recall@1000"), tags$td("Did the right items make it past retrieval?")),
                      tags$tr(tags$td("Ranking quality"), tags$td("NDCG@10"), tags$td("Ranking quality, position-discounted")),
                      tags$tr(tags$td("Click prediction"), tags$td("AUC-ROC"), tags$td("Threshold-independent ranking quality")),
                      tags$tr(tags$td("Watch-time pred."), tags$td("RMSE (normalised)"), tags$td("Regression task — mean squared error")),
                      tags$tr(tags$td("Safety detection"), tags$td("PR-AUC (recall-focused)"), tags$td("Missing unsafe content is worse than false positives")),
                      tags$tr(tags$td("Diversity"), tags$td("ILD (Intra-List Diversity)"), tags$td("Measures item dissimilarity in ranked list"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Calibration for Watch-Time"),
                  tags$p("DLRM predicts P(watch_30s) and P(share). These probabilities must be calibrated — a score of 0.3 should correspond to 30% actual watch-30s rate."),
                  tags$ul(
                    tags$li(tags$b("Platt scaling:"), " Post-hoc calibration on held-out set"),
                    tags$li(tags$b("Isotonic regression:"), " More flexible for non-monotonic miscalibration"),
                    tags$li(tags$b("Why it matters:"), " Weighted score combination requires calibrated probabilities — if P(share) is uncalibrated, the 10× weight produces incorrect final scores"),
                    tags$li(tags$b("Reliability diagram:"), " Plot predicted vs actual rate across 10 buckets; check for systematic over/under-confidence")
                  )
                )
              )
            )
          ),

          srPanel("sr5p2",
            div(class="section-heading-dark", "Sliced Evaluation — K&B Ch.6 Mandatory"),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("Slice"), tags$th("Segment"), tags$th("NDCG@10"), tags$th("Safety AUC"), tags$th("Issue?"))),
              tags$tbody(
                tags$tr(tags$td("Overall"), tags$td("All users"), tags$td("0.74"), tags$td("0.93"), tags$td("\u2705")),
                tags$tr(tags$td("Content type"), tags$td("Short-form video (<60s)"), tags$td("0.79"), tags$td("0.94"), tags$td("\u2705")),
                tags$tr(tags$td("Content type"), tags$td("Long-form video (>10min)"), tags$td("0.65"), tags$td("0.91"), tags$td("\u26A0 Weaker ranking")),
                tags$tr(tags$td("Content type"), tags$td("Text-only posts"), tags$td("0.61"), tags$td("0.90"), tags$td("\u26A0 CLIP not effective")),
                tags$tr(tags$td("Language"), tags$td("English"), tags$td("0.76"), tags$td("0.94"), tags$td("\u2705")),
                tags$tr(tags$td("Language"), tags$td("Low-resource (<10M speakers)"), tags$td("0.52"), tags$td("0.78"), tags$td("\u274C Safety risk!")),
                tags$tr(tags$td("User type"), tags$td("New users (<30 days)"), tags$td("0.55"), tags$td("0.93"), tags$td("\u26A0 Cold start")),
                tags$tr(tags$td("Creator"), tags$td("Small creators (<1k followers)"), tags$td("0.68"), tags$td("0.92"), tags$td("\u26A0 Fairness concern")),
                tags$tr(tags$td("Geography"), tags$td("Emerging markets"), tags$td("0.58"), tags$td("0.81"), tags$td("\u274C Safety gap"))
              )
            ),
            div(class="warn-box", HTML("<strong>K&B Ch.6 Critical Finding:</strong> Safety AUC = 0.78 for low-resource languages means harmful content in these languages is significantly more likely to be surfaced. This is both a safety risk and a fairness issue — users in those language communities receive lower-quality safety protection."))
          ),

          srPanel("sr5p3",
            div(class="warn-box", HTML("<strong>K&B Ch.6 — Network Interference: The Biggest A/B Testing Challenge in Social ML.</strong> In social networks, users are connected. Treatment group users share content with control group users. This violates the SUTVA assumption (Stable Unit Treatment Value Assumption) underlying standard A/B tests.")),
            br(),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Network Interference Problem"),
                  tags$ul(
                    tags$li(tags$b("Standard A/B test (incorrect):"), " Randomly assign 50% users to treatment. Treatment users share viral content → content enters control users' feeds → control group contaminated."),
                    tags$li(tags$b("Effect:"), " Underestimates true treatment effect — control group benefits from treatment group's better content."),
                    tags$li(tags$b("K&B documented example:"), " Meta found a 20% underestimate of feed ranking improvements due to network interference."),
                    tags$li(tags$b("Solution 1 — Graph-based randomisation:"), " Assign entire social clusters (connected components) to same arm — minimises cross-arm sharing."),
                    tags$li(tags$b("Solution 2 — Ego network:"), " Ensure a user and all their 1-hop friends are in the same arm."),
                    tags$li(tags$b("Solution 3 — Geographic clustering:"), " Assign entire cities/regions to same arm.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Interleaving — More Efficient Than A/B"),
                  tags$p("K&B recommend interleaving for ranking evaluation: merge ranked lists from control and treatment into a single feed, then measure which model's items get more engagement."),
                  tags$ul(
                    tags$li("100× more statistically efficient than A/B — same statistical power with 100× fewer users"),
                    tags$li("No network interference — both lists served to the same user"),
                    tags$li("Team draft interleaving: alternately pick top item from each model's list into merged feed"),
                    tags$li("Limitation: only measures relative ranking preference, not absolute engagement effects")
                  )
                ),
                div(class="tip-box", tags$small(HTML("<strong>K&B Interview Signal:</strong> Knowing that interleaving exists and why it's more efficient than A/B for ranking — while understanding its limitations — immediately signals FAANG-level system design experience.")))
              )
            )
          ),

          srPanel("sr5p4",
            div(class="section-heading-dark", "Offline-Online Metric Gap — K&B Root Cause Analysis"),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("Gap Source"), tags$th("Mechanism"), tags$th("Social Example"), tags$th("K&B Fix"))),
              tags$tbody(
                tags$tr(tags$td("Position bias"), tags$td("Top positions get more clicks regardless of content quality"), tags$td("Items shown at position 1-3 get 5× more clicks than position 8-10"), tags$td("IPS debiasing; propensity-weighted offline metrics")),
                tags$tr(tags$td("Exposure bias"), tags$td("Only previously surfaced items have engagement data"), tags$td("Niche creators never surfaced → no data → never surfaced (closed loop)"), tags$td("Exploration budget; forced exposure experiments")),
                tags$tr(tags$td("NDCG vs watch-time"), tags$td("NDCG measures click rank; watch-time is the real business metric"), tags$td("High NDCG model surfaces clickbait (high click, low watch-time)"), tags$td("Add normalised watch-time as offline proxy metric")),
                tags$tr(tags$td("Social amplification"), tags$td("Engagement in A/B period may not reflect steady-state after social spread"), tags$td("Viral content in treatment group gets reshared creating non-stationary engagement"), tags$td("Run A/B for minimum 2-week novelty washout period"))
              )
            )
          )
      )
    ),

    # ── BOX 6: Ch.7 Serving ──
    fluidRow(
      box(title="Box 6 — Ch.7: Serving & Deployment (K&B)", status="warning", solidHeader=TRUE, width=12,
          id="sr-box6",
          div(srBtn("sr-box6","sr6p1","Two-Stage Serving Pipeline"),
              srBtn("sr-box6","sr6p2","Model Compression"),
              srBtn("sr-box6","sr6p3","Canary & Rollback"),
              srBtn("sr-box6","sr6p4","Embedding Update Pipeline")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          srPanel("sr6p1",
            div(class="section-heading-dark", "Two-Stage Serving Architecture (K&B Ch.7)"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Stage 1 — Retrieval Service"),
                  tags$ul(
                    tags$li(tags$b("Input:"), " User embedding (256d) from Redis cache"),
                    tags$li(tags$b("Process:"), " FAISS HNSW ANN search over 10B item embeddings"),
                    tags$li(tags$b("Output:"), " Top-1,000 candidate items with approximate similarity scores"),
                    tags$li(tags$b("Latency SLO:"), " 10ms p99"),
                    tags$li(tags$b("Infrastructure:"), " FAISS index sharded across 100 retrieval servers, each holding 100M items; consistent hashing for item ID routing"),
                    tags$li(tags$b("FAISS index type:"), " HNSW — best recall/latency trade-off; 95% recall@1000 at 8ms")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Stage 2 — Ranking Service"),
                  tags$ul(
                    tags$li(tags$b("Input:"), " 1,000 candidates + full feature set from online store"),
                    tags$li(tags$b("Process:"), " DLRM forward pass — 100B parameters, INT8 quantised"),
                    tags$li(tags$b("Output:"), " Per-item scores for each task (click/watch/share/safety)"),
                    tags$li(tags$b("Latency SLO:"), " 50ms p99 for 1,000 items"),
                    tags$li(tags$b("Infrastructure:"), " A100 GPUs (INT8), TorchServe, autoscale 50-500 instances based on QPS"),
                    tags$li(tags$b("Batching:"), " Dynamic batching — up to 64 user requests merged into single GPU batch")
                  )
                )
              )
            )
          ),

          srPanel("sr6p2",
            div(class="section-heading-dark", "Model Compression — K&B Ch.7"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("DLRM Compression Stack"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Technique"), tags$th("Size Reduction"), tags$th("Latency Gain"), tags$th("Quality Loss"))),
                    tags$tbody(
                      tags$tr(tags$td("Baseline (FP32)"), tags$td("—"), tags$td("—"), tags$td("—")),
                      tags$tr(tags$td("FP16 (AMP training)"), tags$td("50%"), tags$td("20%"), tags$td("<0.1% NDCG")),
                      tags$tr(tags$td("INT8 post-training quant."), tags$td("75%"), tags$td("40%"), tags$td("~0.3% NDCG")),
                      tags$tr(tags$td("Embedding pruning (PQ)"), tags$td("80%"), tags$td("35%"), tags$td("~0.5% NDCG")),
                      tags$tr(tags$td("Knowledge distillation"), tags$td("90%"), tags$td("60%"), tags$td("~1.0% NDCG")),
                      tags$tr(style="background:rgba(16,185,129,0.1);", tags$td("INT8 + embedding PQ"), tags$td("85%"), tags$td("55%"), tags$td("\u2705 ~0.5% NDCG — deployed"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Product Quantisation (PQ) for Embeddings"),
                  tags$p("10B item embeddings × 256d × FP32 = 10TB is too large to load into FAISS memory. PQ compresses embeddings to sub-vectors."),
                  tags$ul(
                    tags$li("Split 256d vector into 32 sub-vectors of 8d each"),
                    tags$li("Quantise each sub-vector to 256 centroids (8 bits)"),
                    tags$li("Compressed size: 10B × 32 bytes = 320GB — fits on 20 servers"),
                    tags$li("Recall penalty: ~2-3% vs exact search — acceptable for retrieval stage"),
                    tags$li(tags$b("K&B:"), " PQ is the standard technique for billion-scale ANN. Know FAISS IVF-PQ configuration.")
                  )
                )
              )
            )
          ),

          srPanel("sr6p3",
            div(class="section-heading-dark", "Canary Deployment & Rollback Strategy (K&B Ch.7)"),
            fluidRow(
              column(4, div(class="framework-card",
                tags$h5("1% Canary"),
                tags$ul(
                  tags$li("New model version serves 1% of users for 24hr"),
                  tags$li("Automated checks: engagement delta, safety recall, latency SLO"),
                  tags$li("If any guardrail breached: auto-rollback in <5 min"),
                  tags$li("Human review before proceeding to next phase")
                )
              )),
              column(4, div(class="framework-card",
                tags$h5("10% → 50% Ramp"),
                tags$ul(
                  tags$li("Gradual ramp over 3-5 days"),
                  tags$li("Each step requires: stable engagement trend, no PSI spike, no safety recall drop"),
                  tags$li("Automated daily ramp gates — pass/fail criteria defined upfront"),
                  tags$li("Champion-challenger: keep old model live for instant rollback")
                )
              )),
              column(4, div(class="framework-card",
                tags$h5("100% Rollout + Monitoring"),
                tags$ul(
                  tags$li("Blue-green: old model kept warm for 1 week post full-rollout"),
                  tags$li("Rollback SLO: <5 min via feature flag toggle"),
                  tags$li("K&B: never delete old model artifact for at least 30 days post-rollout"),
                  tags$li("Post-rollout review: compare business metrics pre/post over 14 days")
                )
              ))
            )
          ),

          srPanel("sr6p4",
            div(class="section-heading-dark", "Hourly Embedding Update Pipeline — K&B Stateful Serving"),
            div(class="tip-box", HTML("<strong>K&B Ch.7 Key Point:</strong> At 100B events/day, it is infeasible to retrain the full model hourly. Instead, K&B advocate for <em>stateful serving</em>: keep model weights fixed, but update embeddings incrementally using new engagement data.")),
            br(),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Embedding Update Pipeline"),
                  tags$ol(
                    tags$li("Flink job aggregates engagement events over last 1 hour"),
                    tags$li("For each (user, item) interaction pair, compute gradient update to embeddings only"),
                    tags$li("Apply update to user/item embedding tables (not full model weights)"),
                    tags$li("Push updated embeddings to Redis (users) and FAISS index rebuild (items)"),
                    tags$li("FAISS rebuild is incremental (add/remove vectors) not full rebuild")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Why Stateless Retraining Fails Here"),
                  tags$ul(
                    tags$li(tags$b("Stateless:"), " Full model retrain from scratch on all historical data. Expensive (24hr, 2000 GPUs). Weekly cadence maximum."),
                    tags$li(tags$b("Stateful:"), " Update only embedding layers using fresh data. 1-hour cadence feasible. Adapts to trending content."),
                    tags$li(tags$b("Catastrophic forgetting risk:"), " Stateful update can overwrite knowledge of rare events if learning rate too high. Fix: use smaller LR for embedding updates (0.001) vs full training (0.01)."),
                    tags$li(tags$b("K&B recommendation:"), " Weekly full stateless retrain + hourly stateful embedding updates")
                  )
                )
              )
            )
          )
      )
    ),

    # ── BOX 7: Ch.8 Monitoring ──
    fluidRow(
      box(title="Box 7 — Ch.8: Monitoring, Drift & Responsible AI (K&B)", status="success", solidHeader=TRUE, width=12,
          id="sr-box7",
          div(srBtn("sr-box7","sr7p1","Drift Detection"),
              srBtn("sr-box7","sr7p2","Feedback Loop Monitoring"),
              srBtn("sr-box7","sr7p3","Creator Fairness & DSA"),
              srBtn("sr-box7","sr7p4","MLOps Stack")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          srPanel("sr7p1",
            div(class="section-heading-dark", "Distribution Shift Monitoring — K&B Ch.8"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Covariate Shift Sources"),
                  tags$ul(
                    tags$li(tags$b("News events:"), " Breaking news creates sudden spike in news consumption — model trained on normal distribution underestimates this"),
                    tags$li(tags$b("New content formats:"), " Platform launches Reels/Stories → new content type not in training distribution"),
                    tags$li(tags$b("Seasonal:"), " Holiday periods shift engagement patterns (hours, devices, content types)"),
                    tags$li(tags$b("Geographic expansion:"), " Launching in new country → user behaviour distribution shifts to new cultural norms")
                  )
                ),
                div(class="framework-card",
                  tags$h5("Concept Drift Sources"),
                  tags$ul(
                    tags$li(tags$b("Trend cycles:"), " What constitutes 'engaging' content changes — TikTok trends, meme formats"),
                    tags$li(tags$b("Platform policy changes:"), " New content rules change what is surfaced → changes historical label distribution"),
                    tags$li(tags$b("Social events:"), " Elections, crises — political content engagement spikes, then drops. Model calibration drifts.")
                  )
                )
              ),
              column(6,
                tags$table(class="table table-sm",
                  tags$thead(tags$tr(tags$th("Signal"), tags$th("Frequency"), tags$th("Threshold"), tags$th("Action"))),
                  tags$tbody(
                    tags$tr(tags$td("Engagement rate distribution"), tags$td("Hourly"), tags$td("KS-stat > 0.05"), tags$td("Alert")),
                    tags$tr(tags$td("PSI (user features)"), tags$td("Daily"), tags$td("> 0.1"), tags$td("Alert")),
                    tags$tr(tags$td("PSI (item features)"), tags$td("Hourly"), tags$td("> 0.15"), tags$td("Alert + review")),
                    tags$tr(tags$td("Safety recall"), tags$td("Hourly"), tags$td("Drop > 2%"), tags$td("Page safety team")),
                    tags$tr(tags$td("NDCG@10 (shadow)"), tags$td("Daily"), tags$td("Drop > 3%"), tags$td("Trigger retrain")),
                    tags$tr(tags$td("New content type rate"), tags$td("Daily"), tags$td("> 5% new type"), tags$td("Flag for training data collection")),
                    tags$tr(tags$td("Latency SLO"), tags$td("Real-time"), tags$td("p99 > 100ms"), tags$td("Auto-scale + page"))
                  )
                )
              )
            )
          ),

          srPanel("sr7p2",
            div(class="section-heading-dark", "Feedback Loop Detection — K&B Ch.8 Degenerate Case"),
            div(class="warn-box", HTML("<strong>K&B Ch.8 — The Recommender Feedback Loop:</strong> The model recommends popular content → popular content gets more engagement → model learns it's even better → less popular content never gets a chance. Over time, content diversity collapses.")),
            br(),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Gini Coefficient — Diversity Collapse Metric"),
                  tags$p("Gini coefficient of impression share across all creators. 0 = perfectly equal. 1 = one creator monopolises all impressions."),
                  HTML('
<svg viewBox="0 0 300 180" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <text x="150" y="15" text-anchor="middle" fill="#e8410a" font-size="10" font-weight="bold">Creator Impression Share — Gini Over Time</text>
  <line x1="40" y1="155" x2="280" y2="155" stroke="#374151" stroke-width="1.5"/>
  <line x1="40" y1="155" x2="40" y2="25" stroke="#374151" stroke-width="1.5"/>
  <text x="35" y="155" text-anchor="end" fill="#9ca3af" font-size="7">0.0</text>
  <text x="35" y="115" text-anchor="end" fill="#9ca3af" font-size="7">0.4</text>
  <text x="35" y="75" text-anchor="end" fill="#9ca3af" font-size="7">0.8</text>
  <text x="35" y="38" text-anchor="end" fill="#f59e0b" font-size="7">Threshold</text>
  <line x1="40" y1="43" x2="280" y2="43" stroke="#f59e0b" stroke-width="1" stroke-dasharray="4,3"/>
  <polyline points="40,140 75,135 110,128 145,118 180,105 215,92 250,78 280,62" fill="none" stroke="#ef4444" stroke-width="2"/>
  <text x="285" y="65" fill="#ef4444" font-size="7">No fix</text>
  <polyline points="40,140 75,138 110,135 145,130 180,128 215,127 250,126 280,125" fill="none" stroke="#10b981" stroke-width="2"/>
  <text x="285" y="128" fill="#10b981" font-size="7">With diversity floor</text>
  <text x="160" y="168" text-anchor="middle" fill="#9ca3af" font-size="8">Months of operation</text>
  <text x="18" y="95" fill="#9ca3af" font-size="7" transform="rotate(-90,18,95)">Gini Index</text>
</svg>'
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Mitigation Strategies (K&B Ch.8)"),
                  tags$ul(
                    tags$li(tags$b("Diversity floor:"), " Re-ranking enforces minimum ILD score — ensures no more than 30% of feed from same creator"),
                    tags$li(tags$b("Exploration budget:"), " 5-10% of retrieved candidates are random/fresh — breaks the feedback loop with unbiased data"),
                    tags$li(tags$b("IPS correction:"), " Inverse Propensity Scoring in training — down-weight training examples that were surfaced at very high propensity (corrects for exposure bias)"),
                    tags$li(tags$b("Diversity in retrieval:"), " Maximal Marginal Relevance (MMR) during ANN retrieval — penalise items too similar to already-selected candidates"),
                    tags$li(tags$b("Alert:"), " Automated alert when creator Gini coefficient exceeds 0.6 threshold")
                  )
                )
              )
            )
          ),

          srPanel("sr7p3",
            div(class="section-heading-dark", "Creator Fairness & EU DSA Compliance — K&B Ch.8"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Creator Fairness Metrics"),
                  tags$ul(
                    tags$li(tags$b("Impression share Gini:"), " Alert > 0.60"),
                    tags$li(tags$b("Small creator reach:"), " Creators <1k followers should get ≥ baseline organic reach — monitor weekly"),
                    tags$li(tags$b("Language parity:"), " Safety AUC parity across top 50 languages — low-resource language safety gap is an equity issue"),
                    tags$li(tags$b("Geographic parity:"), " Engagement quality (NDCG@10) comparable across regions — avoid model performing well only on training-abundant geographies")
                  )
                ),
                div(class="warn-box", HTML("<strong>K&B Responsible AI Point:</strong> A recommender that is biased toward large creators and high-resource languages is not just a fairness concern — it is a business risk. Creator attrition and regulatory fines (DSA) can be more expensive than the engineering cost of fixing the bias."))
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("EU DSA Compliance Requirements"),
                  tags$ul(
                    tags$li(tags$b("DSA Art.27 — Explainability:"), " System must explain to users why each item was recommended. Implementation: 'Shown because you watched X, because your friend liked Y.'"),
                    tags$li(tags$b("DSA Art.38 — Opt-out:"), " User can switch to chronological feed. Separate model not trained on engagement (just recency) must exist and be performant."),
                    tags$li(tags$b("DSA risk assessment:"), " Annual risk assessment of systemic risks: information integrity, fundamental rights, public health."),
                    tags$li(tags$b("Independent audit:"), " Annual audit of recommender system by approved auditor. Model cards + data cards must be maintained.")
                  )
                )
              )
            )
          ),

          srPanel("sr7p4",
            div(class="section-heading-dark", "MLOps Stack — K&B Ch.8 Infrastructure"),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("Layer"), tags$th("K&B Category"), tags$th("Tool (Meta-scale)"), tags$th("Notes"))),
              tags$tbody(
                tags$tr(tags$td("Event ingestion"), tags$td("Data layer"), tags$td("Kafka + Flink"), tags$td("100B events/day; exactly-once semantics")),
                tags$tr(tags$td("Offline storage"), tags$td("Data layer"), tags$td("HDFS / S3 (Parquet)"), tags$td("Petabyte scale; 2yr retention; Hive metastore")),
                tags$tr(tags$td("Online store"), tags$td("Feature layer"), tags$td("Redis Cluster (50 shards)"), tags$td("User/item embeddings; INT8; <10ms lookup")),
                tags$tr(tags$td("ANN index"), tags$td("Serving layer"), tags$td("FAISS HNSW (100 shards)"), tags$td("10B items; IVF-PQ; 95% Recall@1k at 8ms")),
                tags$tr(tags$td("Model training"), tags$td("Training layer"), tags$td("PyTorch + TorchRec"), tags$td("2,000 A100s; data + model parallelism")),
                tags$tr(tags$td("Experiment tracking"), tags$td("Training layer"), tags$td("MLflow + internal FB tools"), tags$td("Metrics, artifacts, A/B comparison")),
                tags$tr(tags$td("Model serving"), tags$td("Serving layer"), tags$td("TorchServe + Triton"), tags$td("INT8; dynamic batching; autoscale")),
                tags$tr(tags$td("Orchestration"), tags$td("Orchestration"), tags$td("Airflow (weekly retrain) + Flink (hourly updates)"), tags$td("Separate pipelines for batch and streaming")),
                tags$tr(tags$td("Monitoring"), tags$td("Monitoring layer"), tags$td("Custom + Grafana + PagerDuty"), tags$td("PSI, Gini, safety recall, latency dashboards")),
                tags$tr(tags$td("Governance"), tags$td("Responsible AI"), tags$td("Model cards + DSA audit framework"), tags$td("Annual independent audit required"))
              )
            )
          )
      )
    ),

    # ── Self-Assessment ──
    fluidRow(
      box(title="Self-Assessment — Social Media Recommender", status="primary", solidHeader=TRUE, width=12,
          fluidRow(
            column(4, sliderInput(ns("sc1"),"Requirements & Multi-Objective (Ch.1-2)",1,10,5)),
            column(4, sliderInput(ns("sc2"),"Petabyte Data Pipeline (Ch.3)",1,10,5)),
            column(4, sliderInput(ns("sc3"),"Two-Tower Feature Design (Ch.4)",1,10,5))
          ),
          fluidRow(
            column(4, sliderInput(ns("sc4"),"DLRM Modelling & Multi-Task (Ch.5)",1,10,5)),
            column(4, sliderInput(ns("sc5"),"A/B Testing & Network Interference (Ch.6)",1,10,5)),
            column(4, sliderInput(ns("sc6"),"Serving, Monitoring & Fairness (Ch.7-8)",1,10,5))
          ),
          fluidRow(
            column(4, actionButton(ns("save_self"),"Save Assessment", class="btn-meta", width="100%")),
            column(8, uiOutput(ns("self_result")))
          )
      )
    )
  )
}

social_recommender_case_study_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_self, {
      avg <- mean(c(input$sc1, input$sc2, input$sc3, input$sc4, input$sc5, input$sc6))
      pct <- round(avg * 10)
      prep_manager$update_progress("social_recommender_case_study", pct)
      output$self_result <- renderUI({
        col <- progress_colour(pct)
        div(class=if(pct>=80)"success-box" else "tip-box",
            tags$h5(style=paste0("color:",col), paste0("Social Recommender Readiness: ", pct, "%")),
            if(pct < 50)  tags$p("Focus on K&B Ch.3 (negative sampling) and Ch.6 (network interference in A/B testing) — these are the most differentiated interview topics for social ML."),
            if(pct >= 50 && pct < 80) tags$p("Solid foundation. Deepen on: Two-Tower vs DLRM trade-offs, stateful embedding updates, and creator fairness/DSA compliance."),
            if(pct >= 80) tags$p("\u2705 Excellent. You can walk through a Meta-scale recommendation system end-to-end with the K&B framework."))
      })
      showNotification("Social Recommender assessment saved!", type="message")
    })
  })
}
