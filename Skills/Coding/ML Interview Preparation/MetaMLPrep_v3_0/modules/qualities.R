# modules/qualities.R
# Tab 2: Engineer Qualities Meta Looks For (PDF page 7)

qualities_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    div(class = "meta-hero",
        tags$h1("Qualities Meta Looks For"),
        tags$h2("Software Engineer (Leadership) — What Makes You Stand Out"),
        div(
          span(class="hero-badge", "Ownership"),
          span(class="hero-badge", "Flexibility"),
          span(class="hero-badge", "Boldness"),
          span(class="hero-badge", "L6+ Leadership")
        )
    ),
    
    fluidRow(
      # ── Three Core Qualities ─────────────────────────
      box(title = "🏆 The Three Core Qualities", status = "primary",
          solidHeader = TRUE, width = 8,
          
          # Quality 1
          div(class="framework-card",
              tags$h5(icon("flag-checkered"), "  1. Ownership of Projects — From Start to Finish"),
              tags$p("Meta engineers don't hand-off. They own: design → development → implementation → support → monitoring. You are expected to understand every layer of your system."),
              br(),
              div(class="tip-box",
                  HTML("<strong>💡 For ML Leadership:</strong> You should own model performance in production, not just accuracy on a test set. Talk about oncall, debugging regressions, and root-cause analysis.")),
              br(),
              div(class="section-heading-dark", "How to demonstrate this in your answers:"),
              tags$ul(
                tags$li("Name the system. Give it a real name and describe its impact in user-facing metrics."),
                tags$li("Describe failure modes you fixed — oncall incidents, model degradation, data drift."),
                tags$li("Show the full lifecycle: problem framing → data collection → modelling → deployment → iteration."),
                tags$li("At L6: show you influenced the team's ownership culture, not just your own work.")
              )
          ),
          
          # Quality 2
          div(class="framework-card",
              tags$h5(icon("random"), "  2. Ability to Thrive in a Flat, Flexible Environment"),
              tags$p("Meta's org is relatively flat. You're expected to context-switch, jump into unfamiliar codebases, collaborate without waiting for permission, and drive work without being assigned it."),
              br(),
              div(class="tip-box",
                  HTML("<strong>💡 For ML Leadership:</strong> You should have examples of spotting a problem in an adjacent team's ML system and proactively helping fix it — without being asked.")),
              br(),
              div(class="section-heading-dark", "What flat environment means at L6+:"),
              tags$ul(
                tags$li("You self-direct. You don't need a manager to tell you what the next big problem is."),
                tags$li("You can contribute across: data pipelines, feature engineering, modelling, serving infra, evaluation."),
                tags$li("You coordinate across teams (Research, PM, Data Eng, Infra) without formal authority."),
                tags$li("You context-switch between strategic direction-setting and hands-on debugging.")
              )
          ),
          
          # Quality 3
          div(class="framework-card",
              tags$h5(icon("fire"), "  3. Daringness to Be Bold"),
              tags$p("Meta engineers embrace uncertainty. They take on projects where the path isn't clear. They propose novel approaches. They iterate fast, fail, and learn. Don't be the engineer who waits for certainty."),
              br(),
              div(class="tip-box",
                  HTML("<strong>💡 For ML Leadership:</strong> Talk about times you proposed a risky modelling approach that the team was sceptical of — and what happened. Win or lose, the boldness matters.")),
              br(),
              div(class="section-heading-dark", "Bold engineering stories should include:"),
              tags$ul(
                tags$li("A moment of uncertainty: 'We didn't know if this would work, but I proposed we try...'"),
                tags$li("A fast iteration: 'We shipped a prototype in a week to validate the hypothesis.'"),
                tags$li("A learning from failure: 'The first version underperformed. Here's what we changed.'"),
                tags$li("A non-obvious insight: 'Everyone assumed X, but the data showed Y.'")
              )
          )
      ),
      
      # ── Self-Assessment ──────────────────────────────
      column(4,
             box(title = "📊 Self-Assessment", status = "info",
                 solidHeader = TRUE, width = 12,
                 
                 div(class="section-heading-dark", "Rate your stories"),
                 
                 sliderInput(ns("ownership_score"), "Ownership Examples",
                             min=0, max=10, value=5, step=1),
                 sliderInput(ns("flexibility_score"), "Flexibility Examples",
                             min=0, max=10, value=5, step=1),
                 sliderInput(ns("boldness_score"), "Boldness Examples",
                             min=0, max=10, value=5, step=1),
                 
                 actionButton(ns("assess_btn"), "Update Assessment",
                              class="btn-meta", width="100%"),
                 br(), br(),
                 uiOutput(ns("assessment_result"))
             ),
             
             box(title = "🎯 L6+ Specific Expectations", status = "warning",
                 solidHeader = TRUE, width = 12,
                 
                 div(class="warn-box",
                     HTML("<strong>⚠️ L6 is Staff-equivalent.</strong> The bar is significantly higher than L5.")),
                 
                 tags$ul(style="font-size:13px;",
                   tags$li(tags$b("Scope:"), " Your work impacts multiple teams or the org"),
                   tags$li(tags$b("Autonomy:"), " You drive initiatives, not just execute them"),
                   tags$li(tags$b("Mentorship:"), " You actively grow L4/L5 engineers"),
                   tags$li(tags$b("Communication:"), " You influence VP-level decisions with data and prototypes"),
                   tags$li(tags$b("Technical Vision:"), " You propose 6-18 month roadmaps with justification")
                 )
             )
      )
    ),
    
    # ── Practice Area ─────────────────────────────────
    fluidRow(
      box(title = "✍️ Practice: Write Your Quality Stories",
          status = "success", solidHeader = TRUE, width = 12,
          
          tabsetPanel(
            tabPanel("Ownership Story",
                     br(),
                     div(class="practice-area",
                         p(tags$b("Prompt:"), " Describe an ML system you owned end-to-end. What did you build, what was the business impact, and what did you do when something broke in production?"),
                         textAreaInput(ns("story_ownership"), label=NULL,
                                       placeholder="Write your ownership story here (STAR format recommended)...",
                                       rows=7, width="100%"),
                         actionButton(ns("save_ownership"), "Save", class="btn-meta")
                     ),
                     br(),
                     div(class="tip-box",
                         HTML("<strong>STAR reminder:</strong> <b>S</b>ituation (1 sentence), <b>T</b>ask (1 sentence), <b>A</b>ction (the meaty part — 5+ sentences), <b>R</b>esult (quantified, user-facing metrics)."))
            ),
            tabPanel("Flexibility Story",
                     br(),
                     div(class="practice-area",
                         p(tags$b("Prompt:"), " Tell me about a time you jumped into an unfamiliar codebase or technical domain and drove meaningful change. How did you learn fast and contribute?"),
                         textAreaInput(ns("story_flexibility"), label=NULL,
                                       placeholder="Write your flexibility story here...",
                                       rows=7, width="100%"),
                         actionButton(ns("save_flexibility"), "Save", class="btn-meta")
                     )
            ),
            tabPanel("Boldness Story",
                     br(),
                     div(class="practice-area",
                         p(tags$b("Prompt:"), " Describe a time you took on a project where the outcome was uncertain, you or your team weren't sure it would work, but you moved fast and iterated. What happened?"),
                         textAreaInput(ns("story_boldness"), label=NULL,
                                       placeholder="Write your boldness story here...",
                                       rows=7, width="100%"),
                         actionButton(ns("save_boldness"), "Save", class="btn-meta")
                     )
            )
          )
      )
    )
  )
}

