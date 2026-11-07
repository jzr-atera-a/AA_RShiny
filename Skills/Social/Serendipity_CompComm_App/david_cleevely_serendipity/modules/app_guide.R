# modules/app_guide.R
# App Guide - Purpose, navigation and tab structure

app_guide_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        div(class = "hero-chapter-num", "Serendipity - David Cleevely"),
        tags$h1(class = "hero-title", "\U0001f9ed App Guide"),
        tags$p(class = "hero-subtitle",
          "What this app is, how to use it, and what you'll find in each tab."),
        div(class = "badge-row",
          span(class = "hero-badge", icon("book"),          " David Cleevely"),
          span(class = "hero-badge", icon("university"),    " Cambridge University Press"),
          span(class = "hero-badge", icon("car"),           " Atera Analytics"),
          span(class = "hero-badge", icon("layer-group"),   " 12 Tabs"),
          span(class = "hero-badge", icon("diagram-project")," D3 Interactive")
        )
    ),

    fluidRow(
      box(title = "\U0001f3af Purpose of This App", status = "primary",
          solidHeader = TRUE, width = 12,
          fluidRow(
            column(8,
              tags$p(
                "This interactive guide maps the ideas in ", tags$em("Serendipity"),
                " by David Cleevely (Cambridge University Press) onto the real-world context of ",
                tags$b("Atera Analytics Ltd"),
                " - the same Innovate UK-funded deep-tech company used in the Compelling Communication app - ",
                "to ask a practical question: can Atera deliberately design the conditions for lucky breaks, ",
                "rather than just hoping for them?"
              ),
              tags$p(
                "Every chapter tab has three subtabs: ", tags$b("General Concepts"),
                " (the book's theory), ", tags$b("Interactive"),
                " (a hands-on D3 visual built around that chapter's core idea), and ",
                tags$b("Applicability on Atera Analytics"),
                " (what it means for Atera's actual grant, pilot and partnership work)."
              ),
              div(class = "tip-box",
                tags$strong("\U0001f4a1 How to navigate: "),
                "Use the left sidebar to move between tabs. Chapters most concerned with networks and ",
                "systems (3, 4, 9, 10) carry force-directed D3 network graphs you can drag, hover and, ",
                "in Chapter 10, control with a live slider."
              )
            ),
            column(4,
              div(class = "stat-card", span(class = "stat-value", "10"),  span(class = "stat-label", "Chapters Covered")),
              div(class = "stat-card", span(class = "stat-value", "3"),   span(class = "stat-label", "Subtabs per Chapter")),
              div(class = "stat-card", span(class = "stat-value", "6"),   span(class = "stat-label", "D3 Visual Types")),
              div(class = "stat-card", span(class = "stat-value", "v1"),  span(class = "stat-label", "Current Version"))
            )
          )
      )
    ),

    fluidRow(
      box(title = "\U0001f5fa\ufe0f Tab-by-Tab Guide", status = "info", solidHeader = TRUE, width = 12,
        fluidRow(
          column(6,
            chapter_card("-", "App Guide", "This page - purpose, structure and navigation.", c("Meta")),
            chapter_card("-", "Overview", "The book's central question - 'A Chance Encounter?' - plus Atera's project context.", c("Intro", "Context")),
            chapter_card("1", "The Entangled Bank", "Complexity and interconnection - innovation as a systems property.", c("Network", "D3")),
            chapter_card("2", "Mad About The Moon", "Historical breakthroughs and the conditions behind them.", c("Timeline", "D3")),
            chapter_card("3", "How Networks Work", "Weak ties, strong ties and brokers - the flagship network graph.", c("Network", "D3")),
            chapter_card("4", "Closer To Home", "Place-based clusters - the Cambridge case.", c("Network", "D3"))
          ),
          column(6,
            chapter_card("5", "The Prepared Mind", "Curiosity and readiness - an interactive self-assessment.", c("Radar", "D3")),
            chapter_card("6", "Technology May Not Save Us", "Does more connectivity mean more serendipity?", c("Bar chart", "D3")),
            chapter_card("7", "Too Well Organised To Adapt", "The cost of over-optimisation - an interactive dial.", c("Gauge", "D3")),
            chapter_card("8", "The Ministry Of Predictable Outcomes", "Targets, bureaucracy and suppressed uncertainty.", c("Quadrant", "D3")),
            chapter_card("9", "The Road Most Travelled", "Familiar paths versus deliberate exposure.", c("Network", "D3")),
            chapter_card("10", "The Edge Of Chaos", "Order versus disorder - a live, slider-controlled network.", c("Network", "Slider", "D3"))
          )
        ),
        div(class = "success-box",
            tags$strong("\u2705 Conclusion tab: "),
            "brings all ten chapters together into a single synthesis and an Atera-specific action roadmap.")
      )
    )
  )
}

app_guide_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
