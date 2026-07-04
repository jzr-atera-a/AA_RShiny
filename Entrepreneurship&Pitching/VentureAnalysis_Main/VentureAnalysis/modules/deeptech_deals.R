# modules/deeptech_deals.R: DeepTech Deal Specifics

deeptech_deals_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(10, "\U0001f9ec", "DeepTech Deals",
      "IP, grants, long R&D cycles, strategic investors, dual-use regulation, and university spin-out structures create deal complexity far beyond standard SaaS VC. This tab covers the unique deal mechanics DeepTech founders must master.",
      c("IP STRATEGY", "UNIVERSITY SPIN-OUTS", "STRATEGIC INVESTORS", "DUAL-USE REGULATION")),

    # ── How to use this tab ───────────────────────────────────
    fluidRow(
      box(title = "\U0001f4a1 How to Use This Tab", status = "warning",
          solidHeader = TRUE, width = 12,
        tags$p(style = "color:#8fb0d8;font-size:13px;line-height:1.7;margin:0;",
          tags$b(style = "color:#00e5ff;", "\U0001f4cc Four areas covered: "),
          tags$br(),
          tags$b(style = "color:#cdd9f5;", "IP Strategy"),
          ": why IP assignment must be clean before any VC invests, how to structure
          a licence vs full assignment, and how to use your patent portfolio as a valuation argument.
          The warning box flags university IP as a common deal-delaying issue.",
          tags$br(), tags$br(),
          tags$b(style = "color:#cdd9f5;", "University Spin-Out Structures"),
          ": typical UK spin-out cap table at seed stage (university takes 20:35%),
          how SEIS/EIS stacks with university seed funds, and the Napier Review (2023) guidance
          on keeping university equity below 30% at Series A entry.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "\U0001f4ca Benchmarks chart: "),
          "the grouped bar chart shows median pre-money valuation and round size for 8 UK DeepTech
          sectors with IQR error bars. The secondary axis shows median years to exit.
          Hover over bars to see exact figures. Use this to benchmark your own fundraise
          against comparable sectors before setting expectations with investors.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "\U0001f4ca Investor radar chart: "),
          "the three overlapping polygons compare Deep Tech Specialist VCs, Corporate Strategics,
          and Generalist VCs across 7 criteria. Use this to decide what mix of investors
          to target for your round and understand the trade-offs each brings.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "\U0001f4cc Dual-use warning: "),
          "if your technology has defence applications (common in neuromorphic chips, sensors,
          robotics), read the NSI Act 2021 section before accepting investment from any
          non-UK strategic investor: it affects your future exit options."
        )
      )
    ),

      

    fluidRow(
      box(title = "IP Strategy in VC Deals", status = "primary", solidHeader = TRUE, width = 6,
        sh("IP as the Core Asset"),
        fw("Why IP Assignment Must Be Clean",
          "Before any institutional VC invests, their lawyers will conduct an IP audit. Any IP created before the company was incorporated: by founders during PhDs, postdocs, or previous employment: that hasn't been formally assigned to the company is a deal-killer. Clean IP assignment is non-negotiable."),
        warn_box(tags$strong("\u26a0 University IP: "), "If your IP was developed at a UK university, the university may retain rights. King's College, Imperial, Oxford, and Cambridge all have technology transfer offices (TTO) that must negotiate a licence or assignment. This can add 3:6 months to your fundraising timeline. Start early."),
        fw("Patent Portfolio as Valuation Driver",
          "In neuromorphic computing, a portfolio of 3+ granted patents covering core architecture can support a £5:15M IP premium in valuation negotiations. Use independent IP counsel (not your corporate lawyers) to create an IP landscape map and freedom-to-operate opinion before fundraising."),
        sh("Licence vs Assignment"),
        algo_table(
          c("Structure", "Founder Retains IP?", "VC Comfort", "Best For"),
          list(
            list("Full Assignment to Co.", "No", "High", "Most VC deals"),
            list("Exclusive Licence", "University/founder", "Medium", "Uni spin-outs"),
            list("Non-exclusive Licence", "Yes", "Low", "Avoid for VC"),
            list("IP Holding Co (UK)", "In subsidiary", "Medium", "Complex portfolios")
          )
        )
      ),
      box(title = "University Spin-Out Structures", status = "info", solidHeader = TRUE, width = 6,
        sh("The UK Spin-Out Landscape"),
        fw("Praxis Auril & IP Commercialisation",
          "UK universities take founder equity (typically 25:50% at incorporation) in exchange for IP assignment. A 2023 government-backed review (Napier Review) recommended universities limit their equity stake and reduce founder dilution to encourage more spin-outs. Check the current policy of your specific institution."),
        fw("HALO/EIS Structure for Spin-Outs",
          "Most UK university spin-outs use the University Seed Fund + SEIS structure for first external investment. This provides: (1) non-dilutive proof-of-concept grant from the university, (2) up to £250K SEIS-eligible angel investment at 50% tax relief, then (3) up to £5M EIS-eligible Seed VC round."),
        div(class = "mc-panel",
          tags$h5(style = "color:#00e5ff;", "Typical UK Spin-Out Cap Table at Seed"),
          algo_table(
            c("Holder", "Ownership %"),
            list(
              list("Founding team", "35:50%"),
              list("University (via TTO)", "20:35%"),
              list("SEIS Angel investors", "10:20%"),
              list("University seed fund", "5:10%"),
              list("Option pool", "10:15%")
            )
          )
        ),
        success_box(tags$strong("\u2713 Napier Review (2023): "), "Target keeping total university + seed fund equity below 30% at Series A entry to preserve enough founder motivation and leave room for VC dilution.")
      )
    ),

    fluidRow(
      box(title = "DeepTech Deal Benchmarks: UK 2022:2024", status = "warning", solidHeader = TRUE, width = 12,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>Data sources:</strong> Dealroom, PitchBook, British Patient Capital, BVCA annual report 2024, Innovate UK published data. Values represent UK DeepTech Series A deals 2022:2024 (n≈85 deals analysed).")),
        plotlyOutput(ns("benchmark_chart"), height = "420px")
      )
    ),

    fluidRow(
      box(title = "Dual-Use Technology & Regulatory Risk", status = "danger", solidHeader = TRUE, width = 6,
        sh("What Is Dual-Use?"),
        fw("Definition",
          "Dual-use technology has both civilian and military/security applications. Neuromorphic chips, quantum computing, advanced robotics, hyperspectral sensors, and AI systems with situational awareness can all trigger export control, ITAR compliance, or FCDO security review requirements in the UK."),
        fw("Export Control: UK Strategic Export Controls",
          "Under the Export Control Order 2008 (as amended), exporting certain DeepTech to non-permitted countries may require an export licence. This affects: who you can take strategic investment from, which customers you can serve, and whether a Chinese or Russian acquirer could ever buy you: affecting VC exit options."),
        warn_box(tags$strong("\u26a0 Investment Screening: "), "The National Security and Investment Act 2021 (NSI Act) requires mandatory notification for acquisitions of UK companies in 17 sensitive sectors including AI, advanced materials, computing hardware, and quantum technologies. Any exit to a non-UK acquirer is reviewed. VCs must model this in their exit assumptions."),
        fw("DASA & MOD Investment",
          "Defence and Security Accelerator (DASA) and the MOD offer non-dilutive grants of £100K:£1M for dual-use DeepTech. This can be a valuable proof-of-concept funding source: but accepting MOD money can complicate future strategic investment from certain foreign corporate investors. Plan carefully.")
      ),
      box(title = "Strategic vs Financial Investor Comparison", status = "success", solidHeader = TRUE, width = 6,
        sh("Who Is the Right Lead for DeepTech?"),
        plotlyOutput(ns("investor_radar"), height = "360px"),
        div(class = "tip-box", style = "margin-top:12px;",
          tags$strong("\U0001f4a1 Recommendation for QuantumLeap AI: "),
          "Lead with a DeepTech specialist VC (financial) for governance independence, take a corporate strategic as minority co-investor for customer access and IP licensing optionality. Never let a corporate strategic lead if they operate in your target customer segment: conflict of interest is too high.")
      )
    )
  )
}

