# modules/mobility_commodities.R
# "Commodities for Mobility" — three commodities central to transport/EV supply chains
# (Copper, Lithium Hydroxide, Brent Crude), each paired with: (1) the most relevant
# exchange to trade it FROM THE UK, and (2) a set of complex, event-driven technical-
# analysis chart examples (political-event reaction, macro-data reaction, and an
# indicator overlay), built on the app's existing R/utils_synthetic.R engine
# (syn_path/syn_concat/syn_seg/syn_tag/syn_chart/spec_to_plotly) and R/utils_academic.R
# UI helpers (ua_intro/ua_table/ua_callout), the same pattern used by
# modules/unit1_assignment.R.
#
# Scope note: this module supplies REFERENCE VISUALISATIONS AND MARKET DATA ONLY —
# chart captions describe what each chart shows, not a written critical analysis. It
# is designed as source material a student researching Unit 1 (or similar asset-class/
# macro-impact questions) could adapt into their own answer, not a completed answer.
# All price charts are simulated, seeded, and explicitly labelled as illustrative.

# ══════════════════════════════════════════════════════════════════════════
# MARKET IDENTIFICATION — most relevant UK-accessible venue per commodity
# ══════════════════════════════════════════════════════════════════════════

mc_market_table <- function(asset) {
  info <- switch(asset,
    copper = data.frame(
      Field = c("Commodity", "Mobility linkage", "Most relevant exchange (from UK)", "Contract", "Ticker", "Contract unit", "Trading hours (London)"),
      Value = c(
        "Copper",
        "EV wiring/motors/batteries, charging infrastructure, grid build-out for electrification",
        "London Metal Exchange (LME) \u2014 the global copper price-discovery venue, physically based in London",
        "LME Copper (Grade A) futures/forwards",
        "MCU / CA",
        "25 tonnes",
        "Ring + electronic (LMEselect) trading, core hours approx. 08:00\u201317:00 London time"
      )
    ),
    lithium = data.frame(
      Field = c("Commodity", "Mobility linkage", "Most relevant exchange (from UK)", "Contract", "Ticker", "Contract unit", "Trading hours (London)"),
      Value = c(
        "Lithium Hydroxide",
        "Core cathode material for EV lithium-ion battery cells",
        "London Metal Exchange (LME) \u2014 cash-settled Lithium Hydroxide futures (CIF China/Japan/Korea, Fastmarkets-referenced), London-based",
        "LME Lithium Hydroxide CIF CJK futures",
        "LC0",
        "1 tonne (cash-settled, no physical delivery)",
        "Electronic (LMEselect) trading, core hours approx. 08:00\u201317:00 London time"
      )
    ),
    oil = data.frame(
      Field = c("Commodity", "Mobility linkage", "Most relevant exchange (from UK)", "Contract", "Ticker", "Contract unit", "Trading hours (London)"),
      Value = c(
        "Brent Crude Oil",
        "Feedstock for petrol/diesel/jet fuel \u2014 still the dominant transport-fuel benchmark alongside electrification",
        "ICE Futures Europe \u2014 headquartered in London, sets the global Brent benchmark price",
        "ICE Brent Crude Futures",
        "B",
        "1,000 barrels",
        "Nearly 24hr electronic trading; London session core hours approx. 08:00\u201317:00"
      )
    )
  )
  ua_table(info)
}

# ══════════════════════════════════════════════════════════════════════════
# CHART BUILDERS — political event, macro event, indicator overlay (per commodity)
# ══════════════════════════════════════════════════════════════════════════

