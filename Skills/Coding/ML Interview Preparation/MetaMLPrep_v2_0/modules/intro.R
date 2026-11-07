# modules/intro.R
# Tab 1: Welcome & Overview - Meta ML Interview Prep
# Covers PDF pages 1-6: Welcome, Mission, Interview Practice, Tips, Full Loop

intro_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # ── Hero Banner ──────────────────────────────────
    div(class = "meta-hero",
        tags$img(
          src   = "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Meta_Platforms_Inc._logo.svg/320px-Meta_Platforms_Inc._logo.svg.png",
          style = "height:48px;margin-bottom:16px;"
        ),
        tags$h1("Software Engineer (Leadership)"),
        tags$h2("Machine Learning — Interview Preparation Suite"),
        div(
          span(class = "hero-badge", icon("calendar"), " 2026"),
          span(class = "hero-badge", icon("brain"),    " AI/ML Focus"),
          span(class = "hero-badge", icon("users"),    " Leadership Track"),
          span(class = "hero-badge", icon("code"),     " 5 Interview Rounds")
        )
    ),
    
    # ── Overall Progress ─────────────────────────────
    fluidRow(
      box(title = "🎯 Your Overall Readiness", status = "primary",
          solidHeader = TRUE, width = 12,
          fluidRow(
            column(2, div(class="metric-card", span(class="metric-value", textOutput(ns("pct_overall"))), span(class="metric-label","Overall Score"))),
            column(2, div(class="metric-card", span(class="metric-value","5"),    span(class="metric-label","Interview Rounds"))),
            column(2, div(class="metric-card", span(class="metric-value","2×45m"), span(class="metric-label","ML Design Time"))),
            column(2, div(class="metric-card", span(class="metric-value","1877"), span(class="metric-label","Meta Stock NASDAQ"))),
            column(2, div(class="metric-card", span(class="metric-value","3.1B"),  span(class="metric-label","DAU Across Apps"))),
            column(2, div(class="metric-card", span(class="metric-value","~25"),   span(class="metric-label","SWE L6+ Band")))
          ),
          br(),
          uiOutput(ns("tab_progress_bars"))
      )
    ),
    
    # ── Meta Mission & Culture ────────────────────────
    fluidRow(
      box(title = "🌍 Meta's Mission & Culture (Know This Cold)",
          status = "primary", solidHeader = TRUE, width = 6,
          
          div(class = "section-heading", "The Mission"),
          p("Give people the power to build community and bring the world closer together."),
          
          fluidRow(
            column(4, div(class="framework-card",
                          tags$h5(icon("bolt"), " Move Fast"),
                          tags$p("Ship quickly. Small nimble teams. Don't let perfect be the enemy of good. Move fast with stable infrastructure."))),
            column(4, div(class="framework-card",
                          tags$h5(icon("fire"), " Be Bold"),
                          tags$p("Take on the hardest problems. Tackle complex global challenges. Embrace uncertainty, take risks, learn from failure."))),
            column(4, div(class="framework-card",
                          tags$h5(icon("user"), " Be Yourself"),
                          tags$p("Authentic culture. Diverse perspectives. Positive environment. Everyone belongs regardless of background.")))
          ),
          
          div(class="tip-box",
              HTML("<strong>💡 Interview tip:</strong> Weave 'Move Fast' and 'Be Bold' into your answers naturally. E.g., 'I shipped an MVP in 2 weeks to validate the hypothesis before investing more engineering time.' "))
      ),
      
      box(title = "🗓️ Your 5-Round Interview Loop",
          status = "info", solidHeader = TRUE, width = 6,
          
          timeline_entry("1","Technical Project / Retrospective (45 min)",
                         "Deep dive into one past ML system you owned end-to-end. Architecture, tradeoffs, failures."),
          timeline_entry("2","Coding Interview (45 min)",
                         "1-2 algorithm / data structure problems in CoderPad. Focus on clarity and correctness."),
          timeline_entry("3","Cross-Functional XFN Partnership (45 min)",
                         "Stories of working cross-org: PM, Design, Research, Infra. Conflicts, alignment, influence."),
          timeline_entry("4","ML Design Interview × 2 (2 × 45 min)",
                         "THE key differentiator. Ranking/recommendation systems, CV pipelines, entity matching, LLM serving."),
          timeline_entry("5","Career / Leadership Conversation (45 min)",
                         "Leadership style, mentorship, org impact, conflict resolution, technical direction setting."),
          
          div(class="success-box",
              HTML("<strong>✅ Leadership Track note:</strong> At L6+, every answer should demonstrate system-level thinking, org influence, and engineering judgment — not just individual contribution."))
      )
    ),
    
    # ── Interview Practice Resources ─────────────────
    fluidRow(
      box(title = "📚 Meta-Recommended Study Resources", status = "info",
          solidHeader = TRUE, width = 6,
          
          div(class="section-heading-dark", "Coding & Algorithms"),
          tags$ul(
            tags$li(tags$b("Meta Coding Portal"), " — official practice environment"),
            tags$li(tags$b("GeeksforGeeks"), " — algorithms, data structures"),
            tags$li(tags$b("Cracking the Coding Interview"), " — Gayle McDowell (essential)"),
            tags$li(tags$b("Career Cup"), " — community solutions"),
            tags$li(tags$b("LeetCode"), " — Meta tag filter (Top 50)"),
            tags$li(tags$b("CodeChef / Project Euler"), " — advanced problem solving")
          ),
          
          div(class="section-heading-dark", "ML & System Design"),
          tags$ul(
            tags$li(tags$b("Design a Recommendation System"), " — Meta Engineering Blog"),
            tags$li(tags$b("Machine Learning System Design"), " — Chip Huyen's book"),
            tags$li(tags$b("Grokking the System Design Interview"), " — Educative.io"),
            tags$li(tags$b("Build an Activity Feed"), " — Meta Engineering case study"),
            tags$li(tags$b("Papers With Code"), " — Meta AI research papers"),
            tags$li(tags$b("Machine Learning Interview Questions"), " — Meta format")
          ),
          
          div(class="section-heading-dark", "Leadership & Org"),
          tags$ul(
            tags$li(tags$b("GitHub Systems Design Primer")),
            tags$li(tags$b("HiredInTech"), " — ML system design patterns"),
            tags$li(tags$b("Staff Engineer"), " — Will Larson (leadership book)"),
            tags$li(tags$b("An Elegant Puzzle"), " — Will Larson (Eng Management)")
          )
      ),
      
      box(title = "⚡ Top Interview Tips — Direct From Meta",
          status = "warning", solidHeader = TRUE, width = 6,
          
          div(class="section-heading-dark", "During the Interview"),
          
          div(class="framework-card",
              tags$h5("1. Think Out Loud — Always"),
              tags$p("Interviewers evaluate how you approach problems. Silence is worse than a wrong direction. Narrate your reasoning at every step.")),
          
          div(class="framework-card",
              tags$h5("2. Create a Working Solution First"),
              tags$p("Build a correct but potentially inefficient solution, then iterate. Don't aim for elegant code first — aim for working code.")),
          
          div(class="framework-card",
              tags$h5("3. Take Hints — Don't Ignore Them"),
              tags$p("When the interviewer redirects you, treat it as a gift. Say 'That's a great point — let me consider that approach.' Adjust immediately.")),
          
          div(class="framework-card",
              tags$h5("4. Pace Yourself — 45 Minutes is Short"),
              tags$p("Budget your time. For ML Design: 5 min problem clarification, 10 min framing, 25 min design, 5 min wrap-up.")),
          
          div(class="framework-card",
              tags$h5("5. Own the Design — Drive the Conversation"),
              tags$p("For ML Design: don't just answer their questions. Lead. Show you've built these systems before. Bring real constraints.")),
          
          div(class="tip-box",
              HTML("<strong>💡 Golden rule:</strong> If you can't explain your solution clearly in 5 minutes, it's too complex. Simplify."))
      )
    ),
    
    # ── 2026 Meta Context ─────────────────────────────
    fluidRow(
      box(title = "🔮 Meta in 2026 — What You Must Know",
          status = "primary", solidHeader = TRUE, width = 12,
          
          fluidRow(
            column(4,
                   div(class="section-heading-dark", "AI/ML Priority Areas"),
                   tags$ul(
                     tags$li(tags$b("Llama 4+"), " — open-source LLM ecosystem, fine-tuning at scale"),
                     tags$li(tags$b("Meta AI Assistant"), " — cross-app AI integration (WhatsApp, Instagram, Messenger, FB)"),
                     tags$li(tags$b("Recommendation Systems"), " — Feed ranking, Reels, Ads — still the monetisation engine"),
                     tags$li(tags$b("AR/VR + Horizon"), " — ML for computer vision, spatial computing"),
                     tags$li(tags$b("PyTorch 2.x"), " — Meta-maintained, industry standard"),
                     tags$li(tags$b("FAIR Research"), " — Segment Anything, ImageBind, DINOv2")
                   )
            ),
            column(4,
                   div(class="section-heading-dark", "Infrastructure & Scale"),
                   tags$ul(
                     tags$li(tags$b("Disaggregated serving"), " — billions of inference calls/day"),
                     tags$li(tags$b("MTIA chip"), " — Meta Training and Inference Accelerator (in-house silicon)"),
                     tags$li(tags$b("FBLearner / Chronos"), " — internal ML platform for training pipelines"),
                     tags$li(tags$b("Presto / Spark / Scuba"), " — data infra at 3+ exabyte scale"),
                     tags$li(tags$b("Privacy-preserving ML"), " — differential privacy, federated learning")
                   )
            ),
            column(4,
                   div(class="section-heading-dark", "Leadership Priorities 2026"),
                   tags$ul(
                     tags$li(tags$b("Efficiency Year → Impact Year"), " — 2023 Year of Efficiency, now rebuilding bold investments"),
                     tags$li(tags$b("Year of AI"), " — Zuckerberg committed to embedding AI across all surfaces"),
                     tags$li(tags$b("Long-term bets"), " — AR glasses (Orion), neural interfaces (EMG wristband)"),
                     tags$li(tags$b("Flat org"), " — ICs expected to operate like owners, not just executors"),
                     tags$li(tags$b("L6+ scope"), " — drive technical strategy for a team/org, mentor L4/L5")
                   )
            )
          ),
          
          div(class = "warn-box",
              HTML("<strong>⚠️ Leadership track expectation:</strong> At L6 (Staff Equivalent), you are expected to identify problems before they're assigned, propose solutions at the org level, and influence technical direction beyond your immediate team. Frame every answer with this lens."))
      )
    ),
    
    # ── Quick Checklist ───────────────────────────────
    fluidRow(
      box(title = "✅ Pre-Interview Checklist",
          status = "success", solidHeader = TRUE, width = 12,
          
          fluidRow(
            column(6,
                   div(class="section-heading-dark", "Story Bank (prepare these NOW)"),
                   checkboxGroupInput(ns("stories_checklist"), label = NULL,
                                      choices = c(
                                        "End-to-end ML system I own with full stack depth",
                                        "A model I shipped that had measurable business impact",
                                        "A technical decision I made under uncertainty (tradeoffs)",
                                        "A time I disagreed with leadership but aligned",
                                        "A cross-functional project I drove across PM/Research/Infra",
                                        "A team member whose career I fundamentally improved",
                                        "A project that failed and what I learned",
                                        "How I've influenced technical direction beyond my team",
                                        "A time I identified a problem before being asked to"
                                      )),
                   br(),
                   actionButton(ns("save_checklist"), "Save Progress",
                                class = "btn-meta", icon = icon("save"))
            ),
            column(6,
                   div(class="section-heading-dark", "Technical Topics to Review"),
                   checkboxGroupInput(ns("tech_checklist"), label = NULL,
                                      choices = c(
                                        "Recommendation & ranking system design (two-tower, DLRM)",
                                        "Large-scale feature engineering & embedding tables",
                                        "Online vs offline evaluation metrics for ML",
                                        "Transformer architecture & attention mechanisms",
                                        "Distributed training: data parallelism, model parallelism",
                                        "A/B testing & experimentation at scale",
                                        "Model serving: latency, throughput, SLO, caching",
                                        "Data pipelines: streaming (Kafka) vs batch (Spark)",
                                        "Fairness, bias, and responsible AI considerations",
                                        "LLM fine-tuning: LoRA, RLHF, instruction tuning"
                                      )),
                   br(),
                   uiOutput(ns("checklist_status"))
            )
          )
      )
    )
  )
}

