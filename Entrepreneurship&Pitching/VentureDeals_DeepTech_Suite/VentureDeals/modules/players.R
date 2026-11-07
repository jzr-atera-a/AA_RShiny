# modules/players.R — Chapter 1: The Players

players_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(1, "\U0001f465", "The Players",
      "Every venture deal involves a web of principals with different incentives, time horizons, and definitions of success. Understanding who is in the room — and what they actually want — is the foundation of every negotiation.",
      c("VCS & LPS", "GP CARRY", "FUND STRUCTURE", "DEEPTECH DYNAMICS")),

    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,
        tabsetPanel(id = ns("tabs"),
          tabPanel("\U0001f4da Who's In The Room",
            br(),
            fluidRow(
              column(6,
                sh("The VC Firm Structure"),
                fw("General Partners (GPs)", "GPs run the fund: source deals, sit on boards, manage LP relationships. Their carry (typically 20% of profits above invested capital) creates a powerful incentive to swing for big exits. For DeepTech, seek GPs with PhDs or former operators in your domain — not just finance backgrounds."),
                fw("Limited Partners (LPs)", "LPs provide the capital: pension funds, endowments (Harvard, Oxford), family offices, sovereign wealth funds. They care about DPI (Distributed to Paid-In capital) and TVPI multiples, not individual deal terms. A VC's LP pressure often explains their urgency to deploy or exit."),
                fw("The Management Company", "The 2% annual management fee funds salaries and operations. A £100M fund generates £2M/year in fees. This misalignment — fees regardless of performance — is why smaller funds with hungrier GPs often work harder for founders."),
                pull_quote("The best VCs aren't in it for the management fee. They're in it for the carry — and carry only comes from genuinely great companies.", "Brad Feld, Venture Deals")
              ),
              column(6,
                sh("Key Formulas"),
                div(class = "mc-panel",
                  tags$h5(style = "color:#00e5ff;", "GP Carried Interest"),
                  tags$p(style = "color:#8fb0d8;font-size:12px;", "The GP's share of profits above the invested capital:"),
                  tags$code("GP Carry = (Total Returns − Invested Capital) × 20%"),
                  br(), br(),
                  tags$p(style = "color:#8fb0d8;font-size:12px;", "Example: £100M fund → £400M returned"),
                  tags$code("Carry = (£400M − £100M) × 20% = £60M to GPs"),
                  br(), br(),
                  tags$p(style = "color:#8fb0d8;font-size:12px;", "This is why VCs need 3–5x fund returns: to generate meaningful carry."),
                  tags$h5(style = "color:#00e5ff;margin-top:14px;", "Fund Return Multiple"),
                  tags$code("TVPI = (Unrealised Value + Distributions) / Paid-In Capital"),
                  br(), br(),
                  tags$p(style = "color:#8fb0d8;font-size:12px;", "Top-quartile DeepTech funds target 3–5x TVPI over 10–12 years.")
                ),
                sh("Angels vs Institutional"),
                algo_table(
                  c("Type", "Ticket", "Value-Add", "Patience"),
                  list(
                    list("Angel Syndicates", "£25K–£500K", "Intros, domain expertise", "High"),
                    list("Seed VC", "£500K–£3M", "Network, follow-on", "Medium"),
                    list("Series A VC", "£5M–£20M", "Governance, hiring", "Medium"),
                    list("Corporate Strategic", "£2M–£15M", "Customer, IP, mfg", "Variable"),
                    list("Government/UKRI", "£100K–£5M", "Credibility, grants", "High")
                  )
                )
              )
            )
          ),
          tabPanel("\U0001f916 DeepTech Application",
            br(),
            fluidRow(
              column(6,
                sh("Who To Target for QuantumLeap AI"),
                fw("Lead: Deep Tech Specialist VC",
                  "Target Molten Ventures, Amadeus Capital, or IP Group as lead. These funds have technical partners who understand chip architecture, can evaluate TRL claims credibly, and have 10+ year fund structures to match DeepTech timelines."),
                fw("Co-Investor: Corporate Strategic",
                  "ARM Ventures, Bosch Ventures, or Intel Capital as co-investor adds customer validation and IP licensing optionality. Critically, negotiate ROFR (Right of First Refusal) limitations upfront — strategic co-investors can block acquisitions by competitors."),
                fw("Grant Stack First",
                  "Before any VC round, secure Innovate UK (£500K–£1M), EIC Pathfinder (up to €4M), and DASA funding if applicable. Every £1 of grant capital saved is an extra £1 of post-money valuation at your Series A."),
                success_box(tags$strong("\u2713 QuantumLeap AI Strategy: "), "Raise £12M Series A led by Molten Ventures with ARM Ventures co-investing. Stack £1.5M Innovate UK grant pre-close. Target a £28M pre-money valuation based on comparable neuromorphic chip raises.")
              ),
              column(6,
                sh("Lawyer Selection Is Critical"),
                fw("Use a VC-Specialist Firm",
                  "In the UK: Taylor Wessing, Orrick, Osborne Clarke, and Mishcon de Reya handle the majority of Series A DeepTech deals. Avoid generalist corporate lawyers — they don't know market norms and will over-negotiate boilerplate terms, irritating your investors."),
                warn_box(tags$strong("\u26a0 Common Mistake: "), "Using your seed-stage solicitor (who handled your company formation) for your Series A. The complexity gap is enormous. Budget £30–80K for legal fees on a £10M+ round — it's a rounding error on deal value."),
                fw("What Good Counsel Does",
                  HTML("1. Tells you what's market vs non-market on every term<br>
                        2. Negotiates control provisions without damaging rapport<br>
                        3. Flags IP assignment gaps before investors find them<br>
                        4. Manages closing mechanics so deals don't collapse on process")),
                insight_box("Feld's Lawyer Rule",
                  tags$p("Never let your lawyer negotiate terms your investors consider non-negotiable boilerplate. Choosing the wrong battle on a standard term signals inexperience and poisons the relationship before it starts."))
              )
            )
          )
        )
      )
    )
  )
}

players_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
