# modules/cross_functional_profile.R
# Profile Tab 6: Your XFN Stories — Santander 40-person, BCG multi-region, Atera Gov/Industry

cross_functional_profile_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Your Cross-Functional Partnership Stories"),
        tags$h2("40-Person Teams · 4 Continents · Government · NVIDIA · Oxford · BCG Clients"),
        div(
          span(class = "hero-badge", "Santander: 40+ XFN Team"),
          span(class = "hero-badge", "BCG: East Asia + EU + Americas"),
          span(class = "hero-badge", "Oxford Research Bridge"),
          span(class = "hero-badge", "UK Gov Stakeholders")
        )
    ),

    # ── Your XFN Assets ──────────────────────────────
    fluidRow(
      box(title = "🗺️ Your XFN Evidence — Exceptional for L6+",
          status = "primary", solidHeader = TRUE, width = 12,

          fluidRow(
            column(3, div(class = "metric-card",
                          span(class = "metric-value", "40+"),
                          span(class = "metric-label", "XFN Team (Santander)"))),
            column(3, div(class = "metric-card",
                          span(class = "metric-value", "4"),
                          span(class = "metric-label", "Continents (BCG)"))),
            column(3, div(class = "metric-card",
                          span(class = "metric-value", "3"),
                          span(class = "metric-label", "Partner Types: Gov/Corp/Academia"))),
            column(3, div(class = "metric-card",
                          span(class = "metric-value", "5+"),
                          span(class = "metric-label", "Industry Verticals")))
          ),
          br(),
          div(class = "success-box",
              HTML("<strong>✅ Assessment:</strong> Your XFN profile is unusually rich for a technical candidate. Most engineers at L6 have managed a team of 5-10. You managed 40+ across continents at Santander, coordinated Government/NVIDIA/AWS/GCP partnerships at Atera, and bridged academic research (Oxford/Sydney) with commercial production. The challenge is <em>selecting the right story</em> and making it specific enough."))
      )
    ),

    # ── Story Bank ───────────────────────────────────
    fluidRow(
      box(title = "📖 Your XFN Story Bank — Pre-Identified from CV",
          status = "info", solidHeader = TRUE, width = 12,

          tabsetPanel(
            # ── Research ↔ Eng ────────────────────────
            tabPanel("Research ↔ Engineering",
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "section-heading-dark", "Your Story: Oxford × Santander"),
                              div(class = "framework-card",
                                  tags$h5("Context"),
                                  tags$p("You led a partnership between Santander's ML Engineering team and University of Oxford's Financial Mathematics research group — translating cutting-edge academic research into production-grade systems for 30 million customers."),
                                  tags$p("This is a ", tags$em("classic"), " Research ↔ Engineering XFN tension: Oxford researchers optimise for publication novelty, Santander ML Engineers optimise for production reliability and P&L impact.")),
                              div(class = "framework-card",
                                  tags$h5("Meta's XFN Question Mapped to Your Story"),
                                  div(class = "practice-area",
                                      tags$p(tags$b("Prompt:"), " 'Walk me through a project that required collaboration across research and engineering. How did you ensure alignment?'")),
                                  div(class = "tip-box",
                                      HTML("<strong>💡 Tension to highlight:</strong>
                                      <ul>
                                      <li>Oxford researchers wanted to explore novel financial mathematics models → long research cycles</li>
                                      <li>Santander production required: stable, interpretable, auditable ML (regulatory requirement)</li>
                                      <li>The conflict: how do you maintain research velocity while ensuring production deployability?</li>
                                      <li>Your resolution: [FILL IN — what mechanism did you create? Joint evaluation criteria? Deployment gates? Staged research?]</li>
                                      </ul>"))
                              )
                       ),
                       column(6,
                              div(class = "section-heading-dark", "Write Your Oxford XFN Story (STAR)"),
                              textAreaInput(ns("oxford_xfn"), label = NULL, rows = 14,
                                            width = "100%",
                                            value =
"SITUATION: At Santander, I led a research partnership with University of
Oxford on Financial Mathematics and Deep Learning — bridging academic
research with production requirements for 30M customers.

TASK: My role was to ensure Oxford's novel research translated into
production-grade ML systems — maintaining academic rigour while meeting
Santander's regulatory, latency, and reliability requirements.

ACTION:
[EXPAND - describe the specific tension you navigated. For example:]
- A specific Oxford model that was academically novel but not production-viable
- How you decided which research directions to pursue vs deprioritise
- The mechanism you created for research → production handoff
- A conflict between a researcher's agenda and an engineering constraint
- How you communicated constraints to academics without stifling innovation
- How you communicated research timelines to Santander leadership

RESULT:
- [What shipped? What research was successfully productionised?]
- [What research was abandoned and how did you handle that with Oxford?]
- £20M+ impact — which specific models from Oxford contributed?

WHAT I'D DO DIFFERENTLY:
[Honest reflection — this is what Meta is listening for]"
                              ),
                              actionButton(ns("save_oxford"), "Save Oxford Story", class = "btn-meta")
                       )
                     )
            ),

            # ── Multi-Region ──────────────────────────
            tabPanel("Multi-Region · BCG",
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "section-heading-dark", "Your Story: BCG East Asia + EU + Americas"),
                              div(class = "framework-card",
                                  tags$h5("Context"),
                                  tags$p("At BCG you coordinated software development across four multidisciplinary teams distributed in East Asia, Europe, and the Americas — delivering production AI systems to institutional client standards."),
                                  tags$p("This is a genuine global XFN coordination story. Timezone management (12+ hour gaps), technical alignment across language barriers, institutional client expectations, and software delivery under consulting timelines.")),
                              div(class = "framework-card",
                                  tags$h5("The Hard Parts (expand on these)"),
                                  tags$ul(
                                    tags$li(tags$b("Technical alignment:"), " How did you ensure code quality standards across teams that couldn't pair-program in real time?"),
                                    tags$li(tags$b("Conflict:"), " A specific disagreement between East Asia and EU teams on architecture choice — how did you resolve it?"),
                                    tags$li(tags$b("Client pressure:"), " A Fortune 500 client changing requirements mid-project — how did you communicate the impact to your distributed teams?"),
                                    tags$li(tags$b("Self-awareness moment:"), " Something that went poorly in the cross-timezone coordination that you'd change now.")
                                  )),
                              div(class = "tip-box",
                                  HTML("<strong>💡 L6 angle for this story:</strong> The key insight Meta wants to see is not just 'I coordinated people' but 'I designed a coordination system that scaled.' What process did you create that outlasted your involvement?"))
                       ),
                       column(6,
                              div(class = "section-heading-dark", "Write Your BCG Multi-Region Story"),
                              textAreaInput(ns("bcg_xfn"), label = NULL, rows = 14,
                                            width = "100%",
                                            value =
"SITUATION: At BCG I coordinated four software engineering teams across
East Asia, Europe, and the Americas — delivering production AI and CV
systems for Fortune 500 clients in Health and Bio-Chemical sectors.

TASK: As Lead Consultant, I was responsible for technical alignment,
delivery coordination, and client communication across all four teams
simultaneously — across 12+ timezone gaps.

ACTION:
[EXPAND - describe your coordination system. For example:]
- How did you run technical design reviews across timezones?
- A specific architecture conflict between teams — how resolved?
- A client requirement change mid-project — how communicated?
- The 'asynchronous collaboration' mechanism you invented or evolved
- A relationship that didn't work initially and how you repaired it

RESULT:
- [What was delivered? To what standard? Client reaction?]
- [10× performance increments — which specific project? What was baseline?]
- [What did you build in terms of team culture or process that outlasted you?]

SELF-AWARENESS:
[What would you do differently in multi-region coordination now?]"
                              ),
                              actionButton(ns("save_bcg"), "Save BCG Story", class = "btn-meta")
                       )
                     )
            ),

            # ── Gov / Industry / Partnership ──────────
            tabPanel("Government · NVIDIA · AWS (Atera)",
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "section-heading-dark", "Your Story: UK Gov + NVIDIA + AWS/GCP at Atera"),
                              div(class = "framework-card",
                                  tags$h5("Context"),
                                  tags$p("At Atera you secured UK Government awards and worked alongside NVIDIA, Google Cloud, and AWS as technology partners — while also delivering for transport infrastructure and autonomous vehicle clients. This is a uniquely complex XFN environment: government procurement timelines, corporate partner roadmaps, and client delivery simultaneously."),
                                  tags$p("This is the story that shows L6+ maturity: ", tags$em("you managed stakeholders with fundamentally different incentives and timelines, and delivered."))),
                              div(class = "framework-card",
                                  tags$h5("Tensions to Highlight"),
                                  tags$ul(
                                    tags$li(tags$b("NVIDIA partnership:"), " Their GPU roadmap (H100, L40) influenced your inference architecture choices. How did you navigate commitments to a partner whose product timeline you didn't control?"),
                                    tags$li(tags$b("UK Government:"), " Government procurement and reporting requirements are slow and rigid. How did you deliver innovation in an environment optimised for compliance?"),
                                    tags$li(tags$b("Client vs partner priorities:"), " When a client needed feature X but the NVIDIA/AWS partnership roadmap prioritised Y — how did you navigate?")
                                  ))
                       ),
                       column(6,
                              div(class = "section-heading-dark", "Write Your Atera Stakeholder Story"),
                              textAreaInput(ns("atera_xfn"), label = NULL, rows = 14,
                                            width = "100%",
                                            value =
"SITUATION: At Atera, I managed a complex multi-stakeholder environment:
UK Government funders, NVIDIA/AWS/GCP as technology partners, and
transport infrastructure / AV clients as end customers — simultaneously.

TASK: [What specific XFN challenge did you navigate? Choose one concrete
example — a specific project, a specific conflict, a specific alignment
challenge that tested your partnership skills.]

ACTION:
[The actions you took. Focus on:]
- How you aligned stakeholders with different incentives
- A specific moment of conflict and your resolution approach
- Something you learned about stakeholder management that surprised you
- How you maintained UK Gov reporting requirements while maintaining
  engineering velocity (these two goals often conflict)

RESULT:
[What was the outcome? Awards received? Partnerships formalised?
Client deployment? What did you change in how you manage stakeholders?]

SELF-AWARENESS:
[One thing you'd do differently in managing this stakeholder environment]"
                              ),
                              actionButton(ns("save_atera_xfn"), "Save Atera XFN Story", class = "btn-meta")
                       )
                     )
            ),

            # ── Failure ───────────────────────────────
            tabPanel("Your XFN Failure Story",
                     br(),
                     div(class = "warn-box",
                         HTML("<strong>⚠️ Meta explicitly looks for XFN failure stories.</strong> Prepare ONE specific XFN relationship that didn't go well. Don't sanitise it. Interviewers can tell.")),
                     br(),
                     fluidRow(
                       column(6,
                              div(class = "section-heading-dark", "Candidate XFN Failures from Your CV"),
                              div(class = "framework-card",
                                  tags$h5("Option A: Research relationship at Oxford that ended poorly"),
                                  tags$p("If there was an Oxford researcher whose work you couldn't productionise, or a conflict over methodology that damaged the relationship temporarily — this is gold. Shows self-awareness and analytical honesty.")),
                              div(class = "framework-card",
                                  tags$h5("Option B: A BCG client relationship that was difficult"),
                                  tags$p("A client who kept changing requirements, or a client stakeholder who was resistant to AI adoption. How did you handle it? What would you do differently?")),
                              div(class = "framework-card",
                                  tags$h5("Option C: A team member conflict at Santander (40-person team)"),
                                  tags$p("With 40 people across UK/EU/Americas, there were certainly performance issues, role conflicts, or cultural misalignments. A specific person who was difficult and what you learned from managing that relationship.")),
                              div(class = "tip-box",
                                  HTML("<strong>💡 The formula for a great XFN failure story:</strong><br/>
                                  1. Name the relationship specifically (role, context, not the person)<br/>
                                  2. Describe the moment the relationship broke down<br/>
                                  3. What you thought at the time (vs what you now understand)<br/>
                                  4. What you tried that didn't work<br/>
                                  5. What finally resolved it (or: it never fully resolved, and here's what I accepted)<br/>
                                  6. What you changed in your approach to XFN partnerships as a result"))
                       ),
                       column(6,
                              textAreaInput(ns("xfn_failure"), "Your XFN Failure Story:", rows = 16,
                                            width = "100%",
                                            placeholder = "CONTEXT: Who was the partner / team?\n\nWHAT WENT WRONG: The specific breakdown moment\n\nWHAT I THOUGHT AT THE TIME: (vs what I now understand)\n\nWHAT I TRIED: Actions that didn't work\n\nRESOLUTION (or acceptance):\n\nWHAT I CHANGED: In my approach to XFN partnerships"),
                              actionButton(ns("save_failure"), "Save XFN Failure Story", class = "btn-meta")
                       )
                     )
            )
          )
      )
    ),

    # ── Readiness ────────────────────────────────────
    fluidRow(
      box(title = "📊 XFN Readiness Assessment", status = "success",
          solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, sliderInput(ns("xfn_s1"), "Oxford/Research XFN story polished", 0, 10, 3)),
            column(3, sliderInput(ns("xfn_s2"), "BCG multi-region story polished",    0, 10, 3)),
            column(3, sliderInput(ns("xfn_s3"), "Gov/industry stakeholder story",     0, 10, 3)),
            column(3, sliderInput(ns("xfn_s4"), "XFN failure story ready",            0, 10, 1))
          ),
          actionButton(ns("assess_xfn"), "Calculate XFN Readiness", class = "btn-meta"),
          br(), br(),
          uiOutput(ns("xfn_readiness"))
      )
    )
  )
}

