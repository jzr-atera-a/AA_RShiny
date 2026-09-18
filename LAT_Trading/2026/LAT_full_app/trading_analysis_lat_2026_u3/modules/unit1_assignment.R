# modules/unit1_assignment.R
# Unit 1: Concepts of Financial Market Trading — model answer covering all 4 assignment
# tasks (exchange structure, macro/political event impact, FX market structure &
# participants, retail trading platforms), with interactive charts (built on the app's
# existing R/utils_synthetic.R engine — syn_path/syn_confined_path/syn_chart/spec_to_plotly),
# real Harvard-style references, formulas and comparison tables.
# All price charts are simulated, seeded, and explicitly labelled as illustrative —
# shaped to match the direction/magnitude of the real, cited events they represent,
# not a claim to reproduce exact historical prints.

# ══════════════════════════════════════════════════════════════════════════
# TASK 1 CHARTS — FTSE 100 reaction to a political event and a macro event
# ══════════════════════════════════════════════════════════════════════════

# Illustrative FTSE 100 reaction around the 23 June 2016 EU referendum result: an
# overnight gap down on the "Leave" result, followed by a fast partial recovery over
# the following sessions — the well-documented pattern driven by the index's heavy
# weighting toward multinational, dollar/euro-earning constituents that benefited from
# sterling's simultaneous slide (Bank of England, 2016; FCA, 2016 market commentary).
u1_political_event_chart <- function(seed = 8801) {
  set.seed(seed)
  pre <- syn_path(18, start = 6300, drift = 0.4, vol = 18, seed = seed)
  gap_open <- tail(pre$Close, 1) - 480  # overnight gap down on the referendum result
  shock <- syn_path(3, start = gap_open, drift = -60, vol = 25, seed = seed + 10)
  recovery <- syn_path(14, start = tail(shock$Close, 1), drift = 55, vol = 20, seed = seed + 20)

  df <- syn_concat(pre, shock, recovery)
  shock_dates <- syn_seg(df, 2)
  shapes <- list(syn_hline(df$Date[1], tail(df$Date, 1), tail(pre$Close, 1), "#7f8c8d", "dot", 1.2))
  ann <- list(
    syn_tag(shock_dates[1], gap_open, "Referendum Result \u2192 Overnight Gap Down", "#e74c3c", 9),
    syn_tag(tail(recovery$Date, 1), tail(recovery$Close, 1), "Partial Recovery (GBP Weakness Boosts Dollar-Earners)", "#27ae60", 8)
  )
  syn_chart(df, "FTSE 100 \u2014 Illustrative Reaction to the 2016 EU Referendum Result", shapes, ann)
}

# Illustrative FTSE 100 reaction to a hawkish (larger-than-expected) Bank of England
# interest rate decision: a sharp initial drop as higher rates raise the discount rate
# applied to future equity earnings, common to rate-sensitive, high-multiple sectors.
u1_macro_event_chart <- function(seed = 8802) {
  set.seed(seed)
  pre <- syn_path(20, start = 7500, drift = 0.2, vol = 16, seed = seed)
  reaction <- syn_path(5, start = tail(pre$Close, 1), drift = -35, vol = 22, seed = seed + 10)
  settle <- syn_path(15, start = tail(reaction$Close, 1), drift = -3, vol = 15, seed = seed + 20)

  df <- syn_concat(pre, reaction, settle)
  reaction_dates <- syn_seg(df, 2)
  ann <- list(syn_tag(reaction_dates[1], tail(pre$Close, 1), "Surprise Rate Hike \u2192 Equity Sell-Off", "#e74c3c", 9))
  syn_chart(df, "FTSE 100 \u2014 Illustrative Reaction to a Surprise BoE Rate Decision", list(), ann)
}

# ══════════════════════════════════════════════════════════════════════════
# TASK 2 CHART — three asset classes reacting to the same macro release (a strong
# US Non-Farm Payrolls beat: USD strengthens, rate-cut expectations recede)
# ══════════════════════════════════════════════════════════════════════════

