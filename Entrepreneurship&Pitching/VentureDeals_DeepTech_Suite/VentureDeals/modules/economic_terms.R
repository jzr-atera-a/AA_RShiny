# modules/economic_terms.R — Economic Terms with interactive chart

economic_terms_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(3, "\U0001f4b0", "Economic Terms",
      "Liquidation preferences, anti-dilution provisions, and participation rights determine how proceeds are split when your company exits. These terms matter far more than headline valuation in most DeepTech exits.",
      c("LIQUIDATION PREFS", "ANTI-DILUTION", "PARTICIPATION", "EXIT WATERFALL")),

    fluidRow(
      box(title = "Interactive Exit Waterfall — Who Gets Paid What?", status = "primary", solidHeader = TRUE, width = 12,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>How to read this:</strong> This waterfall shows proceeds distribution at different exit values for QuantumLeap AI's hypothetical Series A structure. Adjust the exit value to see how liquidation preferences affect founder proceeds under different structures. The three structures represent common VC term variations.")),
        fluidRow(
          column(3,
            sliderInput(ns("exit_val"), "Exit Value (£M)", min = 5, max = 200, value = 60, step = 5),
            div(class = "mc-panel",
              tags$h5(style = "color:#00e5ff;font-size:12px;", "Deal Assumptions"),
              tags$p(style = "color:#8fb0d8;font-size:11px;", "Seed: £2.1M at 1x liq pref"),
              tags$p(style = "color:#8fb0d8;font-size:11px;", "Series A: £12M invested"),
              tags$p(style = "color:#8fb0d8;font-size:11px;", "Ownership: VC 30%, Founders 58%, Pool 12%"),
              tags$p(style = "color:#8fb0d8;font-size:11px;", "Seed investors: 12% ownership")
            )
          ),
          column(9, plotlyOutput(ns("waterfall_chart"), height = "380px"))
        )
      )
    ),

    fluidRow(
      box(title = "Liquidation Preferences Explained", status = "info", solidHeader = TRUE, width = 6,
        sh("1x Non-Participating (Founder Friendly)"),
        fw("How It Works",
          "Investor gets back 1x their investment OR converts to common stock — whichever is higher. If the exit is large enough, they convert and share pro-rata. This is the <em>cleanest</em> structure and most founder-friendly."),
        tags$code("Investor gets: max(1x investment, pro-rata share of exit)"),
        br(), br(),
        sh("2x Participating Preferred (Investor Friendly)"),
        fw("How It Works",
          "Investor gets 2x their money FIRST, then also participates pro-rata in remaining proceeds. In a £60M exit on £12M invested: investor takes £24M off the top, then takes 30% of the remaining £36M = £10.8M more. Total: £34.8M. Founders get 65% of £36M = £23.4M."),
        warn_box(tags$strong("\u26a0 DeepTech Warning: "), "Participating preferred is more common in DeepTech rounds because VCs are pricing in longer hold periods and higher failure rates. Push back hard on multiples above 1x — the math destroys founder returns in moderate exits."),
        sh("Anti-Dilution: Broad-Based Weighted Average"),
        fw("When It Triggers",
          "Anti-dilution provisions trigger if you raise a subsequent round at a <em>lower</em> valuation (a 'down round'). DeepTech companies face significant down round risk — a failed tapeout, regulatory setback, or market shift can crash valuation mid-cycle. Broad-based weighted average is the market standard; full-ratchet is punitive and should always be rejected.")
      ),
      box(title = "Anti-Dilution: Down Round Impact", status = "warning", solidHeader = TRUE, width = 6,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>Methodology:</strong> Simulated down round from £28M to £14M pre-money. Shows how broad-based weighted average anti-dilution adjusts Series A investor share count to compensate for value loss — at the expense of founder dilution.")),
        plotlyOutput(ns("antidilution_chart"), height = "300px"),
        br(),
        div(class = "mc-panel",
          tags$h5(style = "color:#00e5ff;", "Down Round Formula (BBWA)"),
          tags$code("New Price = (Old Price × Old Shares + Investment) / (Old Shares + New Shares)"),
          br(), br(),
          tags$p(style = "color:#8fb0d8;font-size:11px;", "BBWA is far less punitive than full ratchet, which resets investor price to the down round price entirely — potentially wiping out founder ownership in a severe down round.")
        )
      )
    )
  )
}

