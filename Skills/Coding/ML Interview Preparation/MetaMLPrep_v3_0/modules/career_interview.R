# modules/career_interview.R
# Tab 7: Career / Leadership Interview (PDF page 12)
# One 45-min: leadership philosophy, org health, tech direction, STAR stories

career_interview_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    div(class="meta-hero",
        tags$h1("Career & Leadership Interview"),
        tags$h2("One 45-Minute Session — Your Story, Leadership Philosophy & Org Impact"),
        div(
          span(class="hero-badge", "STAR Method"),
          span(class="hero-badge", "Leadership Philosophy"),
          span(class="hero-badge", "Mentorship"),
          span(class="hero-badge", "Tech Direction")
        )
    ),
    
    fluidRow(
      box(title="🎯 What the Career Interview Covers",
          status="primary", solidHeader=TRUE, width=6,
          
          div(class="success-box",
              HTML("<strong>✅ Purpose:</strong> Assess your capability to support org health and influence the technical direction of your project and company. This is where your LEADERSHIP story is evaluated.")),
          br(),
          
          div(class="section-heading-dark", "Key Areas Covered"),
          div(class="framework-card",
              tags$h5("1. Your Technical History"),
              tags$p("Walk through your résumé from a leadership perspective. Not 'I built X' but 'I defined the technical strategy for X and drove Y people to deliver it.'")),
          div(class="framework-card",
              tags$h5("2. Leadership in Complexity"),
              tags$p("Stories of navigating complex business problems that affected the company at large. Org restructures, competing priorities, resource constraints, technical debt at scale.")),
          div(class="framework-card",
              tags$h5("3. Mentorship & People Growth"),
              tags$p("At L6, you're expected to grow L4/L5 engineers. 'Can you tell me about people whose careers you fundamentally improved?' — a direct Meta question.")),
          div(class="framework-card",
              tags$h5("4. Successes AND Failures"),
              tags$p("Showcase both. Meta explicitly wants failure stories — projects that failed, conflicts you lost, decisions you got wrong and what you learned."))
      ),
      
      box(title="⭐ The STAR Framework — Meta Style",
          status="info", solidHeader=TRUE, width=6,
          
          div(class="tip-box",
              HTML("<strong>💡 STAR at Meta L6:</strong> Standard STAR but the Action must show <em>leadership judgment</em>, not just execution. And the Result must include <em>org impact</em>, not just personal output.")),
          br(),
          
          div(class="framework-card",
              tags$h5("S — Situation (10-15%)")   ,
              tags$p("1-2 sentences. Set the scene. Don't over-explain the context. 'In 2023, our Ads ML team was facing a performance regression after a major infrastructure migration...'")),
          div(class="framework-card",
              tags$h5("T — Task (5-10%)"),
              tags$p("1 sentence. Your specific responsibility. 'I was the tech lead responsible for diagnosing and resolving the regression, with a 72-hour SLA from leadership.'")),
          div(class="framework-card",
              tags$h5("A — Action (60-70%)"),
              tags$p("This is the gold. Show your THINKING PROCESS. Trade-offs you evaluated. People you mobilised. Decisions you made and why. Alternatives you discarded. Your leadership approach.")),
          div(class="framework-card",
              tags$h5("R — Result (15-20%)"),
              tags$p("Quantify. User impact. Business metric. Time saved. Revenue protected. People who grew. Always include at least one number. 'We resolved the regression in 48 hours, restoring $X daily revenue. Post-mortem led to a new oncall protocol adopted by 3 teams.'")),
          
          div(class="warn-box",
              HTML("<strong>⚠️ Common mistake:</strong> Spending too much time on S and T, leaving 5 minutes for A and R. The interviewers care most about your Action — that's where leadership lives."))
      )
    ),
    
    # ── Required Question Bank ───────────────────────
    fluidRow(
      box(title="💬 Must-Prepare Questions (Direct from Meta Career Interview Guide)",
          status="warning", solidHeader=TRUE, width=12,
          
          tabsetPanel(
            tabPanel("Leadership & Conflict",
                     br(),
                     fluidRow(
                       column(6,
                              div(class="section-heading-dark", "Conflict & Difficult Situations"),
                              div(class="framework-card",
                                  tags$h5('"How do you deal with conflict?"'),
                                  div(class="tip-box", HTML("<strong>Prep angle:</strong> Give a SPECIFIC example. Show empathy + data-driven resolution. E.g., 'When a senior IC disagreed with my model architecture choice, I ran an A/B experiment to let data resolve the disagreement rather than relying on seniority.'")),
                                  textAreaInput(ns("q_conflict"), "Your Answer:", rows=4, width="100%")),
                              div(class="framework-card",
                                  tags$h5('"Tell me about a project you led that failed."'),
                                  div(class="tip-box", HTML("<strong>Prep angle:</strong> Don't deflect or partially blame others. Own it. Describe root cause clearly. Show what you systematically changed afterwards. E.g., 'The ML pipeline for X launched with insufficient bias testing. Model underperformed on mobile users in APAC by 35%. I implemented a demographic holdout evaluation framework that's now team standard.'")),
                                  textAreaInput(ns("q_failure"), "Your Answer:", rows=4, width="100%"))
                       ),
                       column(6,
                              div(class="framework-card",
                                  tags$h5('"What were some excellent collaborations you\'ve had?"'),
                                  div(class="tip-box", HTML("<strong>Prep angle:</strong> Pick one cross-functional, one with Research, one mentoring story. For each: who were they, what was the shared goal, what made it excellent, what was the lasting impact.")),
                                  textAreaInput(ns("q_collab"), "Your Answer:", rows=4, width="100%")),
                              div(class="framework-card",
                                  tags$h5('"What does office politics mean to you, and do you see politics as your job?"'),
                                  div(class="tip-box", HTML("<strong>Prep angle:</strong> Meta expects L6 engineers to navigate org dynamics strategically. Reframe 'politics' as 'alignment'. E.g., 'I see my role as ensuring the right technical decisions win — not because of who argues loudest, but because I've built the evidence and relationships to drive consensus.'")),
                                  textAreaInput(ns("q_politics"), "Your Answer:", rows=4, width="100%"))
                       )
                     )
            ),
            tabPanel("People & Mentorship",
                     br(),
                     fluidRow(
                       column(6,
                              div(class="section-heading-dark", "Growing Others — L6 Requirement"),
                              div(class="warn-box",
                                  HTML("<strong>⚠️ Direct Meta question:</strong> 'Can you tell me about four people whose careers you have fundamentally improved?' — Be SPECIFIC. Name the level they were at, what gap you addressed, what they achieved.")),
                              br(),
                              div(class="framework-card",
                                  tags$h5("Person 1:"),
                                  textAreaInput(ns("mentee1"), "Name/Role (anonymised), their gap, your approach, their outcome:", rows=4, width="100%")),
                              div(class="framework-card",
                                  tags$h5("Person 2:"),
                                  textAreaInput(ns("mentee2"), NULL, rows=4, width="100%")),
                              div(class="framework-card",
                                  tags$h5("Person 3:"),
                                  textAreaInput(ns("mentee3"), NULL, rows=4, width="100%")),
                              div(class="framework-card",
                                  tags$h5("Person 4:"),
                                  textAreaInput(ns("mentee4"), NULL, rows=4, width="100%"))
                       ),
                       column(6,
                              div(class="section-heading-dark", "Team Relationships"),
                              div(class="framework-card",
                                  tags$h5('"Describe a few of your peers and your relationship with each."'),
                                  div(class="tip-box", HTML("<strong>Prep angle:</strong> Show range: a peer you collaborate with well, one you had tension with and how you managed it, one you've grown close to through a shared challenge. Show self-awareness and emotional intelligence.")),
                                  textAreaInput(ns("q_peers"), "Your Answer:", rows=5, width="100%")),
                              div(class="framework-card",
                                  tags$h5('"What did you do on your very best day at work?"'),
                                  div(class="tip-box", HTML("<strong>Prep angle:</strong> This is a question about your values and motivations. The best answers involve helping someone else succeed, shipping something that mattered to users, or solving a problem that had seemed impossible. Authenticity > polish here.")),
                                  textAreaInput(ns("q_best_day"), "Your Answer:", rows=5, width="100%")),
                              div(class="framework-card",
                                  tags$h5('"What were some excellent collaborations you\'ve had?"'),
                                  textAreaInput(ns("q_excellent"), "Your Answer:", rows=4, width="100%"))
                       )
                     ),
                     br(),
                     actionButton(ns("save_mentorship"), "Save All Mentorship Answers",
                                  class="btn-meta", icon=icon("save"))
            ),
            tabPanel("Technical Direction Setting",
                     br(),
                     div(class="section-heading-dark", "At L6, You Set Technical Direction — Not Just Follow It"),
                     fluidRow(
                       column(6,
                              div(class="framework-card",
                                  tags$h5("What questions Meta asks about technical vision:"),
                                  tags$ul(
                                    tags$li("'How do you decide which technical investments to prioritise?'"),
                                    tags$li("'Tell me about a time you pushed back on a technical direction from leadership.'"),
                                    tags$li("'How do you evaluate when to build vs buy vs use open-source?'"),
                                    tags$li("'How do you communicate a multi-year technical vision to non-technical stakeholders?'"),
                                    tags$li("'Tell me about a time you saw a technical risk others missed.'")
                                  )),
                              br(),
                              div(class="tip-box",
                                  HTML("<strong>💡 ML Leadership angle:</strong> Show that you have opinions about the META ML stack — PyTorch 2.x, FBLearner, DLRM, Llama, MTIA. Show you understand how Meta's infrastructure choices create constraints and opportunities for ML systems.")),
                              br(),
                              div(class="framework-card",
                                  tags$h5("Technical Vision Practice"),
                                  textAreaInput(ns("tech_vision"),
                                                "Describe your technical vision for ML engineering at a company like Meta in 2026-2027:",
                                                placeholder="What problems do you see that need solving?\nWhat technical bets would you make?\nHow would you align engineering capacity with ML research?\nWhat risks do you see in current approaches?",
                                                rows=10, width="100%"))
                       ),
                       column(6,
                              div(class="section-heading-dark", "Use of Data & Intuition"),
                              div(class="framework-card",
                                  tags$h5("When to use data vs intuition in decision-making"),
                                  tags$p("Strong answers show you use both:"),
                                  tags$ul(
                                    tags$li(tags$b("Data for:"), " model architecture comparisons, launch decisions, metric trade-offs, resourcing"),
                                    tags$li(tags$b("Intuition for:"), " long-term bets, novel problem framing, sensing team health, detecting non-obvious risks")
                                  ),
                                  textAreaInput(ns("q_data_intuition"),
                                                "Your answer: 'How do you balance data and intuition in technical decisions?'",
                                                placeholder="...", rows=5, width="100%")),
                              div(class="framework-card",
                                  tags$h5("How to Influence Without Authority"),
                                  div(class="tip-box", HTML("<strong>Key frameworks:</strong>
                                  <ul>
                                  <li><b>Prototypes:</b> Build a working demo. Data beats arguments.</li>
                                  <li><b>Pre-mortems:</b> 'If this fails, it'll fail because of X.' Shows rigor.</li>
                                  <li><b>Allies:</b> Build coalition quietly before the big meeting.</li>
                                  <li><b>Shared metrics:</b> Reframe the question around a metric everyone agrees matters.</li>
                                  </ul>")),
                                  textAreaInput(ns("q_influence"), "Your example of influencing without authority:", rows=5, width="100%"))
                       )
                     )
            )
          )
      )
    ),
    
    # ── Final Readiness Score ────────────────────────
    fluidRow(
      box(title="📊 Career Interview Readiness", status="success",
          solidHeader=TRUE, width=12,
          
          fluidRow(
            column(3, sliderInput(ns("car_star"), "STAR Stories Ready", 0, 10, 0)),
            column(3, sliderInput(ns("car_mentorship"), "Mentorship Stories (0-4 people)", 0, 4, 0)),
            column(3, sliderInput(ns("car_vision"), "Technical Vision Clarity", 0, 10, 0)),
            column(3, sliderInput(ns("car_failure"), "Failure Stories with Lessons", 0, 5, 0))
          ),
          actionButton(ns("calc_career"), "Calculate Career Readiness", class="btn-meta"),
          br(), br(),
          uiOutput(ns("career_result"))
      )
    )
  )
}