u1_cross_asset_chart <- function(asset, seed) {
  set.seed(seed)
  pre <- syn_path(15, start = 100, drift = 0.02, vol = 0.5, seed = seed)
  # A strong NFP beat: USD strengthens (EUR/USD falls), risk assets react sharply then
  # partly digest the move, Gold falls as both the USD and real yields rise.
  drift <- switch(asset, fx = -1.3, equity = -0.6, gold = -1.1)
  reaction <- syn_path(3, start = tail(pre$Close, 1), drift = drift, vol = 0.6, seed = seed + 10)
  settle <- syn_path(12, start = tail(reaction$Close, 1), drift = drift * 0.15, vol = 0.5, seed = seed + 20)
  df <- syn_concat(pre, reaction, settle)
  reaction_dates <- syn_seg(df, 2)
  label <- switch(asset, fx = "EUR/USD Falls (USD Strengthens)", equity = "S&P 500 Dips (Fewer Rate Cuts Priced)", gold = "Gold Falls (USD + Real Yields Rise)")
  ann <- list(syn_tag(reaction_dates[1], tail(pre$Close, 1), paste0("NFP Beat \u2192 ", label), "#e74c3c", 8))
  title <- switch(asset, fx = "FX \u2014 EUR/USD (simulated)", equity = "Equities \u2014 S&P 500 (simulated)", gold = "Commodities \u2014 Gold (simulated)")
  syn_chart(df, title, list(), ann)
}

# ══════════════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════════════

