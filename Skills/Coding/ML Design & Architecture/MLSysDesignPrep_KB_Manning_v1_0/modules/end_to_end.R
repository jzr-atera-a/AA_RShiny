# modules/end_to_end.R
# Tab 9: End-to-End Case Studies — Ch. 9 (Recommendation) & Ch. 10 (Search/NLP)

end_to_end_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("End-to-End Case Studies"),
        tags$h2("Chapters 9 & 10 — Full Production Systems: Recommendation, Search, NLP & RAG"),
        div(span(class="hero-badge","Two-Tower"), span(class="hero-badge","LTR"),
            span(class="hero-badge","Entity Resolution"), span(class="hero-badge","RAG"),
            span(class="hero-badge","Cold Start"))
    ),

    tabsetPanel(
      # ── Ch.9: Recommendation System ─────────────────────
      tabPanel("📱 Ch.9 — Recommendation System",
        br(),
        fluidRow(
          box(title="🏗️ Full Recommendation System Design (Ch. 9)", status="primary", solidHeader=TRUE, width=6,
              div(class="practice-area",
                  tags$b("K&B Case Study:"), " 'Design a production content recommendation system for a social platform with 200M daily active users and 50M content items.'"),
              br(),
              div(class="section-heading-dark","Step 1: Requirements (K&B Framework)"),
              div(class="framework-card",
                  tags$h5("Functional"),
                  tags$p("Recommend N content items per user at each session. Personalised by user history, context (time, device), and content signals. Support both new users (cold start) and established users."),
                  tags$p(tags$b("Label:"), " P(positive engagement | user, item, context). Engagement defined as: watch > 30 sec, like, share, comment. NOT click — too noisy.")),
              div(class="framework-card",
                  tags$h5("Non-Functional SLOs"),
                  tags$p(tags$b("Latency:"), " p99 < 150ms for feed generation"),
                  tags$p(tags$b("Freshness:"), " new content eligible within 15 min of publish"),
                  tags$p(tags$b("Cold start:"), " new user gets meaningful recs within first session"),
                  tags$p(tags$b("Diversity:"), " gini coefficient of recommended content type > 0.4")),
              br(),
              div(class="section-heading-dark","Step 2: The Two-Stage Funnel — K&B Pattern"),
              div(class="funnel-stage",
                  div(class="funnel-num","1"),
                  div(div(class="funnel-title","Candidate Generation (Two-Tower ANN Retrieval)"),
                      div(class="funnel-desc","User tower + item tower → embeddings. ANN (FAISS/ScaNN). Recall-optimised.")),
                  div(class="funnel-count","50M → 1,000")),
              div(class="funnel-stage",
                  div(class="funnel-num","2"),
                  div(div(class="funnel-title","Multi-Stage Ranking (Wide & Deep / DLRM)"),
                      div(class="funnel-desc","Cross features, real-time context, multi-task predictions (click + watch + share).")),
                  div(class="funnel-count","1,000 → 100")),
              div(class="funnel-stage",
                  div(class="funnel-num","3"),
                  div(div(class="funnel-title","Re-ranking & Policy Layer"),
                      div(class="funnel-desc","Diversity enforcement (MMR). Freshness boost. Content policy filters. A/B experiment assignments.")),
                  div(class="funnel-count","100 → 20")),
              div(class="funnel-stage",
                  div(class="funnel-num","4"),
                  div(div(class="funnel-title","Serving via Feature Store"),
                      div(class="funnel-desc","User embedding (batch, Redis). Item metadata (batch, Redis). Real-time events (Kafka → Flink → Redis).")),
                  div(class="funnel-count","< 150ms total"))
          ),

          box(title="🧊 Cold Start & Advanced Topics (Ch. 9)", status="info", solidHeader=TRUE, width=6,
              div(class="section-heading-dark","Cold Start — K&B's Full Treatment"),
              div(class="framework-card",
                  tags$h5("New User Cold Start"),
                  tags$p(tags$b("Non-personalised baseline:"), " Popularity-based recs. Trending content. Not embarrassing to ship."),
                  tags$p(tags$b("Onboarding signals:"), " Explicit interest selection during signup → populate user embedding with item embeddings from selected topics."),
                  tags$p(tags$b("Session-based model:"), " Recurrent or Transformer model over in-session clicks. No historical data needed — uses only current session."),
                  tags$p(tags$b("Transfer learning:"), " Initialise new user embedding from similar users (kNN in content-signal space).")),
              div(class="framework-card",
                  tags$h5("New Item Cold Start"),
                  tags$p(tags$b("Content-based:"), " Embed item from text/image features (without engagement history). Use CLIP/BERT to compute item embedding at publish time."),
                  tags$p(tags$b("Exploration bonus:"), " Boost new items' ranking score by +ε to get initial impressions."),
                  tags$p(tags$b("Contextual bandit:"), " Treat new item as an arm to explore. UCB or Thompson sampling for exploitation/exploration balance.")),
              br(),
              div(class="section-heading-dark","K&B's Multi-Task Training Design"),
              div(class="framework-card",
                  tags$h5("Separate Models per Objective (K&B Recommendation)"),
                  tags$p("Train separate models for: click prediction, watch-time prediction, share/comment prediction. Combine scores at serving time with learned or business-tuned weights."),
                  tags$p(tags$b("Why not one model?"), " Different objectives have different data requirements, feedback delays, and label noise. Separate models allow independent iteration.")),
              div(class="tip-box",
                  HTML("<strong>💡 K&B key insight (Ch.9):</strong> The retrieval stage is often the bottleneck for recommendation quality. A ranking model can only rank what the retrieval stage passes up. Invest heavily in retrieval recall@K before optimising the ranker."))
          )
        )
      ),

      # ── Ch.10: Search & NLP ──────────────────────────────
      tabPanel("🔍 Ch.10 — Search Ranking & NLP",
        br(),
        fluidRow(
          box(title="🔍 Search Ranking System (Ch. 10)", status="primary", solidHeader=TRUE, width=6,
              div(class="practice-area",
                  tags$b("K&B Case Study:"), " 'Design a search ranking system for a large e-commerce platform with 50M products and 10M daily search queries.'"),
              br(),
              div(class="section-heading-dark","Query Understanding Pipeline"),
              div(class="framework-card",
                  tags$h5("Step 1: Query Classification"),
                  tags$p(tags$b("Intent:"), " navigational (find specific product), transactional (buy), informational (explore)."),
                  tags$p(tags$b("Query type:"), " head (high-frequency, well-understood), torso, long-tail (rare, context-dependent)."),
                  tags$p("Head queries get the most training signal but long-tail is where most search failures occur. K&B recommend dedicated models per query tier.")),
              div(class="framework-card",
                  tags$h5("Step 2: Query Expansion"),
                  tags$p("Spell correction. Synonym expansion (jacket → coat). Category extraction. Attribute extraction ('red running shoes' → color: red, type: running shoes, category: footwear).")),
              div(class="section-heading-dark","Learning to Rank (LTR) — K&B's Full Framework"),
              div(class="framework-card",
                  tags$h5("Three LTR Paradigms"),
                  tags$p(tags$b("Pointwise:"), " Predict absolute relevance score. Train binary/regression model independently per query-doc pair. Simple but ignores list context."),
                  tags$p(tags$b("Pairwise (RankSVM, RankBoost):"), " Prefer doc A over doc B for query Q. Uses relative preference. Better than pointwise."),
                  tags$p(tags$b("Listwise (LambdaRank/LambdaMART):"), " Directly optimise NDCG on the full list. Best quality. Industry standard at Google, Bing, Amazon. K&B recommendation.")),
              div(class="warn-box",
                  HTML("<strong>⚠️ Position Bias — K&B's #1 LTR warning:</strong> Training on raw clicks creates a self-reinforcing loop. Top-ranked items get more clicks regardless of quality. Fix with IPS (Inverse Propensity Scoring) or position-aware training (include position as a feature during training, zero it at inference)."))
          ),

          box(title="🤖 RAG Systems & LLM Features (Ch. 10)", status="info", solidHeader=TRUE, width=6,
              div(class="section-heading-dark","Retrieval-Augmented Generation (RAG) — K&B Architecture"),
              div(class="funnel-stage",
                  div(class="funnel-num","1"),
                  div(div(class="funnel-title","Query Encoding"),
                      div(class="funnel-desc","Embed user query via bi-encoder (SBERT/E5). Optional: query expansion, intent detection.")),
                  div(class="funnel-count","Query → Vector")),
              div(class="funnel-stage",
                  div(class="funnel-num","2"),
                  div(div(class="funnel-title","Dense Retrieval (ANN)"),
                      div(class="funnel-desc","FAISS/Weaviate/Pinecone. Chunk documents at index time. Retrieve top-K by cosine similarity.")),
                  div(class="funnel-count","N docs → K chunks")),
              div(class="funnel-stage",
                  div(class="funnel-num","3"),
                  div(div(class="funnel-title","Cross-Encoder Re-ranking"),
                      div(class="funnel-desc","Expensive but accurate. Re-rank top-K using query + document jointly (not bi-encoder).")),
                  div(class="funnel-count","K → top-5")),
              div(class="funnel-stage",
                  div(class="funnel-num","4"),
                  div(div(class="funnel-title","LLM Generation with Context"),
                      div(class="funnel-desc","Top-5 chunks in context window. Chain-of-thought. Citation tracking.")),
                  div(class="funnel-count","Answer + citations")),
              br(),
              div(class="framework-card",
                  tags$h5("RAG Failure Modes — K&B's Analysis"),
                  tags$ul(
                    tags$li(tags$b("Retrieval failure:"), " relevant chunk not retrieved. Improve chunk size, embedding model, or hybrid search (BM25 + dense)."),
                    tags$li(tags$b("Context window overflow:"), " too many chunks, most get ignored. Use re-ranking to select top-5 only."),
                    tags$li(tags$b("Hallucination despite context:"), " LLM ignores retrieved docs. Use faithfulness check (NLI model: is answer entailed by context?)."),
                    tags$li(tags$b("Stale knowledge base:"), " documents not updated. Implement incremental indexing triggered by content updates.")
                  )),
              div(class="framework-card",
                  tags$h5("Hybrid Search — BM25 + Dense (K&B Recommended)"),
                  tags$p("BM25 excels at: exact keyword match, rare terms, product SKUs, technical jargon."),
                  tags$p("Dense retrieval excels at: semantic similarity, paraphrases, conceptual queries."),
                  tags$p(tags$b("Reciprocal Rank Fusion (RRF):"), " Merge BM25 + dense rankings without score normalisation. Robust and parameter-free.")),
              div(class="tip-box",
                  HTML("<strong>💡 K&B interview move:</strong> 'For RAG retrieval quality, I'd start with hybrid search (BM25 + dense embeddings combined via RRF) before investing in more complex re-ranking, as this often recovers 80% of the quality gap at 10% of the cost.'"))
          )
        ),
        fluidRow(
          box(title="🔗 Entity Resolution — Ch. 10 K&B Case Study", status="warning", solidHeader=TRUE, width=12,
              fluidRow(
                column(4,
                       div(class="section-heading-dark","Problem Definition"),
                       div(class="framework-card",
                           tags$h5("What is Entity Resolution?"),
                           tags$p("Determine whether two records refer to the same real-world entity. E.g., 'Apple iPhone 14 Pro 256GB Silver' and 'iPhone 14 Pro - 256 GB, Silver' → same product?"),
                           tags$p(tags$b("Also called:"), " deduplication, record linkage, fuzzy matching, entity matching."),
                           tags$p(tags$b("K&B use case:"), " Product catalogue deduplication, customer identity resolution, knowledge graph construction."))),
                column(4,
                       div(class="section-heading-dark","Two-Stage Architecture"),
                       div(class="framework-card",
                           tags$h5("Stage 1: Blocking (Candidate Generation)"),
                           tags$p("Reduce O(N²) comparison problem to manageable candidate pairs. Use blocking keys: first 3 chars of product name, brand + category + approximate price range."),
                           tags$p(tags$b("LSH (Locality Sensitive Hashing):"), " Hash similar items to same bucket. Sub-linear candidate generation.")),
                       div(class="framework-card",
                           tags$h5("Stage 2: Matching (Classification)"),
                           tags$p("Binary classifier: 'do these two records refer to the same entity?' Features: Jaccard similarity of title tokens, brand exact match, image embedding cosine similarity."),
                           tags$p(tags$b("Fine-tuned BERT (Ditto):"), " State-of-art for text entity matching. Serialise both records as text, predict [MATCH/NO_MATCH]."))),
                column(4,
                       div(class="section-heading-dark","K&B's Key Insights"),
                       div(class="framework-card",
                           tags$h5("Evaluation"),
                           tags$p("Pair-level precision/recall is misleading — care about cluster quality (all mentions of same entity in one cluster)."),
                           tags$p(tags$b("Cluster-level metrics:"), " B-cubed, MUC (Mention-based Update Criteria), CEAFm.")),
                       div(class="warn-box",
                           HTML("<strong>⚠️ Blocking recall:</strong> If the blocking step misses a pair, no classifier can recover it. Monitor blocking recall separately from matching precision/recall. K&B recommend targeting ≥ 95% blocking recall.")))
              )
          )
        )
      )
    )
  )
}

end_to_end_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("end_to_end", 50)
  })
}
