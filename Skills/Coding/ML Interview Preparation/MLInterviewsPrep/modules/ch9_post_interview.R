# modules/ch9_post_interview.R
# Ch.9: Post-Interview and Follow-up — Susan Shu Chang

ch9_post_interview_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
      tags$h1("Chapter 9 — Post-Interview and Follow-up"),
      tags$h2("Post-Interview Steps, Rejections, Offers & First 30/60/90 Days — Susan Shu Chang"),
      div(
        span(class = "hero-badge", "Post-Interview Steps"),
        span(class = "hero-badge", "Thank-You Notes"),
        span(class = "hero-badge", "Rejections"),
        span(class = "hero-badge", "Offer Negotiation"),
        span(class = "hero-badge", "First 90 Days")
      )
    ),

    # ── Post-Interview Steps ──────────────────────────────────────────────────
    fluidRow(
      box(title = "📋 Post-Interview Steps (Ch.9)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "success-box",
            HTML("<strong>Chang's insight:</strong> What you do in the 24 hours after an interview
                 matters more than most candidates realise. Structured reflection accelerates
                 learning and improves each subsequent interview.")),
          br(),

          div(class = "framework-card",
            tags$h5("Step 1 — Take Notes of What You Remember from the Interview"),
            tags$p("Do this within 2 hours of leaving — memory decays fast."),
            tags$ul(
              tags$li(tags$b("Questions asked:"), " write down every question you remember — exact wording if possible"),
              tags$li(tags$b("Your answers:"), " what did you say? What was strong? What felt weak?"),
              tags$li(tags$b("Technical topics:"), " what concepts came up that you were uncertain about?"),
              tags$li(tags$b("Interviewer reactions:"), " where did they probe deeper? What seemed to land well?"),
              tags$li(tags$b("Your questions:"), " what did you ask? What was the response?")
            ),
            div(class = "tip-box",
              HTML("<strong>💡 Why this matters:</strong> This note becomes your improvement log.
                   After 5 interviews, patterns emerge — the same questions keep appearing,
                   or the same topic keeps tripping you up. Without notes you cannot spot them."))),

          div(class = "framework-card",
            tags$h5("Step 2 — Make Sure You Are Not Missing Important Information"),
            tags$ul(
              tags$li(tags$b("Role details:"), " do you understand what the day-to-day work actually involves?"),
              tags$li(tags$b("Team structure:"), " who would you work with? How is success measured?"),
              tags$li(tags$b("ML stack:"), " what tools, frameworks, data infrastructure does the team use?"),
              tags$li(tags$b("Growth path:"), " what does progression look like for this role?"),
              tags$li(tags$b("Process questions:"), " ask your recruiter anything unclear about next steps and timeline")
            )),

          div(class = "framework-card",
            tags$h5("Should You Send a Thank-You Email to the Interviewer?"),
            tags$p("Chang's answer: yes, with conditions."),
            tags$ul(
              tags$li(tags$b("Send within 24 hours:"), " after that the window closes"),
              tags$li(tags$b("Keep it brief:"), " 3–5 sentences maximum — not a sales pitch"),
              tags$li(tags$b("Reference something specific:"), " mention a topic or insight from the interview — shows you were paying attention"),
              tags$li(tags$b("Reiterate interest:"), " one sentence on why you remain excited about the role"),
              tags$li(tags$b("No corrections:"), " do not try to fix a bad answer in a thank-you note — it highlights the weakness")
            )),

          div(class = "framework-card",
            tags$h5("Thank-You Note Template"),
            div(class = "practice-area",
              HTML("Subject: Thank You — [Role Title] Interview<br><br>
                    Hi [Name],<br><br>
                    Thank you for taking the time to speak with me today about the [Role] position.
                    I particularly enjoyed our discussion about [specific topic from interview] —
                    it reinforced my interest in [specific aspect of the team or problem].<br><br>
                    I am excited about the opportunity and look forward to hearing about next steps.<br><br>
                    Best,<br>
                    [Your name]"))
            ),
            div(class = "tip-box",
              HTML("<strong>💡 Key:</strong> The specific reference in the middle sentence is what
                   separates a memorable thank-you from a forgettable template.
                   Without it, this is indistinguishable from every other email.")),

          div(class = "framework-card",
            tags$h5("How Long to Wait Before Following Up"),
            tags$ul(
              tags$li(tags$b("After on-site:"), " if no response in 5–7 business days, one polite follow-up email to recruiter is appropriate"),
              tags$li(tags$b("After phone screen:"), " recruiter usually has a timeline — ask for it explicitly and respect it"),
              tags$li(tags$b("Tone:"), " 'I wanted to check in on the timeline' — never 'I am following up again'"),
              tags$li(tags$b("Maximum:"), " two follow-ups total. After that, treat it as a no and move on")
            ))
      ),

      box(title = "🔄 What to Do Between Interviews (Ch.9)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("How to Respond to Rejections"),
            tags$p("Chang is direct: rejection is part of the process, not a verdict on your ability."),
            tags$ul(
              tags$li(tags$b("Feel it, then move on:"), " allow yourself 24 hours to be disappointed — then close the loop"),
              tags$li(tags$b("Ask for feedback:"), " email the recruiter asking if there is any feedback from interviewers — you will not always get a response but it is worth asking"),
              tags$li(tags$b("Review your notes:"), " revisit your post-interview notes. What patterns appear across rejections?"),
              tags$li(tags$b("Do not catastrophise:"), " most ML candidates face 3–10 rejections before an offer. This is normal, not exceptional")
            )),

          div(class = "framework-card",
            tags$h5("Template for Rejection Responses"),
            div(class = "practice-area",
              HTML("Hi [Recruiter name],<br><br>
                   Thank you for letting me know. I appreciate the time the team invested in
                   speaking with me.<br><br>
                   If there is any feedback you are able to share from the interview process,
                   I would find it very helpful for my development.<br><br>
                   I hope to stay in touch and potentially work together in the future.<br><br>
                   Best,<br>
                   [Your name]"))
            ),

          div(class = "framework-card",
            tags$h5("Job Applications Are a Funnel"),
            tags$p("Chang frames the job search as a funnel — you need volume at the top to get offers at the bottom."),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Stage"), tags$th("Typical conversion"), tags$th("Action"))),
              tags$tbody(
                tags$tr(tags$td("Applications submitted"),   tags$td("100%"),  tags$td("Apply broadly — do not self-filter heavily")),
                tags$tr(tags$td("Recruiter screen"),         tags$td("20–30%"), tags$td("Strong resume + referrals increase this")),
                tags$tr(tags$td("Technical phone screen"),   tags$td("40–60%"), tags$td("Consistent coding and ML fundamentals")),
                tags$tr(tags$td("On-site / final round"),    tags$td("30–50%"), tags$td("Full loop — technical + behavioural + design")),
                tags$tr(tags$td("Offer"),                    tags$td("20–40%"), tags$td("Multiple competing offers strengthen negotiation"))
              )
            )),

          div(class = "framework-card",
            tags$h5("Update and Customise Your Resume and Test Variations"),
            tags$ul(
              tags$li(tags$b("One page rule:"), " unless you have 10+ years of experience — every recruiter says this"),
              tags$li(tags$b("Results-led bullets:"), " 'Built X using Y, resulting in Z metric' — not just responsibility lists"),
              tags$li(tags$b("Keyword alignment:"), " match your resume language to the job description — ATS systems filter on exact matches"),
              tags$li(tags$b("A/B test variations:"), " track application → screen conversion rate per resume version"),
              tags$li(tags$b("Referrals:"), " a referral from a current employee bypasses ATS filtering — pursue them actively through LinkedIn")
            ))
      )
    ),

    # ── Offer Stage ───────────────────────────────────────────────────────────
    fluidRow(
      box(title = "💼 Steps of the Offer Stage (Ch.9)", status = "warning",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Let Other Interviews-in-Progress Know You Have an Offer"),
            tags$p("If you have competing interviews, an offer is leverage. Use it professionally."),
            tags$ul(
              tags$li(tags$b("Email to other recruiters:"), " 'I have received an offer with a decision deadline of [date]. I want to let you know I remain very interested in [Company]. Are you able to update your timeline?'"),
              tags$li(tags$b("Tone:"), " transparent and professional — not aggressive or ultimatum-like"),
              tags$li(tags$b("Outcome:"), " this often accelerates timelines at other companies by 1–2 weeks")
            )),

          div(class = "framework-card",
            tags$h5("What to Do If the Offer Response Timeline Is Very Short"),
            tags$ul(
              tags$li(tags$b("Request an extension:"), " most companies will grant 3–5 additional business days — just ask politely"),
              tags$li(tags$b("Be honest:"), " 'I have other processes in progress and want to make a fully informed decision — could we extend to [specific date]?'"),
              tags$li(tags$b("Exploding offers:"), " very short hard deadlines (< 48h) are a red flag about company culture — factor this in")
            )),

          div(class = "framework-card",
            tags$h5("Understand Your Offer — Components to Evaluate"),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Component"), tags$th("What to check"), tags$th("Negotiable?"))),
              tags$tbody(
                tags$tr(tags$td(tags$b("Base salary")),     tags$td("Market rate for level + location"), tags$td("Yes — most common lever")),
                tags$tr(tags$td(tags$b("Equity (RSUs)")),   tags$td("Vesting schedule, cliff, refresh"),  tags$td("Yes — especially grant size")),
                tags$tr(tags$td(tags$b("Signing bonus")),   tags$td("One-time; often used for competing offers"), tags$td("Yes")),
                tags$tr(tags$td(tags$b("Level / title")),   tags$td("Will this affect future promotions?"), tags$td("Sometimes")),
                tags$tr(tags$td(tags$b("Remote policy")),   tags$td("In-office days required?"),           tags$td("Sometimes")),
                tags$tr(tags$td(tags$b("Benefits")),        tags$td("Health, PTO, 401k match, parental"),  tags$td("Rarely"))
              )
            )),

          div(class = "success-box",
            HTML("<strong>✅ Negotiation principle:</strong> Always negotiate at least the base salary.
                 Offers are not final until you accept. Saying 'I am very excited about this role —
                 is there flexibility on the base?' has almost zero downside and frequent upside."))
      ),

      box(title = "🚀 First 30/60/90 Days of Your New ML Job (Ch.9)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "success-box",
            HTML("<strong>Chang's advice:</strong> The first 90 days are not about proving yourself
                 with a big deliverable. They are about building the foundation —
                 knowledge, relationships, and credibility — that makes future impact possible.")),
          br(),

          div(class = "framework-card",
            tags$h5("Days 1–30: Gain Domain Knowledge"),
            tags$ul(
              tags$li(tags$b("Understand the business:"), " what does the company do? How does your team contribute to revenue or users?"),
              tags$li(tags$b("Learn the ML stack:"), " data infrastructure, feature store, training platform, serving layer"),
              tags$li(tags$b("Read existing code:"), " understand the current models and pipelines before suggesting changes"),
              tags$li(tags$b("Shadow on-call:"), " if there is an ML ops rotation, join it — fastest way to learn production issues"),
              tags$li(tags$b("Ask many questions:"), " social permission to ask naive questions expires after ~90 days — use it")
            )),

          div(class = "framework-card",
            tags$h5("Days 31–60: Gain Code Knowledge"),
            tags$ul(
              tags$li(tags$b("Make a small contribution:"), " fix a bug, add a test, improve documentation — ships before anything else"),
              tags$li(tags$b("Understand the data:"), " query the feature tables, understand data lineage, identify known data quality issues"),
              tags$li(tags$b("Attend design reviews:"), " observe before participating — understand how decisions are made"),
              tags$li(tags$b("Map the ML lifecycle:"), " trace a model from training code to production serving endpoint")
            )),

          div(class = "framework-card",
            tags$h5("Days 61–90: Meet Relevant People & Build Credibility"),
            tags$ul(
              tags$li(tags$b("Meet relevant people:"), " schedule 30-minute 1:1s with 10–15 people across your team and partners"),
              tags$li(tags$b("Help improve onboarding documentation:"), " you have unique fresh-eyes perspective — write down what was confusing"),
              tags$li(tags$b("Keep track of your achievements:"), " log every task completed, bug fixed, and experiment run — this feeds your next performance review"),
              tags$li(tags$b("Propose your first project:"), " by day 60 you should have enough context to propose a small impactful project")
            )),

          div(class = "tip-box",
            HTML("<strong>💡 Chang's final word:</strong> The people who succeed in ML careers
                 long-term are those who combine technical excellence with strong communication,
                 business awareness, and the ability to deliver consistently over time —
                 not those who scored best in any single interview."))
      )
    ),

    fluidRow(
      box(title = "✍️ Practice: Post-Interview Reflection", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              selectInput(ns("post_topic"), "What to reflect on:",
                choices = c(
                  "Post-interview notes from a recent interview",
                  "Draft a thank-you email",
                  "Response to a rejection",
                  "Evaluate a job offer",
                  "30/60/90 day plan for a target role"
                )),
              sliderInput(ns("post_conf"), "Confidence in post-interview process (1–10):", 1, 10, 5),
              actionButton(ns("save_post"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8,
              div(class = "practice-area",
                tags$b("Practice: Use the space below for your post-interview reflection or draft."),
                textAreaInput(ns("post_notes"), label = NULL, rows = 10, width = "100%",
                  placeholder = "## What went well\n\n## What to improve\n\n## Technical topics to review\n\n## Follow-up actions\n\n## Key takeaways"),
                uiOutput(ns("post_feedback"))
              )
            )
          )
      )
    )
  )
}

ch9_post_interview_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_post, {
      notes <- input$post_notes
      conf  <- input$post_conf
      score <- 0
      if (grepl("well|strong|positive|good|confident",          notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("improve|weak|missed|better|next time|review",  notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("action|follow|email|research|practice|study",  notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("learn|takeaway|insight|realise|noticed",       notes, ignore.case = TRUE)) score <- score + 25

      prep_manager$update_progress("ch9_post_interview", min(score + conf * 3, 100))
      prep_manager$save_note("ch9_notes", notes)

      output$post_feedback <- renderUI({
        div(class = if (score >= 75) "success-box" else "tip-box",
          tags$h5(paste0("Reflection Quality Score: ", score, "/100")),
          if (score < 25)  tags$p("⚠️ Missing: what went well in this interview"),
          if (score < 50)  tags$p("⚠️ Missing: specific areas to improve"),
          if (score < 75)  tags$p("⚠️ Missing: concrete follow-up actions"),
          if (score < 100) tags$p("⚠️ Missing: key learning or insight to carry forward"),
          if (score >= 75) tags$p("✅ Structured reflection — this is how you improve with every interview!")
        )
      })
      showNotification("Ch.9 post-interview assessment saved!", type = "message")
    })
  })
}
