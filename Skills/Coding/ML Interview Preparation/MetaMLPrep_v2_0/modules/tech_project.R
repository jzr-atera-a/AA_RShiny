# modules/tech_project.R
# Tab 5: Technical Project Interview (PDF page 10)
# One 45-minute discussion-based interview on a past ML system

tech_project_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    div(class="meta-hero",
        tags$h1("Technical Project Interview"),
        tags$h2("One 45-Minute Deep-Dive on Your Best ML System"),
        div(
          span(class="hero-badge", "Architecture"),
          span(class="hero-badge", "Trade-offs"),
          span(class="hero-badge", "End-to-End Ownership"),
          span(class="hero-badge", "No Slide Decks")
        )
    ),
    
    fluidRow(
      box(title="📋 What Meta Is Looking For", status="primary",
          solidHeader=TRUE, width=6,
          
          div(class="success-box",
              HTML("<strong>✅ Format:</strong> A conversation, not a presentation. No slide decks needed. Code examples and architectural diagrams are encouraged. Come prepared to go deep on ONE project.")),
          br(),
          
          div(class="section-heading-dark", "What You'll Need to Cover"),
          timeline_entry("1","Setting Context (3-5 min)",
                         "The business problem. Why did this project exist? What would have happened without it? Make the interviewer care."),
          timeline_entry("2","High-Level Description (5 min)",
                         "Architecture overview. Key components. How data flows end-to-end from raw input to model prediction to business impact."),
          timeline_entry("3","Deep Architecture Discussion (20 min)",
                         "THIS IS THE KEY PART. Design choices and WHY. Alternatives you considered. Trade-offs you made. Constraints you worked under."),
          timeline_entry("4","Q&A — Interviewers Dig In (12 min)",
                         "Expect: 'Why not X instead?', 'How does it perform at scale?', 'What would you do differently?', 'Walk me through a failure.'"),
          timeline_entry("5","Wrap-Up (3 min)",
                         "Future improvements. What you learned. Org impact beyond your team."),
          
          div(class="warn-box",
              HTML("<strong>⚠️ Most common mistake:</strong> Spending too long on context and not enough on architecture. Get to the technical depth fast — that's what they're evaluating."))
      ),
      
      box(title="🏗️ The Perfect ML Project to Present",
          status="info", solidHeader=TRUE, width=6,
          
          div(class="section-heading-dark", "Project Selection Criteria"),
          div(class="framework-card",
              tags$h5("✅ Ideal Characteristics"),
              tags$ul(
                tags$li(tags$b("You owned it end-to-end:"), " from problem framing to production monitoring"),
                tags$li(tags$b("Measurable business impact:"), " you can name a metric that moved"),
                tags$li(tags$b("Technical complexity:"), " non-trivial ML or infrastructure challenges"),
                tags$li(tags$b("Depth available:"), " you can answer 'why' for every design choice"),
                tags$li(tags$b("Failure included:"), " something didn't work and you fixed it"),
                tags$li(tags$b("Scale:"), " ideally millions+ users, large data volumes")
              )),
          
          div(class="framework-card",
              tags$h5("🎯 Evaluation Dimensions"),
              tags$ul(
                tags$li(tags$b("Breadth:"), " Can you describe the full system, not just your piece?"),
                tags$li(tags$b("Depth:"), " Can you go 5 layers deep on any component?"),
                tags$li(tags$b("Clarity:"), " Can you explain complex systems simply?"),
                tags$li(tags$b("Judgment:"), " Do your design choices make sense given the constraints?"),
                tags$li(tags$b("'What if' adaptability:"), " When they change requirements, can you adapt on the fly?")
              )),
          
          div(class="tip-box",
              HTML("<strong>💡 Pro tip:</strong> Choose a project where you can honestly say 'I made the final call on X.' Interviewers want to see decision-making authority, not just execution."))
      )
    ),
    
    # ── Project Builder ──────────────────────────────
    fluidRow(
      box(title="🛠️ Build Your Project Narrative", status="success",
          solidHeader=TRUE, width=12,
          
          tabsetPanel(
            tabPanel("Project Framing",
                     br(),
                     fluidRow(
                       column(6,
                              textInput(ns("proj_name"), "Project Name/Codename:", placeholder="e.g., 'Feed Quality Model', 'Listings Ranker v2'"),
                              textAreaInput(ns("proj_context"), "Business Context (1-3 sentences):",
                                            placeholder="Why did this project exist? What problem did it solve for users? What was the business impact if you didn't build it?",
                                            rows=4, width="100%"),
                              textAreaInput(ns("proj_scale"), "Scale & Constraints:",
                                            placeholder="Users served: ?\nData volume: ?\nLatency requirement: ?\nTeam size: ?\nTimeline: ?",
                                            rows=5, width="100%")
                       ),
                       column(6,
                              textAreaInput(ns("proj_problem"), "The Hard ML Problem:",
                                            placeholder="What made this technically challenging?\n- Data challenge?\n- Label noise / scarcity?\n- Scale / latency constraint?\n- Novel model architecture needed?",
                                            rows=4, width="100%"),
                              textAreaInput(ns("proj_result"), "Measurable Results:",
                                            placeholder="What metrics moved?\ne.g., +8% CTR, -15% latency p99, +2.3% DAU, $12M revenue impact, reduced content policy violations by 40%",
                                            rows=5, width="100%")
                       )
                     )
            ),
            tabPanel("Architecture Deep-Dive",
                     br(),
                     fluidRow(
                       column(6,
                              div(class="section-heading-dark", "Core Architecture"),
                              textAreaInput(ns("proj_arch"), "System Architecture (describe each component):",
                                            placeholder="Data Pipeline:\n- Source: ...\n- Processing: ...\n- Storage: ...\n\nFeature Engineering:\n- Dense features: ...\n- Sparse/categorical: ...\n- Real-time vs batch: ...\n\nModel Architecture:\n- Type: (Transformer / GBT / DLRM / etc.)\n- Why this choice: ...\n- Training: loss function, optimizer, infra\n\nServing:\n- How predictions are served\n- Latency SLO: ...\n- Caching strategy: ...",
                                            rows=16, width="100%")
                       ),
                       column(6,
                              div(class="section-heading-dark", "Design Trade-offs"),
                              textAreaInput(ns("proj_tradeoffs"), "Key Trade-offs You Made:",
                                            placeholder="Trade-off 1:\n  Option A: ...\n  Option B: ...\n  You chose: ...\n  Why: ...\n\nTrade-off 2:\n  ...\n\nTrade-off 3:\n  ...",
                                            rows=8, width="100%"),
                              div(class="section-heading-dark", "What Failed + What You Fixed"),
                              textAreaInput(ns("proj_failure"), "Failure Story:",
                                            placeholder="What didn't work as expected?\nHow did you debug it?\nWhat did you learn?\nHow did you fix it?",
                                            rows=7, width="100%")
                       )
                     ),
                     br(),
                     actionButton(ns("save_project"), "Save Project Narrative",
                                  class="btn-meta", icon=icon("save"))
            ),
            tabPanel("Likely Interview Questions",
                     br(),
                     div(class="section-heading-dark", "Hard Questions Meta Will Ask — Practice Your Answers"),
                     
                     fluidRow(
                       column(6,
                              lapply(list(
                                list(q="Why did you choose [your model] over [alternative]?",
                                     a="Have specific trade-offs: accuracy vs latency, data requirements, interpretability, training cost."),
                                list(q="What would happen if your training data distribution shifted?",
                                     a="Describe monitoring (data drift detection), retraining triggers, shadow mode testing."),
                                list(q="How did you handle class imbalance / label noise?",
                                     a="Specific techniques: oversampling, focal loss, confidence weighting, data cleaning pipeline."),
                                list(q="Walk me through a production incident with this system.",
                                     a="Describe the symptom, your debugging process (metrics → logs → root cause), fix, and post-mortem."),
                                list(q="How does your system scale to 10× the current load?",
                                     a="Identify bottlenecks, horizontally scalable components, caching, model quantisation for serving.")
                              ), function(qa) {
                                div(class="framework-card",
                                    tags$h5(icon("question-circle"), " ", qa$q),
                                    div(class="tip-box", HTML(paste0("<strong>Prep angle:</strong> ", qa$a))),
                                    textAreaInput(ns(paste0("qa_", which(sapply(list(
                                      "Why model choice?","Data shift?","Class imbalance?","Production incident?","10× scale?"
                                    ), function(x) grepl(x, qa$q, ignore.case=TRUE))))), 
                                               "Your Answer:", rows=2, width="100%"))
                              })
                       ),
                       column(6,
                              lapply(list(
                                list(q="What would you do differently if you started over?",
                                     a="Shows growth mindset. Mention architectural decisions, team/process learnings. Don't say 'nothing'."),
                                list(q="How did you measure the business impact of this project?",
                                     a="Describe A/B test design, primary metric, guardrail metrics, statistical significance, holdout analysis."),
                                list(q="Who else depended on your system? How did you coordinate?",
                                     a="Describe downstream consumers, API contracts, SLOs, communication channels, stakeholder updates."),
                                list(q="What was the hardest engineering problem you solved?",
                                     a="Pick a specific, non-trivial challenge. Show deep technical understanding, creative solution."),
                                list(q="How did you mentor junior engineers on this project?",
                                     a="L6 angle: code review culture, design doc process, pair programming, growth of the team, not just yourself.")
                              ), function(qa) {
                                div(class="framework-card",
                                    tags$h5(icon("question-circle"), " ", qa$q),
                                    div(class="tip-box", HTML(paste0("<strong>Prep angle:</strong> ", qa$a))))
                              })
                       )
                     )
            )
          )
      )
    ),
    
    # ── Self-Score ────────────────────────────────────
    fluidRow(
      box(title="📊 Project Readiness Tracker", status="primary",
          solidHeader=TRUE, width=12,
          
          fluidRow(
            column(3, sliderInput(ns("sc_breadth"),   "System Breadth (know all layers)",  0,10,5)),
            column(3, sliderInput(ns("sc_depth"),     "Architecture Depth (5 layers deep)", 0,10,5)),
            column(3, sliderInput(ns("sc_tradeoffs"), "Trade-off Clarity",                  0,10,5)),
            column(3, sliderInput(ns("sc_impact"),    "Business Impact Quantified",         0,10,5))
          ),
          actionButton(ns("calc_readiness"), "Calculate Readiness", class="btn-meta"),
          br(), br(),
          uiOutput(ns("readiness_result"))
      )
    )
  )
}

