# modules/ml_design_profile.R
# Profile Tab 4: Your ML Systems → Meta Design Interview
# Maps Atera / Santander / Rio Tinto systems to Meta ML design question formats

ml_design_profile_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Your ML Systems → Meta Design Answers"),
        tags$h2("Translating Your Built Systems into Meta ML Design Interview Responses"),
        div(
          span(class = "hero-badge", "Sensor Fusion → Meta Quest"),
          span(class = "hero-badge", "SLAM → Spatial AI"),
          span(class = "hero-badge", "30M Users → Meta Scale"),
          span(class = "hero-badge", "On-Device → Edge ML")
        )
    ),

    # ── System Inventory ─────────────────────────────
    fluidRow(
      box(title = "🗄️ Your Built ML Systems — Pre-Mapped to Meta Design Questions",
          status = "primary", solidHeader = TRUE, width = 12,

          fluidRow(
            column(4, div(class = "framework-card",
                          tags$h5("🏭 Atera: Real-Time Egocentric AR Pipeline"),
                          tags$p(tags$b("What you built:"), " Multi-modal sensor fusion (camera + LiDAR + IMU) → 3D reconstruction → semantic overlay → on-device AR at <10ms."),
                          tags$p(tags$b("Maps to Meta question:"), " 'Design Project Aria's scene understanding pipeline' or 'Design a real-time object detection system for AR glasses'"),
                          tags$p(tags$b("Your advantage:"), " You have SHIPPED this. Not designed it on a whiteboard — shipped it on Meta Quest devices."),
                          div(class = "success-box", HTML("<strong>Score:</strong> 95/100 fit to Meta Reality Labs CV/AR questions")))),
            column(4, div(class = "framework-card",
                          tags$h5("🏦 Santander: 30M-Customer Behavioural ML"),
                          tags$p(tags$b("What you built:"), " End-to-end DL pipeline, real-time behavioural signals, PyTorch distributed inference, Oxford research integration, £20M impact."),
                          tags$p(tags$b("Maps to Meta question:"), " 'Design a user behavioural ranking system' or 'Design a real-time personalisation system at 3B user scale'"),
                          tags$p(tags$b("Your advantage:"), " Real scale (30M) + research-to-production + PyTorch = credible Meta-scale narrative."),
                          div(class = "success-box", HTML("<strong>Score:</strong> 82/100 fit to Meta Feed/Personalisation questions")))),
            column(4, div(class = "framework-card",
                          tags$h5("🔬 Rio Tinto: Autonomous Systems + Classification"),
                          tags$p(tags$b("What you built:"), " Minerals classification CV system, operations forecasting ML, autonomous vehicle systems, published research."),
                          tags$p(tags$b("Maps to Meta question:"), " 'Design a content classification system' or 'Design an entity matching system for taxonomy'"),
                          tags$p(tags$b("Your advantage:"), " Published research = technical depth credibility. Autonomous systems = pioneering ML at scale."),
                          div(class = "success-box", HTML("<strong>Score:</strong> 75/100 fit to Meta Content Moderation / Entity Matching questions"))))
          )
      )
    ),

    # ── Deep Dive by Question Type ───────────────────
    fluidRow(
      box(title = "🔬 Your Answers to Meta's Most Likely ML Design Questions",
          status = "info", solidHeader = TRUE, width = 12,

          tabsetPanel(
            # ── Computer Vision / AR ─────────────────
            tabPanel("CV / AR / Egocentric (Your Strongest)",
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "section-heading-dark",
                                  "Question: 'Design a Real-Time Scene Understanding System for AR Glasses'"),
                              div(class = "practice-area",
                                  p(tags$b("Your opening (use this verbatim):"), br(),
                                    tags$i("'I've actually built and deployed this system — let me walk you through the architecture we used at Atera for egocentric AR on Meta Quest devices, and then we can discuss how I'd scale it to Meta's full user base.'"))),
                              br(),
                              div(class = "framework-card",
                                  tags$h5("Your Architecture Narrative (5 Cs)"),
                                  tags$p(tags$b("CLARIFY:"), " Sub-10ms end-to-end latency SLO (safety-critical for AR). Multi-modal input: RGB camera array, depth sensor, IMU. Output: semantic 3D scene mesh with object labels and pose."),
                                  tags$p(tags$b("CONCEPTUALISE:"), " Frame as: (1) Depth estimation, (2) SLAM/localisation, (3) Semantic segmentation, (4) Object detection + 6-DOF pose, (5) Scene graph construction. Offline metrics: IoU, ATE (Absolute Trajectory Error), pose estimation error. Online: latency p50/p99, user comfort score."),
                                  tags$p(tags$b("CREATE:"), " Sensor Fusion: EKF/UKF for IMU + visual odometry. Depth: stereo matching or learned monocular (UniDepth). Segmentation: lightweight MobileNet-based or EfficientDet on-device. 3D reconstruction: volumetric (TSDF) or learned (NeRF/Gaussian Splatting for static scenes). Pose graph optimisation with loop closure."),
                                  tags$p(tags$b("CALIBRATE:"), " Offline: ATE on EuRoC/TUM-VI benchmarks. Online: A/B test on user session length, head-turn stability, spatial anchor accuracy."),
                                  tags$p(tags$b("CRUISE:"), " On-device inference: quantised INT8 models, neural architecture search for latency. Cloud fallback for heavy reconstruction. Incremental map updates to avoid full recomputation."))
                       ),
                       column(6,
                              div(class = "section-heading-dark", "Depth Questions They Will Ask"),
                              div(class = "framework-card",
                                  tags$h5("Q: 'How do you handle rapid head motion / motion blur?'"),
                                  tags$p(tags$b("Your answer from Atera:"), " 'We used IMU pre-integration at 200Hz to bridge visual frames, combined with a velocity-aware feature tracking algorithm that adjusts FAST corner detection thresholds based on predicted optical flow magnitude. We measured this was the dominant source of tracking loss in our first prototype.'"),
                                  div(class = "tip-box", HTML("💡 Specificity beats generality. If you can name the Hz, the algorithm, and the measurement — you own this answer."))),
                              div(class = "framework-card",
                                  tags$h5("Q: 'How would you scale this to 1 billion AR users?'"),
                                  tags$p("This is a scale bridging question. Key points: (1) On-device model compression — knowledge distillation, quantisation. (2) Federated learning for scene map updates (privacy-preserving). (3) Shared world model: Meta's Live Maps — crowd-sourced spatial anchors. (4) Tiered serving: simple scenes on-device, complex reconstruction in cloud."),
                                  div(class = "success-box", HTML("✅ Reference Meta's actual projects: Project Aria, Live Maps, CoHere spatial computing — shows you know the product roadmap."))),
                              br(),
                              div(class = "section-heading-dark", "Practice Your Design (Timed 45 min)"),
                              textAreaInput(ns("cv_design"), label = NULL, rows = 10,
                                            width = "100%",
                                            placeholder = "Write your full 5-Cs design for the AR scene understanding question...\n\nFocus on: what you ACTUALLY built at Atera, then extrapolate to Meta scale.\nBe specific: name the sensor, the Hz, the algorithm, the latency measurement."),
                              actionButton(ns("save_cv_design"), "Save Design", class = "btn-meta")
                       )
                     )
            ),

            # ── Recommender / Ranking ─────────────────
            tabPanel("Ranking / Feed (Gap Area)",
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "warn-box",
                                  HTML("<strong>⚠️ Preparation priority:</strong> Your CV is CV-heavy. If Meta asks a Feed Ranking or Reels Recommendation question, you need a credible answer. Use your Santander behavioural ML as the bridge.")),
                              br(),
                              div(class = "section-heading-dark", "Bridging Santander → Meta Feed"),
                              div(class = "framework-card",
                                  tags$h5("What transfers from your Santander work"),
                                  tags$ul(
                                    tags$li(tags$b("Real-time behavioural signals:"), " Santander processed real-time signals from 30M customers → Meta processes signals from 3B users. Same architecture, 100× scale."),
                                    tags$li(tags$b("Multi-task learning:"), " Payments + lending + mortgage models simultaneously = multi-task ranking (likes + shares + dwell time)."),
                                    tags$li(tags$b("PyTorch distributed:"), " You've run distributed PyTorch training — directly applicable to DLRM/two-tower training at Meta scale."),
                                    tags$li(tags$b("Oxford research integration:"), " You translated Financial Mathematics research into production — same skill for translating FAIR Research into production ranking systems.")
                                  )),
                              div(class = "framework-card",
                                  tags$h5("Opening bridge statement"),
                                  div(class = "practice-area",
                                      tags$i("'While I haven't built a news feed ranking system specifically, I've designed and deployed real-time ML inference for 30 million users' behavioural signals at Santander — processing payments, lending, and investment signals simultaneously in PyTorch on distributed cloud. The architectural patterns are directly analogous: candidate generation, feature engineering over user history, multi-task scoring, and real-time serving under latency constraints. Let me walk you through how I'd apply that experience to the feed ranking problem...'"))
                               )
                       ),
                       column(6,
                              div(class = "section-heading-dark", "Your Feed Ranking Architecture"),
                              textAreaInput(ns("feed_design"), label = NULL, rows = 16,
                                            width = "100%",
                                            value =
"## Candidate Generation (Two-Tower)
User tower: user_id embedding + behavioural history (from Santander-like
  pipeline — sessions, interactions, dwell time) → 128-d embedding
Item tower: post_id + author + modality (video/image/text) → 128-d embedding
Training: contrastive loss with in-batch negatives
Serving: FAISS ANN index → top-1000 candidates at <10ms

## Ranking (DLRM-style)
Dense features: user activity stats, item freshness, social graph signals
Sparse: categorical embeddings (user_id, author_id, topic_id)
Architecture: dense MLP → bottom MLP + embedding dot products → top MLP
Loss: multi-task: P(like), P(share), P(click), P(30s_view)
Why DLRM: Meta open-source, proven at this scale, efficient sparse lookups

## Evaluation
Offline: AUC per task, NDCG@10
Online: A/B test on L7 retention, sessions/DAU, time-spent with guardrails

## Serving (from my distributed inference experience at Santander)
Real-time feature serving: feature store (Redis-like) for user features
Model serving: TorchServe, batch inference with dynamic batching
Latency SLO: <100ms p99 (from feed request to ranked response)
Monitoring: drift detection on feature distributions, model shadow mode"
                              ),
                              actionButton(ns("save_feed"), "Save Design", class = "btn-meta")
                       )
                     )
            ),

            # ── Entity Matching / Content Mod ─────────
            tabPanel("Entity Matching / Content Moderation",
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "section-heading-dark",
                                  "Question: 'Design a Content Moderation CV System'"),
                              div(class = "success-box",
                                  HTML("<strong>✅ This is a near-perfect question for you.</strong> Your BCG work ('AI and computer vision solutions for Health and Bio-Chemical clients — combining image processing, ML classification') + your Atera semantic scene understanding work = you have direct experience with visual classification pipelines at production quality.")),
                              br(),
                              div(class = "framework-card",
                                  tags$h5("Your Architecture (grounded in real experience)"),
                                  tags$p(tags$b("Detection stage:"), " Visual backbone (ResNet-50 or ViT-B) pre-trained on large image corpus. Fine-tuned on labelled policy violations. Multi-label: nudity, violence, graphic content, spam, misinformation visuals."),
                                  tags$p(tags$b("From your BCG experience:"), " 'When I built CV classification systems for Health clients at BCG, we found that domain-specific fine-tuning on ~10K labelled examples from the target domain outperformed general models trained on millions of general images. I'd apply the same principle here — source violation-type-specific fine-tuning data.'"),
                                  tags$p(tags$b("From your Atera experience:"), " 'In our semantic scene understanding pipeline, we used a two-stage detector with a lightweight backbone for real-time candidate detection and a heavier model for classification — this reduced compute by 4× while preserving accuracy. I'd apply the same cascade approach for content moderation.'")),
                              div(class = "framework-card",
                                  tags$h5("Active Learning — Your Differentiator"),
                                  tags$p("Show you understand the label cost problem: 'Content moderation requires continuous labelling of new violation types. I'd implement an active learning loop — uncertainty sampling to surface hard cases for human reviewers, reducing labelling cost by 60-70% compared to random sampling. I used a similar approach at Rio Tinto for minerals classification where labelled geological samples were expensive to obtain.'"))
                       ),
                       column(6,
                              div(class = "section-heading-dark", "Write Your Design"),
                              textAreaInput(ns("content_mod_design"), label = NULL, rows = 16,
                                            width = "100%",
                                            placeholder = "Design a content moderation CV system using your actual experience:\n\n1. CLARIFY: scale, modality (image/video), latency, appeal process?\n2. CONCEPTUALISE: multi-label classification, active learning loop, human-in-the-loop\n3. CREATE: backbone choice (WHY), fine-tuning strategy, cascade detector\n4. CALIBRATE: precision/recall trade-off, FPR guardrails, subgroup fairness eval\n5. CRUISE: serving at 100M+ uploads/day, near-real-time vs async, model updates\n\nLink explicitly to: BCG image classification, Atera semantic understanding"),
                              actionButton(ns("save_content"), "Save Design", class = "btn-meta")
                       )
                     )
            )
          )
      )
    ),

    # ── Readiness ────────────────────────────────────
    fluidRow(
      box(title = "📊 ML Design Readiness by Question Type",
          status = "success", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, sliderInput(ns("cv_ar_score"), "CV/AR/Egocentric (0-10)", 0, 10, 8)),
            column(3, sliderInput(ns("ranking_score"), "Feed Ranking / Recommender (0-10)", 0, 10, 4)),
            column(3, sliderInput(ns("moderation_score"), "Content Moderation / CV Classification (0-10)", 0, 10, 7)),
            column(3, sliderInput(ns("llm_score"), "LLM / Multi-modal (0-10)", 0, 10, 3))
          ),
          actionButton(ns("assess_design"), "Calculate ML Design Readiness", class = "btn-meta"),
          br(), br(),
          uiOutput(ns("design_readiness"))
      )
    )
  )
}

