# modules/intro_profile.R
# Profile Tab 1: Your Candidacy Overview
# Research Engineer, Computer Vision & AI | Atera · Santander · BCG · Rio Tinto

intro_profile_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Your Candidacy Profile"),
        tags$h2("Research Engineer · Computer Vision & AI · Meta Reality Labs"),
        div(
          span(class = "hero-badge", "3D Spatial AI"),
          span(class = "hero-badge", "Egocentric AR/VR"),
          span(class = "hero-badge", "10+ Yrs ML"),
          span(class = "hero-badge", "Cambridge MBA"),
          span(class = "hero-badge", "Founder → Meta")
        )
    ),

    # ── Fit Score Dashboard ──────────────────────────
    fluidRow(
      box(title = "🎯 Overall Candidacy Strength vs Meta SWE Leadership ML",
          status = "primary", solidHeader = TRUE, width = 12,

          fluidRow(
            column(2, div(class = "metric-card",
                          span(class = "metric-value", "92%"),
                          span(class = "metric-label", "CV–Role Fit"))),
            column(2, div(class = "metric-card",
                          span(class = "metric-value", "5"),
                          span(class = "metric-value-label", "Deployments"),
                          span(class = "metric-label", "Prod ML Systems"))),
            column(2, div(class = "metric-card",
                          span(class = "metric-value", "40+"),
                          span(class = "metric-label", "Team Led (Santander)"))),
            column(2, div(class = "metric-card",
                          span(class = "metric-value", "£20M+"),
                          span(class = "metric-label", "Verified ML Impact"))),
            column(2, div(class = "metric-card",
                          span(class = "metric-value", "3"),
                          span(class = "metric-label", "Academic Affiliations"))),
            column(2, div(class = "metric-card",
                          span(class = "metric-value", "<10ms"),
                          span(class = "metric-label", "Latency Delivered")))
          ),
          br(),
          div(class = "success-box",
              HTML("<strong>✅ Headline Assessment:</strong> This profile is exceptionally well-aligned with Meta Reality Labs' SWE Leadership (ML) track. Egocentric AR/VR engineering at Atera directly maps to Meta Quest / Project Orion work. The combination of hands-on CV systems building + Cambridge MBA + 40-person team leadership positions you at the L6–L7 boundary — exactly where Meta needs technical leaders who can drive both research and production."))
      )
    ),

    # ── Experience Map ───────────────────────────────
    fluidRow(
      box(title = "🗺️ Your Experience Mapped to Meta's Priority Areas",
          status = "info", solidHeader = TRUE, width = 8,

          div(class = "section-heading-dark", "Role-by-Role Meta Relevance"),

          div(class = "framework-card",
              tags$h5(icon("building"), "  Atera Analytics (2023–Present) — HIGHEST RELEVANCE"),
              tags$p(tags$b("What you did:"), " Real-time CV pipelines (multi-camera, LiDAR, GPS/IMU), egocentric AR on Meta Quest, holographic 3D reconstruction, <10ms on-device latency, GIS digital twin, UK Gov awards, NVIDIA/AWS/GCP partnerships."),
              tags$p(tags$b("Meta match:"), " This is ", tags$em("precisely"), " Reality Labs' scope. SLAM, sensor fusion, semantic scene understanding, Meta Quest deployment, sub-10ms on-device ML — every bullet maps to an open Reality Labs research direction."),
              tags$p(tags$b("Interview angle:"), " Lead every technical answer with Atera. It is your showcase system. Own it completely.")),

          div(class = "framework-card",
              tags$h5(icon("university"), "  Santander + Oxford (2019–2023) — HIGH RELEVANCE"),
              tags$p(tags$b("What you did:"), " End-to-end deep learning pipelines, 30M-customer real-time behavioural inference, PyTorch + distributed cloud, 40+ person XFN team, £20M+ impact, research-to-production."),
              tags$p(tags$b("Meta match:"), " Scale (30M users = Meta scale credibility). PyTorch (Meta's framework). Research-to-production transitions. Cross-functional leadership at org level. Exactly what L6 ML leadership interviews probe."),
              tags$p(tags$b("Interview angle:"), " Use for scale, leadership, XFN, and research-to-production stories.")),

          div(class = "framework-card",
              tags$h5(icon("chart-bar"), "  BCG + Caltex + Rio Tinto (2012–2019) — SUPPORTING EVIDENCE"),
              tags$p(tags$b("What you did:"), " CV for Health/Bio-Chemical (BCG), ML at APAC scale (Caltex $20M USD), autonomous systems research + publications (Rio Tinto/Sydney)."),
              tags$p(tags$b("Meta match:"), " Depth in autonomous systems (pre-dates Meta Quest but shows foundational research credibility). Published research = Research Engineer title is authentic. Fortune 500 AI delivery = production ML pedigree."),
              tags$p(tags$b("Interview angle:"), " Use Rio Tinto for \"technical foundation\" and \"failed research project\" stories."))
      ),

      column(4,
             box(title = "⚠️ Gaps to Address", status = "warning",
                 solidHeader = TRUE, width = 12,

                 div(class = "warn-box",
                     HTML("<strong>Gap 1 — Pure ML Research Publications:</strong> Meta Reality Labs interviews expect SOTA awareness. You have Rio Tinto publications but ensure you can discuss recent CVPR/ECCV/ICCV papers (2023–2026) in SLAM, NeRF, Gaussian Splatting, egocentric activity recognition.")),

                 div(class = "warn-box",
                     HTML("<strong>Gap 2 — Transformer Architecture Depth:</strong> Your CV shows PyTorch + DL but doesn't explicitly name transformer-based CV models (ViT, DINO, SAM). Prepare to discuss how you'd use or have used attention-based architectures in your systems.")),

                 div(class = "warn-box",
                     HTML("<strong>Gap 3 — LLM/Multi-modal Bridge:</strong> Meta is investing in multi-modal AI (ImageBind, Llama 3). Prepare a perspective on how your egocentric CV systems would integrate with language models for scene understanding.")),

                 div(class = "tip-box",
                     HTML("<strong>💡 Strength to amplify:</strong> Your <b>Founder</b> background is rare among ML candidates. At L6+, Meta values engineers who can operate with founder-level ownership and accountability. Lead with this mindset."))
             ),

             box(title = "📚 SOTA Papers You Must Know", status = "primary",
                 solidHeader = TRUE, width = 12,
                 tags$ul(style = "font-size: 12px;",
                   tags$li(tags$b("Gaussian Splatting"), " (2023) — SOTA 3D scene representation, directly relevant to your holographic reconstruction work"),
                   tags$li(tags$b("EgoVLP / EgoVLPv2"), " — Meta FAIR: egocentric video-language pretraining"),
                   tags$li(tags$b("Segment Anything (SAM)"), " — Meta FAIR: zero-shot segmentation"),
                   tags$li(tags$b("DINO / DINOv2"), " — Meta FAIR: self-supervised vision features"),
                   tags$li(tags$b("FoundationPose"), " — 6-DOF pose estimation for AR"),
                   tags$li(tags$b("UniDepth / Depth Anything"), " — monocular depth at scale"),
                   tags$li(tags$b("ARIA / Project Aria"), " — Meta's egocentric research device papers")
                 )
             )
      )
    ),

    # ── Interview Readiness by Round ─────────────────
    fluidRow(
      box(title = "📊 Your Predicted Readiness by Interview Round",
          status = "success", solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
                   div(class = "section-heading-dark", "Strongest Rounds"),
                   div(class = "framework-card",
                       tags$h5("🟢 Technical Project (Tab 5) — 95% Ready"),
                       tags$p("Atera's AR/VR pipeline is a near-perfect Meta technical project story. You have ownership, scale, novel architecture, measurable impact, and production deployment.")),
                   div(class = "framework-card",
                       tags$h5("🟢 ML Design: CV/Face/AR (Tab 4) — 90% Ready"),
                       tags$p("Your sensor fusion, on-device inference, SLAM and 3D reconstruction work is directly analogous to Meta Quest perception systems.")),
                   div(class = "framework-card",
                       tags$h5("🟢 XFN Partnership (Tab 6) — 88% Ready"),
                       tags$p("Santander: 40-person XFN team across UK/EU/Americas. BCG: multi-region client coordination. Strong material here."))
            ),
            column(4,
                   div(class = "section-heading-dark", "Needs Work"),
                   div(class = "framework-card",
                       tags$h5("🟡 Coding Interview (Tab 3) — 65% Ready"),
                       tags$p("No evidence of LeetCode-style competitive programming practice. Your algorithmic work exists in systems context. Need 4–6 weeks of daily LeetCode (Hard focus: Sliding Window, Tree DP, Graph problems).")),
                   div(class = "framework-card",
                       tags$h5("🟡 ML Design: Ranking/Recommender (Tab 4) — 70% Ready"),
                       tags$p("Your CV is CV-heavy (computer vision). Meta's other ML Design track covers feed ranking, ads, recommendations. Prepare DLRM, two-tower, multi-task learning explicitly."))
            ),
            column(4,
                   div(class = "section-heading-dark", "Unique Differentiators"),
                   div(class = "success-box",
                       HTML("<strong>🏆 What sets you apart from other ML candidates:</strong>
                       <ul>
                       <li><b>Founder credential</b> — rare at this level, shows ownership mindset</li>
                       <li><b>Meta Quest + WebXR</b> — direct Reality Labs platform experience</li>
                       <li><b>Cambridge MBA</b> — uniquely positions you to lead technical + business strategy</li>
                       <li><b>UK Gov + NVIDIA/AWS/GCP partner</b> — institutional credibility</li>
                       <li><b>Multi-continent delivery</b> — Sydney, London, East Asia, Americas</li>
                       </ul>")),
                   div(class = "tip-box",
                       HTML("<strong>💡 Opening statement for every interview:</strong> 'I've spent the last decade building and deploying real-time perception systems — from autonomous vehicle infrastructure to egocentric AR on Meta Quest devices — and I'm joining Meta to scale that work to a billion users.'"))
            )
          )
      )
    ),

    # ── 8-Week Plan ──────────────────────────────────
    fluidRow(
      box(title = "🗓️ Your Personalised 8-Week Interview Prep Plan",
          status = "primary", solidHeader = TRUE, width = 12,

          fluidRow(
            column(3,
                   div(class = "section-heading-dark", "Weeks 1-2: Foundations"),
                   div(class = "framework-card",
                       tags$h5("LeetCode Daily"),
                       tags$p("2 problems/day. Meta tag. Focus: arrays, hash maps, sliding window, BFS/DFS. Start Medium, add Hard in week 2.")),
                   div(class = "framework-card",
                       tags$h5("SOTA Paper Review"),
                       tags$p("Read: Gaussian Splatting, SAM, DINOv2, EgoVLP. Write one-page summary of each linking to your Atera work."))
            ),
            column(3,
                   div(class = "section-heading-dark", "Weeks 3-4: ML Design"),
                   div(class = "framework-card",
                       tags$h5("Design from CV"),
                       tags$p("Formalise your Atera system into a Meta-style ML design document. 5 Cs structure. Timing yourself at 45 minutes.")),
                   div(class = "framework-card",
                       tags$h5("Ranking Systems"),
                       tags$p("Study DLRM, two-tower, NDCG. Build one mock design for Feed Ranking — the question most likely to appear."))
            ),
            column(3,
                   div(class = "section-heading-dark", "Weeks 5-6: Story Bank"),
                   div(class = "framework-card",
                       tags$h5("STAR Stories"),
                       tags$p("Write 10 STAR stories covering: Atera ownership, Santander scale, BCG client conflict, Rio Tinto failure, Oxford research translation.")),
                   div(class = "framework-card",
                       tags$h5("XFN + Leadership"),
                       tags$p("Prepare 3 XFN stories: Research↔Eng (Rio Tinto/Sydney), PM↔ML (Santander), Cross-border (BCG East Asia)."))
            ),
            column(3,
                   div(class = "section-heading-dark", "Weeks 7-8: Mock Loops"),
                   div(class = "framework-card",
                       tags$h5("Full Mock Interviews"),
                       tags$p("Run complete 45-min sessions for each round with a practice partner. Record yourself. Review delivery speed and depth balance.")),
                   div(class = "framework-card",
                       tags$h5("Meta Research Review"),
                       tags$p("Read 10 Meta Reality Labs + FAIR papers published 2024-2026. Prepare opinions and extensions linking to your work."))
            )
          )
      )
    )
  )
}

intro_profile_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("intro_profile", 75)
  })
}
