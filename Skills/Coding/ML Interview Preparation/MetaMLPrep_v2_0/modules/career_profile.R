# modules/career_profile.R
# Profile Tab 7: Your Career & Leadership Interview — STAR Stories from CV
# Specific narratives pre-mapped from Atera / Santander / BCG / Rio Tinto

career_profile_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Your Career & Leadership Stories"),
        tags$h2("Pre-Built STAR Narratives — Tailored from Your CV"),
        div(
          span(class = "hero-badge", "Founder → Director"),
          span(class = "hero-badge", "40-Person Leadership"),
          span(class = "hero-badge", "Cambridge MBA"),
          span(class = "hero-badge", "4 Career Pivots"),
          span(class = "hero-badge", "Published Research")
        )
    ),

    # ── Career Arc Framing ───────────────────────────
    fluidRow(
      box(title = "📜 Your Career Arc — The Leadership Narrative",
          status = "primary", solidHeader = TRUE, width = 12,

          fluidRow(
            column(8,
                   div(class = "section-heading-dark", "How to Frame Your Career Story for Meta"),
                   div(class = "practice-area",
                       tags$p(tags$b("Your career arc in one sentence (practise this until fluent):"), br(),
                              tags$i('"I\'ve spent over a decade building and deploying production ML and computer vision systems at scale — from published autonomous systems research at the University of Sydney, through enterprise AI leadership at Santander (30M users, £20M impact), global AI delivery at BCG, to founding Atera where I\'ve built real-time egocentric AR systems deployed on Meta Quest devices — and I\'m joining Meta to scale that work to a billion users in Reality Labs."'))),
                   br(),
                   div(class = "framework-card",
                       tags$h5("Your Unique Leadership Narrative"),
                       tags$p("Most ML candidates at L6 followed one path: research → big tech. You took a harder, richer path: research → global consulting → enterprise at scale → founding a startup building directly on Meta's platform. Each transition required you to rebuild technical credibility from scratch in a new domain — demonstrating exactly the flexibility, boldness, and ownership Meta values at L6+."),
                       div(class = "tip-box",
                           HTML("<strong>💡 Frame each career pivot as a bold decision, not an accident:</strong><br/>
                           Rio Tinto → BCG: 'I wanted to test whether the autonomous systems work had commercial applications across other industries — BCG gave me that proving ground.'<br/>
                           BCG → Santander: 'I wanted to go deeper — to own a production ML system at scale, not advise on it.'<br/>
                           Santander → Atera: 'I saw that the real frontier for perception AI was AR/VR, and I wanted to build it, not wait for someone else to.'"))
                   )
            ),
            column(4,
                   div(class = "section-heading-dark", "Career Timeline"),
                   timeline_entry("2012–15", "Rio Tinto / Sydney",
                                  "Post-Doc Research Lead. Autonomous systems, ML, CV. Published research. Foundation of technical identity."),
                   timeline_entry("2015–17", "BCG London",
                                  "Lead Consultant AI/CV. Fortune 500 clients. Multi-region team. Commercial AI delivery."),
                   timeline_entry("2017–19", "Caltex-Ampol",
                                  "Lead Data Science. APAC scale ML. $20M USD revenue. Complex network optimisation."),
                   timeline_entry("2019–23", "Santander + Oxford",
                                  "Head of Digital Transformation. 40+ team. £20M+ impact. 30M users. Research partnership."),
                   timeline_entry("2023–",   "Atera Analytics",
                                  "Founder & Director. AR/VR + AV. Meta Quest. UK Gov awards. NVIDIA/AWS/GCP partner.")
            )
          )
      )
    ),

    # ── STAR Story Bank ──────────────────────────────
    fluidRow(
      box(title = "⭐ Your STAR Story Bank — Pre-Mapped to Meta Questions",
          status = "info", solidHeader = TRUE, width = 12,

          tabsetPanel(
            tabPanel("Leadership & Conflict",
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "section-heading-dark",
                                  "'How do you deal with conflict?' — Your Story Options"),
                              div(class = "framework-card",
                                  tags$h5("Option 1: Santander — Research vs Production Conflict"),
                                  tags$p("'At Santander, my Oxford research partners and my production engineering team had a fundamental disagreement about a model architecture. Oxford wanted a novel approach that showed 12% improvement on academic benchmarks. My production team argued it was too complex to maintain, had unpredictable latency, and posed regulatory interpretability risks.'"),
                                  tags$p(tags$b("Resolution angle:"), " You designed an A/B evaluation framework that tested both approaches against production metrics (not academic benchmarks). The data resolved the conflict. '[FILL IN: what the data showed and what was deployed.]'")),
                              div(class = "framework-card",
                                  tags$h5("Option 2: BCG — Client vs Team Architecture Conflict"),
                                  tags$p("A Fortune 500 client insisting on an ML architecture your team knew was technically inferior. Navigate: technical credibility vs client relationship management. The resolution showed leadership maturity, not just technical correctness."),
                                  textAreaInput(ns("conflict_story"), "Write your conflict story:", rows = 7,
                                                width = "100%",
                                                placeholder = "STAR format. Focus on: how you stayed curious about their perspective before pushing yours. What data changed the outcome? What would you do differently?")),
                              actionButton(ns("save_conflict"), "Save", class = "btn-meta")
                       ),
                       column(6,
                              div(class = "section-heading-dark",
                                  "'Tell me about a project that failed' — Your Story"),
                              div(class = "framework-card",
                                  tags$h5("Rio Tinto: A Research Direction That Didn't Work"),
                                  tags$p("At Rio Tinto/University of Sydney, you likely pursued research directions that didn't pan out. A specific hypothesis that was disproven, a ML approach for minerals classification that was theoretically sound but practically failed. This is excellent failure material because:"),
                                  tags$ul(
                                    tags$li("It shows intellectual honesty (you can fail and acknowledge it)"),
                                    tags$li("Research failures are 'noble' failures — they advance knowledge"),
                                    tags$li("You can show the learning was built into subsequent systems (Santander, Atera)")
                                  )),
                              div(class = "framework-card",
                                  tags$h5("OR: A Santander Deployment That Regressed"),
                                  tags$p("A model that was deployed to production and then degraded — a performance regression caught in production, not before launch. 'We deployed [model] to [segment of 30M customers] and observed [specific metric] decline by [X%] within [timeframe]. The post-mortem revealed...'"),
                                  textAreaInput(ns("failure_story"), "Write your failure story:", rows = 7,
                                                width = "100%",
                                                placeholder = "STAR format. Include: what you thought caused it vs actual root cause. The debugging process. The systematic fix. What you changed in your process permanently."),
                                  actionButton(ns("save_failure"), "Save", class = "btn-meta"))
                       )
                     )
            ),

            tabPanel("Mentorship — 4 People",
                     br(),
                     div(class = "warn-box",
                         HTML("<strong>⚠️ Direct Meta question:</strong> 'Can you tell me about four people whose careers you have fundamentally improved?' Prepare ALL FOUR. You managed 40+ people at Santander — you have the material.")),
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "framework-card",
                                  tags$h5("Person 1: Santander — L4→L5 Growth"),
                                  tags$p("From your 40-person team: a junior ML engineer or data scientist who you grew significantly. What was their gap (technical? communication? scope?)? What specifically did you do? What did they achieve that they wouldn't have without your investment?"),
                                  textAreaInput(ns("mentee1"), "Their level → gap → your approach → their outcome:", rows = 4,
                                                placeholder = "e.g., 'Junior DS at Santander, strong technically but couldn't communicate to non-technical stakeholders. I ran weekly 30-min sessions structuring their findings for exec audiences. Within 6 months they were presenting directly to the CTO and were promoted.'",
                                                width = "100%")),
                              div(class = "framework-card",
                                  tags$h5("Person 2: BCG — Technical Upskilling"),
                                  tags$p("A BCG team member (East Asia, EU, or Americas) who you coached through a technical challenge — deep learning adoption, Python migration, ML system design. How did you build their capability remotely?"),
                                  textAreaInput(ns("mentee2"), NULL, rows = 4, width = "100%",
                                                placeholder = "Role → gap → approach → outcome (quantified if possible)"))
                       ),
                       column(6,
                              div(class = "framework-card",
                                  tags$h5("Person 3: Atera / Caltex — Research to Industry Transition"),
                                  tags$p("A researcher (Rio Tinto, Caltex, Atera) transitioning from academic/research work to production ML systems. The gap: research mindset (novelty focus) vs production mindset (reliability, maintainability, latency). Your approach to bridging this."),
                                  textAreaInput(ns("mentee3"), NULL, rows = 4, width = "100%",
                                                placeholder = "Role → gap → approach → outcome")),
                              div(class = "framework-card",
                                  tags$h5("Person 4: Cross-functional — Upskilling Non-ML Partner"),
                                  tags$p("Someone from a non-ML background (PM, data engineer, financial analyst, government partner) whose ML literacy you significantly improved — enabling them to be a better partner to the ML team. Shows L6 systemic thinking: you upskill partners, not just direct reports."),
                                  textAreaInput(ns("mentee4"), NULL, rows = 4, width = "100%",
                                                placeholder = "Role → gap → approach → outcome"))
                       )
                     ),
                     br(),
                     actionButton(ns("save_mentorship"), "Save All 4 Mentorship Stories",
                                  class = "btn-meta", icon = icon("save"))
            ),

            tabPanel("Technical Vision & Best Day",
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "section-heading-dark",
                                  "'What did you do on your very best day at work?'"),
                              div(class = "framework-card",
                                  tags$h5("Your Candidate Answer — Atera Deployment Moment"),
                                  tags$p("'My best day was the first time our AR pipeline ran end-to-end on a Meta Quest device — the holographic 3D reconstruction of a live road scene appeared stable and accurate at under 10ms, which we'd been targeting for months. But what made it the best day wasn't the technical result — it was watching a transport engineer see their infrastructure overlaid in 3D for the first time and immediately understand spatial relationships they'd been trying to communicate on 2D maps for years. In that moment, the engineering felt genuinely useful.'"),
                                  div(class = "tip-box",
                                      HTML("<strong>💡 Why this works:</strong> It shows: technical achievement, user empathy, mission-driven motivation, and a memorable sensory moment. Meta values engineers who build for users, not just for technical elegance.")),
                                  br(),
                                  textAreaInput(ns("best_day"), "Refine your best day story:", rows = 6,
                                                width = "100%",
                                                value = "My best day was [specific moment at Atera / Santander / Rio Tinto]...\n\n[Add: who was there, what you saw or heard, why it mattered beyond the technical metric]"),
                                  actionButton(ns("save_best_day"), "Save", class = "btn-meta")
                              )
                       ),
                       column(6,
                              div(class = "section-heading-dark", "Technical Vision — L6 Requirement"),
                              div(class = "framework-card",
                                  tags$h5("'How do you influence technical direction?'"),
                                  tags$p("Frame from your Founder experience: 'At Atera, I had to define technical direction without any existing team or precedent — every architectural choice was a bet. That experience taught me to:"),
                                  tags$ul(
                                    tags$li("Start with the user constraint (latency SLO) and work backwards to architecture"),
                                    tags$li("Prototype the risky assumption first, not the safe parts"),
                                    tags$li("Build technical consensus through demonstration, not argument — show, don't tell"),
                                    tags$li("Maintain a 6-18 month technical roadmap that's shared with all stakeholders — no surprises'")
                                  )),
                              div(class = "framework-card",
                                  tags$h5("Your 2026–2027 Technical Vision (prepare this)"),
                                  textAreaInput(ns("tech_vision"), "Your Meta ML technical vision:", rows = 8,
                                                width = "100%",
                                                value =
"My vision for ML engineering at Meta Reality Labs in 2026-2027:

1. SPATIAL AI AT SCALE: The convergence of Gaussian Splatting + neural
   scene representations + egocentric video-language models (EgoVLP) will
   enable persistent world models that are semantic, dynamic, and
   shareable — the foundation for true social AR.

2. ON-DEVICE INTELLIGENCE: The next frontier is moving from cloud-heavy
   to edge-first ML. With MTIA and Meta Quest's compute capabilities,
   we can run real-time 3D perception + LLM inference on-device with
   privacy guarantees that cloud-based approaches can't offer.

3. THE MISSING LAYER: What I see that others miss — the gap between
   research-grade scene understanding (we have SAM, DINOv2, EgoVLP) and
   production AR systems (Meta Quest). I've built in this gap. The
   challenge is latency-constrained deployment of foundation models,
   and I believe LoRA-based specialisation + speculative decoding will
   solve this within 18 months.

[EXPAND with your specific perspective and why Meta should care]"),
                                  actionButton(ns("save_vision"), "Save Vision", class = "btn-meta"))
                       )
                     )
            ),

            tabPanel("Office Politics & Career",
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "section-heading-dark",
                                  "'What does office politics mean to you?'"),
                              div(class = "framework-card",
                                  tags$h5("Your Answer — Reframe as Technical Alignment"),
                                  div(class = "practice-area",
                                      tags$p(tags$i('"I prefer to reframe \'politics\' as \'alignment\'. In every organisation I\'ve worked in — from the University of Sydney to a Fortune 500 bank to a startup — there have been competing priorities, incentive misalignments, and differing views on technical direction. I see my role as understanding those incentive structures and finding the framing that aligns everyone around a shared technical goal. At Santander, my ML team and the compliance team had fundamentally different risk tolerances. Rather than fight that tension, I built the evaluation framework that let both teams speak the same language — regulatory audit trails and ML performance metrics unified into a single dashboard. The \'politics\' dissolved when the measurement system made both teams\' goals visible simultaneously."')))
                              ),
                              br(),
                              div(class = "section-heading-dark",
                                  "'Describe a few of your peers'"),
                              div(class = "framework-card",
                                  tags$p("Draw from Santander (40-person team) or Atera. Show range: a peer you learned from technically, a peer you had productive creative tension with, a peer you mentored upward. Show emotional intelligence and genuine relationship quality."),
                                  textAreaInput(ns("peers_story"), "Your peers description:", rows = 6,
                                                width = "100%",
                                                placeholder = "Peer 1 (name/role anonymised): Strong on X, I learned Y from them...\nPeer 2: We disagreed about Z — how that played out...\nPeer 3: I invested in their growth by..."),
                                  actionButton(ns("save_peers"), "Save", class = "btn-meta"))
                       ),
                       column(6,
                              div(class = "section-heading-dark",
                                  "Your Cambridge MBA — How to Use It"),
                              div(class = "framework-card",
                                  tags$h5("Cambridge MBA + ML Engineering = Rare Combination"),
                                  tags$p("At L6+, Meta needs technical leaders who can translate between engineering and business strategy. Your Cambridge MBA is not background noise — it's a differentiator. Use it explicitly:"),
                                  tags$ul(
                                    tags$li("'My Advanced Finance concentration at Cambridge shaped how I think about ML project ROI — I structure technical bets the same way I'd structure a financial hedge: expected value, downside risk, and optionality.'"),
                                    tags$li("'The MBA taught me that technical excellence is necessary but insufficient — what matters is whether the system delivers business value. I hold myself to both standards.'"),
                                    tags$li("'When I disagree with a PM or Director, I use the financial framing from my MBA: expected NPV of each approach, risk-adjusted. It moves the conversation from opinions to numbers.'")
                                  )),
                              div(class = "section-heading-dark", "Overall Career Readiness"),
                              sliderInput(ns("car_stars"), "STAR stories polished (0-10 stories)", 0, 10, 0),
                              sliderInput(ns("car_mentees"), "4 mentorship stories ready (0-4)", 0, 4, 0),
                              sliderInput(ns("car_vision2"), "Technical vision clarity (0-10)", 0, 10, 0),
                              sliderInput(ns("car_failure2"), "Failure stories with lessons (0-5)", 0, 5, 0),
                              actionButton(ns("calc_career"), "Calculate Readiness", class = "btn-meta"),
                              br(), br(),
                              uiOutput(ns("career_readiness"))
                       )
                     )
            )
          )
      )
    )
  )
}

