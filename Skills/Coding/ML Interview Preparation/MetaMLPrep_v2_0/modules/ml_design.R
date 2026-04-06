# modules/ml_design.R
# Tab 4: ML Design Interview (PDF page 9) — THE KEY DIFFERENTIATOR
# Two 45-minute sessions | Ranking, Recommenders, CV, Entity Matching

ml_design_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    div(class="meta-hero",
        tags$h1("ML Design Interview"),
        tags$h2("Two × 45-Minute Sessions — The Decisive Differentiator"),
        div(
          span(class="hero-badge", "Recommender Systems"),
          span(class="hero-badge", "Ranking"),
          span(class="hero-badge", "Computer Vision"),
          span(class="hero-badge", "Entity Matching"),
          span(class="hero-badge", "LLM Systems")
        )
    ),
    
    # ── Interview Structure ──────────────────────────
    fluidRow(
      box(title="🎯 How to Ace the ML Design Interview at Meta",
          status="primary", solidHeader=TRUE, width=12,
          
          fluidRow(
            column(3, div(class="metric-card", span(class="metric-value","DRIVE"), span(class="metric-label","Own the Conversation"))),
            column(3, div(class="metric-card", span(class="metric-value","WHY"),   span(class="metric-label","Justify Every Choice"))),
            column(3, div(class="metric-card", span(class="metric-value","TRADE"),  span(class="metric-label","Off Every Decision"))),
            column(3, div(class="metric-card", span(class="metric-value","BOLD"),   span(class="metric-label","Challenge Assumptions")))
          ),
          br(),
          
          fluidRow(
            column(6,
                   div(class="warn-box",
                       HTML("<strong>⚠️ Critical:</strong> This is NOT a passive Q&A. You should drive the session. 80% of the talking should be YOU. Treat it as if you're presenting your system design to a Principal Engineer at Meta.")),
                   br(),
                   div(class="success-box",
                       HTML("<strong>✅ The 5 Cs Framework (Meta ML Design):</strong><br/>
                       1. <b>Clarify</b> — requirements, constraints, scale, latency SLOs<br/>
                       2. <b>Conceptualise</b> — frame as an ML problem, define metrics<br/>
                       3. <b>Create</b> — feature engineering, model architecture, training<br/>
                       4. <b>Calibrate</b> — evaluation, A/B testing, online metrics<br/>
                       5. <b>Cruise</b> — serving, monitoring, iteration strategy"))
            ),
            column(6,
                   div(class="framework-card",
                       tags$h5("45-Minute Time Budget"),
                       timeline_entry("0-5",  "Problem Clarification", "Ask about scale (DAUs, QPS), latency budget, success metrics."),
                       timeline_entry("5-15", "ML Problem Framing",    "Define the label, data sources, online/offline metrics, baseline."),
                       timeline_entry("15-30","Model Architecture",    "Feature pipeline, model choice + why, training setup, embeddings."),
                       timeline_entry("30-40","Evaluation & Serving",  "Offline eval, A/B tests, serving infra, latency optimisation."),
                       timeline_entry("40-45","Iteration & Extension", "What you'd do with more time, known limitations, future directions."))
            )
          )
      )
    ),
    
    # ── Sample Questions Deep Dives ──────────────────
    fluidRow(
      box(title="🔬 Deep Dives: Meta ML Design Questions",
          status="info", solidHeader=TRUE, width=12,
          
          tabsetPanel(
            # ── Tab A: Recommendation System ─────────
            tabPanel("Recommender / Feed Ranking",
                     br(),
                     fluidRow(
                       column(6,
                              div(class="section-heading-dark", "Sample Question"),
                              div(class="practice-area",
                                  p(tags$b("'Design Meta's News Feed ranking system.'")),
                                  p(tags$i("Or: 'Design a Reels recommendation system for Instagram.'")),
                                  p(tags$i("Or: 'Design the ads ranking system for Facebook.'"))),
                              br(),
                              div(class="section-heading-dark", "Clarifying Questions to Ask"),
                              tags$ul(
                                tags$li("What is the DAU? (Meta: 3.1B) → QPS implications"),
                                tags$li("What is the latency budget? (<100ms for feed, <500ms for ads auction)"),
                                tags$li("Single engagement type or multi-objective? (likes, comments, shares, clicks, time-spent)"),
                                tags$li("Real-time or batch personalisation?"),
                                tags$li("Cold start strategy required?"),
                                tags$li("Explicit feedback (ratings) or implicit (clicks, dwell time)?")
                              ),
                              br(),
                              div(class="section-heading-dark", "ML Problem Framing"),
                              div(class="framework-card",
                                  tags$h5("Label Definition"),
                                  tags$p("Predict P(engagement | user, item, context). Multi-task: predict likes, shares, clicks, video completion separately. Combine via learned weighted sum or Pareto-optimal selection.")),
                              div(class="framework-card",
                                  tags$h5("Offline Metric"),
                                  tags$p("AUC-ROC per task. Normalised Discounted Cumulative Gain (NDCG). Mean Reciprocal Rank (MRR) for search-like surfaces.")),
                              div(class="framework-card",
                                  tags$h5("Online Metric"),
                                  tags$p("CTR, DAU × sessions, L7 retention, time-spent (with guardrails against low-quality bait). Engagement weighted by quality score."))
                       ),
                       column(6,
                              div(class="section-heading-dark", "Architecture: Meta DLRM-Style"),
                              div(class="framework-card",
                                  tags$h5("Candidate Generation (Funnel Stage 1)"),
                                  tags$p("Two-tower model: user embedding + item embedding. Trained with in-batch negative sampling. ANN search (FAISS) over item index. Retrieve top-1000 candidates."),
                                  tags$code("User Tower: [user_id, age, location, device, time] → MLP → 128-d embedding"),
                                  br(),tags$code("Item Tower: [post_id, author, topic, media_type] → MLP → 128-d embedding")),
                              
                              div(class="framework-card",
                                  tags$h5("Ranking (Funnel Stage 2 — DLRM)"),
                                  tags$p("Deep Learning Recommendation Model. Dense features (user activity, item stats) + sparse features (categorical IDs via embedding tables). Cross-product feature interactions via dot products."),
                                  tags$code("DLRM: Dense MLP → Bottom MLP\nEmbedding tables for sparse feats\nFeature interactions (dot product)\nTop MLP → Sigmoid → P(engagement)")),
                              
                              div(class="framework-card",
                                  tags$h5("Re-ranking & Diversity"),
                                  tags$p("MMR (Maximal Marginal Relevance) for diversity. Business rules: suppress low-quality, apply policy filters, inject ads at defined positions. Contextual bandit for exploration.")),
                              
                              div(class="tip-box",
                                  HTML("<strong>💡 Drop this at Meta:</strong> 'I'd consider using DLRM (Meta's open-source model) as the base ranking model given its proven performance on sparse + dense feature combinations at this scale.'"))
                       )
                     )
            ),
            
            # ── Tab B: Entity Matching ────────────────
            tabPanel("Entity Matching / Taxonomy",
                     br(),
                     fluidRow(
                       column(6,
                              div(class="section-heading-dark", "Sample Question"),
                              div(class="practice-area",
                                  p(tags$b("'Design an entity matching system for Meta's product catalogue.'")),
                                  p(tags$i("Or: 'Design a system to match user-generated content to a structured taxonomy.'")),
                                  p(tags$i("Or: 'Build a deduplication system for Facebook Pages.'")),
                              ),
                              br(),
                              div(class="section-heading-dark", "Problem Decomposition"),
                              div(class="framework-card",
                                  tags$h5("Step 1: Blocking"),
                                  tags$p("Reduce the O(n²) comparison problem. Use MinHash LSH (Locality Sensitive Hashing) or inverted index on TF-IDF tokens to retrieve candidate pairs with high recall but reduced compute.")),
                              div(class="framework-card",
                                  tags$h5("Step 2: Feature Engineering for Matching"),
                                  tags$p("String similarity: Jaccard, edit distance, character n-gram overlap. Semantic similarity: embed both entities with BERT/SBERT, compute cosine similarity. Structured field matching: phone, address, URL exact/fuzzy match.")),
                              div(class="framework-card",
                                  tags$h5("Step 3: Classification"),
                                  tags$p("Train a binary classifier (match / no-match). Features: pairwise similarity scores. Model: gradient boosted trees (fast, interpretable) or a cross-encoder transformer (higher accuracy, slower)."))
                       ),
                       column(6,
                              div(class="section-heading-dark", "Advanced Considerations"),
                              div(class="framework-card",
                                  tags$h5("Label Collection"),
                                  tags$p("Active learning: prioritise hard cases near the decision boundary. Weak supervision: programmatic labels from heuristic rules (Snorkel framework). Human-in-the-loop for ambiguous pairs.")),
                              div(class="framework-card",
                                  tags$h5("Taxonomy Classification"),
                                  tags$p("Hierarchical classification problem. Use zero-shot or few-shot with LLM (Llama) for rare taxonomy nodes. Fine-tune on labelled examples for high-frequency nodes. Beam search over the taxonomy tree.")),
                              div(class="framework-card",
                                  tags$h5("Scale"),
                                  tags$p("Batch processing: Spark for pairwise candidate generation at scale. Online: real-time entity matching API with <100ms latency using approximate nearest neighbour (FAISS/ScaNN) + lightweight linear classifier.")),
                              div(class="success-box",
                                  HTML("<strong>✅ Leadership angle:</strong> Mention that you'd define the recall vs precision operating point as a product decision, not a pure ML decision — inform PM/legal on implications of false positives (wrongly merging entities)."))
                       )
                     )
            ),
            
            # ── Tab C: Face Tagging / CV ──────────────
            tabPanel("Computer Vision — Face Tagging",
                     br(),
                     fluidRow(
                       column(6,
                              div(class="section-heading-dark", "Sample Question"),
                              div(class="practice-area",
                                  p(tags$b("'Design a face tagging system for Facebook Photos.'")),
                                  p(tags$i("Or: 'Design an AR filter system for Instagram.'")),
                                  p(tags$i("Or: 'Build a visual content moderation system.'")),
                              ),
                              br(),
                              div(class="section-heading-dark", "System Components"),
                              div(class="framework-card",
                                  tags$h5("Stage 1: Face Detection"),
                                  tags$p("RetinaFace or MTCNN for multi-scale face detection. Anchor-free detectors (FCOS-style) for speed. Output: bounding boxes + confidence scores. Filter with NMS.")),
                              div(class="framework-card",
                                  tags$h5("Stage 2: Face Recognition (Embedding)"),
                                  tags$p("ArcFace / CosFace loss for discriminative embeddings. ResNet-50/100 or ViT backbone. Output: 512-d face embedding. Gallery = user photo embeddings (one per user, updated periodically).")),
                              div(class="framework-card",
                                  tags$h5("Stage 3: Matching"),
                                  tags$p("ANN search with FAISS over the gallery index. Friends-only search (filter by social graph). Threshold tuning: high precision over recall for auto-tag; allow lower precision for 'suggestions'."))
                       ),
                       column(6,
                              div(class="section-heading-dark", "Privacy & Responsible AI — CRITICAL at Meta"),
                              div(class="warn-box",
                                  HTML("<strong>⚠️ This is a high-stakes area at Meta.</strong> Facebook paid $650M FTC settlement over face tagging. You MUST address privacy proactively.")),
                              div(class="framework-card",
                                  tags$h5("Consent & Control"),
                                  tags$p("Opt-in by default in GDPR regions. Clear user controls to disable. Audit trail of tagging decisions. Right to delete: remove from gallery index.")),
                              div(class="framework-card",
                                  tags$h5("Bias & Fairness"),
                                  tags$p("Evaluate accuracy stratified by gender, age, skin tone (Fitzpatrick scale). Train on demographically balanced datasets. Monitor for performance drift across subgroups. Report fairness metrics to stakeholders.")),
                              div(class="framework-card",
                                  tags$h5("Meta's Actual Stack"),
                                  tags$p("DeepFace (published 2014, 97.35% accuracy). PyTorch for training. FAISS for ANN at billion-scale. On-device inference via mobile-optimised models (MobileNet variants) for privacy-preserving edge inference.")),
                              div(class="success-box",
                                  HTML("<strong>✅ Leadership move:</strong> Proactively propose a fairness review board process before launch, not as an afterthought. Shows maturity at L6+."))
                       )
                     )
            ),
            
            # ── Tab D: LLM Systems ─────────────────────
            tabPanel("LLM Systems (2026 Focus)",
                     br(),
                     fluidRow(
                       column(6,
                              div(class="section-heading-dark", "Sample Question"),
                              div(class="practice-area",
                                  p(tags$b("'Design Meta AI Assistant — the cross-app LLM-powered chatbot.'")),
                                  p(tags$i("Or: 'Design a system to fine-tune Llama for a specific vertical.'")),
                                  p(tags$i("Or: 'Design an LLM-based content moderation system.'")),
                              ),
                              br(),
                              div(class="section-heading-dark", "RAG System Design"),
                              div(class="framework-card",
                                  tags$h5("Retrieval-Augmented Generation"),
                                  tags$p("1. Query → dense retrieval (FAISS + bi-encoder). 2. Top-k documents → context window. 3. LLM generates response grounded in retrieved docs."),
                                  tags$p("Key challenges: context length limits, retrieval quality, latency.")),
                              div(class="framework-card",
                                  tags$h5("Fine-tuning Llama at Meta Scale"),
                                  tags$p("LoRA (Low-Rank Adaptation): 0.1% of parameters, 3× less GPU memory. RLHF (PPO or DPO) for alignment. Data: instruction-following pairs, quality filtered. FBLearner for training orchestration.")),
                              div(class="framework-card",
                                  tags$h5("Serving Infrastructure"),
                                  tags$p("vLLM / TGI for PagedAttention (30× throughput vs naive). Dynamic batching. KV-cache management. Speculative decoding for latency."))
                       ),
                       column(6,
                              div(class="section-heading-dark", "Evaluation for LLM Systems"),
                              div(class="framework-card",
                                  tags$h5("Offline Metrics"),
                                  tags$p("BLEU/ROUGE (weak), BERTScore, win rate vs baseline (human eval), MMLU, HumanEval for coding tasks. Constitutional AI self-critique scoring.")),
                              div(class="framework-card",
                                  tags$h5("Online Metrics"),
                                  tags$p("Session depth (messages per conversation), explicit feedback thumbs-up/down, task completion rate, retention (did user return?), hallucination rate (fact-checking pipeline).")),
                              div(class="framework-card",
                                  tags$h5("Safety & Moderation Layer"),
                                  tags$p("Llama Guard (Meta's safety classifier). Input/output filtering. PII detection. Policy violation classifier. Rate limiting for abuse prevention.")),
                              div(class="tip-box",
                                  HTML("<strong>💡 2026 Meta angle:</strong> Position Meta AI as needing multi-modal capabilities — text + images (via Segment Anything + ImageBind integration). Show you understand the full Meta AI vision, not just text-only LLMs."))
                       )
                     )
            )
          )
      )
    ),
    
    # ── Practice Designer ────────────────────────────
    fluidRow(
      box(title="✍️ ML Design Practice — Timed Session",
          status="success", solidHeader=TRUE, width=12,
          
          fluidRow(
            column(4,
                   selectInput(ns("design_topic"), "Choose Design Topic:",
                               choices = c(
                                 "News Feed Ranking",
                                 "Reels Recommendation",
                                 "Ads Auction & Ranking",
                                 "Entity Matching (Dedup)",
                                 "Face Tagging System",
                                 "Content Moderation (CV)",
                                 "Meta AI Assistant (LLM/RAG)",
                                 "Llama Fine-tuning Pipeline",
                                 "Instagram Search Ranking",
                                 "Friend Recommendation"
                               )),
                   actionButton(ns("start_design"), "Start Timed Design (45 min)",
                                class="btn-meta", icon=icon("clock"), width="100%"),
                   br(), br(),
                   uiOutput(ns("timer_display")),
                   br(),
                   sliderInput(ns("design_confidence"), "Self-assessed confidence (1-10):",
                               min=1, max=10, value=5),
                   actionButton(ns("save_design"), "Submit Design", class="btn-meta",
                                width="100%")
            ),
            column(8,
                   div(class="practice-area",
                       p(tags$b("Your Design Notes (5 Cs Framework):")),
                       textAreaInput(ns("design_notes"), label=NULL, rows=18,
                                     width="100%",
                                     placeholder=
"## 1. CLARIFY
- Scale: ? DAUs, ? QPS
- Latency: ?
- Success metrics: ?

## 2. CONCEPTUALISE (ML Framing)
- Task type: classification / ranking / generation
- Label: what are we predicting?
- Offline metric: AUC / NDCG / MRR
- Online metric: CTR / DAU / retention

## 3. CREATE (Architecture)
- Features: dense features, sparse embeddings, context
- Model: architecture choice + WHY
- Training: loss function, data, infrastructure

## 4. CALIBRATE (Evaluation)
- Offline eval setup
- A/B test design
- Guardrail metrics

## 5. CRUISE (Serving & Ops)
- Serving architecture: latency, throughput
- Monitoring: data drift, model degradation
- Iteration plan: what's next?"
                       ),
                       uiOutput(ns("design_feedback"))
                   )
            )
          )
      )
    )
  )
}