qualities_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$assess_btn, {
      avg <- mean(c(input$ownership_score, input$flexibility_score, input$boldness_score))
      pct <- round(avg * 10)
      prep_manager$update_progress("qualities", pct)
      
      output$assessment_result <- renderUI({
        colour <- progress_colour(pct)
        div(style = paste0("text-align:center;padding:15px;background:",
                           if(pct>=70) "#f0fdf4" else "#fef3c7",
                           ";border-radius:10px;"),
            tags$h3(style=paste0("color:",colour), paste0(pct, "% ready")),
            tags$p(if(pct >= 80) "Strong story bank! Focus on refining delivery."
                   else if(pct >= 60) "Good foundation. Add more specific examples."
                   else "Need more concrete stories with metrics. Use the Practice tabs."))
      })
    })
    
    observeEvent(input$save_ownership,   {
      prep_manager$save_note("qualities_ownership", input$story_ownership)
      showNotification("Ownership story saved!", type="message")
    })
    observeEvent(input$save_flexibility, {
      prep_manager$save_note("qualities_flexibility", input$story_flexibility)
      showNotification("Flexibility story saved!", type="message")
    })
    observeEvent(input$save_boldness,    {
      prep_manager$save_note("qualities_boldness", input$story_boldness)
      showNotification("Boldness story saved!", type="message")
    })
  })
}
