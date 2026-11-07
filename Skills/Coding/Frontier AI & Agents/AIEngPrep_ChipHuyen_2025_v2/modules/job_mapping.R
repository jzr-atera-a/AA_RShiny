# modules/job_mapping.R
# Dedicated tab: A1 (seeded by BJAK) context + JD bullet <-> book chapter/page cross-reference

job_mapping_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("A1 Job Mapping"),
        tags$h2("VP of Research, Machine Learning — A1 (independent AI startup seeded with US$100M by BJAK)"),
        div(
          span(class = "hero-badge", "Full time · London (remote/hybrid)"),
          span(class = "hero-badge", "Assessments run via BJAK talent systems"),
          span(class = "hero-badge", "Proactive AI assistant product")
        )
    ),

    fluidRow(
      box(title = "🏢 Company & Product Context", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(6,
                   div(class = "framework-card",
                       tags$h5("The company"),
                       tags$p("A1 is an independent AI startup seeded with US$100M by BJAK. A1 runs the product and hiring bar; BJAK's talent systems currently handle assessments and scheduling — worth noting explicitly if asked about reporting lines or process in an early screen.")),
                   div(class = "framework-card",
                       tags$h5("The product"),
                       tags$p("A proactive, AI-native smart assistant sitting on top of everyday tools (email, notes, tasks) for 5B+ users who are still on non-AI-native apps. Goal: minimal-prompting task completion — conversations, errands, organising, workflows — with a target of >90% time reduction on daily tasks."))
            ),
            column(6,
                   div(class = "framework-card",
                       tags$h5("The core engineering problem"),
                       tags$p("High reliability for long-running, multi-step workflows with persistent context, external tool use, and real-world task completion — despite foundation models being fundamentally non-deterministic. This is precisely the gap between a model and a production AI system that the book is written to close.")),
                   div(class = "framework-card",
                       tags$h5("The team"),
                       tags$p("Small, high talent-density, founder-mode team; collective decision-making; hands-on VP role (not a large-org research manager role) — own the research/intelligence direction directly."))
            )
          )
      )
    ),

    fluidRow(
      box(title = "🔗 JD Requirement ↔ Book Chapter Cross-Reference", status = "info", solidHeader = TRUE, width = 12,
          tags$table(class = "table table-hover",
            tags$thead(tags$tr(
              tags$th("JD Requirement"), tags$th("Book Chapter(s)"), tags$th("Page Range"), tags$th("Why It Matches")
            )),
            tags$tbody(
              tags$tr(tags$td(tags$b("Context representation, memory, reasoning, planning, orchestration")), tags$td(tags$span(class="stage-pill","Ch. 6")), tags$td("253–306"), tags$td("RAG architecture & retrieval, agent tool use/planning/failure modes, and memory systems are the chapter's core sections.")),
              tags$tr(tags$td(tags$b("Design new architectures vs. adapt/leverage frontier models")), tags$td(tags$span(class="stage-pill","Ch. 4")), tags$td("159–210"), tags$td("The build-vs-buy model selection framework is the central decision tool of this chapter.")),
              tags$tr(tags$td(tags$b("Evaluation frameworks for real-world usefulness, robustness, safety — not benchmark vanity")), tags$td(tags$span(class="stage-pill","Ch. 3 & 4")), tags$td("113–210"), tags$td("Two full chapters move from public leaderboard metrics to custom, production-grade evaluation pipelines.")),
              tags$tr(tags$td(tags$b("Alignment, safety, and guardrail strategy as first-class concerns")), tags$td(tags$span(class="stage-pill","Ch. 5 & 10")), tags$td("211–252, 449–494"), tags$td("Defensive prompting (jailbreaks, injection, defenses) plus guardrails as an architectural layer, not an afterthought.")),
              tags$tr(tags$td(tags$b("Reliability under non-deterministic model behaviour")), tags$td(tags$span(class="stage-pill","Ch. 2")), tags$td("49–112"), tags$td("A dedicated section on the probabilistic nature of AI and its downstream engineering implications.")),
              tags$tr(tags$td(tags$b("Frontier techniques: RAG, MoE, distillation, multi-agent, multimodal")), tags$td(tags$span(class="stage-pill","Ch. 2, 6, 8")), tags$td("49–112, 253–306, 363–404"), tags$td("Architecture/MoE in Ch. 2, RAG & agents in Ch. 6, distillation & data synthesis in Ch. 8.")),
              tags$tr(tags$td(tags$b("Production reliability, long-running workflows, real-world deployment")), tags$td(tags$span(class="stage-pill","Ch. 9 & 10")), tags$td("405–494"), tags$td("Inference optimization, architecture patterns (routers, caching, agent patterns), monitoring, and user feedback design.")),
              tags$tr(tags$td(tags$b("Builder's mindset, not just publishing/benchmarks")), tags$td(tags$span(class="stage-pill","Ch. 1")), tags$td("1–48"), tags$td("Frames the whole book around shipping applications with foundation models, not research-for-its-own-sake."))
            )
          )
      )
    ),

    fluidRow(
      box(title = "✅ Requirements Checklist Self-Assessment", status = "success", solidHeader = TRUE, width = 6,
          checkboxGroupInput(ns("reqs_check"), label = NULL, choices = c(
            "Deep experience building/evolving production ML systems",
            "Strong judgment on model behaviour, failure modes, long-horizon trade-offs",
            "Builder's mindset — systems that work, not just ideas",
            "Comfortable with irreversible/high-impact decisions, incomplete info",
            "Obsession with evaluation, correctness, behaviour-over-time",
            "High ownership — operate as a founder, not a manager",
            "Python / PyTorch / JAX hands-on",
            "GPU-based training & inference systems experience"
          )),
          uiOutput(ns("reqs_feedback"))
      ),
      box(title = "📝 Your A1-Specific Narrative", status = "warning", solidHeader = TRUE, width = 6,
          div(class = "tip-box", HTML("<strong>💡 Prompt:</strong> Draft a 3–4 sentence answer to: \"Walk me through a time you owned a high-impact, irreversible decision with incomplete information in a production ML system.\"")),
          textAreaInput(ns("narrative"), label = NULL, rows = 8, width = "100%",
                        placeholder = "Situation → Decision → Trade-off you accepted → Outcome / what you'd do differently"),
          actionButton(ns("save_narrative"), "Save Narrative", class = "btn-meta", width = "100%"),
          uiOutput(ns("narrative_feedback"))
      )
    )
  )
}

job_mapping_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    output$reqs_feedback <- renderUI({
      n <- length(input$reqs_check)
      pct <- round(n / 8 * 100)
      prep_manager$update_progress("job_mapping", pct)
      div(class = if (pct >= 75) "success-box" else "tip-box",
          tags$b(paste0(n, " / 8 requirements checked (", pct, "%)")))
    })

    observeEvent(input$save_narrative, {
      notes <- input$narrative
      score <- 0
      if (grepl("situation|context|system|product", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("decision|chose|trade.?off|irreversible", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("data|latency|risk|constraint|evaluat", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("outcome|result|impact|learn|next time", notes, ignore.case = TRUE)) score <- score + 25

      prep_manager$save_note("job_mapping_narrative", notes)
      prep_manager$add_practice_score("job_mapping", score, "A1 narrative")

      output$narrative_feedback <- renderUI({
        div(class = if (score >= 75) "success-box" else "tip-box",
            tags$h5(paste0("Narrative Score: ", score, "/100")),
            if (score < 100) tags$p("Structure it as Situation → Decision/Trade-off → Constraints considered → Outcome. That maps directly onto \"comfortable making irreversible decisions with incomplete information.\"")
        )
      })
      showNotification("Narrative saved!", type = "message")
    })
  })
}