unit1_assignment_ui <- function(id) {
  ns <- NS(id)

  fx_participants <- data.frame(
    Participant = c("Central Banks", "Commercial &amp; Investment Banks", "Corporations (MNCs)", "Hedge Funds &amp; Institutional Investors", "Retail Traders"),
    Role = c(
      "Manage domestic monetary policy and, less frequently, intervene directly to influence their currency's value; hold FX reserves (Nasdaq, 2019).",
      "Sit at the centre of the interbank market as market makers, quoting continuous two-way prices and warehousing the bulk of daily FX turnover (Axi, 2026).",
      "Exchange currency to settle cross-border trade, repatriate profits, and hedge transactional/translation currency risk on forward contracts (ECMarkets, 2025).",
      "Trade speculatively and via macro strategies to profit from currency moves, and hedge FX exposure on international equity/bond holdings (Nasdaq, 2019).",
      "Access the market via retail brokers/CFD and spread-betting platforms, typically the smallest and most leveraged participant by account size (BabyPips, 2024)."
    )
  )

  platform_compare <- data.frame(
    Factor = c("Underlying ownership", "UK tax treatment", "Leverage (retail)", "Regulatory protection", "Typical cost"),
    `Spread Betting / CFDs` = c(
      "No ownership of the underlying asset \u2014 a bet/contract on price movement",
      "Spread bets: profits free of UK Capital Gains Tax and stamp duty; CFDs: subject to CGT (The Investors Centre, 2026)",
      "FCA caps leverage between 30:1 and 2:1 depending on asset volatility (FCA, 2019)",
      "Negative balance protection under FCA rules \u2014 cannot lose more than account funds (FCA, 2019)",
      "The bid/offer spread; no separate commission on most platforms"
    ),
    `Equity Trading` = c(
      "Full beneficial ownership of the underlying shares",
      "Subject to UK stamp duty (0.5%) on purchase and CGT on gains above the annual allowance",
      "No leverage on a standard cash account (leverage only via a separate margin facility)",
      "Shares held in a regulated nominee/custody account; standard investor protection scheme cover",
      "Explicit commission per trade plus the bid/offer spread"
    ),
    check.names = FALSE
  )

  tagList(
    ua_intro("Unit 1", "Concepts of Financial Market Trading", "30%", "3,150\u20133,850 words (excl. references)",
             "Assess the structure and trading mechanics of different financial asset classes, how fundamental, economic and political events influence financial markets, and the risks associated with retail and institutional trading."),

    ua_task(1, "International Stock Exchange Structure &amp; Political/Macro Impact on Equity Indices", 30,
      tags$p(paste0(
        "The London Stock Exchange (LSE) is used here as the reference exchange. Tracing its origins to informal ",
        "trading among brokers at Jonathan's Coffee House in 1698, the LSE was formally constituted in 1801 and today ",
        "operates two principal markets: the Main Market, for large, established companies meeting the UK Listing ",
        "Authority's full disclosure requirements, and the Alternative Investment Market (AIM), a lighter-touch venue for ",
        "smaller, higher-growth firms (Wikipedia, 2025; AJ Bell, n.d.). Trading is fully electronic via the SETS order-book ",
        "system, a continuous auction in which buy and sell orders are matched automatically by price-time priority \u2014 ",
        "a structure introduced by the 1986 \u201cBig Bang\u201d deregulation, which replaced open-outcry floor trading (Wall ",
        "Street Oasis, 2025). Its benchmark index, the FTSE 100, tracks the 100 largest companies by market ",
        "capitalisation and is widely used as a proxy for UK large-cap equity market sentiment."
      )),
      tags$h5("How political and macroeconomic news moves the index"),
      tags$p(paste0(
        "Because an equity index is a weighted aggregate of its constituents' share prices, any event that changes the ",
        "market's collective expectation of future corporate earnings or the discount rate applied to them will move the ",
        "index. Two example categories, each illustrated below with a simulated but event-shaped chart:"
      )),
      withSpinner(plotlyOutput(ns("politicalChart"), height = "330px")),
      tags$p(class = "ua-task-body", style = "font-size:12px; margin-top:6px;", paste0(
        "Political example: the result of the 23 June 2016 UK EU membership referendum. Sterling fell sharply against ",
        "major currencies overnight and the FTSE 100 gapped down at the open. The index recovered a large part of that ",
        "loss within the following sessions \u2014 a pattern widely attributed to the index's heavy weighting toward large, ",
        "internationally-earning companies, whose overseas (dollar- and euro-denominated) revenues were worth more in ",
        "sterling terms once the pound weakened, partly offsetting the initial risk-off reaction."
      )),
      withSpinner(plotlyOutput(ns("macroChart"), height = "330px")),
      tags$p(class = "ua-task-body", style = "font-size:12px; margin-top:6px;", paste0(
        "Macroeconomic example: an unexpectedly hawkish Bank of England interest-rate decision. Because equity ",
        "valuations are commonly modelled as the present value of future cash flows, a higher-than-expected policy ",
        "rate raises the discount rate applied to those cash flows, compressing valuations \u2014 an effect felt most acutely ",
        "in rate-sensitive, high-multiple sectors."
      ))
    ),

    ua_task(2, "Macroeconomic Data Releases Across Three Asset Classes", 30,
      tags$p(paste0(
        "A single scheduled release can move every major asset class simultaneously because it revises the market's ",
        "expectations for interest rates, growth, and risk appetite all at once. The example used here is a stronger-",
        "than-expected US Non-Farm Payrolls (NFP) report, which historically ranks among the highest-volatility ",
        "scheduled releases across FX, equity and commodity markets."
      )),
      fluidRow(
        column(4, withSpinner(plotlyOutput(ns("fxReaction"), height = "260px"))),
        column(4, withSpinner(plotlyOutput(ns("equityReaction"), height = "260px"))),
        column(4, withSpinner(plotlyOutput(ns("goldReaction"), height = "260px")))
      ),
      tags$h5("Why the three assets move together, but not identically"),
      ua_table(data.frame(
        `Asset Class` = c("FX (EUR/USD)", "Equity Index (S&amp;P 500)", "Commodities (Gold)"),
        `Typical Reaction to a Strong NFP Beat` = c(
          "Falls \u2014 stronger jobs data raises the odds the Federal Reserve holds rates higher for longer, increasing USD demand relative to EUR.",
          "Often falls initially \u2014 fewer expected rate cuts raise the discount rate on future earnings, though a strong labour market can also support the growth outlook, producing a mixed/volatile reaction.",
          "Falls \u2014 gold pays no yield, so it becomes relatively less attractive as short-term USD interest rates and the US dollar itself both firm."
        ), check.names = FALSE
      ))
    ),

    ua_task(3, "History &amp; Structure of the FX Market, and FIVE Market Participants", 20,
      tags$p(paste0(
        "The modern FX market traces its structure to the collapse of the Bretton Woods fixed-exchange-rate system in ",
        "the early 1970s, after which major currencies were left to float freely against one another, creating the need ",
        "for continuous price discovery (Strike.money, n.d.). Unlike an exchange, FX has no single physical or electronic ",
        "venue: it is an over-the-counter (OTC) market, operating as a decentralised network of banks, brokers and ",
        "electronic platforms trading around the clock across overlapping time zones (London, New York, Singapore, ",
        "Hong Kong, Tokyo). The Bank for International Settlements' Triennial Survey put average daily FX turnover at ",
        "US$9.6 trillion in 2025, making it by far the largest financial market in the world (Axi, 2026)."
      )),
      tags$h5("Five types of FX market participants"),
      ua_table(fx_participants)
    ),

    ua_task(4, "Retail Trading Platforms: Spread Betting/CFDs vs Equity Trading", 20,
      tags$p(paste0(
        "Retail traders in the UK typically access financial markets through one of two structurally different route: ",
        "leveraged derivative products (spread betting and CFDs) or traditional share dealing. The FCA has restricted ",
        "the sale of CFDs and CFD-like products to retail consumers since 2019, citing high and persistent retail loss ",
        "rates \u2014 an estimated 78% of active retail CFD accounts were loss-making in the sample period the FCA reviewed ",
        "before introducing the rules (FCA, 2018)."
      )),
      ua_table(platform_compare),
      ua_callout(HTML(paste0(
        "<strong>Key trade-off:</strong> spread betting/CFDs offer leverage and tax efficiency but concentrate risk ",
        "(the FCA reports 65\u201384% of retail CFD accounts lose money across providers), while equity trading offers full ",
        "ownership and shareholder rights but requires more capital for equivalent market exposure and carries stamp ",
        "duty on every purchase."
      )))
    ),

    ua_references(
      ua_ref("<b>Wikipedia (2025)</b> <i>London Stock Exchange</i>. Available at: Wikipedia.",
             "https://en.wikipedia.org/wiki/London_Stock_Exchange"),
      ua_ref("<b>Wall Street Oasis (2025)</b> <i>London Stock Exchange (LSE) \u2014 Overview, Primary &amp; Specialized Markets</i>.",
             "https://www.wallstreetoasis.com/resources/skills/trading-investing/london-stock-exchange-lse"),
      ua_ref("<b>Axi (2026)</b> <i>Forex Market Participants: Who Controls the Forex Market?</i>",
             "https://www.axi.com/int/blog/education/forex/forex-market-participants"),
      ua_ref("<b>Nasdaq (2019)</b> <i>Foreign Exchange (Forex) Market Participants</i>.",
             "https://www.nasdaq.com/articles/foreign-exchange-forex-market-participants-2019-06-07"),
      ua_ref("<b>Financial Conduct Authority (2019)</b> <i>FCA confirms permanent restrictions on the sale of CFDs and CFD-like options to retail consumers</i>.",
             "https://www.fca.org.uk/news/press-releases/fca-confirms-permanent-restrictions-sale-cfds-and-cfd-options-retail-consumers"),
      ua_ref("<b>Financial Conduct Authority (2018)</b> <i>CP18/38: Restricting contract for difference products sold to retail clients</i>.",
             "https://www.fca.org.uk/publication/consultation/cp18-38.pdf"),
      ua_ref("<b>The Investors Centre (2026)</b> <i>UK Spread Betting Statistics 2026: Losses, Tax &amp; Market Data</i>.",
             "https://www.theinvestorscentre.co.uk/trading/statistics/spread-betting/")
    )
  )
}

unit1_assignment_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    output$politicalChart <- renderPlotly({ spec_to_plotly(u1_political_event_chart()) })
    output$macroChart     <- renderPlotly({ spec_to_plotly(u1_macro_event_chart()) })
    output$fxReaction     <- renderPlotly({ spec_to_plotly(u1_cross_asset_chart("fx", 8810)) })
    output$equityReaction <- renderPlotly({ spec_to_plotly(u1_cross_asset_chart("equity", 8820)) })
    output$goldReaction   <- renderPlotly({ spec_to_plotly(u1_cross_asset_chart("gold", 8830)) })
    session$onSessionEnded(function() {})
  })
}