ml_design_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    
    timer_start <- reactiveVal(NULL)
    timer_active <- reactiveVal(FALSE)
    
    observeEvent(input$start_design, {
      timer_start(Sys.time())
      timer_active(TRUE)
      showNotification("Timer started! 45 minutes — drive the design.", type="message")
    })
    
    output$timer_display <- renderUI({
      invalidateLater(1000)
      if (!timer_active() || is.null(timer_start())) {
        return(div(class="metric-card", span(class="metric-value","45:00"),
                   span(class="metric-label","Ready")))
      }
      elapsed <- as.numeric(difftime(Sys.time(), timer_start(), units="secs"))
      total   <- 45 * 60
      remaining <- max(0, total - elapsed)
      mins <- floor(remaining / 60)
      secs <- floor(remaining %% 60)
      colour <- if(remaining < 300) "#dc2626" else if(remaining < 600) "#d97706" else "#1877F2"
      div(style=paste0("background:",colour,";color:white;border-radius:12px;padding:15px;text-align:center;"),
          span(style="font-size:2em;font-weight:800;display:block;",
               sprintf("%02d:%02d", mins, secs)),
          span(style="font-size:11px;", "Remaining"))
    })
    
    observeEvent(input$save_design, {
      notes <- input$design_notes
      conf  <- input$design_confidence
      
      score <- 0
      if (grepl("CLARIFY|clarify|scale|QPS|latency", notes, ignore.case=TRUE)) score <- score + 20
      if (grepl("metric|AUC|NDCG|CTR|recall", notes, ignore.case=TRUE)) score <- score + 20
      if (grepl("embedding|model|feature|train", notes, ignore.case=TRUE)) score <- score + 20
      if (grepl("A/B|eval|offline|online", notes, ignore.case=TRUE)) score <- score + 20
      if (grepl("serving|latency|monitor|infra", notes, ignore.case=TRUE)) score <- score + 20
      
      prep_manager$add_practice_score("ml_design", score, input$design_topic)
      prep_manager$update_progress("ml_design", min(score + conf * 5, 100))
      timer_active(FALSE)
      
      output$design_feedback <- renderUI({
        div(class = if(score >= 80) "success-box" else "tip-box",
            tags$h5(paste0("Design Score: ", score, "/100 (confidence: ", conf, "/10)")),
            if (score < 20)  tags$p("⚠️ Missing: problem clarification (scale, latency, metrics)"),
            if (score < 40)  tags$p("⚠️ Missing: ML problem framing and metric definition"),
            if (score < 60)  tags$p("⚠️ Missing: model architecture and feature engineering"),
            if (score < 80)  tags$p("⚠️ Missing: evaluation strategy and A/B test design"),
            if (score < 100) tags$p("⚠️ Missing: serving infrastructure and monitoring"),
            if (score >= 80) tags$p("✅ All 5 Cs covered! Excellent design structure."))
      })
    })
  })
}
