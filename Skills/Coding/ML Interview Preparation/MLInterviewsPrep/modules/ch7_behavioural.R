# modules/ch7_behavioural.R
# Ch.7: Behavioral Interviews — Susan Shu Chang

ch7_behavioural_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
      tags$h1("Chapter 7 — Behavioral Interviews"),
      tags$h2("Behavioral Interview Questions, Responses & Big Tech Prep — Susan Shu Chang"),
      div(
        span(class = "hero-badge", "STAR Method"),
        span(class = "hero-badge", "Hero's Journey"),
        span(class = "hero-badge", "Communication"),
        span(class = "hero-badge", "Teamwork"),
        span(class = "hero-badge", "Big Tech Specifics")
      )
    ),

    # ── STAR & Hero's Journey ─────────────────────────────────────────────────
    fluidRow(
      box(title = "⭐ Behavioral Interview Questions and Responses (Ch.7)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "success-box",
            HTML("<strong>Chang's core principle:</strong> Most candidates fail behavioural interviews
                 not because they lack experience, but because they tell stories without structure.
                 Every answer needs a clear arc — situation, actions, measurable outcome.")),
          br(),

          div(class = "framework-card",
            tags$h5("Use the STAR Method to Answer Behavioral Questions"),
            tags$p("STAR is the universal structure for behavioural answers in ML interviews."),
            tags$table(class = "table table-hover",
              tags$thead(tags$tr(tags$th("Element"), tags$th("What to cover"), tags$th("Time allocation"))),
              tags$tbody(
                tags$tr(tags$td(tags$b("S — Situation")), tags$td("Context: team, company stage, what problem existed"), tags$td("~15%")),
                tags$tr(tags$td(tags$b("T — Task")),      tags$td("Your specific responsibility — not the team's goal"), tags$td("~10%")),
                tags$tr(tags$td(tags$b("A — Action")),    tags$td("What YOU specifically did — use 'I', not 'we'"),       tags$td("~60%")),
                tags$tr(tags$td(tags$b("R — Result")),    tags$td("Quantified outcome: metric improvement, $ saved, time reduced"), tags$td("~15%"))
              )
            ),
            div(class = "tip-box",
              HTML("<strong>💡 Key rule:</strong> The Action section gets 60% of the time.
                   Interviewers want to know what YOU did, not what the team did.
                   Use 'I' deliberately — saying 'we' throughout is the most common mistake."))),

          div(class = "framework-card",
            tags$h5("Enhance Your Answers with the Hero's Journey Method"),
            tags$p("Layer the STAR structure with a narrative arc for more compelling answers."),
            timeline_entry("1", "The Ordinary World",
              "Set the scene — what was normal before the challenge. 1–2 sentences."),
            timeline_entry("2", "The Call to Adventure",
              "What changed? The problem, incident, or opportunity that required action."),
            timeline_entry("3", "Trials and Tribulations",
              "What obstacles did you face? What did you try that did not work first?"),
            timeline_entry("4", "The Transformation",
              "The key action or insight that changed the outcome. This is your core contribution."),
            timeline_entry("5", "Return with the Boon",
              "The result — metric, business impact, team outcome — and what you learned.")
          )
      ),

      box(title = "🎯 Best Practices from an Interviewer's Perspective (Ch.7)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("What Interviewers Are Actually Evaluating"),
            tags$ul(
              tags$li(tags$b("Self-awareness:"), " do you understand your own strengths and gaps?"),
              tags$li(tags$b("Impact orientation:"), " do you frame your work in terms of outcomes, not activities?"),
              tags$li(tags$b("Collaboration:"), " how do you work with people who disagree with you?"),
              tags$li(tags$b("Learning agility:"), " how do you respond when you are wrong or when things fail?"),
              tags$li(tags$b("Communication:"), " can you explain complex ML concepts to a non-technical stakeholder?")
            )),

          div(class = "framework-card",
            tags$h5("Best Practices from an Interviewer's Perspective"),
            tags$ul(
              tags$li(tags$b("Be specific, not generic:"), " 'I improved model accuracy' is weak. 'I reduced false positive rate from 12% to 4% saving $200k annually' is strong"),
              tags$li(tags$b("Own failures honestly:"), " interviewers respect candidates who acknowledge what went wrong and what they learned"),
              tags$li(tags$b("Match seniority level:"), " senior candidates should show initiative, scope, and cross-functional influence"),
              tags$li(tags$b("Keep answers to 2 minutes:"), " longer answers lose the interviewer. Practise to this constraint"),
              tags$li(tags$b("Prepare 8–10 stories:"), " not just one per question. Different questions can pull from the same story at different angles")
            )),

          div(class = "warn-box",
            HTML("<strong>⚠️ Most common failures:</strong> (1) Using 'we' throughout — interviewers cannot assess your individual contribution. (2) No quantified result — 'it was successful' is not a result. (3) Answering a different question than was asked."))
      )
    ),

    # ── Common Questions by Category ─────────────────────────────────────────
    fluidRow(
      box(title = "💬 Common Behavioral Questions and Recommendations (Ch.7)", status = "warning",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(3,
              div(class = "framework-card",
                tags$h5("Questions About Communication Skills"),
                tags$ul(
                  tags$li("Tell me about a time you had to explain a complex ML concept to a non-technical stakeholder."),
                  tags$li("Describe a situation where you had to present bad news to leadership."),
                  tags$li("Tell me about a time you convinced a team to change direction on a project."),
                  tags$li("How do you communicate trade-offs between model accuracy and business constraints?")
                ),
                div(class = "tip-box",
                  HTML("<strong>💡 Prep tip:</strong> For ML roles, always include a technical
                       translation moment — show you can bridge the gap between ML jargon
                       and business language."))
              )
            ),
            column(3,
              div(class = "framework-card",
                tags$h5("Questions About Collaboration and Teamwork"),
                tags$ul(
                  tags$li("Tell me about a time you worked with a difficult colleague or stakeholder."),
                  tags$li("Describe a situation where your team disagreed on a technical approach."),
                  tags$li("Tell me about a project where you had to rely heavily on others' expertise."),
                  tags$li("How do you handle it when your ML recommendations are rejected by product or business teams?")
                ),
                div(class = "success-box",
                  HTML("<strong>✅ Chang's advice:</strong> Show that you can disagree AND commit.
                       The strongest answers end with 'I disagreed with the decision but I
                       fully supported the team once it was made, and here is what happened.'"))
              )
            ),
            column(3,
              div(class = "framework-card",
                tags$h5("Questions on Responding to Feedback"),
                tags$ul(
                  tags$li("Tell me about a time you received critical feedback that was hard to hear."),
                  tags$li("Describe a situation where a code review or model review identified a serious issue you had missed."),
                  tags$li("Tell me about a time feedback changed your approach to a problem."),
                  tags$li("How do you seek feedback proactively rather than waiting for it?")
                )),

              div(class = "framework-card",
                tags$h5("Questions on Challenges and Learning New Skills"),
                tags$ul(
                  tags$li("Tell me about a time you had to learn a completely new technology or domain quickly."),
                  tags$li("Describe a project that failed and what you learned from it."),
                  tags$li("Tell me about the most technically challenging project you have worked on.")
                ))
            ),
            column(3,
              div(class = "framework-card",
                tags$h5("Questions About the Company"),
                tags$ul(
                  tags$li("Why do you want to work here specifically?"),
                  tags$li("What do you know about our ML infrastructure / products?"),
                  tags$li("Where do you see ML at this company in 3 years?"),
                  tags$li("What would you prioritise in your first 90 days?")
                ),
                div(class = "tip-box",
                  HTML("<strong>💡 Prep:</strong> Research the company's ML blog, recent papers,
                       and job descriptions. Name a specific product or technical challenge.
                       'I'm excited because...' backed by specifics is far stronger than
                       generic enthusiasm."))),

              div(class = "framework-card",
                tags$h5("Questions About Work Projects"),
                tags$ul(
                  tags$li("Tell me about the project you are most proud of."),
                  tags$li("Walk me through your most impactful ML project end-to-end."),
                  tags$li("Tell me about a time you went beyond your job description.")
                )),

              div(class = "framework-card",
                tags$h5("Free-Form Questions"),
                tags$ul(
                  tags$li("Tell me about yourself."),
                  tags$li("What are your biggest strengths and weaknesses?"),
                  tags$li("Where do you want to be in 5 years?"),
                  tags$li("What motivates you?")
                ))
            )
          )
      )
    ),

    # ── Best Practices ────────────────────────────────────────────────────────
    fluidRow(
      box(title = "🏆 Behavioral Interview Best Practices (Ch.7)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("How to Answer If You Don't Have Relevant Work Experience"),
            tags$p("Chang explicitly addresses this for newer candidates and career changers."),
            tags$ul(
              tags$li(tags$b("Academic projects count:"), " treat your thesis, capstone, or research as work experience — frame it professionally"),
              tags$li(tags$b("Open source contributions:"), " PRs, issues, community interactions all demonstrate real collaboration"),
              tags$li(tags$b("Internships and freelance:"), " any paid or structured work is valid"),
              tags$li(tags$b("Side projects:"), " frame with business context — 'I built X which achieved Y for Z purpose'"),
              tags$li(tags$b("Volunteer / club work:"), " leadership and teamwork stories transfer from any context")
            ),
            div(class = "success-box",
              HTML("<strong>✅ Chang's reframe:</strong> A lack of work experience is not a disqualifier
                   if you can demonstrate the underlying competency through any structured experience
                   where you had a goal, took actions, and produced measurable results."))),

          div(class = "framework-card",
            tags$h5("Senior+ Behavioral Interview Tips"),
            tags$p("At L5/L6+ levels, interviewers look for scope, influence, and ambiguity handling."),
            tags$ul(
              tags$li(tags$b("Scope:"), " your stories should involve cross-team, cross-functional, or org-level impact"),
              tags$li(tags$b("Ambiguity:"), " show you drove clarity when the problem was not well-defined"),
              tags$li(tags$b("Influence without authority:"), " you persuaded, aligned, or unblocked without being the decision-maker"),
              tags$li(tags$b("Multiplied others:"), " you improved team processes, mentored someone, or built reusable tooling"),
              tags$li(tags$b("Strategic thinking:"), " you connected your ML work to company-level goals, not just task completion")
            ))
      ),

      box(title = "🏢 Big Tech Specific Preparation (Ch.7)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Amazon — Leadership Principles Focus"),
            tags$p("Amazon's behavioural round is structured entirely around their 16 Leadership Principles."),
            tags$ul(
              tags$li(tags$b("Customer Obsession:"), " start with the customer impact of every project"),
              tags$li(tags$b("Ownership:"), " show you acted beyond your scope when necessary"),
              tags$li(tags$b("Invent and Simplify:"), " you found a simpler solution or created something new"),
              tags$li(tags$b("Dive Deep:"), " you got into the data / code details rather than delegating"),
              tags$li(tags$b("Bias for Action:"), " you made a decision with imperfect information and moved fast"),
              tags$li(tags$b("Prep tip:"), " prepare 2 stories per LP — interviewers ask until they find a weak one")
            )),

          div(class = "framework-card",
            tags$h5("Meta / Facebook — Impact at Scale"),
            tags$ul(
              tags$li(tags$b("Focus on impact:"), " Meta interviewers want numbers — DAU, revenue, latency, precision"),
              tags$li(tags$b("Speed and iteration:"), " show you shipped fast and learned from results"),
              tags$li(tags$b("Cross-functional:"), " Meta values people who work across product, eng, data science"),
              tags$li(tags$b("Be direct:"), " Meta culture is direct — say what you think clearly")
            )),

          div(class = "framework-card",
            tags$h5("Alphabet / Google — Googleyness and Leadership"),
            tags$ul(
              tags$li(tags$b("Googleyness:"), " comfort with ambiguity, collaborative approach, intellectual humility"),
              tags$li(tags$b("Leadership:"), " show you lead through influence at all seniority levels"),
              tags$li(tags$b("Role-related knowledge:"), " strong technical depth expected alongside soft skills"),
              tags$li(tags$b("Structured Communication:"), " STAR is expected — interviewers are trained to probe it")
            )),

          div(class = "framework-card",
            tags$h5("Netflix — Freedom and Responsibility"),
            tags$ul(
              tags$li(tags$b("Culture deck alignment:"), " demonstrate you thrive with autonomy and minimal process"),
              tags$li(tags$b("Context not control:"), " show you give and receive context rather than directives"),
              tags$li(tags$b("Highly aligned, loosely coupled:"), " you operated independently but stayed aligned with goals"),
              tags$li(tags$b("Keeper test:"), " show you are someone the manager would fight to keep — exceptional, not just solid")
            ))
      )
    ),

    # ── Practice ─────────────────────────────────────────────────────────────
    fluidRow(
      box(title = "✍️ Practice: Write Your STAR Story", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              selectInput(ns("behav_topic"), "Choose a behavioral question to practise:",
                choices = c(
                  "Explain complex ML to a non-technical stakeholder",
                  "Worked with a difficult colleague",
                  "Project you are most proud of",
                  "Time you failed and what you learned",
                  "Critical feedback that changed your approach",
                  "Convinced a team to change direction",
                  "Learned a new skill or technology quickly",
                  "Went beyond your job description",
                  "Handled competing priorities",
                  "Tell me about yourself"
                )),
              sliderInput(ns("behav_conf"), "Confidence in behavioural interviews (1–10):", 1, 10, 5),
              actionButton(ns("save_behav"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8,
              div(class = "practice-area",
                tags$b("Practice: Write your STAR story for the selected question."),
                textAreaInput(ns("behav_notes"), label = NULL, rows = 10, width = "100%",
                  placeholder = "## S — Situation (15%)\nContext: team size, company, problem\n\n## T — Task (10%)\nYour specific responsibility\n\n## A — Action (60%)\nWhat YOU specifically did — use 'I' not 'we'\n\n## R — Result (15%)\nQuantified outcome: metric, $ impact, time saved\n\n## What I learned / would do differently"),
                uiOutput(ns("behav_feedback"))
              )
            )
          )
      )
    )
  )
}

ch7_behavioural_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_behav, {
      notes <- input$behav_notes
      conf  <- input$behav_conf
      score <- 0
      if (grepl("situation|context|team|company|problem|background", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("task|responsible|goal|objective|my role",            notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("\\bI\\b|action|did|built|implemented|decided|drove", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("result|outcome|impact|metric|reduced|increased|saved|improved", notes, ignore.case = TRUE)) score <- score + 20
      if (grepl("[0-9]|%|\\$|x |times|days|weeks|hours",             notes, ignore.case = TRUE)) score <- score + 20

      prep_manager$update_progress("ch7_behavioural", min(score + conf * 3, 100))
      prep_manager$save_note("ch7_notes", notes)

      output$behav_feedback <- renderUI({
        div(class = if (score >= 80) "success-box" else "tip-box",
          tags$h5(paste0("STAR Story Score: ", score, "/100")),
          if (score < 20)  tags$p("⚠️ Missing: Situation — set the context clearly"),
          if (score < 40)  tags$p("⚠️ Missing: Task — what was YOUR specific responsibility?"),
          if (score < 60)  tags$p("⚠️ Missing: Action — what did YOU specifically do? (use 'I')"),
          if (score < 80)  tags$p("⚠️ Missing: Result — what was the measurable outcome?"),
          if (score < 100) tags$p("⚠️ Missing: Quantified metric — add a number, %, $, or time"),
          if (score >= 80) tags$p("✅ Strong STAR structure with quantified result!")
        )
      })
      showNotification("Ch.7 behavioural assessment saved!", type = "message")
    })
  })
}
