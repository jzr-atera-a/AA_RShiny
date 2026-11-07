# modules/convertible.R — Convertible Debt & SAFEs

convertible_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(6, "\U0001f504", "Convertible Debt & SAFEs",
      "Convertible notes and SAFEs dominate DeepTech seed rounds. They're faster than priced rounds, but the economics are more complex than they appear. Master caps, discounts, and conversion mechanics before you sign.",
      c("CONVERTIBLE NOTES", "SAFES", "VALUATION CAPS", "CONVERSION MECHANICS")),

    fluidRow(
      box(title = "SAFE vs Convertible Note vs Priced Round", status = "primary", solidHeader = TRUE, width = 12,
        algo_table(
          c("Feature", "SAFE", "Convertible Note", "Priced Equity Round"),
          list(
            list("Interest", "None", "5–8% p.a.", "N/A"),
            list("Maturity Date", "None", "12–24 months", "N/A"),
            list("Valuation Cap", "Yes (usually)", "Yes (negotiable)", "Fixed at close"),
            list("Discount", "Yes (10–25%)", "Yes (10–25%)", "N/A"),
            list("Negotiation time", "Days", "Weeks", "Months"),
            list("Legal cost", "£2–8K", "£5–20K", "£30–80K"),
            list("Investor protection", "Low", "Medium (debt priority)", "High (preferred stock)"),
            list("Best for", "Pre-seed / seed", "Seed / bridge", "Series A+"),
            list("DeepTech suitability", "\u2605\u2605\u2605\u2605", "\u2605\u2605\u2605\u2605\u2605", "\u2605\u2605\u2605 (Series A+)")
          )
        )
      )
    ),

    fluidRow(
      box(title = "Interactive Conversion Calculator", status = "info", solidHeader = TRUE, width = 6,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>How this works:</strong> Enter your convertible note terms and the Series A price. The calculator shows what price your note converts at — and what % of the company the note holders receive.")),
        sliderInput(ns("note_size"), "Note Size (£K)", 100, 3000, 1200, 50),
        sliderInput(ns("cap"), "Valuation Cap (£M)", 2, 30, 8, 0.5),
        sliderInput(ns("discount"), "Discount (%)", 5, 30, 20, 5),
        sliderInput(ns("serA_pre"), "Series A Pre-Money (£M)", 5, 60, 28, 1),
        hr_blue(),
        uiOutput(ns("conversion_results"))
      ),
      box(title = "Conversion Mechanics Explained", status = "warning", solidHeader = TRUE, width = 6,
        sh("The Conversion Price Formula"),
        div(class = "mc-panel",
          tags$h5(style = "color:#00e5ff;", "Key Formula"),
          tags$code("Cap Price = Cap Valuation / Fully Diluted Shares"),
          br(), br(),
          tags$code("Discount Price = Series A Price × (1 - Discount %)"),
          br(), br(),
          tags$code("Conversion Price = min(Cap Price, Discount Price)"),
          br(), br(),
          tags$p(style = "color:#8fb0d8;font-size:11px;", "The note holder converts at whichever is LOWER — giving them the better deal. VCs know this; they'll push cap valuations up to reduce note holder advantage.")
        ),
        sh("DeepTech-Specific Guidance"),
        fw("Cap Valuation Strategy",
          "For a neuromorphic chip startup raising £1.2M seed SAFE with a £28M Series A target: a £7–10M cap is market. At £8M cap with 20% discount, note holders convert at a massive advantage over Series A investors — which is fair compensation for taking the earliest risk."),
        fw("Watch for: MFN Clauses",
          "Most Favoured Nation (MFN) provisions in SAFEs give early note holders the right to adopt better terms from later notes. In DeepTech where you may run multiple bridge notes, MFN can create unexpected dilution if later notes have lower caps."),
        warn_box(tags$strong("\u26a0 UK Specific: "), "SEIS/EIS qualifying shares cannot be convertible instruments — they must be ordinary shares. Ensure your note/SAFE converts into a new share class that preserves EIS eligibility for future investors. Take UK tax advice before structuring seed instruments.")
      )
    )
  )
}

convertible_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
    output$conversion_results <- renderUI({
      note <- input$note_size * 1000
      cap_val <- input$cap * 1e6
      disc    <- input$discount / 100
      serA_pre <- input$serA_pre * 1e6
      serA_shares <- 10000000 * 1.25  # approx diluted shares pre-SerA

      cap_price      <- cap_val / serA_shares
      serA_price     <- serA_pre / serA_shares
      discount_price <- serA_price * (1 - disc)
      conv_price     <- min(cap_price, discount_price)
      note_shares    <- note / conv_price
      total_serA     <- serA_shares + note_shares + (serA_pre / serA_price)
      note_pct       <- note_shares / total_serA * 100
      effective_val  <- conv_price * serA_shares / 1e6

      method <- if (cap_price < discount_price) "Cap" else "Discount"

      tagList(
        mc_stat(paste0("£", round(conv_price * 1000, 2), ""), "Conversion Price (per £1K face)"),
        mc_stat(paste0(round(note_pct, 1), "%"), paste0("Note Holder Ownership (via ", method, ")")),
        mc_stat(paste0("£", round(effective_val, 1), "M"), "Effective Pre-Money for Note Holders"),
        mc_stat(paste0(round((serA_price / conv_price - 1) * 100, 1), "%"), "Discount vs Series A Price"),
        if (method == "Cap") {
          success_box(tags$strong("\u2713 Cap triggered: "), paste0("The £", input$cap, "M cap gives note holders a better price than the ", input$discount, "% discount at your £", input$serA_pre, "M pre-money. Note holders effectively invested at a £", round(effective_val, 1), "M valuation."))
        } else {
          info_box(tags$strong("\u2139 Discount triggered: "), paste0("The ", input$discount, "% discount is more favourable than the cap at this pre-money. Consider whether the cap is set at the right level for your expected Series A valuation."))
        }
      )
    })
  })
}