career_interview_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$save_mentorship, {
      prep_manager$save_note("career_mentee1", input$mentee1)
      prep_manager$save_note("career_mentee2", input$mentee2)
      prep_manager$save_note("career_vision", input$tech_vision)
      showNotification("Mentorship answers saved!", type="message")
    })
    
    observeEvent(input$calc_career, {
      score <- (input$car_star / 10 * 30) +
               (input$car_mentorship / 4 * 25) +
               (input$car_vision / 10 * 25) +
               (input$car_failure / 5 * 20)
      pct <- round(score)
      prep_manager$update_progress("career_interview", pct)
      
      output$career_result <- renderUI({
        colour <- progress_colour(pct)
        div(
          fluidRow(
            column(3, div(style=paste0("text-align:center;background:",
                                       if(pct>=70)"#f0fdf4" else "#fef3c7",
                                       ";border-radius:12px;padding:20px;"),
                          tags$h2(style=paste0("color:",colour), paste0(pct, "%")),
                          tags$p("Career Readiness"))),
            column(9,
                   if (input$car_mentorship < 2)
                     div(class="warn-box", HTML("⚠️ <strong>Critical gap:</strong> You need 4 mentorship stories. This is a direct Meta question. Prepare specific examples NOW.")),
                   if (input$car_failure < 2)
                     div(class="warn-box", HTML("⚠️ <strong>Critical gap:</strong> You need failure stories. Meta explicitly looks for self-awareness. Without failure stories, you'll seem defensive.")),
                   if (input$car_star < 5)
                     div(class="tip-box", HTML("💡 Aim for 8-10 STAR stories covering: ownership, conflict, failure, mentorship, technical vision, XFN, best day, worst day, career pivot.")),
                   if (pct >= 80)
                     div(class="success-box", HTML("✅ Strong career profile! Focus on delivery: practise verbal STAR answers under time pressure. Aim for 90-120 seconds per story."))
            )
          )
        )
      })
    })
  })
}