intro_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Overall progress
    output$pct_overall <- renderText({
      prep_manager$progress_trigger()
      paste0(prep_manager$get_overall_progress(), "%")
    })
    
    # Per-tab progress bars
    output$tab_progress_bars <- renderUI({
      prep_manager$progress_trigger()
      tabs <- list(
        list(id="qualities",       label="Engineer Qualities"),
        list(id="coding_interview",label="Coding Interview"),
        list(id="ml_design",       label="ML Design"),
        list(id="tech_project",    label="Technical Project"),
        list(id="cross_functional",label="Cross-Functional"),
        list(id="career_interview",label="Career Interview")
      )
      bars <- lapply(tabs, function(t) {
        pct <- prep_manager$get_progress(t$id)
        col <- progress_colour(pct)
        fluidRow(
          column(3, tags$small(tags$b(t$label))),
          column(7, div(style="background:#e5e7eb;border-radius:6px;height:14px;",
                        div(style=paste0("width:",pct,"%;background:",col,
                                         ";border-radius:6px;height:14px;transition:width 0.5s;")))),
          column(2, tags$small(paste0(pct, "%")))
        )
      })
      do.call(tagList, bars)
    })
    
    # Checklist save
    observeEvent(input$save_checklist, {
      n_stories <- length(input$stories_checklist)
      n_tech    <- length(input$tech_checklist)
      total     <- n_stories + n_tech
      pct       <- round(total / (9 + 10) * 100)
      prep_manager$update_progress("intro", pct)
      showNotification(paste0("Saved! ", n_stories, " stories + ", n_tech,
                              " tech topics checked."), type = "message")
    })
    
    output$checklist_status <- renderUI({
      n_stories <- length(input$stories_checklist)
      n_tech    <- length(input$tech_checklist)
      div(class = "success-box",
          tags$b(paste0("Stories ready: ", n_stories, "/9")), tags$br(),
          tags$b(paste0("Tech topics covered: ", n_tech, "/10")), tags$br(),
          tags$small("Aim for 100% before your interview day."))
    })
  })
}