economic_terms_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {

    output$waterfall_chart <- renderPlotly({
      exit <- input$exit_val
      seed_inv   <- 2.1
      seriesA_inv <- 12
      vc_own  <- 0.30
      seed_own <- 0.12
      found_own <- 0.58

      # Structure 1: 1x non-participating
      s1_vc_pref   <- min(seriesA_inv, exit)
      s1_seed_pref <- min(seed_inv, max(0, exit - s1_vc_pref))
      s1_rem        <- max(0, exit - s1_vc_pref - s1_seed_pref)
      # VCs convert if pro-rata > preference
      vc_pro_rata <- vc_own * exit
      if (vc_pro_rata > s1_vc_pref && exit > (seriesA_inv / vc_own)) {
        s1_vc    <- vc_pro_rata
        s1_seed  <- seed_own * exit
        s1_found <- found_own * exit
      } else {
        s1_vc    <- s1_vc_pref
        s1_seed  <- s1_seed_pref + seed_own * s1_rem
        s1_found <- found_own * s1_rem
      }

      # Structure 2: 1x participating
      s2_vc_pref <- min(seriesA_inv, exit)
      s2_rem2    <- max(0, exit - s2_vc_pref - seed_inv)
      s2_vc      <- s2_vc_pref + vc_own * s2_rem2
      s2_seed    <- seed_inv + seed_own * s2_rem2
      s2_found   <- found_own * s2_rem2

      # Structure 3: 2x participating
      s3_vc_pref <- min(seriesA_inv * 2, exit)
      s3_rem3    <- max(0, exit - s3_vc_pref - seed_inv)
      s3_vc      <- s3_vc_pref + vc_own * s3_rem3
      s3_seed    <- seed_inv + seed_own * s3_rem3
      s3_found   <- found_own * s3_rem3

      structs <- c("1x Non-Participating\n(Founder Friendly)", "1x Participating", "2x Participating\n(Investor Friendly)")
      founders <- c(round(s1_found, 1), round(s2_found, 1), round(s3_found, 1))
      vcs      <- c(round(s1_vc, 1),    round(s2_vc, 1),   round(s3_vc, 1))
      seeds    <- c(round(s1_seed, 1),   round(s2_seed, 1),  round(s3_seed, 1))

      plot_ly() %>%
        add_trace(x = structs, y = founders, type = "bar", name = "Founders (58%)",
                  marker = list(color = "#00e5ff")) %>%
        add_trace(x = structs, y = vcs, type = "bar", name = "Series A VC (30%)",
                  marker = list(color = "#0066cc")) %>%
        add_trace(x = structs, y = seeds, type = "bar", name = "Seed Investors (12%)",
                  marker = list(color = "#00aa55")) %>%
        layout(barmode = "stack",
               title = list(text = paste0("Exit Proceeds at £", exit, "M — Who Gets What?"), font = list(color = "#cdd9f5")),
               yaxis = list(title = "Proceeds (£M)"),
               xaxis = list(title = "")) %>% dt_theme()
    })

    output$antidilution_chart <- renderPlotly({
      rounds <- c("Series A Price\n(£28M pre)", "Down Round Price\n(£14M pre)", "After BBWA\nAdjustment", "After Full\nRatchet")
      price  <- c(1.00, 0.50, 0.72, 0.50)
      colors <- c("#00e5ff", "#e74c3c", "#f39c12", "#8b0000")

      plot_ly(x = rounds, y = price, type = "bar",
              marker = list(color = colors),
              text = paste0("£", price, " per share (normalised)"),
              hoverinfo = "text+x") %>%
        layout(title = list(text = "Effective Share Price Under Anti-Dilution", font = list(color = "#cdd9f5")),
               yaxis = list(title = "Share Price (normalised to £1)")) %>% dt_theme()
    })
  })
}