# -- Copper -------------------------------------------------------------
mc_copper_political <- function(seed = 9101) {
  set.seed(seed)
  pre <- syn_path(18, start = 9200, drift = 4, vol = 45, seed = seed)
  shock <- syn_path(3, start = tail(pre$Close, 1), drift = 210, vol = 60, seed = seed + 10)
  settle <- syn_path(14, start = tail(shock$Close, 1), drift = 15, vol = 45, seed = seed + 20)
  df <- syn_concat(pre, shock, settle)
  d2 <- syn_seg(df, 2)
  ann <- list(syn_tag(d2[1], tail(pre$Close, 1), "China EV Subsidy Extension Announced \u2192 Demand Shock", "#27ae60", 8))
  syn_chart(df, "LME Copper \u2014 Illustrative Reaction to a Political/Policy Announcement", list(), ann)
}
mc_copper_macro <- function(seed = 9102) {
  set.seed(seed)
  pre <- syn_path(18, start = 9100, drift = 2, vol = 40, seed = seed)
  shock <- syn_path(3, start = tail(pre$Close, 1), drift = 140, vol = 50, seed = seed + 10)
  settle <- syn_path(14, start = tail(shock$Close, 1), drift = 8, vol = 40, seed = seed + 20)
  df <- syn_concat(pre, shock, settle)
  d2 <- syn_seg(df, 2)
  ann <- list(syn_tag(d2[1], tail(pre$Close, 1), "China Manufacturing PMI Beat \u2192 Demand-Read-Through Rally", "#27ae60", 8))
  syn_chart(df, "LME Copper \u2014 Illustrative Reaction to a Macro Data Release", list(), ann)
}
mc_copper_indicator <- function(seed = 9103) {
  set.seed(seed)
  pre <- syn_path(40, start = 8600, drift = 6, vol = 40, seed = seed)
  df <- pre
  ma_fast <- zoo::rollmean(df$Close, 10, fill = NA, align = "right")
  ma_slow <- zoo::rollmean(df$Close, 25, fill = NA, align = "right")
  cross_i <- suppressWarnings(min(which(ma_fast > ma_slow & !is.na(ma_fast) & !is.na(ma_slow))))
  ann <- if (is.finite(cross_i)) list(syn_tag(df$Date[cross_i], df$Close[cross_i], "10/25-Day MA Golden Cross", "#27ae60", 8)) else list()
  syn_chart(df, "LME Copper \u2014 Moving Average Crossover (10-day vs 25-day)", list(), ann,
            indicator = list(dates = df$Date, values = ma_fast, label = "MA(10)", color = "#3498db",
                              values2 = ma_slow, label2 = "MA(25)", color2 = "#e67e22"))
}

# -- Lithium Hydroxide ----------------------------------------------------
mc_lithium_political <- function(seed = 9201) {
  set.seed(seed)
  pre <- syn_path(18, start = 14200, drift = 5, vol = 90, seed = seed)
  shock <- syn_path(3, start = tail(pre$Close, 1), drift = 480, vol = 140, seed = seed + 10)
  settle <- syn_path(14, start = tail(shock$Close, 1), drift = 25, vol = 90, seed = seed + 20)
  df <- syn_concat(pre, shock, settle)
  d2 <- syn_seg(df, 2)
  ann <- list(syn_tag(d2[1], tail(pre$Close, 1), "Chile Export Royalty Announcement \u2192 Supply-Shock Rally", "#27ae60", 8))
  syn_chart(df, "LME Lithium Hydroxide \u2014 Illustrative Reaction to a Political/Policy Announcement", list(), ann)
}
mc_lithium_macro <- function(seed = 9202) {
  set.seed(seed)
  pre <- syn_path(18, start = 14400, drift = 3, vol = 90, seed = seed)
  shock <- syn_path(3, start = tail(pre$Close, 1), drift = -420, vol = 130, seed = seed + 10)
  settle <- syn_path(14, start = tail(shock$Close, 1), drift = -20, vol = 90, seed = seed + 20)
  df <- syn_concat(pre, shock, settle)
  d2 <- syn_seg(df, 2)
  ann <- list(syn_tag(d2[1], tail(pre$Close, 1), "Global EV Sales Data Miss \u2192 Demand Read-Through Sell-Off", "#e74c3c", 8))
  syn_chart(df, "LME Lithium Hydroxide \u2014 Illustrative Reaction to a Macro/Demand Data Release", list(), ann)
}
mc_lithium_indicator <- function(seed = 9203) {
  set.seed(seed)
  pre <- syn_path(15, start = 13800, drift = 2, vol = 80, seed = seed)
  shock <- syn_path(3, start = tail(pre$Close, 1), drift = 500, vol = 120, seed = seed + 10)
  settle <- syn_path(20, start = tail(shock$Close, 1), drift = -35, vol = 80, seed = seed + 20)  # price stalls/reverses -> bearish RSI divergence
  df <- syn_concat(pre, shock, settle)
  rsi <- TTR::RSI(df$Close, n = 14)
  d2 <- syn_seg(df, 2)
  ann <- list(syn_tag(d2[1], tail(pre$Close, 1), "Supply-Shock Spike (Watch RSI for Overbought Divergence)", "#e67e22", 8))
  syn_chart(df, "LME Lithium Hydroxide \u2014 RSI(14) Overbought/Divergence Check", list(), ann,
            indicator = list(dates = df$Date, values = rsi, label = "RSI(14)", color = "#9b59b6",
                              hlines = c(70, 30), yrange = c(0, 100)))
}

