# modules/guide.R — App Guide

guide_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("", "\U0001f9ed", "DeepTech Fundraising Suite",
      "A complete interactive guide to venture capital deal terms, fundraising strategy, and Monte Carlo simulations — built for DeepTech founders raising their first institutional round.",
      c("VENTURE DEALS", "BRAD FELD & JASON MENDELSON", "DEEPTECH FOCUS", "MONTE CARLO MODELS")),

    fluidRow(
      box(title = "\U0001f4d6 About This App", status = "primary", solidHeader = TRUE, width = 6,
        p("This app translates ", tags$em("Venture Deals"), " by Brad Feld & Jason Mendelson into an interactive playbook for ",
          tags$b("DeepTech founders"), " navigating their first institutional fundraise. Deep tech — covering AI hardware, quantum computing, synthetic biology, advanced robotics, and next-gen semiconductors — has unique deal dynamics that differ materially from SaaS."),
        hr_blue(),
        p("Each tab covers a key concept from the book with DeepTech-specific context, real deal benchmarks, and interactive tools. Two Monte Carlo simulation tabs let you project valuations and runway under uncertainty — the same models used by VC associates."),
        div(class = "tip-box", tags$strong("\U0001f4a1 How to use: "),
          "Navigate tabs via the left sidebar. Start with ", tags$b("Overview"), " for the landscape, then work through deal mechanics. The Monte Carlo tabs (7 & 8) are interactive — adjust sliders to model your own company.")
      ),
      box(title = "\U0001f5fa\ufe0f Tabs Covered", status = "info", solidHeader = TRUE, width = 6,
        toc_item("1", HTML("<b>The Players</b> — VCs, LPs, GPs, angels, lawyers. Who does what and why.")),
        toc_item("2", HTML("<b>Term Sheet</b> — Economics vs control. What to fight for and what to let go.")),
        toc_item("3", HTML("<b>Economic Terms</b> — Liquidation preferences, antidilution, option pool shuffle.")),
        toc_item("4", HTML("<b>Control Terms</b> — Board seats, protective provisions, drag-along rights.")),
        toc_item("5", HTML("<b>Cap Table</b> — Interactive dilution modelling across multiple rounds.")),
        toc_item("6", HTML("<b>Convertible Debt & SAFEs</b> — Caps, discounts, conversion mechanics.")),
        toc_item("7", HTML("<b>Monte Carlo: Valuation</b> — 10,000-path exit value simulation for DeepTech.")),
        toc_item("8", HTML("<b>Monte Carlo: Runway</b> — Burn rate & cash survival probability modelling.")),
        toc_item("9", HTML("<b>Negotiation Tactics</b> — BATNA, leverage, what VCs actually negotiate on.")),
        toc_item("10", HTML("<b>DeepTech Deals</b> — IP, grants, long cycles, strategic vs financial investors."))
      )
    ),

    fluidRow(
      box(title = "\U0001f916 Hypothetical Company: QuantumLeap AI", status = "success", solidHeader = TRUE, width = 12,
        p("Throughout the Monte Carlo tabs, simulations use ", tags$b("QuantumLeap AI"), " — a fictional UK-based DeepTech startup developing neuromorphic computing chips for edge AI inference. This is the scenario:"),
        fluidRow(
          column(3, metric_card("£2.1M", "Seed Raised")),
          column(3, metric_card("18 mo", "Current Runway")),
          column(3, metric_card("£12M", "Target Series A")),
          column(3, metric_card("TRL 5", "Technology Readiness"))
        ),
        br(),
        fluidRow(
          column(4, fw("Sector", "Neuromorphic computing / edge AI inference chips. 3–5x power efficiency vs GPU alternatives. Target markets: autonomous vehicles, IoT, defence.")),
          column(4, fw("Investors", "Seed: Innovate UK grant (£900K) + angel syndicate (£1.2M). Series A target: deep tech specialist VC + corporate strategic from semiconductor sector.")),
          column(4, fw("Key Risks", "Long R&D cycles (3–5 years to revenue), IP licensing complexity, talent scarcity, competition from ARM and Intel, regulatory uncertainty in dual-use tech."))
        )
      )
    )
  )
}

guide_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
