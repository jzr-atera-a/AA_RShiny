# modules/term_sheet.R — Term Sheet Overview

term_sheet_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(2, "\U0001f4c4", "The Term Sheet",
      "The term sheet is a 5–15 page document that determines the economic and governance outcome of your company for the next decade. Most founders focus on the wrong terms. Learn what actually matters.",
      c("ECONOMICS", "CONTROL", "VALUATION", "DEEPTECH NORMS")),

    fluidRow(
      box(title = "Term Sheet: Economics vs Control", status = "primary", solidHeader = TRUE, width = 12,
        p("Brad Feld's central insight: ", tags$b("there are only two things that matter in a term sheet — economics and control."),
          " Everything else is either a subset of one of these or immaterial boilerplate. Founders who focus on valuation and ignore control provisions routinely end up unable to run their own company."),
        fluidRow(
          column(6,
            sh("Economic Terms (What You Get)"),
            algo_table(
              c("Term", "What It Determines", "DeepTech Importance"),
              list(
                list("Pre-money valuation", "Your ownership % after round", "\u2605\u2605\u2605\u2605\u2605"),
                list("Liquidation preference", "Who gets paid first on exit", "\u2605\u2605\u2605\u2605\u2605"),
                list("Participation rights", "Double-dip on upside", "\u2605\u2605\u2605\u2605\u2606"),
                list("Anti-dilution (ratchet)", "Protection in down rounds", "\u2605\u2605\u2605\u2605\u2605"),
                list("Option pool size", "Pre-money dilution to founders", "\u2605\u2605\u2605\u2605\u2606"),
                list("Dividends", "Rarely paid, but cumulative can add up", "\u2605\u2605\u2606\u2606\u2606"),
                list("Vesting schedule", "Founder equity lock-in", "\u2605\u2605\u2605\u2605\u2606")
              )
            )
          ),
          column(6,
            sh("Control Terms (Who Decides)"),
            algo_table(
              c("Term", "What It Determines", "DeepTech Importance"),
              list(
                list("Board composition", "Governance authority", "\u2605\u2605\u2605\u2605\u2605"),
                list("Protective provisions", "Investor veto rights", "\u2605\u2605\u2605\u2605\u2605"),
                list("Drag-along rights", "Force a sale vote", "\u2605\u2605\u2605\u2605\u2606"),
                list("Pro-rata rights", "Right to invest in next round", "\u2605\u2605\u2605\u2605\u2606"),
                list("Information rights", "Access to financials", "\u2605\u2605\u2605\u2606\u2606"),
                list("ROFR / Co-sale", "Restrict founder share sales", "\u2605\u2605\u2605\u2606\u2606"),
                list("Redemption rights", "Force company to repurchase", "\u2605\u2605\u2605\u2605\u2606")
              )
            )
          )
        )
      )
    ),

    fluidRow(
      box(title = "The Option Pool Shuffle — The Most Misunderstood Term", status = "danger", solidHeader = TRUE, width = 6,
        sh("How the Option Pool Shuffle Works"),
        fw("The Mechanism",
          "VCs typically require a 10–15% option pool to be created <em>before</em> the investment closes. This pool comes out of the <em>pre-money</em> valuation — meaning founders bear all of the dilution, not the incoming investors."),
        div(class = "mc-panel",
          tags$h5(style = "color:#00e5ff;", "Example: £20M Post-Money with 15% Pool"),
          tags$p(style = "color:#8fb0d8;font-size:12px;", "Without pool pre-creation:"),
          tags$code("Pre-money = £20M − £5M = £15M. Founder owns 75%."),
          br(), br(),
          tags$p(style = "color:#8fb0d8;font-size:12px;", "With 15% pool pre-created (pool = £3M carved from founder share):"),
          tags$code("Effective pre-money = £20M − £5M − £3M = £12M"),
          tags$code("Founder effectively owns only 60% — not 75%"),
          br(),
          tags$p(style = "color:#e74c3c;font-size:12px;font-weight:700;", "\u26a0 That 15% difference cost the founder 15% of their company before a single hire.")
        ),
        tip_box(tags$strong("Counter-strategy: "), "Negotiate the pool size down to what you can justify based on your hiring plan. A credible 12-month hiring plan showing you only need 8% is a legitimate negotiation. VCs know the shuffle exists — they just hope you don't.")
      ),
      box(title = "Pre vs Post-Money: The Fundamental Formula", status = "info", solidHeader = TRUE, width = 6,
        sh("The Core Valuation Equation"),
        div(class = "mc-panel",
          tags$h5(style = "color:#00e5ff;", "Valuation Formula"),
          tags$code("Post-Money = Pre-Money + Investment"),
          br(), br(),
          tags$code("Investor Ownership % = Investment / Post-Money × 100"),
          br(), br(),
          tags$h5(style = "color:#00e5ff;margin-top:14px;", "QuantumLeap AI Series A Example"),
          tags$p(style = "color:#8fb0d8;font-size:12px;", "Target: £12M raise at £28M pre-money"),
          tags$code("Post-Money = £28M + £12M = £40M"),
          tags$code("VC Ownership = £12M / £40M = 30%"),
          tags$code("Founder + Seed Retention = 70% (before option pool)"),
          br(),
          tags$p(style = "color:#8fb0d8;font-size:12px;", "After 12% option pool creation pre-close:"),
          tags$code("Effective founder retention ≈ 58%")
        ),
        sh("DeepTech Valuation Reality"),
        fw("Benchmark: UK DeepTech Series A 2022–2024",
          "Median pre-money: £15–35M. Top-quartile: £40–80M. Neuromorphic/AI hardware at TRL 5–6 with first silicon: £20–45M. Quantum computing: £35–100M (higher risk tolerance from deep-pocketed investors).")
      )
    )
  )
}

term_sheet_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