tech_project_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$save_project, {
      prep_manager$save_note("tech_project_name",    input$proj_name)
      prep_manager$save_note("tech_project_context", input$proj_context)
      prep_manager$save_note("tech_project_arch",    input$proj_arch)
      showNotification("Project narrative saved!", type="message")
    })
    
    observeEvent(input$calc_readiness, {
      avg <- mean(c(input$sc_breadth, input$sc_depth, input$sc_tradeoffs, input$sc_impact))
      pct <- round(avg * 10)
      prep_manager$update_progress("tech_project", pct)
      
      output$readiness_result <- renderUI({
        colour <- progress_colour(pct)
        weakest <- c(breadth=input$sc_breadth, depth=input$sc_depth,
                     tradeoffs=input$sc_tradeoffs, impact=input$sc_impact)
        weak_name <- names(which.min(weakest))
        
        div(class = if(pct>=70) "success-box" else "tip-box",
            fluidRow(
              column(4, div(style=paste0("text-align:center;"),
                            tags$h2(style=paste0("color:",colour), paste0(pct, "%")),
                            tags$p("Project Readiness"))),
              column(8,
                     tags$p(tags$b("Weakest area: "), weak_name),
                     if (pct < 60) tags$p("⚠️ Your project narrative needs more depth. Use the Architecture tab to flesh out every component."),
                     if (pct >= 60 && pct < 80) tags$p("💡 Good foundation. Practise answering the 'what would you do differently?' question."),
                     if (pct >= 80) tags$p("✅ Strong project story! Focus on delivery — be concise but deep.")
              )
            )
        )
      })
    })
  })
}
