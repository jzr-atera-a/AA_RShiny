# modules/family_office_architecture.R
#
# "Strategy for Business > Family Office Platform Architecture" - the
# architecture diagram for a full family-office-grade extension of the
# Portfolio Optimisation Lab (6 stages, 30 components, 5 portfolios of 10
# companies each), analysed in an earlier turn as a genuine "Phase 2" design
# that assumes the Lab as its foundation.
#
# WHY AN IFRAME, NOT A REBUILT DIAGRAM: the original file is a bundled React
# artifact with real two-tier interactivity - clicking a portfolio box opens
# a detail panel, and clicking a specific holding inside THAT panel opens a
# second, nested panel (founding date, IPO/listing, what it does, why it's in
# the basket). Reimplementing that in Shiny/plotly would risk not matching
# the original's behaviour exactly. Embedding the actual working file via
# www/family_office_architecture.html guarantees the interaction logic is
# the real thing, unmodified, not a re-creation of it.
#
# MOBILE: the diagram's own canvas is intentionally wide (min-width: 1140px)
# with its own internal horizontal scroll, rather than reflowing 30 boxes
# into an unreadable narrow column - that is the diagram's own built-in
# accommodation, not a limitation introduced here. The iframe height below is
# viewport-relative (85vh) so it fits a phone screen without needing the
# whole Shiny page to scroll along with it, and a "view full-screen" link is
# provided since a complex diagram is easier to explore at full browser width.

family_office_architecture_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ui_banner("Strategy for Business", "Family Office Platform Architecture",
              "The full architecture for extending the Portfolio Optimisation Lab into a family-office-grade multi-portfolio platform \u2014 6 stages, 30 components, 5 portfolios of 10 companies each."),

    ua_callout(paste0(
      "This is a design document, not a built feature \u2014 an architecture diagram for how the Portfolio Optimisation Lab could grow, ",
      "not something that runs in this app today. See how it aligns with and extends what's already built on the Hedge Fund / Wealth ",
      "and Portfolio Optimisation Lab tabs."
    )),

    box(width = 12, status = "info", solidHeader = TRUE, title = "How to use this diagram",
      tags$ul(style = "font-size:12.5px; color:#4a5560; line-height:1.8; padding-left:20px; margin:0;",
        tags$li(tags$b("Tap a stage tab"), " along the top (Data & Universes, Signal Engine, Risk & Theory, ML & Bayesian, Allocation, Client Layer) to see that stage's components."),
        tags$li(tags$b("Tap any box"), " (e.g. a portfolio, or a component like \u201cAdvanced Metrics \u2014 Sortino-Led\u201d) to open its detail panel \u2014 methodology, data and Harvard-referenced theory."),
        tags$li(tags$b("Two levels deep: "), "inside a portfolio's detail panel, tap any individual holding (e.g. NVIDIA) to open a ",
                tags$i("second"), " panel on top of the first, with that company's founding date, IPO/listing, what it does, and why it's in that specific basket."),
        tags$li("The diagram itself is wider than a phone screen by design \u2014 scroll/swipe sideways inside it to see everything, or use ",
                tags$b("\u201cView full-screen\u201d"), " below for more room.")
      )
    ),

    fluidRow(
      column(12, style = "text-align:right; margin-bottom:8px;",
        tags$a(href = "family_office_architecture.html", target = "_blank", class = "btn btn-primary btn-sm",
               icon("up-right-from-square"), " View full-screen")
      )
    ),

    tags$div(style = "border:1px solid #e2e8f0; border-radius:8px; overflow:hidden; box-shadow:0 1px 4px rgba(0,44,60,0.06);",
      tags$iframe(
        src = "family_office_architecture.html",
        style = "width:100%; height:85vh; min-height:600px; border:none; display:block;",
        title = "Family Office Multi-Portfolio Platform architecture diagram"
      )
    )
  )
}

family_office_architecture_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Static embedded content — no server logic needed.
  })
}
