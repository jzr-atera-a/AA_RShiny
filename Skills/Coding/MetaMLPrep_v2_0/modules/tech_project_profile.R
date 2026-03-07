# modules/tech_project_profile.R
# Profile Tab 5: Your Technical Project Interview — Pre-filled from CV
# Three candidate projects with full STAR + architecture narrative

tech_project_profile_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Your Technical Project Stories"),
        tags$h2("Three Candidate Projects — Pick One, Own It Completely"),
        div(
          span(class = "hero-badge", "Project A: Atera AR/AV Pipeline"),
          span(class = "hero-badge", "Project B: Santander 30M-User DL"),
          span(class = "hero-badge", "Project C: Rio Tinto Autonomous")
        )
    ),

    fluidRow(
      box(title = "🎯 Which Project to Lead With",
          status = "primary", solidHeader = TRUE, width = 12,

          fluidRow(
            column(4, div(class = "framework-card",
                          tags$h5("🥇 PROJECT A: Atera AR/AV Pipeline (RECOMMENDED)"),
                          div(class = "success-box", HTML("✅ <strong>Best choice for Reality Labs interview.</strong>")),
                          tags$p("Ownership: 100% (Founder)", tags$br(),
                                 "Technical complexity: VERY HIGH", tags$br(),
                                 "Meta relevance: DIRECT (Meta Quest, spatial AI)", tags$br(),
                                 "Measurable impact: UK Gov awards, NVIDIA partner", tags$br(),
                                 "Failure story available: YES (building novel system)", tags$br(),
                                 "Depth available: MAXIMUM (you built every component)"))),
            column(4, div(class = "framework-card",
                          tags$h5("🥈 PROJECT B: Santander 30M-User DL (Strong Backup)"),
                          div(class = "tip-box", HTML("💡 <strong>Use if interviewer is on ML Platform/Infra team.</strong>")),
                          tags$p("Ownership: High (Head of DT)", tags$br(),
                                 "Technical complexity: HIGH", tags$br(),
                                 "Meta relevance: HIGH (scale, PyTorch, distributed ML)", tags$br(),
                                 "Measurable impact: £20M+ verified", tags$br(),
                                 "Failure story: Oxford research that didn't productionise", tags$br(),
                                 "Depth: Strong on infrastructure, strong on org leadership"))),
            column(4, div(class = "framework-card",
                          tags$h5("🥉 PROJECT C: Rio Tinto Autonomous Systems (Academic Depth)"),
                          div(class = "tip-box", HTML("💡 <strong>Use if interviewer is from FAIR Research track.</strong>")),
                          tags$p("Ownership: HIGH (Post-Doc Research Lead)", tags$br(),
                                 "Technical complexity: HIGH (research-grade)", tags$br(),
                                 "Meta relevance: MEDIUM (autonomous systems, CV)", tags$br(),
                                 "Measurable impact: Published research + awards", tags$br(),
                                 "Failure story: Research dead-end (publishable failure)", tags$br(),
                                 "Depth: Strongest on algorithms and research methodology")))
          )
      )
    ),

    # ── Project A Deep Dive ──────────────────────────
    fluidRow(
      box(title = "🏭 Project A: Atera Real-Time AR/AV Perception Pipeline — Full Narrative",
          status = "primary", solidHeader = TRUE, width = 12,

          tabsetPanel(
            tabPanel("Context & Architecture",
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "section-heading-dark", "Opening Context (memorise this, 90 seconds)"),
                              div(class = "practice-area",
                                  tags$p(tags$i(
                                    '"At Atera, I founded and led the development of a real-time egocentric AR and autonomous vehicle perception system. The business problem was clear: transport infrastructure operators and AV developers needed spatial intelligence systems that could reconstruct 3D environments in real time from moving sensors, overlay semantic understanding on a live AR view, and operate under strict safety-critical latency constraints. I owned the entire technical stack — from sensor hardware integration through to deployed AR applications on Meta Quest devices."'
                                  ))),
                              br(),
                              div(class = "section-heading-dark", "System Architecture"),
                              div(class = "framework-card",
                                  tags$h5("Layer 1: Sensor Input"),
                                  tags$p("Multi-camera stereo arrays (RGB + depth), LiDAR point cloud, GPS/IMU at 200Hz. Synchronisation: hardware timestamping + software interpolation for frame alignment.")),
                              div(class = "framework-card",
                                  tags$h5("Layer 2: Sensor Fusion + SLAM"),
                                  tags$p("Visual-inertial odometry (VIO) with EKF-based IMU pre-integration. LiDAR-visual fusion for metric scale. Pose graph optimisation with loop closure for drift correction. [FILL IN: specific algorithm choices and WHY you chose them over alternatives]")),
                              div(class = "framework-card",
                                  tags$h5("Layer 3: 3D Scene Reconstruction"),
                                  tags$p("TSDF volumetric fusion for dense maps. Semantic labels from segmentation network fused into voxel grid. GIS data integration for coordinate alignment with national infrastructure databases. [FILL IN: how you handled the GIS coordinate frame transformation]")),
                              div(class = "framework-card",
                                  tags$h5("Layer 4: On-Device AR Rendering"),
                                  tags$p("WebXR + Three.js for Meta Quest deployment. Holographic overlay of semantic 3D reconstruction on live camera feed. INT8 quantised inference models for <10ms on-device latency. [FILL IN: how you achieved the 10ms constraint — model architecture, quantisation strategy, what you cut to get there]"))
                       ),
                       column(6,
                              div(class = "section-heading-dark", "Fill in the Hard Parts"),
                              textAreaInput(ns("atera_arch_detail"), "Architecture Deep-dive Notes:", rows = 12,
                                            width = "100%",
                                            placeholder =
"Sensor fusion challenge:
- What was the hardest synchronisation problem?
- How did you handle LiDAR sparsity vs camera density?
- What failed in your first prototype and how did you fix it?

SLAM choice:
- Why your specific algorithm over ORB-SLAM3 / LIO-SAM?
- What were the failure modes in dynamic environments?
- How did you handle loop closure under adversarial conditions?

Latency story:
- What was your first measurement? (probably much higher than 10ms)
- What was the bottleneck? (inference? data transfer? rendering?)
- Specific optimisation: which model change gave the biggest win?
- What did you have to REMOVE to hit the SLO?

Impact:
- How many vehicles / sites deployed to?
- What measurement proved it worked? (beyond 'it ran fast')
- What did clients / UK Gov measure as success?"
                              ),
                              br(),
                              div(class = "section-heading-dark", "Trade-off Stories (prepare 3)"),
                              textAreaInput(ns("atera_tradeoffs"), "Key Trade-offs Made:", rows = 10,
                                            width = "100%",
                                            placeholder =
"Trade-off 1: [Real-time completeness vs accuracy]
Option A: Full dense reconstruction (accurate, 50ms latency)
Option B: Sparse keyframe representation (faster, less detail)
You chose: [?] Why: [?]

Trade-off 2: [On-device vs cloud inference]
Option A: All on-device (privacy, latency)
Option B: Cloud offload for heavy reconstruction
You chose: [?] Under what conditions? What was the decision rule?

Trade-off 3: [SLAM algorithm choice]
Why [your choice] over [alternatives]?
What did you sacrifice in exchange for what benefit?"
                              ),
                              actionButton(ns("save_atera"), "Save Atera Narrative", class = "btn-meta")
                       )
                     )
            ),
            tabPanel("Failure Story",
                     br(),
                     div(class = "section-heading-dark", "The Failure Story — Critical for Meta Interview"),
                     div(class = "warn-box",
                         HTML("<strong>⚠️ Meta WILL ask about a failure.</strong> Prepare this specifically — don't let it catch you off-guard. A well-told failure story is MORE impressive than a polished success story at L6.")),
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "framework-card",
                                  tags$h5("Candidate Failure Story Template for Atera"),
                                  tags$p("'In our first prototype of the sensor fusion pipeline, [SPECIFIC FAILURE: e.g., 'the pose estimation diverged in GPS-denied environments such as tunnels and underpasses — which was precisely the use case our transport clients needed most']."),
                                  tags$p("'The symptom was clear — the AR overlay drifted 10+ metres from the actual road surface within 30 seconds of entering a GPS-denied zone. But the root cause wasn't immediately obvious."),
                                  tags$p("[FILL IN: How did you debug it? What measurements did you take? What did you find that surprised you? What was the fix?]"),
                                  tags$p("'What I'd do differently: [FILL IN — a specific architectural decision you'd change. Not 'nothing' — always something.]")
                              ),
                              div(class = "tip-box",
                                  HTML("<strong>💡 Structure of a great failure story:</strong>
                                  <ol>
                                  <li>Name the specific failure (not vague — 'the model was inaccurate' is weak)</li>
                                  <li>What you THOUGHT the cause was (and why you were wrong)</li>
                                  <li>How you debugged systematically</li>
                                  <li>What the actual root cause was (often surprising)</li>
                                  <li>The fix and what you validated</li>
                                  <li>What you changed in your PROCESS as a result (the learning)</li>
                                  </ol>"))
                       ),
                       column(6,
                              textAreaInput(ns("atera_failure"), "Write Your Failure Story:", rows = 16,
                                            width = "100%",
                                            placeholder = "FAILURE: What specifically broke?\n\nSYMPTOM: What did it look like from the outside?\n\nINITIAL HYPOTHESIS: What did you think caused it?\n\nDEBUGGING: Steps you took, measurements you made\n\nROOT CAUSE: What you actually found (often surprising)\n\nFIX: Specific change made\n\nVALIDATION: How you confirmed it worked\n\nPROCESS CHANGE: What you do differently now as a result"),
                              actionButton(ns("save_failure"), "Save Failure Story", class = "btn-meta")
                       )
                     )
            ),
            tabPanel("Likely Interview Q&A",
                     br(),
                     fluidRow(
                       column(6,
                              lapply(list(
                                list(q = "Why sensor fusion with LiDAR + camera + IMU vs camera-only?",
                                     a = "Camera-only: scale ambiguity, failure in low light. IMU: drift without vision correction. LiDAR: sparse, expensive. Fusion: complementary failure modes. Each sensor covers the other's blind spots. Key for safety-critical AV."),
                                list(q = "How did you achieve sub-10ms? What was your profiling process?",
                                     a = "Profile each stage separately. Use NVIDIA Nsight or PyTorch profiler. Identify the bottleneck (usually: data transfer GPU↔CPU, not inference). Specific optimisations: async camera capture, model quantisation (FP32→INT8), batched inference."),
                                list(q = "What would you do differently if starting over?",
                                     a = "Never say 'nothing'. Good answer: 'I'd start with a tighter latency budget validation before committing to the full pipeline architecture. We spent 3 weeks on a reconstruction approach that we later had to abandon because it couldn't hit the 10ms SLO. A 2-day latency prototype experiment upfront would have saved that.'")
                              ), function(qa) {
                                div(class = "framework-card",
                                    tags$h5(icon("question-circle"), " ", qa$q),
                                    div(class = "tip-box", HTML(paste0("<strong>Answer angle:</strong> ", qa$a))),
                                    textAreaInput(ns(paste0("qa_", sample(1000:9999, 1))),
                                                  "Your specific answer:", rows = 3, width = "100%"))
                              })
                       ),
                       column(6,
                              lapply(list(
                                list(q = "How did you validate the AR overlay accuracy against ground truth?",
                                     a = "Describe your evaluation methodology: survey-grade GPS as ground truth, mean positional error in metres, user study on perceived accuracy. Key: how did you define 'good enough' as a product metric, not just an engineering metric?"),
                                list(q = "How do you handle sensor failures at runtime?",
                                     a = "Graceful degradation: if LiDAR drops, fall back to camera-only VIO with reduced map quality. If IMU fails, camera-only SLAM with increased uncertainty. Explicit state machine for sensor availability. Communicate uncertainty to the AR UI."),
                                list(q = "What does the team structure look like and how did you coordinate?",
                                     a = "This is an XFN question in disguise. Describe: who owned what, how you ran design reviews, how you communicated with NVIDIA/AWS/GCP partner teams, how UK Gov stakeholders were updated on progress.")
                              ), function(qa) {
                                div(class = "framework-card",
                                    tags$h5(icon("question-circle"), " ", qa$q),
                                    div(class = "tip-box", HTML(paste0("<strong>Answer angle:</strong> ", qa$a))))
                              })
                       )
                     )
            )
          )
      )
    ),

    # ── Project B Summary ────────────────────────────
    fluidRow(
      box(title = "🏦 Project B: Santander 30M-User ML — Key Narrative Points",
          status = "info", solidHeader = TRUE, width = 12,
          fluidRow(
            column(4, div(class = "framework-card",
                          tags$h5("Architecture Highlights to Prepare"),
                          tags$ul(
                            tags$li("Real-time feature store design for 30M users' behavioural signals"),
                            tags$li("Research-to-production workflow with Oxford (how did you evaluate Oxford research for productionisation?)"),
                            tags$li("How you managed model versioning and safe deployment across payments/mortgages/lending simultaneously"),
                            tags$li("Specific Oxford Financial Mathematics research → ML production pipeline story")
                          ))),
            column(4, div(class = "framework-card",
                          tags$h5("Impact Metrics to Quantify"),
                          tags$ul(
                            tags$li("£20M+ — which projects contributed what? (mortgages? payments? credit cards?)"),
                            tags$li("30M customers — what was the latency SLO for real-time inference?"),
                            tags$li("40-person team — what was your specific hiring/growth contribution?"),
                            tags$li("Research projects co-authored with Oxford? (if any)")
                          ))),
            column(4, div(class = "framework-card",
                          tags$h5("Failure Story for Santander"),
                          tags$p("'An Oxford research model that showed 15% improvement offline but degraded in production.' OR 'A distributed training setup that worked in staging but had race conditions in production.' Find your specific failure — this is what makes the story memorable."),
                          textAreaInput(ns("santander_failure"), "Santander failure story (brief):",
                                        rows = 5, width = "100%",
                                        placeholder = "What failed? Root cause? Fix? Learning?"),
                          actionButton(ns("save_santander"), "Save", class = "btn-meta")))
          )
      )
    )
  )
}

tech_project_profile_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_atera, {
      prep_manager$save_note("tpp_atera_arch",      input$atera_arch_detail)
      prep_manager$save_note("tpp_atera_tradeoffs", input$atera_tradeoffs)
      prep_manager$update_progress("tech_project_profile", 70)
      showNotification("Atera narrative saved!", type = "message")
    })
    observeEvent(input$save_failure, {
      prep_manager$save_note("tpp_atera_failure", input$atera_failure)
      prep_manager$update_progress("tech_project_profile", 85)
      showNotification("Failure story saved!", type = "message")
    })
    observeEvent(input$save_santander, {
      prep_manager$save_note("tpp_santander_fail", input$santander_failure)
      showNotification("Santander story saved!", type = "message")
    })
  })
}