deeptech_deals_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {

    output$benchmark_chart <- renderPlotly({
      sectors <- c("AI/ML Software", "Quantum Computing", "Neuromorphic Chips",
                   "Advanced Robotics", "Synthetic Biology", "Photonics", "Clean Energy Tech", "Space Tech")
      pre_med    <- c(22, 42, 26, 19, 16, 13, 18, 35)
      pre_p25    <- c(14, 28, 18, 12, 10, 8,  12, 22)
      pre_p75    <- c(38, 72, 45, 32, 26, 20, 30, 60)
      round_med  <- c(8,  18, 11, 8,  6,  5,  7,  15)
      time_exit  <- c(5,  9,  7,  6,  8,  6,  7,  10)

      plot_ly() %>%
        add_trace(
          x = sectors, y = pre_med, type = "bar", name = "Median Pre-Money (£M)",
          marker = list(color = "#0066cc"),
          error_y = list(
            type = "data",
            symmetric = FALSE,
            array    = pre_p75 - pre_med,
            arrayminus = pre_med - pre_p25,
            color = "#00e5ff"
          )
        ) %>%
        add_trace(
          x = sectors, y = round_med, type = "bar", name = "Median Round Size (£M)",
          marker = list(color = "#00aa55")
        ) %>%
        add_trace(
          x = sectors, y = time_exit, type = "scatter", mode = "markers+lines",
          yaxis = "y2", name = "Median Yrs to Exit",
          marker = list(color = "#f39c12", size = 10),
          line = list(color = "#f39c12", dash = "dot")
        ) %>%
        layout(
          barmode = "group",
          title = list(text = "UK DeepTech Series A Deal Benchmarks 2022:2024 (with IQR error bars)", font = list(color = "#cdd9f5")),
          yaxis  = list(title = "Value (£M)"),
          yaxis2 = list(title = "Years to Exit", overlaying = "y", side = "right",
                        color = "#f39c12"),
          xaxis  = list(tickangle = -15)
        ) %>% dt_theme()
    })

    output$investor_radar <- renderPlotly({
      categories <- c("Patient Capital", "Technical DD", "Board Expertise",
                      "Customer Access", "IP Value-Add", "Exit Optionality",
                      "Independence")
      deeptech_vc  <- c(90, 85, 80, 40, 70, 75, 95)
      corp_strat   <- c(70, 75, 65, 95, 90, 45, 30)
      generalist   <- c(50, 40, 70, 30, 30, 85, 90)

      plot_ly(type = "scatterpolar", fill = "toself") %>%
        add_trace(r = deeptech_vc, theta = categories, name = "DeepTech Specialist VC",
                  line = list(color = "#00e5ff"), fillcolor = "rgba(0,229,255,0.10)") %>%
        add_trace(r = corp_strat, theta = categories, name = "Corporate Strategic",
                  line = list(color = "#f39c12"), fillcolor = "rgba(243,156,18,0.10)") %>%
        add_trace(r = generalist, theta = categories, name = "Generalist VC",
                  line = list(color = "#e74c3c"), fillcolor = "rgba(231,76,60,0.10)") %>%
        layout(
          polar = list(
            radialaxis = list(visible = TRUE, range = c(0, 100), color = "#7aa8e0",
                              gridcolor = "rgba(0,191,255,0.15)"),
            angularaxis = list(color = "#adc8ff")
          ),
          title = list(text = "Investor Type Comparison: DeepTech Criteria", font = list(color = "#cdd9f5"))
        ) %>% dt_theme()
    })
  })
}
