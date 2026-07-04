# modules/guide.R: App Guide

guide_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("", "\U0001f9ed", "Venture Analysis",
      "A complete interactive intelligence platform for DeepTech founders: built by Atera Analytics. Covers deal terms, fundraising strategy, and proprietary Monte Carlo simulations.",
      c("ATERA ANALYTICS", "DEEPTECH FOCUS", "MONTE CARLO MODELS", "UK & EU BENCHMARKS")),

    # ── How to use this tab ───────────────────────────────────
    fluidRow(
      box(title = "\U0001f4a1 How to Use This Tab", status = "warning",
          solidHeader = TRUE, width = 12,
        tags$p(style = "color:#8fb0d8;font-size:13px;line-height:1.7;margin:0;",
          tags$b(style = "color:#00e5ff;", "\U0001f4cc This is the app configuration reference tab. "),
          "Use it to understand the full scope of the platform, the hypothetical QuantumLeap AI
          scenario used throughout the interactive tools, and the data & methodology behind
          the platform. The two boxes below: About This App and Tabs Covered: give you a
          complete map of the platform before you start exploring.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "QuantumLeap AI scenario: "),
          "the four metric cards show the baseline assumptions used across all interactive tools.
          The three framework cards (Sector, Investors, Key Risks) explain the context.
          When you use sliders in Tabs 7 & 8, you are modifying these baseline assumptions.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "For first-time users: "),
          "start with the ", tags$b(style = "color:#cdd9f5;", "Introduction tab"),
          " (top of the sidebar) for a visual overview of every tab, then return here
          for the QuantumLeap AI scenario context before using the Monte Carlo tools."
        )
      )
    ),

    fluidRow(
      box(title = "\U0001f4d6 About This App", status = "primary", solidHeader = TRUE, width = 6,
        p(tags$b("Venture Analysis"), " by Atera Analytics is an interactive intelligence platform for ",
          tags$b("DeepTech founders"), " navigating their first institutional fundraise. Deep tech: covering AI hardware, quantum computing, synthetic biology, advanced robotics, and next-gen semiconductors: has unique deal dynamics that differ materially from SaaS."),
        hr_blue(),
        p("Each tab covers a key concept from the book with DeepTech-specific context, real deal benchmarks, and interactive tools. Two Monte Carlo simulation tabs let you project valuations and runway under uncertainty: the same models used by VC associates."),
        div(class = "tip-box", tags$strong("\U0001f4a1 How to use: "),
          "Navigate tabs via the left sidebar. Start with ", tags$b("Overview"), " for the landscape, then work through deal mechanics. The Monte Carlo tabs (7 & 8) are interactive: adjust sliders to model your own company.")
      ),
      box(title = "\U0001f5fa\ufe0f Tabs Covered", status = "info", solidHeader = TRUE, width = 6,
        toc_item("1", HTML("<b>The Players</b>: VCs, LPs, GPs, angels, lawyers. Who does what and why.")),
        toc_item("2", HTML("<b>Term Sheet</b>: Economics vs control. What to fight for and what to let go.")),
        toc_item("3", HTML("<b>Economic Terms</b>: Liquidation preferences, antidilution, option pool shuffle.")),
        toc_item("4", HTML("<b>Control Terms</b>: Board seats, protective provisions, drag-along rights.")),
        toc_item("5", HTML("<b>Cap Table</b>: Interactive dilution modelling across multiple rounds.")),
        toc_item("6", HTML("<b>Convertible Debt & SAFEs</b>: Caps, discounts, conversion mechanics.")),
        toc_item("7", HTML("<b>Monte Carlo: Valuation</b>: 10,000-path exit value simulation for DeepTech.")),
        toc_item("8", HTML("<b>Monte Carlo: Runway</b>: Burn rate & cash survival probability modelling.")),
        toc_item("9", HTML("<b>Negotiation Tactics</b>: BATNA, leverage, what VCs actually negotiate on.")),
        toc_item("10", HTML("<b>DeepTech Deals</b>: IP, grants, long cycles, strategic vs financial investors."))
      )
    ),

    fluidRow(
      box(title = "\U0001f916 Hypothetical Company: QuantumLeap AI", status = "success", solidHeader = TRUE, width = 12,
        p("Throughout the Monte Carlo tabs, simulations use ", tags$b("QuantumLeap AI"), ": a fictional UK-based DeepTech startup developing neuromorphic computing chips for edge AI inference. This is the scenario:"),
        fluidRow(
          column(3, metric_card("£2.1M", "Seed Raised")),
          column(3, metric_card("18 mo", "Current Runway")),
          column(3, metric_card("£12M", "Target Series A")),
          column(3, metric_card("TRL 5", "Technology Readiness"))
        ),
        br(),
        fluidRow(
          column(4, fw("Sector", "Neuromorphic computing / edge AI inference chips. 3:5x power efficiency vs GPU alternatives. Target markets: autonomous vehicles, IoT, defence.")),
          column(4, fw("Investors", "Seed: Innovate UK grant (£900K) + angel syndicate (£1.2M). Series A target: deep tech specialist VC + corporate strategic from semiconductor sector.")),
          column(4, fw("Key Risks", "Long R&D cycles (3:5 years to revenue), IP licensing complexity, talent scarcity, competition from ARM and Intel, regulatory uncertainty in dual-use tech."))
        )
      )
    ),

    # ── Book Attribution ──────────────────────────────────────
    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,
        div(style = "display:flex;align-items:flex-start;gap:24px;padding:8px 4px;",
          div(style = "font-size:48px;line-height:1;flex-shrink:0;", "📚"),
          div(
            tags$h5(style = "color:#00e5ff;font-family:'Syne',sans-serif;font-size:15px;font-weight:800;margin:0 0 8px;",
              "About This Analysis"),
            tags$p(style = "color:#8fb0d8;font-size:13px;line-height:1.7;margin:0 0 10px;",
              "The analytical frameworks, deal term definitions, negotiation principles, and fundraising strategies presented in ",
              tags$b(style="color:#cdd9f5;", "Venture Analysis"),
              " are grounded in principles drawn from ",
              tags$em(style="color:#adc8ff;", "Venture Deals"),
              " by ",
              tags$b(style="color:#cdd9f5;", "Brad Feld and Jason Mendelson"),
              " (Wiley). This foundational work on venture capital deal mechanics and term sheet structure has informed the conceptual architecture of this platform."
            ),
            tags$p(style = "color:#8fb0d8;font-size:13px;line-height:1.7;margin:0 0 10px;",
              "All ",
              tags$b(style="color:#cdd9f5;", "quantitative data, market benchmarks, deal statistics, and simulation models"),
              ": including the Monte Carlo valuation and runway models, DeepTech sector benchmarks, UK/EU deal comparables, and investor category analysis: have been independently researched, curated, and developed by ",
              tags$b(style="color:#cdd9f5;", "Atera Analytics"),
              ". The simulation algorithms are proprietary to Atera Analytics and do not originate from the referenced book."
            ),
            div(style = "display:flex;gap:10px;flex-wrap:wrap;margin-top:12px;",
              span(class = "hero-badge", "📖 Principles: Feld & Mendelson"),
              span(class = "hero-badge", "📊 Data: Atera Analytics"),
              span(class = "hero-badge", "🤖 Simulations: Atera Proprietary"),
              span(class = "hero-badge", "🇬🇧 UK & EU DeepTech Focus")
            )
          )
        )
      )
    )
  )
}

guide_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
