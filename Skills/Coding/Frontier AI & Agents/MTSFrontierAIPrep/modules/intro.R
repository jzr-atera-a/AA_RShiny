# modules/intro.R
# Tab: Welcome & Overview - MTS, Frontier AI (micro1)

intro_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Member of Technical Staff — Frontier AI"),
        tags$h2("micro1 — Interview Preparation Suite"),
        div(
          span(class = "hero-badge", icon("laptop-house"), " Remote"),
          span(class = "hero-badge", icon("robot"),        " AI Interview + Exercise"),
          span(class = "hero-badge", icon("clock"),        " ~48 minutes"),
          span(class = "hero-badge", icon("calendar-day"), " Due Jun 14, 2026, 10:04am")
        )
    ),

    fluidRow(
      box(title = "The 4 Focus Areas, At a Glance", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, div(class = "metric-card", span(class = "metric-value", "01"), span(class = "metric-label", "Ops \u2192 Research Translation"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "02"), span(class = "metric-label", "ML-Oriented Data Design"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "03"), span(class = "metric-label", "Research Signal Judgment"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "04"), span(class = "metric-label", "Stakeholder Judgment")))
          ),
          div(class = "loop-flow",
              span(class = "stage-pill", "Messy real-world signal"),
              span(class = "arrow", "\u2192"),
              span(class = "stage-pill", "Translate to research problem"),
              span(class = "arrow", "\u2192"),
              span(class = "stage-pill", "Design data / eval"),
              span(class = "arrow", "\u2192"),
              span(class = "stage-pill", "Validate the signal"),
              span(class = "arrow", "\u2192"),
              span(class = "stage-pill", "Communicate to stakeholders"),
              span(class = "arrow", "\u2192"),
              span(class = "stage-pill", "Feeds next round of ops")
          ),
          p(style = "text-align:center;color:#555;font-size:13px;",
            "The four focus areas aren't four separate skills \u2014 they're four stations on one loop. Each tab below covers one station in depth.")
      )
    ),

    fluidRow(
      box(title = "What This Role Is Looking For", status = "info", solidHeader = TRUE, width = 7,
          div(class = "section-heading-dark", "Core responsibilities, in 8 points"),
          tags$ol(
            tags$li(tags$b("Technical owner across research, data and real systems"), " \u2014 hands-on, improving model/system performance via evaluation, failure analysis and iteration; not a single isolated component."),
            tags$li(tags$b("End-to-end ownership of research & evaluation"), " \u2014 from problem framing and data design through quality calibration to validating that a signal is real."),
            tags$li(tags$b("Designs ML-oriented data systems"), " \u2014 task definitions, annotation schemas, rubrics, incentive structures and pipelines, optimised for downstream model performance."),
            tags$li(tags$b("Strong failure analysis"), " \u2014 diagnosing model/system failures to find root causes, edge cases and improvement opportunities."),
            tags$li(tags$b("Translates messy real-world behaviour into structured research"), " \u2014 converting ambiguous production signals into evaluation frameworks and new data categories."),
            tags$li(tags$b("Works closely with researchers & domain experts"), " \u2014 calibrating quality early and continuously raising the signal bar, including at kickoff and during iteration."),
            tags$li(tags$b("Acts as a quality gate"), " \u2014 willing to block claims, pause work, or push for scope changes when evidence/data integrity isn't strong enough; recommends where to invest, iterate or stop."),
            tags$li(tags$b("Communicates clearly across audiences"), " \u2014 turning research progress into credible, evidence-based narratives for technical and non-technical stakeholders, including tradeoffs and limitations.")
          ),
          div(class = "tip-box", HTML("<strong>\U0001F4A1 Reading the JD:</strong> Points 2 &amp; 7 map mostly to <b>Research Signal Judgment</b>, point 3 to <b>ML-Oriented Data Design</b>, points 4 &amp; 5 to <b>Ops \u2192 Research Translation</b>, and points 6 &amp; 8 to <b>Stakeholder Judgment</b>. Point 1 is the thread running through all four."))
      ),

      box(title = "Interview Day Checklist", status = "warning", solidHeader = TRUE, width = 5,
          uiOutput(ns("checklist_ui")),
          br(),
          div(class = "section-heading-dark", "Your readiness"),
          uiOutput(ns("progress_ui"))
      )
    ),

    fluidRow(
      box(title = "How To Use This App", status = "success", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, framework_box("Stations 1-4", "Each tab is one focus area: a short framework, a worked example, and 2-3 practice prompts in the JD's own language.", "compass")),
            column(3, framework_box("Universal structure", "Every tab applies the same 5-step answer shape: Frame \u2192 Evidence \u2192 Mechanism \u2192 Tradeoffs \u2192 Decision. See the Practice & Exercise tab.", "diagram-project")),
            column(3, framework_box("Think out loud", "It's an AI interviewer \u2014 it can only grade what you say. Narrate your reasoning explicitly, including when you'd say 'not yet'.", "microphone")),
            column(3, framework_box("Practice & Exercise tab", "Run through the scenario bank and the exercise-format tips before your interview slot.", "stopwatch"))
          )
      )
    )
  )
}

intro_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    checklist_items <- c(
      "Quiet space, stable internet" = "chk1",
      "Laptop/desktop ready, camera & mic allowed" = "chk2",
      "Screen-share tested" = "chk3",
      "Read the role page once more" = "chk4",
      "Skimmed all 4 focus-area tabs" = "chk5",
      "Picked 1 concrete example per focus area" = "chk6"
    )

    output$checklist_ui <- renderUI({
      checkboxGroupInput(session$ns("ready_checks"), label = NULL,
                          choices = checklist_items, selected = character(0))
    })

    output$progress_ui <- renderUI({
      done <- length(input$ready_checks %||% character(0))
      total <- length(checklist_items)
      pct <- round(100 * done / total)
      tagList(
        div(style = paste0("background:#e2e8f0;border-radius:8px;height:14px;overflow:hidden;"),
            div(style = paste0("background:", progress_colour(pct), ";width:", pct, "%;height:100%;transition:width .3s;"))
        ),
        p(style = "margin-top:6px;font-size:13px;color:#555;",
          sprintf("%d of %d ready (%d%%)", done, total, pct))
      )
    })
  })
}