# -- Brent Crude ------------------------------------------------------------
mc_oil_political <- function(seed = 9301) {
  set.seed(seed)
  pre <- syn_path(18, start = 78, drift = 0.05, vol = 0.6, seed = seed)
  shock <- syn_path(3, start = tail(pre$Close, 1), drift = 2.6, vol = 0.9, seed = seed + 10)
  settle <- syn_path(14, start = tail(shock$Close, 1), drift = 0.15, vol = 0.6, seed = seed + 20)
  df <- syn_concat(pre, shock, settle)
  d2 <- syn_seg(df, 2)
  ann <- list(syn_tag(d2[1], tail(pre$Close, 1), "Surprise OPEC+ Production Cut \u2192 Supply-Shock Gap Up", "#27ae60", 8))
  syn_chart(df, "ICE Brent Crude \u2014 Illustrative Reaction to a Political/OPEC+ Decision", list(), ann)
}
mc_oil_macro <- function(seed = 9302) {
  set.seed(seed)
  pre <- syn_path(18, start = 80, drift = -0.02, vol = 0.6, seed = seed)
  shock <- syn_path(3, start = tail(pre$Close, 1), drift = -1.8, vol = 0.8, seed = seed + 10)
  settle <- syn_path(14, start = tail(shock$Close, 1), drift = -0.1, vol = 0.6, seed = seed + 20)
  df <- syn_concat(pre, shock, settle)
  d2 <- syn_seg(df, 2)
  ann <- list(syn_tag(d2[1], tail(pre$Close, 1), "US EIA Crude Inventory Build (Bigger Than Expected) \u2192 Sell-Off", "#e74c3c", 8))
  syn_chart(df, "ICE Brent Crude \u2014 Illustrative Reaction to a Macro Inventory Data Release", list(), ann)
}
mc_oil_indicator <- function(seed = 9303) {
  set.seed(seed)
  pre <- syn_path(45, start = 74, drift = 0.12, vol = 0.7, seed = seed)
  df <- pre
  macd <- TTR::MACD(df$Close, nFast = 12, nSlow = 26, nSig = 9)
  syn_chart(df, "ICE Brent Crude \u2014 MACD(12,26,9) Momentum Panel", list(), list(),
            indicator = list(dates = df$Date, values = macd[, "macd"], label = "MACD", color = "#3498db",
                              values2 = macd[, "signal"], label2 = "Signal", color2 = "#e67e22"))
}

# ══════════════════════════════════════════════════════════════════════════
# UI — one sidebar row per commodity, mirroring the "Unit Assignments" group
# (Unit 1 / Unit 2 / Unit 3 each get their own tabName + menuSubItem; the four
# tabs here share ONE module id/namespace so a single moduleServer below can
# serve outputs to all of them).
# ══════════════════════════════════════════════════════════════════════════

