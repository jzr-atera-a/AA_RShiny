# modules/qualities_profile.R
# Profile Tab 2: Your Engineer Qualities Evidence
# Maps candidate's Atera / Santander / BCG / Rio Tinto work to Meta's 3 core qualities

qualities_profile_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Your Engineer Qualities Evidence"),
        tags$h2("How Your Career Proves Meta's Three Core Engineering Qualities"),
        div(
          span(class = "hero-badge", "Ownership → Atera Founder"),
          span(class = "hero-badge", "Flexibility → 4 Industries"),
          span(class = "hero-badge", "Boldness → UK Gov Awards")
        )
    ),

    # ── Quality 1: Ownership ─────────────────────────
    fluidRow(
      box(title = "🏆 Quality 1: Ownership — Your Evidence",
          status = "primary", solidHeader = TRUE, width = 12,

          fluidRow(
            column(6,
                   div(class = "section-heading-dark", "Your Strongest Ownership Story"),
                   div(class = "framework-card",
                       tags$h5("Atera Analytics: Full-Stack AR/AV Pipeline (2023–Present)"),
                       tags$p("You founded Atera and built the entire perception stack — from hardware sensor integration (multi-camera, LiDAR, GPS/IMU) through to deployed AR on Meta Quest devices with <10ms latency. No hand-off. No partial ownership. You own every layer: hardware integration, sensor fusion, 3D reconstruction, semantic overlay, cloud distributed serving, and production monitoring."),
                       tags$p(tags$b("Meta interviewer will hear:"), " 'This engineer has operated at founder-level ownership. They've experienced every failure mode because they couldn't blame another team.'"),
                       div(class = "success-box",
                           HTML("<strong>✅ Your ownership proof points:</strong><br/>
                           • Sensor fusion pipeline: designed, built, deployed, monitored by you<br/>
                           • On-device ML inference: you own the latency SLO (sub-10ms) and debug when it breaks<br/>
                           • UK Government awards: external validation of delivery ownership<br/>
                           • NVIDIA/AWS/GCP partnerships: you drove technical relationships, not just used the tools"))
                   ),
                   br(),
                   div(class = "section-heading-dark", "Santander Ownership Proof"),
                   div(class = "framework-card",
                       tags$h5("30M-Customer Real-Time Inference Pipeline"),
                       tags$p("You architected and deployed end-to-end DL pipelines from research experimentation through production — processing real-time behavioural signals from 30 million customers. You owned the full lifecycle from Oxford research collaboration through to production £20M+ impact."),
                       div(class = "tip-box",
                           HTML("<strong>💡 Ownership framing:</strong> 'At Santander I was accountable for both the research quality (co-developing with Oxford) and the production reliability (30M customers in real-time). There was no split — I owned the full stack.'"))
                   )
            ),
            column(6,
                   div(class = "section-heading-dark", "Refine Your Ownership Story (STAR)"),
                   div(class = "practice-area",
                       tags$p(tags$b("Pre-filled from your CV — refine and make specific:")),
                       textAreaInput(ns("ownership_story"), label = NULL, rows = 14,
                                     width = "100%",
                                     value =
"SITUATION: At Atera Analytics, I founded and led development of a real-time
computer vision and AR system for autonomous vehicle deployment — processing
multi-modal sensor data from multi-camera arrays, LiDAR, and GPS/IMU sensors
simultaneously across distributed edge + cloud architecture.

TASK: As founder and director, I owned the full technical stack from sensor
integration through to AR visualisation on Meta Quest devices — with a
hard requirement of sub-10ms on-device latency for safety-critical systems.

ACTION: [EXPAND - describe the hardest technical decision you made, what
failed, how you debugged it, what architecture choices you made and WHY,
specifically: how you handled the sensor fusion fusion latency challenge]

RESULT: Deployed to [X] vehicles / infrastructure sites. Received multiple
UK Government awards. Revenue of £[?]. Partnerships with NVIDIA, AWS, GCP."
                       ),
                       actionButton(ns("save_ownership"), "Save Story", class = "btn-meta")
                   )
            )
          )
      )
    ),

    # ── Quality 2: Flexibility ───────────────────────
    fluidRow(
      box(title = "🔄 Quality 2: Flexibility — Your Evidence",
          status = "info", solidHeader = TRUE, width = 12,

          fluidRow(
            column(5,
                   div(class = "section-heading-dark", "Your Flexibility Evidence — Unmatched"),
                   div(class = "framework-card",
                       tags$h5("Industry Range (Rare at L6+ ML)"),
                       tags$p("You have successfully applied ML/CV across:"),
                       tags$ul(
                         tags$li(tags$b("AR/VR + Autonomous Vehicles:"), " Atera (spatial AI, egocentric AR, AV deployment)"),
                         tags$li(tags$b("Financial Services at Scale:"), " Santander (30M customers, behavioural ML, distributed inference)"),
                         tags$li(tags$b("Health + Bio-Chemical:"), " BCG (image classification, CV pipelines, C++ backends)"),
                         tags$li(tags$b("Energy + Distribution:"), " Caltex (molecular simulation ML, APAC-scale distributed systems)"),
                         tags$li(tags$b("Autonomous Mining + Academia:"), " Rio Tinto/Sydney (minerals classification, published research)")
                       ),
                       tags$p(tags$b("Meta interviewer will hear:"), " 'This engineer doesn't get stuck in one domain. They can context-switch to Reality Labs problems even if different from their current stack.'")
                   ),
                   div(class = "framework-card",
                       tags$h5("Language & Stack Flexibility"),
                       tags$p("Python (primary), Rust (systems-level), C++ (BCG, Rio Tinto), PyTorch, WebXR/Three.js, AWS/GCP. You can jump into Meta's infra codebase without needing to relearn fundamentals."),
                       div(class = "tip-box",
                           HTML("<strong>💡 Flexibility story angle:</strong> 'When I moved from financial services ML at Santander to building AR perception systems at Atera, I had to completely re-architect my thinking from batch/offline behavioural modelling to sub-10ms streaming inference. That transition shaped how I now design every ML system — starting from the serving constraint and working backwards.'"))
                   )
            ),
            column(7,
                   div(class = "section-heading-dark", "Your Best Flexibility Story (BCG to Atera transition)"),
                   div(class = "practice-area",
                       textAreaInput(ns("flex_story"), label = NULL, rows = 10,
                                     width = "100%",
                                     value =
"SITUATION: After 4 years in financial services ML (Santander/Oxford), I
founded Atera and immediately had to context-switch to real-time computer
vision and AR systems — a fundamentally different engineering paradigm.

TASK: Build a production-grade egocentric AR system on Meta Quest with
sub-10ms latency, while simultaneously learning the Meta Quest SDK, WebXR
APIs, and LiDAR sensor integration — none of which I had used before.

ACTION: [EXPAND - how fast did you get productive? What did you do in the
first 2-4 weeks? Which existing skills transferred? What did you have to
completely rebuild from scratch? How did you navigate unknown territory?]

RESULT: [Deployed system / awarded UK Gov recognition / specific metric
showing you delivered despite the context switch]"
                       ),
                       actionButton(ns("save_flex"), "Save Story", class = "btn-meta")
                   ),
                   br(),
                   div(class = "section-heading-dark", "Cross-Geography Flexibility (BCG)"),
                   div(class = "framework-card",
                       tags$h5("East Asia + Europe + Americas Simultaneously"),
                       tags$p("At BCG you coordinated software development across four multidisciplinary teams in East Asia, Europe, and the Americas — delivering production AI systems to institutional standards. This is L6+ XFN flexibility evidence. Prepare a specific example: timezone management, technical alignment despite language barriers, and a specific delivery outcome."))
            )
          )
      )
    ),

    # ── Quality 3: Boldness ──────────────────────────
    fluidRow(
      box(title = "🔥 Quality 3: Boldness — Your Evidence",
          status = "warning", solidHeader = TRUE, width = 12,

          fluidRow(
            column(6,
                   div(class = "section-heading-dark", "Your Boldness Credentials"),
                   div(class = "framework-card",
                       tags$h5("Founding Atera — The Ultimate Boldness Story"),
                       tags$p("You left a senior role (Santander £20M ML lead) to found a company in a domain (AR/AV) that requires building novel systems from scratch, working under UK Government scrutiny, and delivering with NVIDIA/AWS/GCP as partners. Most engineers at your level don't take this risk."),
                       div(class = "success-box",
                           HTML("<strong>✅ Meta will love this:</strong> 'Be Bold' is one of three core values. Founding a company and securing government awards is exactly the boldness narrative Meta is looking for at L6+."))),
                   div(class = "framework-card",
                       tags$h5("10× Performance at BCG"),
                       tags$p("'Delivered 10× performance increments for Fortune 500 organisations through applied ML.' Be specific: what was the baseline, what did you change, what was the constraint that made it hard, and how did you validate the 10×? This is a boldness story — non-obvious ML approach that sceptics doubted.")),
                   div(class = "framework-card",
                       tags$h5("Sub-10ms On-Device AR — A Bold Latency Bet"),
                       tags$p("Achieving sub-10ms on-device AR on Meta Quest with multi-modal sensor fusion is a genuinely hard engineering constraint. Prepare the story of the moment you committed to this SLO before knowing if it was achievable — that's the boldness moment."))
            ),
            column(6,
                   div(class = "section-heading-dark", "Write Your Boldness Story"),
                   div(class = "practice-area",
                       textAreaInput(ns("bold_story"), label = NULL, rows = 12,
                                     width = "100%",
                                     value =
"SITUATION: [Describe a moment where you proposed or committed to a
technically risky approach that others were sceptical of.]

For Atera: 'When I designed the real-time sensor fusion architecture,
I proposed using [specific approach] even though the team / client /
conventional wisdom suggested [alternative]. The risk was [specific]:
if [X] didn't work, [consequence].'

TASK: I committed to [the bold technical bet] despite [the uncertainty].

ACTION: [What did you do in the first 2 weeks to validate the bet?
Fast iteration. Prototype. Measurement. What failed first and how did
you adapt? This is the meta moment — iterating fast when uncertain.]

RESULT: [What worked? What didn't? What did you learn that changed
how you approach ML system design now?]"
                       ),
                       actionButton(ns("save_bold"), "Save Story", class = "btn-meta")
                   )
            )
          )
      )
    ),

    # ── Assessment ───────────────────────────────────
    fluidRow(
      box(title = "📊 Qualities Evidence Assessment", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(3, sliderInput(ns("q1_score"), "Ownership stories polished (0-10)", 0, 10, 7)),
            column(3, sliderInput(ns("q2_score"), "Flexibility stories ready (0-10)",  0, 10, 8)),
            column(3, sliderInput(ns("q3_score"), "Boldness stories ready (0-10)",     0, 10, 6)),
            column(3, sliderInput(ns("q4_score"), "L6 scope in every answer (0-10)",   0, 10, 5))
          ),
          actionButton(ns("assess"), "Calculate Readiness", class = "btn-meta"),
          br(), br(),
          uiOutput(ns("assessment_out"))
      )
    )
  )
}

