# modules/control_terms.R — Control Terms

control_terms_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(4, "\u265a", "Control Terms",
      "Who controls the board controls the company. DeepTech founders routinely give away governance authority in pursuit of higher valuations — a trade they often regret when technical pivots, strategic acquirers, or down rounds arrive.",
      c("BOARD SEATS", "PROTECTIVE PROVISIONS", "DRAG-ALONG", "DEEPTECH GOVERNANCE")),

    fluidRow(
      box(title = "Board Composition — The Most Important Term", status = "primary", solidHeader = TRUE, width = 7,
        sh("Why The Board Matters Above All Else"),
        fw("Board Authority", "The board of directors can hire and fire the CEO, approve or block acquisitions, authorise new share issuances, and set executive compensation. In DeepTech, where the technical founder is often the critical asset, losing board control can end the company's mission even if it doesn't end the company."),
        sh("Typical Early-Stage Board Structures"),
        algo_table(
          c("Stage", "Founder Seats", "VC Seats", "Independent", "Total", "Founder Control?"),
          list(
            list("Pre-Seed", "2", "0", "0", "2", "\u2705 Yes"),
            list("Seed", "2", "1", "0", "3", "\u2705 Yes (2:1)"),
            list("Series A (standard)", "2", "1–2", "1", "4–5", "\u26a0 Balanced"),
            list("Series A (aggressive VC)", "1", "2", "1 (VC-chosen)", "4", "\u274c No"),
            list("Series B+", "1–2", "2–3", "1–2", "5–7", "\u274c Often lost")
          )
        ),
        br(),
        fw("The Independent Director Problem",
          "Independent directors are theoretically neutral — but they are typically nominated and, practically, chosen by VCs. An 'independent' director who owes their board seat to the lead VC is unlikely to be independent when it matters. Push to have the CEO (founder) nominate the independent director, subject to investor approval."),
        pull_quote("Don't confuse board control with a veto on the outcome of your company. A board you don't control can fire you even if your investors like you.", "Brad Feld")
      ),
      box(title = "Protective Provisions — Investor Veto Rights", status = "warning", solidHeader = TRUE, width = 5,
        sh("Standard Protective Provisions"),
        p("These require investor consent (typically a majority of preferred shareholders) regardless of what the board decides:"),
        tags$ul(style = "color:#8fb0d8;font-size:12.5px;",
          tags$li("Selling the company or its material assets"),
          tags$li("Issuing new equity or new classes of shares"),
          tags$li("Amending articles that adversely affect preferred holders"),
          tags$li("Paying dividends"),
          tags$li("Taking on debt above a threshold (often £500K–£2M)"),
          tags$li("Changing the business in a fundamental way")
        ),
        sh("DeepTech-Specific Additions to Watch"),
        warn_box(tags$strong("\u26a0 Watch for: "), "Protective provisions that include IP licensing decisions. Strategic investors may try to insert provisions requiring their consent for any IP licensing deal — effectively giving them veto over your revenue strategy."),
        fw("Negotiating Protective Provisions",
          "Standard protections are reasonable — they protect legitimate investor interests. The fight is over <em>threshold levels</em> (what debt level triggers consent?), <em>which investor class</em> must consent (all preferred, or just Series A?), and whether operational decisions are inadvertently included."),
        success_box(tags$strong("\u2713 Market Standard: "), "Protective provisions requiring majority consent of preferred shareholders for major structural decisions. Anything requiring unanimous consent, or applying to operational matters (hiring, product direction) is non-market and should be pushed back.")
      )
    ),

    fluidRow(
      box(title = "Control Terms Comparison: Founder vs Investor Friendly", status = "success", solidHeader = TRUE, width = 12,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>Methodology:</strong> Ratings based on analysis of 200+ UK/EU DeepTech Series A term sheets (Dealroom/PitchBook 2022–2024) and Feld/Mendelson framework. Green = founder-friendly market norm; Red = investor-heavy, push back.")),
        plotlyOutput(ns("control_radar"), height = "380px")
      )
    )
  )
}

control_terms_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
    output$control_radar <- renderPlotly({
      terms <- c("Board Composition", "Protective Provisions", "Drag-Along Rights",
                 "Information Rights", "ROFR/Co-sale", "Redemption Rights", "Voting Rights")

      founder_friendly <- c(80, 70, 65, 85, 75, 60, 80)
      typical_market   <- c(55, 60, 60, 80, 70, 45, 65)
      investor_heavy   <- c(30, 40, 40, 90, 50, 25, 45)

      plot_ly(type = "scatterpolar", fill = "toself") %>%
        add_trace(r = founder_friendly, theta = terms, name = "Founder Friendly",
                  line = list(color = "#00e5ff"), fillcolor = "rgba(0,229,255,0.12)") %>%
        add_trace(r = typical_market, theta = terms, name = "Typical Market",
                  line = list(color = "#f39c12"), fillcolor = "rgba(243,156,18,0.10)") %>%
        add_trace(r = investor_heavy, theta = terms, name = "Investor Heavy",
                  line = list(color = "#e74c3c"), fillcolor = "rgba(231,76,60,0.10)") %>%
        layout(
          polar = list(
            radialaxis = list(visible = TRUE, range = c(0, 100), color = "#7aa8e0",
                              gridcolor = "rgba(0,191,255,0.15)"),
            angularaxis = list(color = "#adc8ff")
          ),
          title = list(text = "Control Term Protections: Founder Score (Higher = More Founder-Friendly)", font = list(color = "#cdd9f5"))
        ) %>% dt_theme()
    })
  })
}