career_profile_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$save_conflict,   { prep_manager$save_note("cp_conflict",   input$conflict_story); showNotification("Conflict story saved!",     type = "message") })
    observeEvent(input$save_failure,    { prep_manager$save_note("cp_failure",    input$failure_story);  showNotification("Failure story saved!",      type = "message") })
    observeEvent(input$save_mentorship, {
      prep_manager$save_note("cp_mentee1", input$mentee1)
      prep_manager$save_note("cp_mentee2", input$mentee2)
      prep_manager$save_note("cp_mentee3", input$mentee3)
      prep_manager$save_note("cp_mentee4", input$mentee4)
      showNotification("All 4 mentorship stories saved!", type = "message")
    })
    observeEvent(input$save_best_day,   { prep_manager$save_note("cp_best_day",   input$best_day);       showNotification("Best day story saved!",     type = "message") })
    observeEvent(input$save_vision,     { prep_manager$save_note("cp_vision",     input$tech_vision);    showNotification("Technical vision saved!",   type = "message") })
    observeEvent(input$save_peers,      { prep_manager$save_note("cp_peers",      input$peers_story);    showNotification("Peers description saved!",  type = "message") })

    observeEvent(input$calc_career, {
      score <- (input$car_stars   / 10 * 30) +
               (input$car_mentees /  4 * 30) +
               (input$car_vision2 / 10 * 20) +
               (input$car_failure2 / 5 * 20)
      pct <- round(score)
      prep_manager$update_progress("career_profile", pct)

      output$career_readiness <- renderUI({
        colour <- progress_colour(pct)
        div(class = if (pct >= 70) "success-box" else "warn-box",
            tags$h4(style = paste0("color:", colour), paste0("Career Readiness: ", pct, "%")),
            if (input$car_mentees < 4) div(class = "warn-box",
                HTML("⚠️ <strong>Critical gap:</strong> You have 40+ people you managed at Santander alone. You MUST have 4 mentorship stories. This is a direct Meta question.")),
            if (input$car_failure2 < 2) div(class = "warn-box",
                HTML("⚠️ Prepare 2+ failure stories. Rio Tinto research + Santander production regression = strong pair.")),
            if (pct >= 80) div(class = "success-box",
                HTML("✅ Strong career profile. Your Founder arc + Cambridge MBA + 40-person leadership is exceptional differentiation at L6+."))
        )
      })
    })
  })
}