# One commodity's tab body: market ID table + 3 chart panels with plain descriptive
# captions (what the chart shows — no analysis text, by design; see file header).
mc_commodity_ui <- function(ns, asset, heading) {
  tagList(
    tags$h3(heading),
    tags$h5("Most relevant UK-accessible market"),
    mc_market_table(asset),
    ua_callout("Reference visualisation only \u2014 charts below use simulated, seeded price paths shaped to illustrate a named event/indicator pattern, not a claim to reproduce real historical prints. Use them as a starting structure for your own researched examples and citations."),

    tags$h5("Political/policy event \u2014 reaction chart"),
    withSpinner(plotlyOutput(ns(paste0(asset, "Political")), height = "320px")),

    tags$h5("Macroeconomic data event \u2014 reaction chart"),
    withSpinner(plotlyOutput(ns(paste0(asset, "Macro")), height = "320px")),

    tags$h5("Technical indicator overlay"),
    withSpinner(plotlyOutput(ns(paste0(asset, "Indicator")), height = "320px"))
  )
}

mobility_copper_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ua_intro("Commodities for Mobility", "Copper \u2014 EV Wiring, Motors & Grid Build-Out", "\u2014", "\u2014",
             "Copper is one of three asset classes covered in this group (alongside Lithium Hydroxide and Brent Crude), each mapped to the exchange most relevant to trading it from the UK."),
    mc_commodity_ui(ns, "copper", "Copper \u2014 EV Wiring, Motors & Grid Build-Out")
  )
}
mobility_lithium_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ua_intro("Commodities for Mobility", "Lithium Hydroxide \u2014 EV Battery Cathode Material", "\u2014", "\u2014",
             "Lithium Hydroxide is one of three asset classes covered in this group (alongside Copper and Brent Crude), each mapped to the exchange most relevant to trading it from the UK."),
    mc_commodity_ui(ns, "lithium", "Lithium Hydroxide \u2014 EV Battery Cathode Material")
  )
}
mobility_oil_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ua_intro("Commodities for Mobility", "Brent Crude Oil \u2014 Transport Fuel Benchmark", "\u2014", "\u2014",
             "Brent Crude is one of three asset classes covered in this group (alongside Copper and Lithium Hydroxide), each mapped to the exchange most relevant to trading it from the UK."),
    mc_commodity_ui(ns, "oil", "Brent Crude Oil \u2014 Transport Fuel Benchmark")
  )
}

# ══════════════════════════════════════════════════════════════════════════
# "Approaching the Unit 1 Questions" — a plain-English APPROACH GUIDE, not a
# completed answer. For each task: what it is asking (in simple terms) and the
# structure a good answer follows. No essay text, no filled-in analysis — this
# is a study aid, written in British English, with ~15 real, verifiable,
# reputable Harvard-style references a student can read and cite themselves.
# ══════════════════════════════════════════════════════════════════════════

ma_step <- function(title, ...) {
  tags$div(class = "ua-task",
    tags$div(class = "ua-task-head", tags$div(class = "ua-task-title", title)),
    tags$div(class = "ua-task-body", ...)
  )
}