qualities_profile_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$save_ownership, {
      prep_manager$save_note("qp_ownership", input$ownership_story)
      showNotification("Ownership story saved!", type = "message")
    })
    observeEvent(input$save_flex, {
      prep_manager$save_note("qp_flex", input$flex_story)
      showNotification("Flexibility story saved!", type = "message")
    })
    observeEvent(input$save_bold, {
      prep_manager$save_note("qp_bold", input$bold_story)
      showNotification("Boldness story saved!", type = "message")
    })

    observeEvent(input$assess, {
      avg <- mean(c(input$q1_score, input$q2_score, input$q3_score, input$q4_score))
      pct <- round(avg * 10)
      prep_manager$update_progress("qualities_profile", pct)
      output$assessment_out <- renderUI({
        colour <- progress_colour(pct)
        div(class = if (pct >= 70) "success-box" else "tip-box",
            tags$h4(style = paste0("color:", colour), paste0(pct, "% — Qualities Readiness")),
            if (input$q4_score < 7) div(class = "warn-box",
                HTML("⚠️ <strong>Critical for L6:</strong> Every ownership/flexibility/boldness story must end with an org-level impact statement, not just 'I built X'. Add: 'This changed how my team approaches Y', or 'This became the standard approach across Z teams'.")),
            if (pct >= 80) tags$p("✅ Strong evidence bank. Practise verbal delivery under 90-second constraint per story.")
        )
      })
    })
  })
}
