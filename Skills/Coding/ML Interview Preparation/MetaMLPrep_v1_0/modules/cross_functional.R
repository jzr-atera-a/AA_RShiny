# modules/cross_functional.R
# Tab 6: Cross-Functional (XFN) Partnership Interview (PDF page 11)
# One 45-min interview on collaboration, influence, conflict resolution

cross_functional_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    div(class="meta-hero",
        tags$h1("Cross-Functional (XFN) Interview"),
        tags$h2("One 45-Minute Session — Partnerships, Influence & Alignment"),
        div(
          span(class="hero-badge", "Collaboration"),
          span(class="hero-badge", "Conflict Resolution"),
          span(class="hero-badge", "Influence Without Authority"),
          span(class="hero-badge", "Self-Awareness")
        )
    ),
    
    fluidRow(
      box(title="🤝 What the XFN Interview Covers",
          status="primary", solidHeader=TRUE, width=6,
          
          div(class="success-box",
              HTML("<strong>✅ Core premise:</strong> Meta wants to know if you can build and maintain effective partnerships across PM, Design, Research, Data Engineering, Infra, Legal, Policy — and do so WITHOUT formal authority.")),
          br(),
          
          div(class="section-heading-dark", "Typical Opening Prompt"),
          div(class="practice-area",
              p(tags$i('"Walk me through a project or initiative you led that required collaboration across multiple functions. How did you ensure effectiveness? How did you keep teams aligned?"'))),
          br(),
          
          div(class="section-heading-dark", "What They're Evaluating"),
          div(class="framework-card",
              tags$h5("1. Can You Work Across the Company?"),
              tags$p("Do you have stories that span multiple teams? Did you bridge ML Research with Product Engineering? Coordinate between Policy and your model's output? Influence decisions at VP level with data?")),
          div(class="framework-card",
              tags$h5("2. Self-Awareness"),
              tags$p("Meta values honesty. They want to hear about partnerships that DIDN'T go well, conflicts you COULDN'T fully resolve, and what you LEARNED. Don't only tell success stories.")),
          div(class="framework-card",
              tags$h5("3. Different Approaches & Agendas"),
              tags$p("Can you handle a PM who doesn't understand ML constraints? A Research team who wants to ship a complex model you think is over-engineered? A Legal team blocking your data usage?"))
      ),
      
      box(title="💡 XFN at L6 — The Leadership Lens",
          status="info", solidHeader=TRUE, width=6,
          
          div(class="warn-box",
              HTML("<strong>⚠️ At L6+:</strong> XFN isn't just 'I collaborated with PM.' You're expected to BUILD the systems and processes that enable your team and adjacent teams to collaborate effectively.")),
          br(),
          
          div(class="section-heading-dark", "L6 XFN Expectations"),
          tags$ul(
            tags$li(tags$b("Influence upward:"), " You've shaped decisions at VP/Director level. Show how you used data and prototypes to move leadership."),
            tags$li(tags$b("Define the collaboration model:"), " You've designed how ML Engineering works with Research or with Product for your org, not just your team."),
            tags$li(tags$b("Navigate org politics:"), " You understand incentive misalignments between teams and know how to align them."),
            tags$li(tags$b("Handle difficult partnerships:"), " You have specific stories of hard working relationships and how you navigated them."),
            tags$li(tags$b("Build coalition:"), " You've recruited allies, built shared visions, and driven org-wide change.")
          ),
          br(),
          
          div(class="section-heading-dark", "XFN Failure Modes at Meta (What NOT to Do)"),
          div(class="warn-box", HTML("<strong>❌ Avoid:</strong> 'We had weekly syncs and used Slack.' This is table stakes, not L6 XFN.")),
          div(class="warn-box", HTML("<strong>❌ Avoid:</strong> Only telling stories where everything worked out perfectly. Self-awareness matters.")),
          div(class="warn-box", HTML("<strong>❌ Avoid:</strong> Vague collaboration stories without specific people, teams, outcomes.")),
          div(class="success-box", HTML("<strong>✅ Do:</strong> Name the teams, describe the conflict, show your process, acknowledge what you'd do differently."))
      )
    ),
    
    # ── ML-Specific XFN Scenarios ────────────────────
    fluidRow(
      box(title="🔬 ML-Specific XFN Scenarios to Prepare",
          status="warning", solidHeader=TRUE, width=12,
          
          tabsetPanel(
            tabPanel("Research ↔ Engineering",
                     br(),
                     fluidRow(
                       column(6,
                              div(class="practice-area",
                                  p(tags$b("Scenario:"), " FAIR Research published a breakthrough model (e.g., Segment Anything). Your product team needs to productionise it. Research wants to preserve model quality. Infra says the model is too large for serving. Product wants it shipped in 6 weeks."),
                                  p(tags$b("Typical conflict:"), " Research is measured on paper acceptance. Engineering is measured on latency SLOs. Product is measured on feature launches.")),
                              br(),
                              div(class="tip-box",
                                  HTML("<strong>💡 Strong answer includes:</strong>
                                  <ul>
                                  <li>How you <b>translated</b> Research metrics (perplexity, IOU) to product metrics (user engagement)</li>
                                  <li>How you <b>negotiated</b> model distillation or quantisation as a middle path</li>
                                  <li>How you set up a <b>shared evaluation framework</b> both teams accepted</li>
                                  <li>How you <b>managed expectations</b> with Product about the 6-week timeline</li>
                                  </ul>"))
                       ),
                       column(6,
                              div(class="section-heading-dark", "Write Your Research XFN Story"),
                              textAreaInput(ns("story_research_xfn"), label=NULL,
                                            placeholder="Describe a Research ↔ Engineering collaboration...\n\nSituation:\nTeams involved:\nConflict/Tension:\nYour Role:\nActions you took:\nResult:\nWhat you'd do differently:",
                                            rows=12, width="100%"),
                              actionButton(ns("save_research"), "Save Story", class="btn-meta")
                       )
                     )
            ),
            tabPanel("Product ↔ ML Engineering",
                     br(),
                     fluidRow(
                       column(6,
                              div(class="practice-area",
                                  p(tags$b("Scenario:"), " A PM wants to launch a new ML feature (e.g., personalised notifications). Your team's assessment is that you don't have enough quality data for the model to work well in the first 6 months. The PM has an OKR that requires the launch. Leadership is aligned with the PM."),
                                  p(tags$b("Typical conflict:"), " PM wants feature. ML Engineer says it won't work. Leadership wants to move fast.")),
                              br(),
                              div(class="tip-box",
                                  HTML("<strong>💡 Strong answer includes:</strong>
                                  <ul>
                                  <li>How you <b>quantified the risk</b>: 'A bad recommendation at launch will reduce opt-in rates by X%'</li>
                                  <li>How you proposed a <b>phased launch</b>: limited rollout to gather quality feedback data</li>
                                  <li>How you influenced the PM to reframe their OKR around a leading indicator vs lagging metric</li>
                                  <li>What you agreed on: 1% rollout with quality guardrails, then decision gate</li>
                                  </ul>"))
                       ),
                       column(6,
                              div(class="section-heading-dark", "Write Your PM XFN Story"),
                              textAreaInput(ns("story_pm_xfn"), label=NULL,
                                            placeholder="Describe a Product ↔ ML Engineering collaboration...",
                                            rows=12, width="100%"),
                              actionButton(ns("save_pm"), "Save Story", class="btn-meta")
                       )
                     )
            ),
            tabPanel("Data, Legal & Policy",
                     br(),
                     fluidRow(
                       column(6,
                              div(class="practice-area",
                                  p(tags$b("Scenario:"), " You need user behavioural data to train a content moderation model. Legal/Privacy says certain signals can't be used without consent. Policy says the model outputs must be explainable. Data Engineering says the pipeline to get the data will take 3 months."),
                                  p(tags$b("Typical conflict:"), " Technical needs vs legal constraints vs timeline pressure.")),
                              br(),
                              div(class="tip-box",
                                  HTML("<strong>💡 Strong answer includes:</strong>
                                  <ul>
                                  <li>How you <b>engaged Legal early</b> — data privacy review in the design phase, not after</li>
                                  <li>How you used <b>differential privacy</b> or aggregation to make legally compliant training data</li>
                                  <li>How you <b>reframed explainability</b> as a feature for trust, not a constraint</li>
                                  <li>How you <b>unblocked Data Engineering</b> by scoping a smaller, faster MVP dataset</li>
                                  </ul>"))
                       ),
                       column(6,
                              div(class="section-heading-dark", "Write Your Data/Legal XFN Story"),
                              textAreaInput(ns("story_legal_xfn"), label=NULL,
                                            placeholder="Describe a Data/Legal/Policy collaboration...",
                                            rows=12, width="100%"),
                              actionButton(ns("save_legal"), "Save Story", class="btn-meta")
                       )
                     )
            )
          )
      )
    ),
    
    # ── Self-Score ────────────────────────────────────
    fluidRow(
      box(title="📊 XFN Readiness Tracker", status="success",
          solidHeader=TRUE, width=12,
          
          fluidRow(
            column(3, sliderInput(ns("xfn_stories"),   "XFN Stories Prepared (0-5 stories)", 0, 5, 0)),
            column(3, sliderInput(ns("xfn_failure"),   "Failure Stories w/ Learnings (0-3)",  0, 3, 0)),
            column(3, sliderInput(ns("xfn_influence"),  "Leadership/Influence Examples (0-5)", 0, 5, 0)),
            column(3, sliderInput(ns("xfn_awareness"), "Self-Awareness Moments (0-3)",         0, 3, 0))
          ),
          actionButton(ns("calc_xfn"), "Calculate XFN Readiness", class="btn-meta"),
          br(), br(),
          uiOutput(ns("xfn_result"))
      )
    )
  )
}

cross_functional_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$save_research, {
      prep_manager$save_note("xfn_research", input$story_research_xfn)
      showNotification("Research XFN story saved!", type="message")
    })
    observeEvent(input$save_pm, {
      prep_manager$save_note("xfn_pm", input$story_pm_xfn)
      showNotification("PM XFN story saved!", type="message")
    })
    observeEvent(input$save_legal, {
      prep_manager$save_note("xfn_legal", input$story_legal_xfn)
      showNotification("Legal XFN story saved!", type="message")
    })
    
    observeEvent(input$calc_xfn, {
      score <- (input$xfn_stories / 5 * 30) +
               (input$xfn_failure / 3 * 25) +
               (input$xfn_influence / 5 * 30) +
               (input$xfn_awareness / 3 * 15)
      pct <- round(score)
      prep_manager$update_progress("cross_functional", pct)
      
      output$xfn_result <- renderUI({
        colour <- progress_colour(pct)
        div(
          div(style=paste0("text-align:center;padding:20px;background:",
                           if(pct>=70)"#f0fdf4" else "#fef3c7",
                           ";border-radius:12px;"),
              tags$h2(style=paste0("color:",colour), paste0(pct, "%")),
              tags$p(tags$b("XFN Readiness")),
              if (input$xfn_failure == 0) div(class="warn-box", HTML("⚠️ You need failure stories. Meta interviewers <em>specifically</em> look for self-awareness. Add 1-2 stories where XFN didn't go perfectly.")),
              if (input$xfn_stories < 3) div(class="tip-box", HTML("💡 Aim for at least 3 distinct XFN stories across different partner types (Research, PM, Legal).")),
              if (pct >= 80) div(class="success-box", HTML("✅ Strong XFN profile. Practise verbal delivery — keep each story to 90 seconds max."))
          )
        )
      })
    })
  })
}
