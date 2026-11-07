# modules/introduction.R: Full App Introduction Tab
# Available to all users, first tab shown after login

introduction_ui <- function(id) {
  ns <- NS(id)
  tagList(

    # ── Hero ─────────────────────────────────────────────────
    div(class = "chapter-hero",
      div(class = "hero-chapter-num", "VENTURE ANALYSIS · ATERA ANALYTICS"),
      tags$h1(class = "hero-title",
        "\U0001f680 Welcome to Venture Analysis"),
      tags$p(class = "hero-subtitle",
        "Your complete intelligence platform for DeepTech fundraising. Built by Atera Analytics, ",
        "this platform combines venture capital deal mechanics, real-world UK & EU market benchmarks, ",
        "and proprietary Monte Carlo simulation models to help DeepTech founders raise smarter, ",
        "negotiate better, and model their financial future with confidence."),
      div(class = "badge-row",
        span(class = "hero-badge", "\U0001f4ca Atera Analytics"),
        span(class = "hero-badge", "\U0001f1ec\U0001f1e7 UK & EU Focus"),
        span(class = "hero-badge", "\U0001f916 Monte Carlo Models"),
        span(class = "hero-badge", "\U0001f4b0 VC Deal Intelligence"),
        span(class = "hero-badge", "\U0001f9ec DeepTech Specialists")
      )
    ),

    # ── What this platform does ───────────────────────────────
    fluidRow(
      box(title = "\U0001f3af What This Platform Does", status = "primary",
          solidHeader = TRUE, width = 12,
        fluidRow(
          column(4,
            div(class = "framework-card",
              tags$h5("\U0001f4da Deal Intelligence"),
              tags$p("Understand every term in a VC term sheet: from liquidation preferences
                to protective provisions: with DeepTech-specific context. Know what to fight
                for, what to let go, and what market norms look like for UK & EU Series A rounds.")
            ),
            div(class = "framework-card",
              tags$h5("\U0001f4ca Market Benchmarks"),
              tags$p("Real deal data from 85+ UK & EU DeepTech Series A rounds (2022:2024),
                covering pre-money valuations, round sizes, exit timelines, and investor
                category comparisons across AI chips, quantum, robotics, and more.")
            )
          ),
          column(4,
            div(class = "framework-card",
              tags$h5("\U0001f916 Monte Carlo Simulations"),
              tags$p("Run 10,000-path exit valuation simulations and 5,000-path cash survival
                models for a hypothetical DeepTech company (QuantumLeap AI). Adjust sliders
                to model your own assumptions and see probability distributions, not just point estimates.")
            ),
            div(class = "framework-card",
              tags$h5("\U0001f91d Negotiation Playbook"),
              tags$p("BATNA strategies, VC negotiating tactics, what corporate strategics
                try to insert into DeepTech deals, and a worked Series A negotiation playbook
                for a neuromorphic computing startup raising £12M.")
            )
          ),
          column(4,
            div(class = "framework-card",
              tags$h5("\U0001f9ec DeepTech Specifics"),
              tags$p("IP assignment, university spin-out structures, dual-use technology
                regulation, grant stacking (Innovate UK + EIC), and how to choose between
                deep tech specialist VCs, corporate strategics, and generalist growth funds.")
            ),
            div(class = "framework-card",
              tags$h5("\U0001f4c4 Interactive Tools"),
              tags$p("Interactive cap table modeller, exit waterfall calculator, convertible
                note/SAFE conversion calculator, and real-time Monte Carlo parameter sliders :
                all built to model your actual fundraising scenario.")
            )
          )
        )
      )
    ),

    # ── Tab-by-tab guide ──────────────────────────────────────
    fluidRow(
      box(title = "\U0001f5fa\ufe0f Complete Tab Guide", status = "info",
          solidHeader = TRUE, width = 12,
        tags$p(style = "color:#8fb0d8;font-size:13px;margin-bottom:18px;",
          "Navigate using the sidebar. Each tab is self-contained: you can start anywhere,
          but the logical flow follows the fundraising journey from understanding the landscape
          through to closing and structuring your deal."),

        fluidRow(
          column(6,

            div(class = "chapter-card",
              div(class = "ch-num", "OVERVIEW"),
              div(class = "ch-title", "\U0001f30d DeepTech VC Landscape"),
              div(class = "ch-desc",
                "Start here for the big picture. See where DeepTech sits in global VC,
                understand the UK grant landscape, compare investor categories (specialist VCs,
                corporate strategics, government funds), and view an interactive bubble chart
                of pre-money valuations vs exit timelines across 8 DeepTech sectors."),
              div(class = "ch-tags",
                span(class = "topic-tag", "MARKET DATA"),
                span(class = "topic-tag", "INVESTOR TYPES"),
                span(class = "topic-tag", "GRANT STACK"))
            ),

            div(class = "chapter-card",
              div(class = "ch-num", "TAB 1"),
              div(class = "ch-title", "\U0001f465 The Players"),
              div(class = "ch-desc",
                "Who is in the room and what do they actually want? Covers GP/LP/fund structure,
                carry calculations, angel vs institutional investors, lawyer selection,
                and a specific investor target strategy for a neuromorphic chip startup."),
              div(class = "ch-tags",
                span(class = "topic-tag", "VCS & LPS"),
                span(class = "topic-tag", "GP CARRY"),
                span(class = "topic-tag", "LAWYERS"))
            ),

            div(class = "chapter-card",
              div(class = "ch-num", "TAB 2"),
              div(class = "ch-title", "\U0001f4c4 The Term Sheet"),
              div(class = "ch-desc",
                "The term sheet decoded. Economics vs control: the two things that actually matter.
                Includes a deep dive on the option pool shuffle (the most misunderstood term),
                pre/post-money valuation formulas, and UK DeepTech Series A benchmarks
                for pre-money valuations of £15:35M."),
              div(class = "ch-tags",
                span(class = "topic-tag", "ECONOMICS"),
                span(class = "topic-tag", "CONTROL"),
                span(class = "topic-tag", "OPTION POOL"))
            ),

            div(class = "chapter-card",
              div(class = "ch-num", "TAB 3"),
              div(class = "ch-title", "\U0001f4b0 Economic Terms"),
              div(class = "ch-desc",
                "Interactive exit waterfall showing how liquidation preferences split proceeds
                across three structures (1x non-participating, 1x participating, 2x participating).
                Adjust the exit value slider to see in real time how much founders receive under
                different VC deal structures. Also covers anti-dilution provisions and down round risk."),
              div(class = "ch-tags",
                span(class = "topic-tag", "INTERACTIVE"),
                span(class = "topic-tag", "EXIT WATERFALL"),
                span(class = "topic-tag", "LIQ PREFS"))
            ),

            div(class = "chapter-card",
              div(class = "ch-num", "TAB 4"),
              div(class = "ch-title", "\u265a Control Terms"),
              div(class = "ch-desc",
                "Who controls the company controls its destiny. Board composition strategies,
                protective provisions that give investors veto rights, drag-along rights, and
                a radar chart comparing founder-friendly vs investor-heavy structures across
                seven key control provisions. Critical for DeepTech where technical pivots require board agility."),
              div(class = "ch-tags",
                span(class = "topic-tag", "BOARD SEATS"),
                span(class = "topic-tag", "VETO RIGHTS"),
                span(class = "topic-tag", "RADAR CHART"))
            ),

            div(class = "chapter-card",
              div(class = "ch-num", "TAB 5"),
              div(class = "ch-title", "\U0001f4ca Cap Table"),
              div(class = "ch-desc",
                "Fully interactive cap table modeller for QuantumLeap AI across Seed, Series A,
                and Series B. Adjust all round parameters via sliders and see ownership dilution
                as a stacked bar chart, post-Series A ownership as a pie chart, share prices
                at each round, and a formatted DT table: all update instantly."),
              div(class = "ch-tags",
                span(class = "topic-tag", "INTERACTIVE"),
                span(class = "topic-tag", "DILUTION MODEL"),
                span(class = "topic-tag", "SLIDERS"))
            )

          ),
          column(6,

            div(class = "chapter-card",
              div(class = "ch-num", "TAB 6"),
              div(class = "ch-title", "\U0001f504 Convertible Debt & SAFEs"),
              div(class = "ch-desc",
                "Real-time SAFE and convertible note conversion calculator. Enter your note size,
                valuation cap, discount rate, and Series A pre-money to instantly see your conversion
                price, effective pre-money, and whether the cap or discount triggers. Includes
                MFN clause warnings and UK SEIS/EIS compatibility guidance."),
              div(class = "ch-tags",
                span(class = "topic-tag", "CALCULATOR"),
                span(class = "topic-tag", "SAFES"),
                span(class = "topic-tag", "EIS/SEIS"))
            ),

            div(class = "chapter-card",
              div(class = "ch-num", "TAB 7"),
              div(class = "ch-title", "\U0001f3b2 Monte Carlo: Exit Valuation"),
              div(class = "ch-desc",
                "10,000-path Monte Carlo simulation of exit enterprise value for QuantumLeap AI.
                Adjust revenue CAGR, exit multiple, dilution, and time horizon to generate a
                full probability distribution. Shows median, P10/P90 confidence bands, founder
                proceeds after liquidation preferences, and a bear/base/bull scenario comparison chart."),
              div(class = "ch-tags",
                span(class = "topic-tag", "10,000 PATHS"),
                span(class = "topic-tag", "PROBABILITY"),
                span(class = "topic-tag", "MONTE CARLO"))
            ),

            div(class = "chapter-card",
              div(class = "ch-num", "TAB 8"),
              div(class = "ch-title", "\U0001f6e3\ufe0f Monte Carlo: Runway"),
              div(class = "ch-desc",
                "5,000-path cash survival simulation. Models monthly burn rate growth, revenue ramp,
                unexpected cash shocks, and Series B milestone timing. Outputs: survival probability
                curve, runway distribution vs milestone timing, and a tornado chart showing which
                parameters most affect your probability of surviving to Series B fundraise."),
              div(class = "ch-tags",
                span(class = "topic-tag", "5,000 PATHS"),
                span(class = "topic-tag", "SURVIVAL CURVE"),
                span(class = "topic-tag", "TORNADO CHART"))
            ),

            div(class = "chapter-card",
              div(class = "ch-num", "TAB 9"),
              div(class = "ch-title", "\U0001f91d Negotiation Tactics"),
              div(class = "ch-desc",
                "BATNA theory and practice: your most powerful negotiating tool is a competing
                term sheet. Covers VC negotiating tactics (exploding offers, market norm bluffing,
                good cop/bad cop), what to fight for vs let go on each term, and a step-by-step
                Series A negotiation playbook for QuantumLeap AI including IP valuation arguments."),
              div(class = "ch-tags",
                span(class = "topic-tag", "BATNA"),
                span(class = "topic-tag", "VC TACTICS"),
                span(class = "topic-tag", "PLAYBOOK"))
            ),

            div(class = "chapter-card",
              div(class = "ch-num", "TAB 10"),
              div(class = "ch-title", "\U0001f9ec DeepTech Deals"),
              div(class = "ch-desc",
                "DeepTech-specific deal complexity: IP assignment requirements, university spin-out
                structures and the Napier Review, dual-use technology and the NSI Act 2021,
                DASA/MOD investment implications. Includes a benchmarks chart (pre-money, round size,
                exit timeline) for 8 UK DeepTech sectors with IQR error bars, and a radar chart
                comparing investor types across 7 criteria."),
              div(class = "ch-tags",
                span(class = "topic-tag", "IP STRATEGY"),
                span(class = "topic-tag", "SPIN-OUTS"),
                span(class = "topic-tag", "BENCHMARKS"))
            )

          )
        )
      )
    ),

    # ── QuantumLeap AI scenario ───────────────────────────────
    fluidRow(
      box(title = "\U0001f916 The QuantumLeap AI Scenario", status = "success",
          solidHeader = TRUE, width = 8,
        tags$p(style = "color:#8fb0d8;font-size:13px;line-height:1.7;",
          "Throughout the interactive tools: especially the Monte Carlo simulations,
          cap table modeller, and negotiation playbook: a consistent hypothetical company
          called ", tags$b(style = "color:#cdd9f5;", "QuantumLeap AI"), " is used as the worked example."),
        fluidRow(
          column(6,
            div(class = "stat-card", span(class = "stat-value", "£2.1M"),
                span(class = "stat-label", "Seed Raised")),
            div(class = "stat-card", span(class = "stat-value", "18 mo"),
                span(class = "stat-label", "Current Runway")),
            div(class = "stat-card", span(class = "stat-value", "TRL 5"),
                span(class = "stat-label", "Technology Readiness"))
          ),
          column(6,
            div(class = "stat-card", span(class = "stat-value", "£12M"),
                span(class = "stat-label", "Target Series A")),
            div(class = "stat-card", span(class = "stat-value", "£28M"),
                span(class = "stat-label", "Target Pre-Money")),
            div(class = "stat-card", span(class = "stat-value", "Neuro"),
                span(class = "stat-label", "Neuromorphic Chips"))
          )
        ),
        hr_blue(),
        tags$p(style = "color:#8fb0d8;font-size:12.5px;line-height:1.7;margin:0;",
          tags$b(style = "color:#cdd9f5;", "Sector: "),
          "Neuromorphic computing chips for edge AI inference. 3:5x power efficiency vs GPU alternatives. ",
          tags$br(),
          tags$b(style = "color:#cdd9f5;", "Target investors: "),
          "Molten Ventures (lead) + ARM Ventures (co-investor). Pre-stacked with £900K Innovate UK grant. ",
          tags$br(),
          tags$b(style = "color:#cdd9f5;", "Use the sliders "),
          "in Tabs 7 & 8 to replace QuantumLeap's assumptions with your own company's numbers."
        )
      ),
      box(title = "\U0001f4a1 How To Get The Most From This Platform",
          status = "warning", solidHeader = TRUE, width = 4,
        div(class = "timeline-strip", style = "flex-direction:column;gap:10px;overflow:visible;",
          div(style = "display:flex;align-items:flex-start;gap:12px;",
            div(class = "tl-num", "1"),
            div(tags$b(style = "color:#cdd9f5;font-size:12px;", "Read before you negotiate"),
                tags$p(style = "color:#8fb0d8;font-size:11px;margin:3px 0 0;",
                  "Work through Tabs 1:4 before any investor meeting."))
          ),
          div(style = "display:flex;align-items:flex-start;gap:12px;",
            div(class = "tl-num", "2"),
            div(tags$b(style = "color:#cdd9f5;font-size:12px;", "Model your own numbers"),
                tags$p(style = "color:#8fb0d8;font-size:11px;margin:3px 0 0;",
                  "Use Tabs 5, 6, 7, 8 with your real fundraising parameters."))
          ),
          div(style = "display:flex;align-items:flex-start;gap:12px;",
            div(class = "tl-num", "3"),
            div(tags$b(style = "color:#cdd9f5;font-size:12px;", "Benchmark your deal"),
                tags$p(style = "color:#8fb0d8;font-size:11px;margin:3px 0 0;",
                  "Tab 10 has sector-specific comparables for your negotiation."))
          ),
          div(style = "display:flex;align-items:flex-start;gap:12px;",
            div(class = "tl-num", "4"),
            div(tags$b(style = "color:#cdd9f5;font-size:12px;", "Build your playbook"),
                tags$p(style = "color:#8fb0d8;font-size:11px;margin:3px 0 0;",
                  "Tab 9 gives you scripts and tactics for the negotiation table."))
          )
        )
      )
    ),

    # ── Attribution ───────────────────────────────────────────
    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,
        div(style = "display:flex;align-items:flex-start;gap:20px;padding:4px;",
          div(style = "font-size:36px;flex-shrink:0;", "\U0001f4da"),
          div(
            tags$p(style = "color:#8fb0d8;font-size:13px;line-height:1.7;margin:0 0 8px;",
              "Analytical frameworks and deal term definitions in this platform are informed by principles
              from ", tags$em(style = "color:#adc8ff;", "Venture Deals"),
              " by ", tags$b(style = "color:#cdd9f5;", "Brad Feld and Jason Mendelson"), " (Wiley).
              All quantitative data, market benchmarks, simulation models, and algorithms are
              independently developed by ", tags$b(style = "color:#cdd9f5;", "Atera Analytics"),
              " and do not originate from the referenced book."),
            div(style = "display:flex;gap:8px;flex-wrap:wrap;",
              span(class = "hero-badge", "\U0001f4d6 Frameworks: Feld & Mendelson"),
              span(class = "hero-badge", "\U0001f4ca Data: Atera Analytics"),
              span(class = "hero-badge", "\U0001f916 Simulations: Atera Proprietary")
            )
          )
        )
      )
    )
  )
}

introduction_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
