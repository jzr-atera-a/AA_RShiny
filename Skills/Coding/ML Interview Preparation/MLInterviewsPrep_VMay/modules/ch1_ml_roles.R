# modules/ch1_ml_roles.R
# Ch.1: Machine Learning Roles and the Interview Process

ch1_ml_roles_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
      tags$h1("Chapter 1 — ML Roles & the Interview Process"),
      tags$h2("Machine Learning Roles and the Interview Process — Susan Shu Chang"),
      div(
        span(class = "hero-badge", "ML Job Titles"),
        span(class = "hero-badge", "Three Pillars"),
        span(class = "hero-badge", "Skills Matrix"),
        span(class = "hero-badge", "Interview Loop"),
        span(class = "hero-badge", "Recruiter Screening")
      )
    ),

    # ── History & Job Titles ──────────────────────────────────────────────────
    fluidRow(
      box(title = "📖 Overview & History of ML Job Titles (Ch.1)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "success-box",
            HTML("<strong>Chang's framing:</strong> Before preparing for any ML interview, you must
                 understand what role you are actually applying for. The ML job market has evolved
                 dramatically — the same work is done under many different titles, and compensation
                 and interview difficulty vary enormously by label.")),
          br(),

          div(class = "framework-card",
            tags$h5("A Brief History of ML and Data Science Job Titles"),
            tags$p("The field has fragmented into specialisms over time."),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Era"), tags$th("Dominant Title"), tags$th("Primary focus"))),
              tags$tbody(
                tags$tr(tags$td("2010–2014"), tags$td("Data Scientist"),           tags$td("Statistical modelling, A/B testing, dashboards")),
                tags$tr(tags$td("2014–2017"), tags$td("ML Engineer"),              tags$td("Production ML pipelines, model serving")),
                tags$tr(tags$td("2017–2020"), tags$td("Applied Scientist"),        tags$td("Research + engineering hybrid, LLM fine-tuning")),
                tags$tr(tags$td("2020–now"),  tags$td("MLOps / ML Platform Eng"), tags$td("Infrastructure, training platforms, feature stores"))
              )
            )),

          div(class = "framework-card",
            tags$h5("Job Titles Requiring ML Experience"),
            tags$ul(
              tags$li(tags$b("Machine Learning Engineer (MLE):"), " builds and deploys production ML systems — coding + modelling + serving"),
              tags$li(tags$b("Data Scientist:"), " statistical analysis, experimentation, modelling — may or may not deploy"),
              tags$li(tags$b("Applied Scientist:"), " research-leaning MLE — publishes and productionises novel methods"),
              tags$li(tags$b("Research Scientist:"), " primarily research — papers, pre-training, novel architectures"),
              tags$li(tags$b("ML Platform / MLOps Engineer:"), " ML infrastructure — training clusters, feature stores, serving"),
              tags$li(tags$b("Data Engineer:"), " data pipelines, warehouses, ETL — ML-adjacent but not modelling"),
              tags$li(tags$b("AI Product Manager:"), " owns ML-powered product — technical enough to partner with MLE/DS")
            ))
      ),

      box(title = "🏗️ The Machine Learning Lifecycle (Ch.1)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("ML Lifecycle — How Teams are Structured"),
            tags$p("The same ML lifecycle plays out differently depending on company size."),
            timeline_entry("1", "Problem definition",
              "Business goal → ML objective. What are we predicting? What is the label? What is success?"),
            timeline_entry("2", "Data collection and labelling",
              "Identify data sources, build pipelines, label if needed, audit quality."),
            timeline_entry("3", "Feature engineering",
              "Transform raw signals into model-ready representations. Feature store if at scale."),
            timeline_entry("4", "Model development",
              "Baseline → experiment → iterate. Training infrastructure, hyperparameter search, evaluation."),
            timeline_entry("5", "Deployment and serving",
              "Package model, build API or batch job, integrate into product."),
            timeline_entry("6", "Monitoring and maintenance",
              "Track data drift, performance degradation, retraining triggers.")
          ),

          fluidRow(
            column(6,
              div(class = "framework-card",
                tags$h5("Startups — ML Lifecycle"),
                tags$ul(
                  tags$li(tags$b("One person, many hats:"), " a single MLE often owns the entire lifecycle"),
                  tags$li(tags$b("Speed over polish:"), " ship a working model fast; optimise later"),
                  tags$li(tags$b("Interview focus:"), " can you build end-to-end with minimal tooling?"),
                  tags$li(tags$b("What they value:"), " versatility, speed, ownership, no hand-holding")
                )
              )
            ),
            column(6,
              div(class = "framework-card",
                tags$h5("Larger ML Teams"),
                tags$ul(
                  tags$li(tags$b("Specialisation:"), " separate teams for data, features, training, serving, monitoring"),
                  tags$li(tags$b("Interview focus:"), " depth in one area + ability to collaborate across teams"),
                  tags$li(tags$b("What they value:"), " craft, scale, communication, cross-team influence"),
                  tags$li(tags$b("Levels:"), " L3/L4 = execution; L5 = ownership; L6+ = strategy + multiplying others")
                )
              )
            )
          )
      )
    ),

    # ── Three Pillars ─────────────────────────────────────────────────────────
    fluidRow(
      box(title = "🏛️ The Three Pillars of ML Roles (Ch.1)", status = "warning",
          solidHeader = TRUE, width = 12,

          div(class = "warn-box",
            HTML("<strong>⚠️ Chang's key framework:</strong> Every ML interview is testing you on
                 a combination of these three pillars. Knowing which pillar a question targets
                 — and which pillar is your weakest — lets you prep with precision.")),
          br(),

          fluidRow(
            column(4,
              div(class = "framework-card",
                tags$h5("Pillar 1 — ML Algorithms and Data Intuition: Ability to Adapt"),
                tags$p("Can you reason about data and models with deep intuition?"),
                tags$ul(
                  tags$li(tags$b("What it covers:"), " algorithm selection, bias-variance, regularisation, feature importance, evaluation metrics, domain-specific models (NLP, CV, RecSys, RL)"),
                  tags$li(tags$b("Tested by:"), " algorithm explanation questions, 'why would you use X vs Y', sample interview questions at end of Ch.3"),
                  tags$li(tags$b("Minimum bar:"), " can explain 10 algorithms with trade-offs; can define and justify evaluation metrics for a given task")
                ),
                div(class = "tip-box",
                  HTML("<strong>💡 Interview signal:</strong> Candidates who can say 'I would use
                       XGBoost here because the data is tabular with mixed types and latency
                       is a constraint — but I would start with a logistic regression baseline'
                       demonstrate Pillar 1 fluency."))
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Pillar 2 — Programming and Software Engineering: Ability to Build"),
                tags$p("Can you translate ML ideas into working, maintainable code?"),
                tags$ul(
                  tags$li(tags$b("What it covers:"), " Python fluency, data manipulation (pandas, numpy), coding algorithms from scratch, SQL, API design, Docker, version control, testing"),
                  tags$li(tags$b("Tested by:"), " coding screens, LeetCode-style problems, take-home exercises, SQL challenges"),
                  tags$li(tags$b("Minimum bar:"), " implement core ML algorithms without libraries; fluent pandas and numpy; write clean, readable code under time pressure")
                ),
                div(class = "tip-box",
                  HTML("<strong>💡 Interview signal:</strong> Writing code that handles edge cases,
                       uses appropriate data structures, and includes brief comments
                       signals engineering maturity beyond just getting the right answer."))
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Pillar 3 — Execution and Communication: Ability to Get Things Done in a Team"),
                tags$p("Can you ship ML projects in a real organisation with real constraints?"),
                tags$ul(
                  tags$li(tags$b("What it covers:"), " stakeholder communication, project scoping, ambiguity handling, cross-functional collaboration, prioritisation, presenting results to non-technical audiences"),
                  tags$li(tags$b("Tested by:"), " behavioural questions (Ch.7), system design discussions, take-home presentation, 'tell me about a project' deep-dives"),
                  tags$li(tags$b("Minimum bar:"), " can tell a structured STAR story for each competency; frames ML work in business impact terms")
                ),
                div(class = "tip-box",
                  HTML("<strong>💡 Interview signal:</strong> Volunteering constraints and trade-offs
                       unprompted — 'I chose this approach because the latency budget was 100ms
                       and we had limited labelled data' — demonstrates Pillar 3 thinking."))
              )
            )
          ),

          div(class = "framework-card",
            tags$h5("Clearing the Minimum Requirements in the Three ML Pillars"),
            tags$p("Chang is direct: you do not need to be exceptional in all three pillars. You need to clear the minimum bar in each, then excel in the one most relevant to the role."),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Role Type"), tags$th("Pillar 1 weight"), tags$th("Pillar 2 weight"), tags$th("Pillar 3 weight"))),
              tags$tbody(
                tags$tr(tags$td("ML Engineer"),         tags$td("High"),    tags$td("Very High"), tags$td("Medium")),
                tags$tr(tags$td("Data Scientist"),      tags$td("High"),    tags$td("Medium"),    tags$td("High")),
                tags$tr(tags$td("Applied Scientist"),   tags$td("Very High"), tags$td("High"),   tags$td("Medium")),
                tags$tr(tags$td("Research Scientist"),  tags$td("Very High"), tags$td("Medium"),  tags$td("Medium")),
                tags$tr(tags$td("MLOps Engineer"),      tags$td("Medium"),  tags$td("Very High"), tags$td("Medium")),
                tags$tr(tags$td("AI Product Manager"),  tags$td("Medium"),  tags$td("Low"),       tags$td("Very High"))
              )
            ))
      )
    ),

    # ── Skills Matrix & Interview Process ────────────────────────────────────
    fluidRow(
      box(title = "📊 ML Skills Matrix (Ch.1)", status = "primary",
          solidHeader = TRUE, width = 5,

          div(class = "framework-card",
            tags$h5("Machine Learning Skills Matrix"),
            tags$p("Chang introduces the ML Skills Matrix as a self-assessment and job-matching tool."),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Skill Area"), tags$th("Pillar"), tags$th("Self-rate 1–5"))),
              tags$tbody(
                tags$tr(tags$td("ML algorithm knowledge"),          tags$td(tags$span(class = "stage-pill", "P1")), tags$td("—")),
                tags$tr(tags$td("Statistics and probability"),      tags$td(tags$span(class = "stage-pill", "P1")), tags$td("—")),
                tags$tr(tags$td("Model evaluation and metrics"),    tags$td(tags$span(class = "stage-pill", "P1")), tags$td("—")),
                tags$tr(tags$td("Python / coding fluency"),         tags$td(tags$span(class = "stage-pill", "P2")), tags$td("—")),
                tags$tr(tags$td("Data wrangling (pandas, SQL)"),    tags$td(tags$span(class = "stage-pill", "P2")), tags$td("—")),
                tags$tr(tags$td("ML systems and deployment"),       tags$td(tags$span(class = "stage-pill", "P2")), tags$td("—")),
                tags$tr(tags$td("Communication and storytelling"),  tags$td(tags$span(class = "stage-pill", "P3")), tags$td("—")),
                tags$tr(tags$td("Project ownership and delivery"),  tags$td(tags$span(class = "stage-pill", "P3")), tags$td("—")),
                tags$tr(tags$td("Cross-functional collaboration"),  tags$td(tags$span(class = "stage-pill", "P3")), tags$td("—"))
              )
            )),

          div(class = "success-box",
            HTML("<strong>✅ How to use this matrix:</strong> Rate yourself honestly 1–5 on each row.
                 Your lowest-rated skills are your prep priorities — not your highest.
                 Use it again in Ch.2 to match your profile to specific job postings."))
      ),

      box(title = "🔄 The ML Job Interview Process (Ch.1)", status = "info",
          solidHeader = TRUE, width = 7,

          div(class = "framework-card",
            tags$h5("Introduction to ML Job Interviews"),
            tags$p("The ML interview process is longer and more varied than standard software engineering interviews.
                   Typical full process: 4–8 weeks, 3–7 interview rounds."),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Stage"), tags$th("Who"), tags$th("What they assess"), tags$th("Typical duration"))),
              tags$tbody(
                tags$tr(tags$td(tags$b("Application")),         tags$td("ATS / Recruiter"), tags$td("Resume keywords, experience level"),     tags$td("1–2 weeks")),
                tags$tr(tags$td(tags$b("Recruiter Screen")),    tags$td("Recruiter"),       tags$td("Role fit, salary expectations, basics"), tags$td("30 min")),
                tags$tr(tags$td(tags$b("Technical Screen")),    tags$td("Hiring Manager"),  tags$td("Coding + ML fundamentals"),              tags$td("45–60 min")),
                tags$tr(tags$td(tags$b("On-site / Final Loop")), tags$td("Panel (4–6)"),   tags$td("All pillars — depth + breadth"),          tags$td("4–6 hours")),
                tags$tr(tags$td(tags$b("Offer")),               tags$td("Recruiter"),       tags$td("Negotiation, decision"),                  tags$td("1–2 weeks"))
              )
            )),

          div(class = "framework-card",
            tags$h5("Three Application Channels — and Which Works Best"),
            tags$ul(
              tags$li(tags$b("Job boards (LinkedIn, Indeed, Greenhouse):"), " highest volume, lowest conversion — ATS filters heavily. Use for awareness and tracking."),
              tags$li(tags$b("Company careers pages:"), " apply directly — avoids some aggregator filters. Research the team first."),
              tags$li(tags$b("Referrals:"), " highest conversion by far. A referral from a current employee moves your application to the top of the pile and bypasses ATS.")
            ),
            div(class = "warn-box",
              HTML("<strong>⚠️ Chang's rule:</strong> Spend 20% of your application time on
                   job boards and 80% on referral generation and networking.
                   The conversion rate difference is that large."))),

          div(class = "framework-card",
            tags$h5("Pre-Interview Checklist — Before Every Interview"),
            tags$ul(
              tags$li(tags$b("Research the company:"), " ML blog, recent papers, product releases, engineering blog posts"),
              tags$li(tags$b("Research the team:"), " LinkedIn profiles of interviewers — note their background"),
              tags$li(tags$b("Review the job description:"), " map every requirement to an example from your experience"),
              tags$li(tags$b("Prepare your 3 stories:"), " success, failure, and cross-functional collaboration — STAR ready"),
              tags$li(tags$b("Technical warm-up:"), " solve 2–3 LeetCode problems the day before to get into flow state"),
              tags$li(tags$b("Logistics:"), " test the video link, charge your laptop, have water ready")
            )),

          div(class = "framework-card",
            tags$h5("Recruiter Screening — What to Expect"),
            tags$ul(
              tags$li(tags$b("Tell me about yourself:"), " 90-second career summary ending at 'why this role now'"),
              tags$li(tags$b("Why this company:"), " specific reasons — product, team, technical challenge — not 'great culture'"),
              tags$li(tags$b("Salary expectations:"), " research market rates first; give a range anchored high"),
              tags$li(tags$b("Timeline:"), " be honest about other interviews in progress — gives you negotiation leverage"),
              tags$li(tags$b("Red flags to avoid:"), " speaking negatively about previous employers, vague answers, inability to articulate why this specific role")
            )),

          div(class = "framework-card",
            tags$h5("Overview of the Main Interview Loop"),
            tags$ul(
              tags$li(tags$b("Coding round (Pillar 2):"), " LeetCode-style or data manipulation — 45–60 min"),
              tags$li(tags$b("ML algorithms round (Pillar 1):"), " algorithm explanation, trade-offs, metrics — 45–60 min"),
              tags$li(tags$b("ML system design (Pillar 1+2):"), " open-ended production system design — 45–60 min"),
              tags$li(tags$b("Behavioural rounds (Pillar 3):"), " STAR questions, leadership, cross-functional — 2–3 rounds"),
              tags$li(tags$b("Hiring manager round:"), " vision alignment, role expectations, growth — 30–45 min")
            ))
      )
    ),

    # ── Practice ─────────────────────────────────────────────────────────────
    fluidRow(
      box(title = "✍️ Practice: Self-Assessment Against the Three Pillars", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              div(class = "section-heading-dark", "Rate your Three Pillars"),
              sliderInput(ns("p1_score"), "Pillar 1 — ML Algorithms & Data Intuition", 0, 10, 5),
              sliderInput(ns("p2_score"), "Pillar 2 — Programming & Software Engineering", 0, 10, 5),
              sliderInput(ns("p3_score"), "Pillar 3 — Execution & Communication", 0, 10, 5),
              selectInput(ns("target_role"), "Target role:",
                choices = c("ML Engineer", "Data Scientist", "Applied Scientist",
                            "Research Scientist", "MLOps Engineer", "AI Product Manager")),
              actionButton(ns("save_ch1"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8,
              br(),
              uiOutput(ns("ch1_feedback"))
            )
          )
      )
    )
  )
}

ch1_ml_roles_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_ch1, {
      p1 <- input$p1_score
      p2 <- input$p2_score
      p3 <- input$p3_score
      avg <- mean(c(p1, p2, p3))
      pct <- round(avg * 10)
      prep_manager$update_progress("ch1_ml_roles", pct)

      output$ch1_feedback <- renderUI({
        weakest <- which.min(c(p1, p2, p3))
        pillar_names <- c("Pillar 1 (ML Algorithms)", "Pillar 2 (Coding)", "Pillar 3 (Communication)")
        div(class = if (pct >= 60) "success-box" else "tip-box",
          tags$h3(style = paste0("color:", progress_colour(pct), ";font-size:2em;font-weight:800;"),
            paste0(pct, "% — Three Pillars Baseline")),
          tags$p(tags$b(paste0("Weakest pillar: ", pillar_names[weakest], " — prioritise this in your prep."))),
          if (p1 < 6) tags$p("📌 Pillar 1: Study Ch.3 (ML Algorithms) and Ch.4 (Model Training)"),
          if (p2 < 6) tags$p("📌 Pillar 2: Study Ch.5 (Coding) — aim for 30+ LeetCode + pandas/SQL fluency"),
          if (p3 < 6) tags$p("📌 Pillar 3: Study Ch.7 (Behavioural) — prepare 8 STAR stories with quantified results"),
          tags$p(tags$b("Role selected:"), paste0(" ", input$target_role, " — weight your prep accordingly using the pillar table above."))
        )
      })
      showNotification("Ch.1 Three Pillars assessment saved!", type = "message")
    })
  })
}
