# modules/overview.R: Overview Tab

overview_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("", "\U0001f30d", "DeepTech VC Landscape",
      "Deep technology fundraising in 2024:2026 operates under fundamentally different rules from SaaS. Longer cycles, higher capital intensity, strategic investor dynamics, and IP-centric deal structures demand a different playbook.",
      c("DEEPTECH VC", "2024:2026", "UK & EUROPE", "SERIES A FOCUS")),

    # ── How to use this tab ───────────────────────────────────
    fluidRow(
      box(title = "\U0001f4a1 How to Use This Tab", status = "warning",
          solidHeader = TRUE, width = 12,
        div(style = "display:flex;gap:20px;align-items:flex-start;flex-wrap:wrap;",
          div(style = "flex:1;min-width:220px;",
            tags$p(style = "color:#8fb0d8;font-size:13px;line-height:1.7;margin:0;",
              tags$b(style = "color:#00e5ff;", "\U0001f4cc Start here "),
              "to understand the DeepTech fundraising landscape before diving into deal terms.
              The four metric cards show global market size and UK position.
              Below them, the stat bars show UK grant availability by programme: use these
              to identify non-dilutive funding to stack before any VC round.",
              tags$br(), tags$br(),
              tags$b(style = "color:#00e5ff;", "\U0001f4ca Bubble chart: "),
              "hover over each sector bubble to see median pre-money valuation, round size,
              and years to exit. Bubble size = median round size. Use this to benchmark
              where your sector sits before setting your own valuation expectations.",
              tags$br(), tags$br(),
              tags$b(style = "color:#00e5ff;", "\U0001f465 Investor categories: "),
              "the four cards at the bottom explain who the players are in DeepTech fundraising
              and what each type of investor brings beyond capital. Read these before
              targeting investors for your round."
            )
          )
        )
      )
    ),


    fluidRow(
      column(3, metric_card("$67B", "Global DeepTech VC 2023")),
      column(3, metric_card("3:7yr", "Typical Exit Timeline")),
      column(3, metric_card("£280M", "UK DeepTech Raised 2023")),
      column(3, metric_card("18%", "DeepTech of All VC Deals"))
    ),

    fluidRow(
      box(title = "What Makes DeepTech Fundraising Different", status = "primary", solidHeader = TRUE, width = 7,
        sh("The Core Tension"),
        fw("Capital Intensity vs Milestone Uncertainty",
          "DeepTech companies burn capital at rates far exceeding SaaS at equivalent stages: but the milestones that unlock the next round are technical, not commercial. A neuromorphic chip startup at TRL 5 cannot show MRR growth; it must show silicon tape-out, benchmark performance, or patent grant. VCs price this uncertainty into deal terms."),
        fw("Long Cycles Demand Different Structures",
          "A SaaS Series A investor expects a 5:7 year hold. A DeepTech investor at Series A may be looking at 8:12 years to exit. This extends everything: vesting cliffs, board patience, follow-on reserves, and liquidation preference stacking across 4:6 rounds before exit."),
        sh("What Investors Look For"),
        algo_table(
          c("Factor", "SaaS Weight", "DeepTech Weight", "Why It Differs"),
          list(
            list("Revenue / ARR", "40%", "5%", "DeepTech pre-revenue for years"),
            list("IP / Patents", "10%", "35%", "Defensibility is the moat"),
            list("Team (PhDs, domain)", "20%", "30%", "Technical depth is primary"),
            list("Market Size (TAM)", "20%", "20%", "Similar importance"),
            list("TRL / Tech Readiness", "0%", "10%", "Unique to hardware/science")
          )
        )
      ),
      box(title = "DeepTech Fundraising Stages", status = "info", solidHeader = TRUE, width = 5,
        sh("Typical UK/EU DeepTech Journey"),
        timeline_strip(
          list("Pre-Seed", "Grants, angels\n£100K:£500K"),
          list("Seed", "Angels + grants\n£500K:£3M"),
          list("Series A", "VC lead\n£5M:£20M"),
          list("Series B", "Growth VC\n£20M:£80M"),
          list("Exit", "Strategic M&A\nor IPO")
        ),
        br(),
        sh("UK Grant Landscape (Non-Dilutive)"),
        pct_bar("Innovate UK (UKRI)", 85, "#00e5ff"),
        pct_bar("Horizon Europe", 70, "#0099ff"),
        pct_bar("DASA (Defence)", 55, "#0066cc"),
        pct_bar("EIC Accelerator (EU)", 65, "#00ccaa"),
        div(class = "tip-box", tags$strong("\U0001f4a1 Tip: "),
          "UK DeepTech founders should stack non-dilutive grants before any VC round. Innovate UK + EIC can fund £1:5M before you give up equity: dramatically improving your pre-money valuation.")
      )
    ),

    fluidRow(
      box(title = "DeepTech Investor Categories", status = "warning", solidHeader = TRUE, width = 12,
        fluidRow(
          column(3,
            div(class = "chapter-card",
              div(class = "ch-num", "CATEGORY 1"),
              div(class = "ch-title", "\U0001f9ec Deep Tech Specialists"),
              div(class = "ch-desc", "Lux Capital, Amadeus Capital, Molten Ventures, IP Group, Octopus Ventures. Long hold, patient capital, technical DD teams. Best for hardware/science."),
              div(class = "ch-tags", span(class = "topic-tag", "PATIENT"), span(class = "topic-tag", "TECHNICAL DD"), span(class = "topic-tag", "BOARD SUPPORT"))
            )
          ),
          column(3,
            div(class = "chapter-card",
              div(class = "ch-num", "CATEGORY 2"),
              div(class = "ch-title", "\U0001f3ed Corporate Strategics"),
              div(class = "ch-desc", "Intel Capital, Bosch Ventures, Samsung Next, ARM. Provide strategic value beyond capital: customer access, IP licensing, manufacturing. Watch for control terms."),
              div(class = "ch-tags", span(class = "topic-tag", "STRATEGIC"), span(class = "topic-tag", "CUSTOMER ACCESS"), span(class = "topic-tag", "ROFR RISK"))
            )
          ),
          column(3,
            div(class = "chapter-card",
              div(class = "ch-num", "CATEGORY 3"),
              div(class = "ch-title", "\U0001f3db\ufe0f Government & University"),
              div(class = "ch-desc", "British Patient Capital, EIC, UKRI, University spin-out funds. Often co-invest. Critical for early credibility and matching private capital."),
              div(class = "ch-tags", span(class = "topic-tag", "NON-DILUTIVE"), span(class = "topic-tag", "CO-INVEST"), span(class = "topic-tag", "CREDIBILITY"))
            )
          ),
          column(3,
            div(class = "chapter-card",
              div(class = "ch-num", "CATEGORY 4"),
              div(class = "ch-title", "\U0001f4b0 Generalist Growth VCs"),
              div(class = "ch-desc", "Sequoia, a16z, Accel: entering DeepTech at Series B+. Higher valuation expectations, less technical patience. Better for scaling than R&D."),
              div(class = "ch-tags", span(class = "topic-tag", "SERIES B+"), span(class = "topic-tag", "GROWTH"), span(class = "topic-tag", "HIGH EXPECTATIONS"))
            )
          )
        )
      )
    ),

    fluidRow(
      box(title = "Interactive: DeepTech Sector Performance vs Valuation", status = "success", solidHeader = TRUE, width = 12,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>How we built this:</strong> Median pre-money valuations and round sizes are drawn from Dealroom, PitchBook, and UKRI published deal data for 2022:2024 UK/EU DeepTech Series A rounds. Bubble size = median round size.")),
        plotlyOutput(ns("sector_chart"), height = "400px")
      )
    )
  )
}