ml_design_profile_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$save_cv_design,     { prep_manager$save_note("mldp_cv",      input$cv_design);         showNotification("CV/AR design saved!",         type = "message") })
    observeEvent(input$save_feed,          { prep_manager$save_note("mldp_feed",    input$feed_design);       showNotification("Feed design saved!",           type = "message") })
    observeEvent(input$save_content,       { prep_manager$save_note("mldp_content", input$content_mod_design);showNotification("Content moderation saved!",    type = "message") })

    observeEvent(input$assess_design, {
      avg <- mean(c(input$cv_ar_score, input$ranking_score, input$moderation_score, input$llm_score))
      pct <- round(avg * 10)
      prep_manager$update_progress("ml_design_profile", pct)

      output$design_readiness <- renderUI({
        div(class = if (pct >= 65) "success-box" else "warn-box",
            tags$h4(paste0("ML Design Readiness: ", pct, "%")),
            if (input$ranking_score < 6) div(class = "warn-box",
                HTML("⚠️ <strong>Priority gap:</strong> Feed Ranking is the most common ML Design question at Meta. Use your Santander work as the bridge. Study DLRM, two-tower, multi-task loss.")),
            if (input$llm_score < 5) div(class = "warn-box",
                HTML("⚠️ <strong>2026 gap:</strong> LLM/multi-modal is increasingly tested. Prepare a RAG system design that extends your Atera spatial AI work (spatial queries + LLM description generation).")),
            if (input$cv_ar_score >= 8) div(class = "success-box",
                HTML("✅ <strong>CV/AR strength:</strong> Lead every ML design session by showing your Atera work. Interviewers at Reality Labs will want to go deep here."))
        )
      })
    })
  })
}