cross_functional_profile_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$save_oxford,     { prep_manager$save_note("xfnp_oxford",  input$oxford_xfn);   showNotification("Oxford XFN saved!",   type = "message") })
    observeEvent(input$save_bcg,        { prep_manager$save_note("xfnp_bcg",     input$bcg_xfn);      showNotification("BCG XFN saved!",      type = "message") })
    observeEvent(input$save_atera_xfn,  { prep_manager$save_note("xfnp_atera",   input$atera_xfn);    showNotification("Atera XFN saved!",    type = "message") })
    observeEvent(input$save_failure,    { prep_manager$save_note("xfnp_failure", input$xfn_failure);  showNotification("Failure story saved!", type = "message") })

    observeEvent(input$assess_xfn, {
      avg <- mean(c(input$xfn_s1, input$xfn_s2, input$xfn_s3, input$xfn_s4))
      pct <- round(avg * 10)
      prep_manager$update_progress("cross_functional_profile", pct)

      output$xfn_readiness <- renderUI({
        colour <- progress_colour(pct)
        div(class = if (pct >= 65) "success-box" else "tip-box",
            tags$h4(style = paste0("color:", colour), paste0("XFN Readiness: ", pct, "%")),
            if (input$xfn_s4 < 5) div(class = "warn-box",
                HTML("⚠️ <strong>Priority:</strong> Your XFN failure story needs work. Meta interviewers specifically probe for self-awareness moments. A high score on success stories with no failure story will feel defensive.")),
            if (input$xfn_s1 >= 7 && input$xfn_s2 >= 7) div(class = "success-box",
                HTML("✅ Strong research + multi-region stories. These are exactly what Meta Reality Labs XFN interviewers want to hear.")),
            if (pct >= 75) tags$p("Good XFN profile. Practise 90-second verbal delivery for each story. The goal is concise specificity, not comprehensive coverage.")
        )
      })
    })
  })
}