overview_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
    output$sector_chart <- renderPlotly({
      sectors <- data.frame(
        sector    = c("Neuromorphic/AI Chips", "Quantum Computing", "Synthetic Biology",
                      "Advanced Robotics", "Photonics", "Next-Gen Semiconductors",
                      "Space Tech", "Clean Energy Tech"),
        valuation = c(28, 45, 18, 22, 15, 35, 38, 20),
        round_sz  = c(12, 20, 8, 10, 7, 15, 18, 9),
        yrs_exit  = c(6, 9, 7, 5, 6, 7, 10, 8),
        stringsAsFactors = FALSE
      )
      plot_ly(sectors, x = ~yrs_exit, y = ~valuation, size = ~round_sz,
              color = ~sector, type = "scatter", mode = "markers",
              sizes = c(30, 80),
              marker = list(opacity = 0.85, line = list(color = "#00bfff", width = 1)),
              text = ~paste0("<b>", sector, "</b><br>Pre-money: £", valuation, "M<br>Round: £", round_sz, "M<br>Yrs to exit: ", yrs_exit),
              hoverinfo = "text") %>%
        layout(
          xaxis = list(title = "Median Years to Exit", range = c(3, 12)),
          yaxis = list(title = "Median Pre-Money Valuation (£M)"),
          showlegend = TRUE
        ) %>% dt_theme()
    })
  })
}