mobility_approach_ui <- function(id) {
  ns <- NS(id)

  tagList(
    ua_intro("Commodities for Mobility", "Approaching the Unit 1 Questions", "\u2014", "\u2014",
             "A plain-English guide to structuring your own answer to Unit 1: Concepts of Financial Market Trading. This explains what each task is asking and how to approach it \u2014 it does not answer the questions for you."),

    ua_callout("This page is a study guide only. It sets out how to structure your answer and points you to real, checkable sources \u2014 it does not contain finished answer text. You still need to do your own research, write in your own words, add your own examples and charts, and reference correctly."),

    ma_step("Task 1(a) \u2014 1050 words, 10 marks: Pick one stock exchange and explain how it works",
      tags$p(paste0(
        "Choose one well-known international exchange (for example the London Stock Exchange, New York Stock Exchange, ",
        "or NASDAQ). Explain, in simple terms: when it was set up, what kind of companies list there, how a trade is ",
        "actually matched (most large exchanges today use an electronic order book, where computers match buy and sell ",
        "orders by price and time), and who regulates it. Finish by naming its main index, since you will use this in Task 1(b)."
      ))
    ),

    ma_step("Task 1(b) \u2014 (same 1050 words, 20 marks): How political news and economic data move the index",
      tags$p(paste0(
        "Pick the main index of the exchange you chose in 1(a). Explain simply why a piece of news can move an index: ",
        "an index is just the combined value of many company share prices, so anything that changes what investors ",
        "expect those companies to earn in future \u2014 or how safe that money feels \u2014 moves the index. Then give ",
        "TWO worked examples with a chart for each:"
      )),
      tags$ul(
        tags$li("A political event (for example a referendum, election result, or war/conflict) and how the index reacted."),
        tags$li("A macroeconomic data event (for example an interest rate decision, inflation figure, or jobs report) and how the index reacted.")
      ),
      tags$p("For each chart, mark the date of the event and briefly say what happened to the price before and after \u2014 that is what \u201ccritically examine\u201d means here: don't just describe the move, explain why it happened.")
    ),

    ma_step("Task 2 \u2014 1050 words, 30 marks: Macro data across THREE asset classes",
      tags$p(paste0(
        "Pick one macro data release (for example an interest rate decision or a jobs report) and show how the SAME ",
        "release affects THREE different types of asset \u2014 for example a stock index, a currency pair, and a ",
        "commodity such as gold or oil. For each asset class, explain in a sentence or two why that particular type of ",
        "asset reacts the way it does (for example: a currency often strengthens on a strong jobs report because higher ",
        "rates are expected; gold often falls because it pays no interest, so it becomes less attractive when rates rise). ",
        "Use one real, dated example per asset class."
      ))
    ),

    ma_step("Task 3 \u2014 750 words, 20 marks: History and structure of the FX market, plus FIVE participants",
      tags$p(paste0(
        "Briefly explain how today's currency market came about (most courses point to the early 1970s, when major ",
        "currencies stopped being fixed to gold/the US dollar and were left to float). Explain that FX has no single ",
        "building or exchange \u2014 it is a network of banks and platforms trading around the clock. Then name and ",
        "briefly explain FIVE different types of participant, for example: central banks, commercial/investment banks, ",
        "large companies (hedging trade), hedge funds/institutional investors, and retail traders. For each one, say ",
        "HOW they access the market and WHY they are in it."
      ))
    ),

    ma_step("Task 4 \u2014 750 words, 20 marks: Spread betting/CFDs vs equity trading",
      tags$p(paste0(
        "Compare the two ways a UK retail trader can access the market. For spread betting/CFDs, cover: no ownership ",
        "of the actual shares, leverage (and the FCA's limits on this), UK tax treatment, and the main risks. For direct ",
        "equity trading, cover: full ownership of real shares, no leverage on a normal account, UK stamp duty on ",
        "purchases, and shareholder rights. Use one concrete example (a cost, a tax rule, or a risk scenario) for each side."
      ))
    ),

    ua_references(
      ua_ref("<b>Financial Conduct Authority (2026)</b> <i>Contract for differences</i>.", "https://www.fca.org.uk/firms/contract-for-differences"),
      ua_ref("<b>Financial Conduct Authority (2019)</b> <i>PS19/18: Restricting contract for difference products sold to retail clients</i>.", "https://www.fca.org.uk/publications/policy-statements/ps19-18-restricting-contract-difference-products"),
      ua_ref("<b>GOV.UK / HM Revenue &amp; Customs (2023)</b> <i>Stamp Duty and Stamp Duty Reserve Tax</i>.", "https://www.gov.uk/government/publications/stamp-duty-and-stamp-duty-reserve-tax/stamp-duty-and-stamp-duty-reserve-tax"),
      ua_ref("<b>Bank of England (2026)</b> <i>Monetary policy</i>.", "https://www.bankofengland.co.uk/monetary-policy"),
      ua_ref("<b>Bank of England (2026)</b> <i>Interest rates and Bank Rate: our latest decision</i>.", "https://www.bankofengland.co.uk/monetary-policy/the-interest-rate-bank-rate"),
      ua_ref("<b>Bank of England (2022)</b> <i>Foreign exchange and OTC derivatives markets turnover survey \u2014 2022</i>.", "https://www.bankofengland.co.uk/statistics/bis-survey/2022"),
      ua_ref("<b>Bank for International Settlements (2022)</b> <i>Triennial Central Bank Survey of foreign exchange and OTC derivatives markets in 2022</i>.", "https://www.bis.org/statistics/rpfx22.htm"),
      ua_ref("<b>US Bureau of Labor Statistics (2026)</b> <i>Employment Situation (Non-Farm Payrolls) news release</i>.", "https://www.bls.gov/news.release/empsit.htm"),
      ua_ref("<b>International Monetary Fund (2021)</b> <i>From the History Books: The Rethinking of the International Monetary System</i>.", "https://www.imf.org/en/blogs/articles/2021/08/16/from-the-history-books-the-rethinking-of-the-international-monetary-system"),
      ua_ref("<b>Federal Reserve History (n.d.)</b> <i>Creation of the Bretton Woods System</i>.", "https://www.federalreservehistory.org/essays/bretton-woods-created"),
      ua_ref("<b>Federal Reserve History (2013)</b> <i>The Smithsonian Agreement</i>.", "https://www.federalreservehistory.org/essays/smithsonian-agreement"),
      ua_ref("<b>LSEG / FTSE Russell (2026)</b> <i>FTSE UK Index Series \u2014 Ground Rules</i>.", "https://www.lseg.com/content/dam/ftse-russell/en_us/documents/ground-rules/ftse-uk-index-series-ground-rules.pdf"),
      ua_ref("<b>AIM-Watch (2020)</b> <i>SEAQ, SETS &amp; SETSqx Trading Systems Explained</i>.", "https://aim-watch.com/project/seaq-sets-setsqx/"),
      ua_ref("<b>Wikipedia (2026)</b> <i>London Stock Exchange</i>.", "https://en.wikipedia.org/wiki/London_Stock_Exchange"),
      ua_ref("<b>Fern\u00e1ndez-Rodr\u00edguez, F., Sosvilla-Rivero, S. and Garc\u00eda-Rubio, J.M. (2019)</b> <i>Differential market reactions to pre and post Brexit referendum</i>. <i>Physica A</i>.", "https://www.sciencedirect.com/science/article/abs/pii/S0378437118313128")
    )
  )
}

mobility_commodities_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    output$copperPolitical  <- renderPlotly({ spec_to_plotly(mc_copper_political()) })
    output$copperMacro      <- renderPlotly({ spec_to_plotly(mc_copper_macro()) })
    output$copperIndicator  <- renderPlotly({ spec_to_plotly(mc_copper_indicator()) })

    output$lithiumPolitical <- renderPlotly({ spec_to_plotly(mc_lithium_political()) })
    output$lithiumMacro     <- renderPlotly({ spec_to_plotly(mc_lithium_macro()) })
    output$lithiumIndicator <- renderPlotly({ spec_to_plotly(mc_lithium_indicator()) })

    output$oilPolitical     <- renderPlotly({ spec_to_plotly(mc_oil_political()) })
    output$oilMacro         <- renderPlotly({ spec_to_plotly(mc_oil_macro()) })
    output$oilIndicator     <- renderPlotly({ spec_to_plotly(mc_oil_indicator()) })

    session$onSessionEnded(function() {})
  })
}
