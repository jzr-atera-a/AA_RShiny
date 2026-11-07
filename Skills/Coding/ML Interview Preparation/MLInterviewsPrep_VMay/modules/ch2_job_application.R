# modules/ch2_job_application.R
# Ch.2: Machine Learning Job Application and Resume

ch2_job_application_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
      tags$h1("Chapter 2 — ML Job Application & Resume"),
      tags$h2("Machine Learning Job Application and Resume — Susan Shu Chang"),
      div(
        span(class = "hero-badge", "Where Are the Jobs"),
        span(class = "hero-badge", "Referrals & Networking"),
        span(class = "hero-badge", "Resume Guide"),
        span(class = "hero-badge", "ATS & Formatting"),
        span(class = "hero-badge", "Tracking Applications")
      )
    ),

    # ── Where Are the Jobs & Application Guide ────────────────────────────────
    fluidRow(
      box(title = "🔍 Where Are the Jobs? (Ch.2)", status = "primary",
          solidHeader = TRUE, width = 5,

          div(class = "framework-card",
            tags$h5("Best Channels for Finding ML Roles"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Channel"), tags$th("Conversion"), tags$th("Best for"))),
              tags$tbody(
                tags$tr(tags$td(tags$b("LinkedIn")),          tags$td(tags$span(class = "stage-pill", "Medium")),  tags$td("Networking, referrals, recruiter inbound")),
                tags$tr(tags$td(tags$b("Company careers")),   tags$td(tags$span(class = "stage-pill", "Medium")),  tags$td("Direct applications, avoids aggregator filters")),
                tags$tr(tags$td(tags$b("Referrals")),         tags$td(tags$span(class = "stage-pill", "High")),    tags$td("Highest conversion — bypasses ATS entirely")),
                tags$tr(tags$td(tags$b("Job boards")),        tags$td(tags$span(class = "stage-pill", "Low")),     tags$td("Volume and market awareness")),
                tags$tr(tags$td(tags$b("ML conferences")),    tags$td(tags$span(class = "stage-pill", "High")),    tags$td("Research roles, applied scientist positions")),
                tags$tr(tags$td(tags$b("Recruiters")),        tags$td(tags$span(class = "stage-pill", "Medium")),  tags$td("Senior+ roles, passive candidates"))
              )
            )),

          div(class = "framework-card",
            tags$h5("Your Effectiveness per Application"),
            tags$p("Chang introduces the concept of application ROI — not all applications are equal."),
            tags$ul(
              tags$li(tags$b("Cold application (job board):"), " ~3–8% to recruiter screen. High volume needed."),
              tags$li(tags$b("Direct company apply:"), " ~8–15% to recruiter screen. Research the team first."),
              tags$li(tags$b("Warm referral:"), " ~30–60% to recruiter screen. This is where to invest time."),
              tags$li(tags$b("Strong referral (friend/colleague):"), " ~50–70% to recruiter screen.")
            ),
            div(class = "warn-box",
              HTML("<strong>⚠️ Chang's math:</strong> Sending 50 cold applications and getting 2 screens
                   takes the same time as securing 2 referrals — and the referral path leads to better
                   roles with better offer outcomes. Prioritise quality over quantity.")))
      ),

      box(title = "🤝 Job Referrals and Networking (Ch.2)", status = "info",
          solidHeader = TRUE, width = 7,

          div(class = "framework-card",
            tags$h5("Job Referrals — How to Get Them"),
            tags$p("A referral does not require a close friend at the company. It requires a professional connection willing to submit a form."),
            tags$ul(
              tags$li(tags$b("LinkedIn warm outreach:"), " message second-degree connections at target companies — be specific about the role and why you are reaching out"),
              tags$li(tags$b("Alumni networks:"), " university alumni are disproportionately likely to help — always mention the connection"),
              tags$li(tags$b("ML community:"), " Kaggle, open source contributions, Discord/Slack ML communities — build relationships before you need them"),
              tags$li(tags$b("Past colleagues:"), " former managers and teammates who moved to target companies are the highest-value outreach"),
              tags$li(tags$b("Referral message template:"), " 'Hi [Name], I am applying for [Role] at [Company] — I noticed your background in [relevant area]. Would you be willing to submit a referral? Happy to share my resume and a brief summary of why I am a good fit.'")
            )),

          div(class = "framework-card",
            tags$h5("Networking — Beyond Immediate Job Applications"),
            tags$ul(
              tags$li(tags$b("Industry events:"), " NeurIPS, ICML, ICLR, local ML meetups — introduce yourself and follow up on LinkedIn"),
              tags$li(tags$b("Online presence:"), " a GitHub with clean ML projects, a technical blog, or a Kaggle profile increases inbound recruiter contact"),
              tags$li(tags$b("Informational interviews:"), " ask for 20-minute calls — not to ask for a job, but to learn about a team or company. Referrals often emerge naturally"),
              tags$li(tags$b("Give before you take:"), " share useful resources, comment on others' posts, contribute to open source. Network as a long-term investment, not a transactional ATM")
            )),

          div(class = "tip-box",
            HTML("<strong>💡 Chang's networking rule:</strong> The best time to build your ML network
                 is 6–12 months before you need it. Start now, even if you are not actively
                 looking — the connections you build today are the referrals of tomorrow."))
      )
    ),

    # ── Resume Guide ──────────────────────────────────────────────────────────
    fluidRow(
      box(title = "📄 Machine Learning Resume Guide (Ch.2)", status = "warning",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(3,
              div(class = "framework-card",
                tags$h5("Step 1 — Take Inventory of Your Past Experience"),
                tags$p("Before writing a single bullet, catalogue everything."),
                tags$ul(
                  tags$li(tags$b("Projects:"), " every ML project — academic, professional, personal, open source"),
                  tags$li(tags$b("Tools and frameworks:"), " Python, PyTorch, TensorFlow, sklearn, SQL, Spark, Docker — list all"),
                  tags$li(tags$b("Algorithms deployed:"), " which models have you put into production? At what scale?"),
                  tags$li(tags$b("Business impact:"), " for each project — what metric moved? By how much?"),
                  tags$li(tags$b("Team context:"), " what was your specific individual contribution vs the team's?")
                )
              )
            ),
            column(3,
              div(class = "framework-card",
                tags$h5("Step 2 — Overview of Resume Sections"),
                tags$ul(
                  tags$li(tags$b("Header:"), " name, email, LinkedIn, GitHub — no photo, no address"),
                  tags$li(tags$b("Summary (optional):"), " 2–3 sentences for career changers or those with non-linear paths"),
                  tags$li(tags$b("Experience:"), " reverse chronological, 3–5 bullet points per role — results-led"),
                  tags$li(tags$b("Skills:"), " grouped by category — Languages, Frameworks, Tools, Cloud. Not a keyword dump."),
                  tags$li(tags$b("Education:"), " degree, institution, graduation year — GPA only if 3.5+"),
                  tags$li(tags$b("Projects:"), " 2–3 impactful projects with GitHub links — especially for new graduates")
                )
              )
            ),
            column(3,
              div(class = "framework-card",
                tags$h5("Step 3 — Tailoring Your Resume to Desired Roles"),
                tags$ul(
                  tags$li(tags$b("Read the job description carefully:"), " extract the 5–7 most important keywords"),
                  tags$li(tags$b("Mirror the language:"), " if the JD says 'model deployment' use that exact phrase — not 'productionisation'"),
                  tags$li(tags$b("Reorder bullets:"), " put the most relevant bullets first — recruiters scan the first line per role"),
                  tags$li(tags$b("Adjust skills section:"), " move the most relevant technologies to the top of each category"),
                  tags$li(tags$b("Customise the summary:"), " if you have one, make it role-specific")
                ),
                div(class = "tip-box",
                  HTML("<strong>💡 ATS tip:</strong> Use the exact phrases from the job description —
                       ATS systems do exact-match keyword filtering before a human ever sees your resume."))
              )
            ),
            column(3,
              div(class = "framework-card",
                tags$h5("Step 4 — Final Resume Touch-ups"),
                tags$ul(
                  tags$li(tags$b("One page rule:"), " enforced unless you have 10+ years experience"),
                  tags$li(tags$b("Consistent formatting:"), " same font, same bullet style, same date format throughout"),
                  tags$li(tags$b("Action verbs:"), " Built, Deployed, Designed, Reduced, Improved, Trained, Automated"),
                  tags$li(tags$b("Quantify everything:"), " 'improved model accuracy' → 'improved F1 from 0.72 to 0.89 on 2M-example test set'"),
                  tags$li(tags$b("No objectives:"), " replace 'Seeking a challenging role...' with a skills summary or remove entirely"),
                  tags$li(tags$b("Proofread:"), " spell check, then read backwards to catch typos")
                )
              )
            )
          )
      )
    ),

    # ── Applying to Jobs & Additional Materials ───────────────────────────────
    fluidRow(
      box(title = "📋 Applying to Jobs (Ch.2)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Vetting Job Postings"),
            tags$p("Not all job postings are worth applying to. Chang gives criteria for vetting before investing time."),
            tags$ul(
              tags$li(tags$b("Role clarity:"), " does the JD clearly describe what the ML problem is? Vague JDs often indicate an unclear role"),
              tags$li(tags$b("Tech stack alignment:"), " at least 60% overlap with your experience — do not waste time chasing 100% match"),
              tags$li(tags$b("Team signals:"), " has the team published ML work? Do engineers have visible ML profiles? These signal a real ML team"),
              tags$li(tags$b("Level fit:"), " are the years-of-experience requirements realistic for your background?"),
              tags$li(tags$b("Growth trajectory:"), " is this a role you can grow from, not just into?")
            )),

          div(class = "framework-card",
            tags$h5("Mapping Your Skills and Experience to the ML Skills Matrix"),
            tags$p("Use the Skills Matrix from Ch.1 to map your profile to specific job requirements."),
            tags$ul(
              tags$li(tags$b("Step 1:"), " rate yourself on each skills matrix dimension (Ch.1)"),
              tags$li(tags$b("Step 2:"), " extract skill requirements from the job description"),
              tags$li(tags$b("Step 3:"), " map your rating to each requirement — identify gaps"),
              tags$li(tags$b("Step 4:"), " decide: is the gap closable before the interview? If yes, prioritise it. If not, be ready to address it honestly.")
            )),

          div(class = "framework-card",
            tags$h5("Tracking Applications"),
            tags$p("Chang recommends a structured tracking spreadsheet to manage the pipeline."),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Column"), tags$th("What to record"))),
              tags$tbody(
                tags$tr(tags$td("Company / Role"),     tags$td("Full job title and team name")),
                tags$tr(tags$td("Channel"),            tags$td("Applied via: job board, referral, direct")),
                tags$tr(tags$td("Date applied"),       tags$td("Timestamp for follow-up timing")),
                tags$tr(tags$td("Status"),             tags$td("Applied → Screen → Technical → On-site → Offer → Rejected")),
                tags$tr(tags$td("Contacts"),           tags$td("Recruiter name, hiring manager if known")),
                tags$tr(tags$td("Interview notes"),    tags$td("Link to post-interview notes (Ch.9)")),
                tags$tr(tags$td("Salary range"),       tags$td("Disclosed or researched range"))
              )
            ))
      ),

      box(title = "🎓 Additional Materials, Credentials & FAQ (Ch.2)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Do You Need a Project Portfolio?"),
            tags$p("Chang's answer: for most roles, a strong resume is sufficient. But a portfolio helps in specific situations."),
            tags$ul(
              tags$li(tags$b("New graduates:"), " yes — projects substitute for work experience. 2–3 polished GitHub repos are essential"),
              tags$li(tags$b("Career changers:"), " yes — a portfolio proves ML ability independent of your previous job title"),
              tags$li(tags$b("Experienced MLEs:"), " optional — strong references and a clear resume often suffice"),
              tags$li(tags$b("What makes a good portfolio project:"), " has a clear problem statement, uses real data, shows end-to-end pipeline, includes a README, has clean reproducible code")
            )),

          div(class = "framework-card",
            tags$h5("Do Online Certifications Help?"),
            tags$p("Chang is nuanced: certifications signal effort but rarely substitute for demonstrated ability."),
            tags$ul(
              tags$li(tags$b("Helpful for:"), " career changers demonstrating domain pivot; filling specific knowledge gaps"),
              tags$li(tags$b("Recognized programmes:"), " Coursera ML Specialization (Ng), fast.ai, DeepLearning.AI, AWS/GCP/Azure ML certifications"),
              tags$li(tags$b("Not a substitute for:"), " coding ability, ML depth, or production experience — interviewers will probe beyond the cert"),
              tags$li(tags$b("Chang's verdict:"), " a cert on a resume is better than nothing, but a GitHub project demonstrating the same skill is stronger")
            )),

          div(class = "framework-card",
            tags$h5("FAQ — Common Resume Questions"),
            tags$ul(
              tags$li(tags$b("How many pages should my resume be?"), " One page for < 10 years experience. Two pages maximum ever."),
              tags$li(tags$b("Should I format for ATS?"), " Yes — use standard section headers (Experience, Education, Skills), avoid tables and columns, save as PDF"),
              tags$li(tags$b("Should I include a photo?"), " No — never in the US, UK, or Canada. It invites unconscious bias."),
              tags$li(tags$b("Should I include my GPA?"), " Only if >= 3.5 and you are within 3 years of graduation."),
              tags$li(tags$b("Should I include all my jobs?"), " No — include only roles where your work is relevant or where removing them creates unexplained gaps.")
            ))
      )
    ),

    # ── Next Steps & Practice ─────────────────────────────────────────────────
    fluidRow(
      box(title = "🗺️ Next Steps After Ch.2 (Ch.2)", status = "warning",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Browsing Job Postings — How to Do It Efficiently"),
            tags$ul(
              tags$li(tags$b("Set up alerts:"), " LinkedIn and Indeed job alerts for 'machine learning engineer', 'data scientist', 'applied scientist' — filter to your target level and location"),
              tags$li(tags$b("Save postings:"), " save immediately — postings close, and the wording is useful for resume tailoring even after the posting expires"),
              tags$li(tags$b("Research the team:"), " for every application, spend 10 minutes reading the team's engineering blog, LinkedIn profiles, and recent papers"),
              tags$li(tags$b("Quality target:"), " 5 targeted applications per week with research beats 20 spray-and-pray applications")
            )),

          div(class = "framework-card",
            tags$h5("Identifying the Gaps Between Your Current Skills and Target Roles"),
            tags$ul(
              tags$li(tags$b("The gap analysis:"), " compare your Skills Matrix rating with the requirements of your 5 target job descriptions"),
              tags$li(tags$b("Common MLE gaps:"), " deployment experience, ML system design, production monitoring — all covered in Ch.4 and Ch.6"),
              tags$li(tags$b("Common DS gaps:"), " SQL depth, A/B test design, stakeholder communication — covered in Ch.5 and Ch.7"),
              tags$li(tags$b("Actionable:"), " for each gap, identify one resource that would close it — and schedule time to address it")
            ),
            div(class = "success-box",
              HTML("<strong>✅ Chang's bridge:</strong> This chapter ends with a clear directive:
                   complete your resume, identify 3–5 target companies, request referrals from
                   your network, and begin the technical prep in Ch.3 through Ch.6.
                   These are parallel activities — do not wait for the resume to be perfect
                   before starting technical prep.")))
      ),

      box(title = "✍️ Practice: Resume Bullet Builder", status = "success",
          solidHeader = TRUE, width = 6,

          div(class = "section-heading-dark", "Transform weak bullets into strong ones"),
          fluidRow(
            column(12,
              selectInput(ns("resume_example"), "Choose a weak bullet to rewrite:",
                choices = c(
                  "Worked on machine learning models for the team",
                  "Used Python and scikit-learn for data analysis",
                  "Helped improve the recommendation system",
                  "Responsible for model training and deployment",
                  "Developed NLP solutions for customer service"
                )),
              sliderInput(ns("resume_conf"), "Confidence in resume writing (1–10):", 1, 10, 5),
              div(class = "practice-area",
                tags$b("Rewrite the selected bullet using the formula: Action verb + what you built/did + quantified result"),
                textAreaInput(ns("resume_notes"), label = NULL, rows = 5, width = "100%",
                  placeholder = "Example strong bullet:\nBuilt a two-stage recommendation model (collaborative filtering + content-based re-ranking) deployed to 4M daily active users, increasing CTR by 18% and reducing cold-start failures by 40%\n\nYour rewrite:"),
                uiOutput(ns("resume_feedback"))
              ),
              br(),
              actionButton(ns("save_ch2"), "Save Assessment", class = "btn-meta", width = "100%")
            )
          )
      )
    )
  )
}

ch2_job_application_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_ch2, {
      notes <- input$resume_notes
      conf  <- input$resume_conf
      score <- 0
      if (grepl("built|developed|designed|deployed|trained|reduced|improved|automated|created", notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("[0-9]|%|million|thousand|\\$|x |times|users|DAU|MAU",  notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("model|algorithm|pipeline|system|api|feature|data",     notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("result|impact|metric|performance|latency|accuracy|precision|recall|auc|F1", notes, ignore.case = TRUE)) score <- score + 25

      prep_manager$update_progress("ch2_job_application", min(score + conf * 2, 100))
      prep_manager$save_note("ch2_notes", notes)

      output$resume_feedback <- renderUI({
        div(class = if (score >= 75) "success-box" else "tip-box",
          tags$h5(paste0("Resume Bullet Score: ", score, "/100")),
          if (score < 25)  tags$p("⚠️ Missing: strong action verb at the start (Built, Deployed, Trained, Reduced...)"),
          if (score < 50)  tags$p("⚠️ Missing: quantified number (%, users, $, time saved, metric improvement)"),
          if (score < 75)  tags$p("⚠️ Missing: specific ML technology or system mentioned"),
          if (score < 100) tags$p("⚠️ Missing: result or business impact"),
          if (score >= 75) tags$p("✅ Strong ML resume bullet — specific, quantified, and impactful!")
        )
      })
      showNotification("Ch.2 resume assessment saved!", type = "message")
    })
  })
}
