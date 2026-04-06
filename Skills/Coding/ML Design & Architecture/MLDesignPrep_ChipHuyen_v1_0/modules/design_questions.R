# modules/design_questions.R
# Tab 9: Classic ML Design Questions with full Huyen-framework solutions

design_questions_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Classic ML Design Questions"),
        tags$h2("Deep-Dive Solutions Using Chip Huyen's Production-First Framework"),
        div(
          span(class = "hero-badge", "Recommendation"),
          span(class = "hero-badge", "Search Ranking"),
          span(class = "hero-badge", "Fraud Detection"),
          span(class = "hero-badge", "LLM Systems")
        )
    ),

    tabsetPanel(

      # ── Recommendation System ────────────────────────
      tabPanel("📱 Recommendation System",
        br(),
        fluidRow(
          box(title = "🎯 Design a Recommendation System", status = "primary",
              solidHeader = TRUE, width = 6,

              div(class = "practice-area",
                  tags$b("Question:"), " 'Design a video recommendation system for a streaming platform with 100M users and 10M videos.'"),
              br(),
              div(class = "section-heading-dark", "Step 1: Clarify"),
              tags$ul(
                tags$li("Homepage recs or in-session watch-next?"),
                tags$li("Latency budget: <200ms for homepage?"),
                tags$li("Cold start: new users, new videos?"),
                tags$li("Explicit (ratings) or implicit (watch time) feedback?"),
                tags$li("Multi-objective: engagement + retention + diversity?")
              ),
              div(class = "section-heading-dark", "Step 2: ML Framing"),
              div(class = "framework-card",
                  tags$h5("Label: Watch-through rate"),
                  tags$p("P(user watches >50% of video | user, video, context). Richer than click — captures satisfaction not just curiosity. Secondary task: explicit like/share.")),
              div(class = "framework-card",
                  tags$h5("Offline Metric: NDCG@K"),
                  tags$p("K = 10 for homepage carousel. Also: recall@K for retrieval stage, AUC-ROC for engagement prediction.")),
              div(class = "framework-card",
                  tags$h5("Online Metric: L7 watch time per user"),
                  tags$p("7-day rolling watch time. Guardrails: DAU retention, user report rate, content diversity index (prevent filter bubble)."))
          ),

          box(title = "🏗️ Architecture: Two-Stage Funnel", status = "info",
              solidHeader = TRUE, width = 6,

              div(class = "section-heading-dark", "Candidate Retrieval → Ranking Funnel"),
              div(class = "funnel-stage",
                  div(class = "funnel-num", "1"),
                  div(div(class = "funnel-title", "Two-Tower Embedding Retrieval"),
                      div(class = "funnel-desc", "User + video embeddings. ANN search via FAISS. Recall-optimised.")),
                  div(class = "funnel-count", "10M → 1K")),
              div(class = "funnel-stage",
                  div(class = "funnel-num", "2"),
                  div(div(class = "funnel-title", "Collaborative Filtering"),
                      div(class = "funnel-desc", "Matrix factorisation (ALS). Item-item similarity. Complements two-tower.")),
                  div(class = "funnel-count", "10M → 1K")),
              div(class = "funnel-stage",
                  div(class = "funnel-num", "3"),
                  div(div(class = "funnel-title", "Ranking Model (Wide & Deep / DLRM)"),
                      div(class = "funnel-desc", "Dense + sparse features. Multi-task: watch-through + like + share.")),
                  div(class = "funnel-count", "2K → 50")),
              div(class = "funnel-stage",
                  div(class = "funnel-num", "4"),
                  div(div(class = "funnel-title", "Re-ranking & Diversity"),
                      div(class = "funnel-desc", "MMR for diversity. Business rules. Freshness boost. Inject new content.")),
                  div(class = "funnel-count", "50 → 10")),
              br(),
              div(class = "tip-box",
                  HTML("<strong>💡 Huyen angle:</strong> 'Feature store is critical here — user embeddings and video statistics must be consistent between training and serving. Online store (Redis) for real-time features + offline store (Parquet) for training.'"))
          )
        )
      ),

      # ── Search Ranking ───────────────────────────────
      tabPanel("🔍 Search Ranking",
        br(),
        fluidRow(
          box(title = "🔍 Design a Search Ranking System", status = "primary",
              solidHeader = TRUE, width = 6,

              div(class = "practice-area",
                  tags$b("Question:"), " 'Design a product search ranking system for an e-commerce platform.'"),
              br(),
              div(class = "framework-card",
                  tags$h5("Task Type: Learning to Rank"),
                  tags$p(tags$b("Pointwise:"), " Predict relevance score independently per document."),
                  tags$p(tags$b("Pairwise:"), " Prefer A over B. RankSVM, RankBoost."),
                  tags$p(tags$b("Listwise (preferred):"), " Directly optimise list quality — NDCG. LambdaRank, LambdaMART. Production standard.")),
              div(class = "framework-card",
                  tags$h5("Key Features"),
                  tags$ul(
                    tags$li("Query features: embedding, type (navigational/transactional/informational)"),
                    tags$li("Document features: title match, description, category, ratings, inventory"),
                    tags$li("Query-doc interaction: BM25, dense retrieval cosine similarity"),
                    tags$li("Personalisation: user purchase history, viewed items, price sensitivity"),
                    tags$li("Business: sponsored status, margin, inventory level")
                  ))
          ),

          box(title = "⚠️ Position Bias — Critical Trap (Ch. 5)", status = "danger",
              solidHeader = TRUE, width = 6,

              div(class = "warn-box",
                  HTML("<strong>⚠️ Huyen's top warning:</strong> Training on click data without correcting for position bias creates a self-reinforcing loop — top-ranked items get more clicks regardless of quality.")),

              div(class = "framework-card",
                  tags$h5("The Problem"),
                  tags$p("Users click position 1 more than position 5, independent of relevance. If you train on raw clicks, your model learns historical position, not true quality.")),
              div(class = "framework-card",
                  tags$h5("Inverse Propensity Scoring (IPS)"),
                  tags$p("Weight each example by 1/P(click | position). Items at position 1 are down-weighted (high propensity regardless). Items at position 10 are up-weighted (rare clicks are more informative).")),
              div(class = "framework-card",
                  tags$h5("Position-Aware Architecture"),
                  tags$p("Include position as a feature during TRAINING but zero it out at INFERENCE. Model learns to separate positional effects from true relevance. Standard practice at Google, Meta, Amazon.")),
              div(class = "tip-box",
                  HTML("<strong>💡 Top signal:</strong> Proactively mentioning position bias and IPS correction is a strong Staff-level signal. Most candidates miss this entirely."))
          )
        )
      ),

      # ── Fraud Detection ──────────────────────────────
      tabPanel("🛡️ Fraud Detection",
        br(),
        fluidRow(
          box(title = "🛡️ Design a Real-Time Fraud Detection System", status = "danger",
              solidHeader = TRUE, width = 6,

              div(class = "practice-area",
                  tags$b("Question:"), " 'Design a real-time fraud detection system for a payments platform processing 10K transactions/second.'"),
              br(),
              div(class = "section-heading-dark", "Key Challenges (Unique to Fraud)"),
              div(class = "framework-card",
                  tags$h5("Severe Class Imbalance"),
                  tags$p("Fraud rate typically <0.1% of transactions. Class ratio 1:10,000. Accuracy is meaningless. Use: Precision, Recall, F-beta (β>1 to weight recall), AUC-PR.")),
              div(class = "framework-card",
                  tags$h5("Concept Drift from Adversaries"),
                  tags$p("Fraudsters adapt. Distribution of fraud patterns changes faster than legitimate transactions. Models degrade quickly — require frequent retraining (daily or near-real-time).")),
              div(class = "framework-card",
                  tags$h5("Delayed Labels"),
                  tags$p("Chargebacks arrive 30–90 days after transaction. Training today means using labels from 3 months ago. Consider: proxy labels (velocity rules), weak supervision, semi-supervised learning."))
          ),

          box(title = "🏗️ Layered Defense Architecture", status = "warning",
              solidHeader = TRUE, width = 6,

              div(class = "funnel-stage",
                  div(class = "funnel-num", "1"),
                  div(div(class = "funnel-title", "Rule Engine (<1ms, Synchronous)"),
                      div(class = "funnel-desc", "Velocity checks, blocklist, impossible travel, amount thresholds. High precision.")),
                  div(class = "funnel-count", "~40% fraud blocked")),
              div(class = "funnel-stage",
                  div(class = "funnel-num", "2"),
                  div(div(class = "funnel-title", "ML Scoring (<50ms, Synchronous)"),
                      div(class = "funnel-desc", "Gradient boosted trees on real-time + historical features. Risk score [0,1].")),
                  div(class = "funnel-count", "~80% total")),
              div(class = "funnel-stage",
                  div(class = "funnel-num", "3"),
                  div(div(class = "funnel-title", "Graph-Based Analysis (Async)"),
                      div(class = "funnel-desc", "Device/IP/card sharing graph. GNN to detect fraud rings. Used for post-hoc review.")),
                  div(class = "funnel-count", "Catches rings")),
              div(class = "funnel-stage",
                  div(class = "funnel-num", "4"),
                  div(div(class = "funnel-title", "Human Review Queue"),
                      div(class = "funnel-desc", "High-risk flagged cases. Active learning: reviewed cases → new training data.")),
                  div(class = "funnel-count", "Top ~1% risky")),
              br(),
              div(class = "tip-box",
                  HTML("<strong>💡 Key signal:</strong> Show you understand the FP vs FN trade-off is a BUSINESS decision. A false positive blocks a legitimate customer (revenue loss + churn). A false negative is the fraud loss. Make the PM/Finance own that threshold."))
          )
        )
      ),

      # ── LLM Systems ──────────────────────────────────
      tabPanel("🤖 LLM Systems",
        br(),
        fluidRow(
          box(title = "🤖 Design an LLM-Powered Feature", status = "info",
              solidHeader = TRUE, width = 6,

              div(class = "practice-area",
                  tags$b("Question:"), " 'Design an LLM-based customer support system.'"),
              br(),
              div(class = "framework-card",
                  tags$h5("RAG vs Fine-tuning Decision"),
                  tags$p(tags$b("Use RAG when:"), " Knowledge changes frequently, traceability to sources required, limited training data available."),
                  tags$p(tags$b("Use Fine-tuning when:"), " Specific response style/format needed, domain terminology highly specialised, high-volume low-latency required.")),
              div(class = "framework-card",
                  tags$h5("RAG Pipeline"),
                  tags$p("1. Query → dense retrieval (bi-encoder + FAISS ANN). 2. Top-k docs → context window. 3. LLM generates response conditioned on retrieved docs. Key challenge: retrieval quality directly caps answer quality.")),
              div(class = "framework-card",
                  tags$h5("LLM Evaluation (Huyen Ch. 12)"),
                  tags$p(tags$b("BLEU/ROUGE:"), " Weak proxy for open-ended generation."),
                  tags$p(tags$b("LLM-as-judge:"), " GPT-4 evaluates responses vs. reference. Scalable."),
                  tags$p(tags$b("Task-specific:"), " Resolution rate, escalation rate, CSAT."),
                  tags$p(tags$b("Human eval:"), " Gold standard — expensive but necessary for calibration."))
          ),

          box(title = "⚡ LLM Serving Infrastructure", status = "primary",
              solidHeader = TRUE, width = 6,

              div(class = "framework-card",
                  tags$h5("Throughput Optimisation"),
                  tags$p(tags$b("Continuous batching:"), " Batch requests of different lengths together."),
                  tags$p(tags$b("PagedAttention (vLLM):"), " Manage KV cache like OS virtual memory. 30× throughput improvement over naive serving."),
                  tags$p(tags$b("Speculative decoding:"), " Small draft model + large verifier. 2–5× latency reduction.")),
              div(class = "framework-card",
                  tags$h5("LoRA Fine-tuning at Scale"),
                  tags$p("Decompose weight update ΔW = BA where B, A are low-rank matrices. Only 0.1–1% parameters trained. 3× less GPU memory."),
                  tags$p(tags$b("Multi-LoRA serving:"), " Share base model weights, swap adapters per request/tenant. Cost-effective for multiple verticals.")),
              div(class = "framework-card",
                  tags$h5("Safety & Guardrails Layer"),
                  tags$p("Input filtering: PII detection, jailbreak detection, prompt injection detection."),
                  tags$p("Output filtering: hallucination detection (NLI model), toxicity classifier, factual grounding check via RAG citations.")),
              div(class = "framework-card",
                  tags$h5("Cost Management"),
                  tags$p(tags$b("Semantic caching:"), " Cache responses to semantically similar queries (20–40% cost reduction)."),
                  tags$p(tags$b("Model routing:"), " Route simple queries to small/cheap model, complex to large."),
                  tags$p(tags$b("Quantisation:"), " INT8/INT4 for 2–4× cost reduction at serving time."))
          )
        )
      )
    )
  )
}

design_questions_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("design_questions", 50)
  })
}
