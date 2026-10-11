# modules/research_academia.R
#
# "Research and Academia" group. Two sub-tabs, each connecting real people and
# companies to this app's content. Everything factual here was checked against
# primary or independent sources (university faculty pages, CEPR, SSRN,
# ScienceDirect, RePEc, Cambridge Judge Business School); where something could
# not be verified it is labelled as such rather than stated as fact.
#
#   1. Prof. Riddiough (U of T) - Steven J. Riddiough, Associate Professor of
#      Finance, University of Toronto. His research is FX / currency risk
#      premia, NOT energy commodities, satellite or weather data - stated
#      plainly, with four connections to this app that are drawn carefully:
#      what each paper actually finds is kept separate from how this app
#      might reasonably use the idea.
#   2. AlgoDynamiX - a real Cambridge-founded risk analytics company. Its own
#      performance claims are flagged as self-published, and it is flagged that
#      its published coverage lists equity indices, fixed income futures and FX
#      futures - energy coverage specifically needs confirming with the vendor.
#
# IMPROVEMENTS over the first version of this group:
#   * Citations carry verified links (no unverified DOIs) and a Harvard
#     reference list; the business-cycle table no longer attributes specific
#     claims to papers that do not make them.
#   * The petrocurrency statistic is computed live and reported two ways - on
#     levels AND on year-on-year changes, with p-values - instead of a single
#     correlation described as "confirming" the link (on 11 points it does not:
#     levels r = -0.43, p = 0.19; changes r = -0.76, p = 0.01).
#   * FX hedging calculator gains a hedge-ratio ladder and cost-per-risk-
#     removed, and states plainly that it is a simplification of the paper.
#   * Build-vs-license gains cumulative cost over 10 years, the crossover year,
#     and an editable vendor time-to-live; plus questions to put to the vendor.

# ===========================================================================
# PURE LOGIC
# ===========================================================================

# Approximate annual-average WTI ($/bbl) and USD/CAD, 2014-2024. Recalled from
# public EIA / Bank of Canada series, NOT downloaded or verified here -
# illustrative. Replace with the real series before relying on any statistic.
ra_petro_data <- data.frame(
  Year   = 2014:2024,
  WTI    = c(93, 49, 43, 51, 65, 57, 39, 68, 95, 78, 76),
  USDCAD = c(1.10, 1.28, 1.33, 1.30, 1.30, 1.33, 1.34, 1.25, 1.30, 1.35, 1.37)
)

# Correlation of levels and of year-on-year changes, with p-values. Two trending
# series can correlate in levels for spurious reasons, so the changes-based
# figure is the sturdier check.
ra_petro_stats <- function(d = ra_petro_data) {
  lv <- cor.test(d$WTI, d$USDCAD)
  ch <- cor.test(diff(d$WTI), diff(d$USDCAD))
  fit <- lm(USDCAD ~ WTI, data = d)
  list(cor_levels = unname(lv$estimate), p_levels = lv$p.value,
       cor_changes = unname(ch$estimate), p_changes = ch$p.value,
       slope_per_10 = unname(coef(fit)[2]) * 10, r2 = summary(fit)$r.squared,
       n_levels = nrow(d), n_changes = nrow(d) - 1, fit = fit)
}

# Deliberately simple: treats FX volatility as the only risk and a hedge as
# removing a fixed fraction of it. It is NOT Opie & Riddiough's method (a
# dynamic hedge that exploits predictability in global factor returns).
ra_hedge_illustration <- function(notional, fx_vol_pct, hedge_ratio, cost_pct) {
  unhedged <- notional * fx_vol_pct / 100
  hedged <- unhedged * (1 - hedge_ratio)
  removed <- unhedged - hedged
  cost <- notional * hedge_ratio * cost_pct / 100
  list(unhedged_vol = unhedged, hedged_vol = hedged,
       reduction_pct = if (unhedged > 0) (1 - hedged / unhedged) * 100 else 0,
       annual_cost = cost,
       cost_per_risk_removed = if (removed > 0) cost / removed else NA_real_)
}

ra_hedge_ladder <- function(notional, fx_vol_pct, cost_pct, ratios = c(0, 0.25, 0.5, 0.75, 1)) {
  do.call(rbind, lapply(ratios, function(r) {
    h <- ra_hedge_illustration(notional, fx_vol_pct, r, cost_pct)
    data.frame(`Hedge ratio` = paste0(round(r * 100), "%"),
               `Residual FX risk (1 sd)` = round(h$hedged_vol),
               `Annual hedge cost` = round(h$annual_cost),
               `Cost per 1 of risk removed` = if (is.na(h$cost_per_risk_removed)) "n/a" else format(round(h$cost_per_risk_removed, 3), nsmall = 3),
               check.names = FALSE)
  }))
}

# Stylised illustration only. The carry column is a widely observed market
# pattern (carry does well in risk-on conditions and unwinds in risk-off), NOT a
# finding of the papers cited on this tab; the energy column is Wyckoff-style
# convention.
ra_business_cycle <- data.frame(
  Phase = c("Early expansion", "Late expansion", "Slowdown / peak", "Recession / trough"),
  `Typical currency carry conditions` = c("Supportive: risk appetite favours high yielders",
                                          "Supportive but crowded, fragile",
                                          "Deteriorating: carry starts to unwind as risk appetite falls",
                                          "Poor: flight to safe-haven funding currencies"),
  `Typical energy trend` = c("Building: demand recovery not yet priced",
                             "Strong uptrend: demand growth confirmed",
                             "Topping: demand growth decelerates first",
                             "Downtrend: demand destruction confirmed"),
  check.names = FALSE, stringsAsFactors = FALSE
)

# ---- AlgoDynamiX build-vs-license -----------------------------------------

ad_build_vs_partner <- function(dev_cost, dev_months, annual_maint, vendor_setup, vendor_fee,
                                 vendor_months = 1, years = 3) {
  inhouse_total <- dev_cost + annual_maint * years
  vendor_total <- vendor_setup + vendor_fee * years
  list(inhouse_total = inhouse_total, vendor_total = vendor_total,
       cheaper = if (inhouse_total < vendor_total) "In-house build" else "Vendor licence",
       savings = abs(inhouse_total - vendor_total),
       inhouse_months = dev_months, vendor_months = vendor_months,
       months_faster = dev_months - vendor_months)
}

# Cumulative cost of each option over `max_years` (year 0 = upfront cost only).
ad_cumulative_costs <- function(dev_cost, annual_maint, vendor_setup, vendor_fee, max_years = 10) {
  yrs <- 0:max_years
  data.frame(Year = yrs, InHouse = dev_cost + annual_maint * yrs, Vendor = vendor_setup + vendor_fee * yrs)
}

# The horizon (in years) at which the cheaper option changes, if it ever does.
# Solves dev + maint*y = setup + fee*y. Returns list(year, before, after) where
# year is NA if the two lines never cross for y > 0.
ad_crossover <- function(dev_cost, annual_maint, vendor_setup, vendor_fee) {
  if (vendor_setup < dev_cost) {
    if (vendor_fee > annual_maint) list(year = (dev_cost - vendor_setup) / (vendor_fee - annual_maint), before = "Vendor", after = "In-house")
    else list(year = NA_real_, before = "Vendor", after = "Vendor")
  } else if (vendor_setup > dev_cost) {
    if (annual_maint > vendor_fee) list(year = (vendor_setup - dev_cost) / (annual_maint - vendor_fee), before = "In-house", after = "Vendor")
    else list(year = NA_real_, before = "In-house", after = "In-house")
  } else {
    if (vendor_fee > annual_maint) list(year = 0, before = "Equal", after = "In-house")
    else if (vendor_fee < annual_maint) list(year = 0, before = "Equal", after = "Vendor")
    else list(year = NA_real_, before = "Equal", after = "Equal")
  }
}

ra_gbp <- function(x) paste0("\u00a3", format(round(x), big.mark = ",", scientific = FALSE))

# "1 month", "2 months", "0.5 months".
ra_months <- function(n) paste0(n, if (isTRUE(abs(n) == 1)) " month" else " months")

# Shared layout helper: a short titled paragraph box used for the four
# "connection" / "opportunity" cards.
ra_card <- function(title, ..., status = "info", width = 6) {
  box(width = width, status = status, solidHeader = TRUE, title = title,
      tags$div(style = "font-size:12.5px; color:#4a5560; line-height:1.65;", ...))
}

# ===========================================================================
# Prof. Riddiough sub-tab
# ===========================================================================

research_riddiough_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ui_banner("Research and Academia", "Prof. Riddiough (University of Toronto)",
              "Real academic research on FX and currency risk premia, connected to this app's energy-commodity work where the link holds up, with the limits of each link stated."),

    fluidRow(
      box(width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE, collapsed = FALSE,
          title = "Who this is",
        tags$p(paste0(
          "Steven J. Riddiough is an Associate Professor of Finance at the University of Toronto (Rotman School of ",
          "Management / University of Toronto Scarborough). His research spans international finance, empirical asset ",
          "pricing and household finance, and has been published in the Journal of Financial Economics, the Review of ",
          "Financial Studies and the IMF Economic Review. \u201cCurrency Premia and Global Imbalances\u201d (with Pasquale Della ",
          "Corte and Lucio Sarno) won the Kepos Capital Award for Best Paper on Investments at the Western Finance ",
          "Association meeting."
        ), style = "font-size:13px; color:#4a5560; line-height:1.6; margin:0;"),
        tags$p(style = "margin:8px 0 0 0; font-size:12px;",
          tags$a(href = "https://www.rotman.utoronto.ca/the-rotman-experience/our-community/people/riddiough-steven-/", target = "_blank", "Rotman faculty page"), " \u00b7 ",
          tags$a(href = "http://www.stevenriddiough.com/research", target = "_blank", "Research page (publication list)"))
      )
    ),

    fluidRow(
      box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
          title = "Honest starting point: his research is FX, not energy or satellite data",
        tags$p(paste0(
          "Prof. Riddiough does not publish on energy commodities, satellite imagery or weather data. His work is centred ",
          "on foreign exchange risk premia. Each card below separates "
        ), tags$b("what the paper finds"), " from ", tags$b("how this app might reasonably use the idea"),
          " \u2014 the second half is this app's reading, not something the paper tests.",
          style = "font-size:12.5px; color:#7d4a00; line-height:1.65; margin:0;")
      )
    ),

    fluidRow(
      ra_card("1. Global imbalances and currency premia",
        tags$p(tags$b("The paper: "), "Della Corte, Riddiough and Sarno (2016) show that a global-imbalance risk factor, ",
               "capturing the spread in countries' external imbalances and their propensity to issue external liabilities in ",
               "foreign currency, explains the cross-section of currency excess returns. Net debtor countries offer a ",
               "risk premium because their currencies depreciate in bad times."),
        tags$p(tags$b("This app's reading: "), "CAD is often called a petrocurrency and Canada's trade balance is oil-linked, ",
               "so oil prices are a plausible input into that external-balance channel. The paper does not test oil directly.")
      ),
      ra_card("2. Hedging currency exposure",
        tags$p(tags$b("The paper: "), "Opie and Riddiough (2020) develop a method to dynamically hedge FX exposure in ",
               "international ", tags$i("equity and bond"), " portfolios, exploiting predictability in global currency factor ",
               "returns (the dollar and carry factors); it outperforms leading alternatives on their metrics."),
        tags$p(tags$b("This app's reading: "), "a non-US fund trading USD-priced WTI and gas carries FX risk on top of the ",
               "commodity risk. Applying the idea to commodity futures is an extension by analogy \u2014 the paper covers ",
               "equity and bond portfolios.")
      )
    ),
    fluidRow(
      ra_card("3. Foreign exchange volume",
        tags$p(tags$b("The paper: "), "Cespa, Gargano, Riddiough and Sarno (2022) use an over-the-counter dataset and find that ",
               "FX volume helps predict next-day currency returns. Predictability implies a stronger reversal for pairs with ",
               "abnormally ", tags$i("low"), " volume today, and comes from the part of volume unrelated to volatility, ",
               "illiquidity and order flow."),
        tags$p(tags$b("This app's reading: "), "the shared principle is that volume carries information beyond price \u2014 the ",
               "Volume Indicators tab uses it that way. The mechanisms differ though: the paper finds reversals after unusually ",
               "low volume, whereas a breakout rule looks for high volume to confirm a move.")
      ),
      ra_card("4. Business cycles and currency returns",
        tags$p(tags$b("The paper: "), "Colacito, Riddiough and Sarno (2020) find a strong link between currency excess returns ",
               "and the relative strength of the business cycle: buying currencies of strong economies and selling those of weak ",
               "economies earns high returns, mostly through spot exchange-rate predictability, and is uncorrelated with common ",
               "currency strategies."),
        tags$p(tags$b("This app's reading: "), "energy demand is also pro-cyclical, so cycle phase is a common variable across ",
               "both markets. The table below is a stylised illustration of that idea, not a result from the paper.")
      )
    ),

    fluidRow(
      box(width = 7, status = "success", solidHeader = TRUE, title = "WTI vs. USD/CAD: is there a petrocurrency link in this data?",
        radioButtons(ns("petroView"), NULL, choices = c("Over time" = "ts", "Scatter with fit" = "sc"), inline = TRUE),
        withSpinner(plotly::plotlyOutput(ns("petroChart"), height = "340px")),
        uiOutput(ns("petroStat")),
        ui_context(tags$b("Reading this: "),
          "a negative relationship means stronger oil coincides with a stronger Canadian dollar (lower USD/CAD). This is ",
          "consistent with the commodity-currency link, but it is not a test of the Della Corte et al. mechanism. Two trending ",
          "series can correlate in levels for spurious reasons, which is why the year-on-year changes are reported too. ",
          "Roughly 10 annual points of approximate data is an illustration, not a study.")
      ),
      box(width = 5, status = "success", solidHeader = TRUE, title = "Should the fund hedge its FX exposure?",
        tags$p("A deliberate simplification: FX volatility is the only risk, and hedging removes a fixed fraction of it. It is not Opie and Riddiough's dynamic method.",
               style = "font-size:11.5px; color:#6b7883;"),
        numericInput(ns("hedgeNotional"), "USD commodity exposure (\u00a3-equivalent notional)", value = 1000000, min = 0, step = 100000),
        sliderInput(ns("hedgeFxVol"), "Assumed annual USD/GBP volatility (%)", min = 2, max = 20, value = 8, step = 0.5),
        sliderInput(ns("hedgeRatio"), "Hedge ratio", min = 0, max = 1, value = 0.75, step = 0.05),
        numericInput(ns("hedgeCost"), "Annual forward hedge cost (%, carry differential)", value = 0.5, min = 0, step = 0.1),
        uiOutput(ns("hedgeResult"))
      )
    ),

    fluidRow(
      box(width = 12, status = "info", solidHeader = TRUE, title = "Hedge-ratio ladder for the inputs above",
        DT::dataTableOutput(ns("hedgeLadder")),
        ui_context("In this simplified model risk falls and cost rises in a straight line, so the cost per unit of risk removed is the same at every ratio. ",
                   "The real trade-off comes from what is hard to model here: hedge costs that vary with the carry differential, and hedges that are ",
                   "sized dynamically \u2014 which is precisely what the paper studies.")
      )
    ),

    fluidRow(
      box(width = 12, status = "primary", solidHeader = TRUE, title = "Business cycle phase: currency carry conditions vs. energy trend (stylised)",
        DT::dataTableOutput(ns("cycleTable")),
        ui_context(tags$b("Not a finding of the papers: "),
                   "the carry column reflects a widely observed market pattern (carry tends to do well when risk appetite is high and to unwind sharply when it falls), ",
                   "and the energy column is conventional Wyckoff-style cycle language. The one thing Colacito, Riddiough and Sarno (2020) establish here is ",
                   "that relative business-cycle strength predicts currency returns.")
      )
    ),

    fluidRow(
      column(12, ua_references(
        ua_ref("<b>Della Corte, P., Riddiough, S.J. and Sarno, L. (2016)</b> \u2018Currency premia and global imbalances\u2019, <i>Review of Financial Studies</i>, 29(8), pp. 2161\u20132193.",
               "https://ssrn.com/abstract=2280952"),
        ua_ref("<b>Colacito, R., Riddiough, S.J. and Sarno, L. (2020)</b> \u2018Business cycles and currency returns\u2019, <i>Journal of Financial Economics</i>, 137(3), pp. 659\u2013678.",
               "https://www.sciencedirect.com/science/article/abs/pii/S0304405X20301203"),
        ua_ref("<b>Opie, W. and Riddiough, S.J. (2020)</b> \u2018Global currency hedging with common risk factors\u2019, <i>Journal of Financial Economics</i>, 136(3), pp. 780\u2013805.",
               "https://www.sciencedirect.com/science/article/abs/pii/S0304405X19302880"),
        ua_ref("<b>Cespa, G., Gargano, A., Riddiough, S.J. and Sarno, L. (2022)</b> \u2018Foreign exchange volume\u2019, <i>Review of Financial Studies</i>, 35, pp. 2386\u20132427. (Listed on the author's research page.)",
               "http://www.stevenriddiough.com/research"),
        ua_ref("<b>Rotman School of Management (n.d.)</b> <i>Steven Riddiough: faculty profile</i>. University of Toronto.",
               "https://www.rotman.utoronto.ca/the-rotman-experience/our-community/people/riddiough-steven-/")
      ))
    )
  )
}

research_riddiough_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    output$petroChart <- plotly::renderPlotly({
      d <- ra_petro_data
      if (identical(input$petroView, "sc")) {
        st <- ra_petro_stats(d)
        xs <- seq(min(d$WTI), max(d$WTI), length.out = 50)
        fit_y <- predict(st$fit, newdata = data.frame(WTI = xs))
        plotly::plot_ly() |>
          plotly::add_trace(data = d, x = ~WTI, y = ~USDCAD, type = "scatter", mode = "markers+text", text = ~Year,
                            textposition = "top center", textfont = list(size = 9),
                            marker = list(color = "#008A82", size = 9), name = "Annual average") |>
          plotly::add_trace(x = xs, y = fit_y, type = "scatter", mode = "lines",
                            line = list(color = "#c0392b", dash = "dot"), name = "Linear fit") |>
          plotly::layout(xaxis = list(title = "WTI ($/bbl)"), yaxis = list(title = "USD/CAD"), showlegend = FALSE,
                         plot_bgcolor = "white", paper_bgcolor = "white")
      } else {
        plotly::plot_ly(d, x = ~Year, y = ~WTI, type = "scatter", mode = "lines+markers", name = "WTI ($/bbl)",
                        line = list(color = "#008A82", width = 2.5), yaxis = "y") |>
          plotly::add_trace(y = ~USDCAD, name = "USD/CAD", line = list(color = "#c0392b", width = 2.5, dash = "dot"), yaxis = "y2") |>
          plotly::layout(yaxis = list(title = "WTI ($/bbl)"), yaxis2 = list(title = "USD/CAD", overlaying = "y", side = "right"),
                         legend = list(orientation = "h", y = 1.15), plot_bgcolor = "white", paper_bgcolor = "white")
      }
    })

    output$petroStat <- renderUI({
      s <- ra_petro_stats()
      sig <- function(p) if (p < 0.05) "significant at 5%" else "not significant at 5%"
      fluidRow(
        column(6, ui_metric_tile("Correlation of levels", sprintf("%.2f", s$cor_levels),
                                 sprintf("p = %.2f, n = %d \u2014 %s", s$p_levels, s$n_levels, sig(s$p_levels)),
                                 color = if (s$p_levels < 0.05) "#1e7a46" else "#9c6b26")),
        column(6, ui_metric_tile("Correlation of yearly changes", sprintf("%.2f", s$cor_changes),
                                 sprintf("p = %.3f, n = %d \u2014 %s", s$p_changes, s$n_changes, sig(s$p_changes)),
                                 color = if (s$p_changes < 0.05) "#1e7a46" else "#9c6b26"))
      )
    })

    output$hedgeResult <- renderUI({
      req(input$hedgeNotional, input$hedgeFxVol, input$hedgeRatio, input$hedgeCost)
      r <- ra_hedge_illustration(input$hedgeNotional, input$hedgeFxVol, input$hedgeRatio, input$hedgeCost)
      tagList(
        fluidRow(
          column(6, ui_metric_tile("Unhedged FX risk (1 sd, per year)", ra_gbp(r$unhedged_vol), "illustrative")),
          column(6, ui_metric_tile("Hedged FX risk", ra_gbp(r$hedged_vol), paste0(round(r$reduction_pct), "% reduction"), color = "#1e7a46"))
        ),
        fluidRow(
          column(6, ui_metric_tile("Annual cost of hedging", ra_gbp(r$annual_cost), "the price of that reduction", color = "#9c6b26")),
          column(6, ui_metric_tile("Cost per \u00a31 of risk removed",
                                   if (is.na(r$cost_per_risk_removed)) "n/a" else paste0("\u00a3", format(round(r$cost_per_risk_removed, 3), nsmall = 3)),
                                   "annual cost divided by risk removed"))
        )
      )
    })

    output$hedgeLadder <- DT::renderDataTable({
      req(input$hedgeNotional, input$hedgeFxVol, input$hedgeCost)
      DT::datatable(ra_hedge_ladder(input$hedgeNotional, input$hedgeFxVol, input$hedgeCost),
                    rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)

    output$cycleTable <- DT::renderDataTable({
      DT::datatable(ra_business_cycle, rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)
  })
}

# ===========================================================================
# AlgoDynamiX sub-tab
# ===========================================================================

ad_flow_box <- function(label, text, color = "#002C3C", bg = "#ffffff") {
  tags$div(style = paste0("border:1.5px solid ", color, "; border-radius:4px; padding:12px 16px; background:", bg, "; margin-bottom:10px;"),
    tags$div(label, style = paste0("font-family:monospace; font-size:10.5px; font-weight:700; color:", color, "; letter-spacing:.03em; margin-bottom:4px;")),
    tags$div(text, style = "font-size:12.5px; color:#4a5560; line-height:1.5;")
  )
}
ad_flow_arrow <- function() tags$div("\u2193", style = "text-align:center; font-size:18px; color:#6b7883; margin:2px 0;")

research_algodynamix_ui <- function(id) {
  ns <- NS(id)
  tagList(
    ui_banner("Research and Academia", "AlgoDynamiX",
              "A real Cambridge-founded risk analytics company, reviewed against its own site and independent sources, connected to this app's Hedge Fund / Wealth planning."),

    fluidRow(
      box(width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE, collapsed = FALSE,
          title = "Company overview",
        tags$p(paste0(
          "AlgoDynamiX was co-founded in 2013 by Jeremy Sosabowski (CEO; engineering PhD, University of Cambridge) and Wei Teo ",
          "(a career in portfolio and counterparty risk at Goldman Sachs and Bank of America Merrill Lynch), and incorporated in ",
          "January 2014, with software based on academic research at the University of Cambridge. It has offices in Cambridge (UK) ",
          "and London, and is an Accelerate Cambridge venture listed by ",
          "Cambridge Judge Business School, which describes a team with over 30 years' software experience at Goldman Sachs, ",
          "McKinsey & Company and Bank of America Merrill Lynch. Described clients include investment banks, asset managers, CTAs, ",
          "hedge funds and family offices."
        ), style = "font-size:13px; color:#4a5560; line-height:1.65;"),
        tags$p(paste0(
          "Core technology, as the company and directory listings describe it: unsupervised machine learning that analyses the ",
          "behaviour of market participants in real-time order book data to flag anomalies, and which is described as not relying on ",
          "historical data or prior similar events. That is a different approach from this app's own indicators, which are built on ",
          "historical price bars."
        ), style = "font-size:13px; color:#4a5560; line-height:1.65; margin-bottom:0;"),
        tags$a(href = "https://www.jbs.cam.ac.uk/ventures/algodynamix/", target = "_blank", style = "font-size:12px;",
               "Cambridge Judge Business School venture page \u2192")
      )
    ),

    fluidRow(
      box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
          title = "Two honest gaps",
        tags$p(tags$b("Performance evidence. "), paste0(
          "No independent, peer-reviewed paper authored by the company's team was found. Its \u201cCambridge research\u201d framing ",
          "and its performance descriptions (for example a directory listing says it claims up to three real-time anomaly alerts a ",
          "month, with quantified metrics for up to five days afterwards) are the company's own claims, not an independently ",
          "verified track record. Client testimonials on its homepage (one says every flag so far has made money) are ",
          "likewise marketing, not evidence."
        ), style = "font-size:12.5px; color:#7d4a00; line-height:1.65; margin:0 0 8px 0;"),
        tags$p(tags$b("Energy coverage. "), paste0(
          "The RAP Platform listing describes global \u2018macro\u2019 coverage across equity indices, fixed income futures and FX futures. ",
          "A separate directory entry says the analytics cover most asset classes including commodities. For a fund scoped to WTI and ",
          "natural gas, whether energy futures are actually covered is the first thing to confirm directly."
        ), style = "font-size:12.5px; color:#7d4a00; line-height:1.65; margin:0;")
      )
    ),

    fluidRow(
      box(width = 12, status = "info", solidHeader = TRUE, title = "Products (as described by the company and listings)",
        DT::dataTableOutput(ns("productTable"))
      )
    ),

    fluidRow(
      ra_card("1. A complementary early-warning layer", status = "success",
        "Order-book anomaly detection needs no historical pattern to fire, so it could sit ahead of this app's indicator-based reads, ",
        "flagging that something unusual is happening in market microstructure before a moving average or pivot level moves. Worth ",
        "exploring as a confirming layer, not a replacement \u2014 subject to the coverage question above."
      ),
      ra_card("2. Downside protection for the fund itself", status = "success",
        "PI-X\u2122 is described as volatility risk forecasting analytics. That maps onto the risk budget in the Hedge Fund / Wealth ",
        "Financial Projections and the position-risk work in Risk & Portfolio Analytics. Whether it includes hedging guidance, rather ",
        "than forecasts alone, is a question for the vendor."
      )
    ),
    fluidRow(
      ra_card("3. Same target client, a real build-or-license question", status = "success",
        "The RAP Platform\u2122 is described as a self-service online portal needing no configuration or API integration, aimed at smaller ",
        "organisations including family offices and smaller hedge funds \u2014 the segment the Business Structure work is planning ",
        "around. That makes licensing a risk layer rather than building one a calculable option (calculator below)."
      ),
      ra_card("4. A bridge to the academic side", status = "success",
        "Order-flow behaviour as a predictor of near-term moves is methodologically adjacent to Cespa, Gargano, Riddiough and Sarno's ",
        "(2022) finding that FX volume predicts next-day currency returns (Prof. Riddiough tab). It is an adjacency of ideas, not evidence ",
        "that the vendor's specific product works."
      )
    ),

    fluidRow(
      box(width = 6, status = "primary", solidHeader = TRUE, title = "Where an anomaly flag would sit in the process",
        ad_flow_box("EXTERNAL SIGNAL", "Vendor anomaly flag fires (described as hours to days ahead of a move, independent of historical pattern).", color = "#8e44ad"),
        ad_flow_arrow(),
        ad_flow_box("STEP 1 \u00b7 existing", "Trend and volatility read: Moving Averages, Volatility Analysis.", color = "#002C3C"),
        ad_flow_arrow(),
        ad_flow_box("STEP 2 \u00b7 existing", "Signal check on the flagged instrument: Pivot Points, Momentum & ROC, Volume Indicators.", color = "#002C3C"),
        ad_flow_arrow(),
        ad_flow_box("STEP 3 \u00b7 existing", "Size the position against a fixed risk-percentage rule (Risk Metrics); consider a hedge (Hedge Ratio Calculator).", color = "#1e7a46", bg = "#f0f9f4")
      ),
      box(width = 6, status = "primary", solidHeader = TRUE, title = "Build our own layer, or license theirs?",
        numericInput(ns("adInhouseCost"), "In-house build cost (\u00a3, one-off)", value = 80000, min = 0, step = 5000),
        sliderInput(ns("adInhouseMonths"), "In-house build time (months)", min = 1, max = 24, value = 9),
        numericInput(ns("adInhouseMaint"), "In-house annual maintenance (\u00a3)", value = 40000, min = 0, step = 5000),
        numericInput(ns("adVendorSetup"), "Vendor setup cost (\u00a3, one-off)", value = 5000, min = 0, step = 1000),
        numericInput(ns("adVendorFee"), "Vendor annual licence fee (\u00a3)", value = 30000, min = 0, step = 1000),
        sliderInput(ns("adVendorMonths"), "Vendor time to go live (months)", min = 0, max = 6, value = 1, step = 0.5),
        sliderInput(ns("adYears"), "Comparison horizon (years)", min = 1, max = 10, value = 3),
        tags$p("Every figure here is a placeholder: the vendor's pricing is not public, and both cost estimates are guesses to replace with real quotes.",
               style = "font-size:11px; color:#6b7883;"),
        uiOutput(ns("adResult"))
      )
    ),

    fluidRow(
      box(width = 12, status = "success", solidHeader = TRUE, title = "Cumulative cost over 10 years",
        withSpinner(plotly::plotlyOutput(ns("adCostChart"), height = "300px")),
        uiOutput(ns("adCrossover")),
        ui_context(tags$b("What this leaves out: "), "it compares cost only. It assumes the in-house build would match the vendor's ",
                   "capability, which is the hard part, and it puts no value on getting to a working system sooner.")
      )
    ),

    fluidRow(
      box(width = 12, status = "info", solidHeader = TRUE, title = "Questions to put to the vendor before spending anything",
        DT::dataTableOutput(ns("adQuestions"))
      )
    ),

    fluidRow(
      column(12, ua_references(
        ua_ref("<b>AlgoDynamix (2026)</b> <i>Home</i>. AlgoDynamix Ltd. (Accessed: 27 September 2026).",
               "https://www.algodynamix.com/"),
        ua_ref("<b>Cambridge Judge Business School (2026)</b> <i>AlgoDynamix: Accelerate Cambridge venture</i>. University of Cambridge.",
               "https://www.jbs.cam.ac.uk/ventures/algodynamix/"),
        ua_ref("<b>AlgoDynamix (n.d.)</b> <i>About</i> and <i>Bespoke Services</i>. AlgoDynamix Ltd. (Founders; enterprise project examples.)",
               "https://www.algodynamix.com/about/"),
        ua_ref("<b>Cambridge Judge Business School (2020)</b> <i>Faster analytics</i>. University of Cambridge. (Founding year and founders.)",
               "https://www.jbs.cam.ac.uk/2020/faster-analytics/"),
        ua_ref("<b>The Wealth Mosaic (n.d.)</b> <i>AlgoDynamix RAP Platform\u2122</i>. Vendor listing.",
               "https://www.thewealthmosaic.com/vendors/algodynamix/rap-platformtm/"),
        ua_ref("<b>Crunchbase (n.d.)</b> <i>AlgoDynamix Ltd.: company profile</i>.",
               "https://www.crunchbase.com/organization/algodynamix-ltd"),
        ua_ref("<b>Tracxn (2026)</b> <i>AlgoDynamix: company profile</i>. (Source of the alert-frequency claim; a third-party summary of the company's own statements.)",
               "https://tracxn.com/d/companies/algodynamix/__ezmc3zXnsUPvJCblTmUE3Ye-GERAutupCWCO8E-5L3U")
      ))
    )
  )
}

research_algodynamix_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    output$productTable <- DT::renderDataTable({
      df <- data.frame(
        Product = c("ALDX PI\u2122", "PI-X\u2122", "RAP Platform\u2122", "Enterprise / bespoke services"),
        `As described` = c("Directional analytics giving advance insight into market-moving events, aimed at end-of-day allocation decisions.",
                           "Volatility risk forecasting analytics.",
                           "Self-service online portal giving hours-to-days advance warning of major downside events; no configuration or API integration.",
                           "Tailored projects. The company's examples: anomaly analytics on proprietary (OTC) datasets, robo-advisory, a turnkey \u2018hedge fund in a box\u2019, ultra-low-volatility multi-index portfolio construction, and a high-throughput GARCH and stochastic (c)VaR engine."),
        `Possible fit here` = c("A confirming layer ahead of the indicator-based reads.",
                                "Input to the fund's downside-risk budget.",
                                "Fastest realistic route to a working risk layer for a small fund.",
                                "A longer-term option once a track record justifies it. Note the \u2018hedge fund in a box\u2019 example overlaps with the business plan on the Hedge Fund / Wealth tab, so it is a build-or-partner question in itself."),
        check.names = FALSE, stringsAsFactors = FALSE
      )
      DT::datatable(df, rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)

    ad_inputs <- reactive({
      req(input$adInhouseCost, input$adInhouseMonths, input$adInhouseMaint, input$adVendorSetup, input$adVendorFee, input$adYears)
      list(dev = input$adInhouseCost, months = input$adInhouseMonths, maint = input$adInhouseMaint,
           setup = input$adVendorSetup, fee = input$adVendorFee, vmonths = input$adVendorMonths %||% 1, years = input$adYears)
    })

    output$adResult <- renderUI({
      i <- ad_inputs()
      r <- ad_build_vs_partner(i$dev, i$months, i$maint, i$setup, i$fee, i$vmonths, i$years)
      tagList(
        fluidRow(
          column(6, ui_metric_tile("In-house total cost", ra_gbp(r$inhouse_total), paste0(ra_months(r$inhouse_months), " to live"))),
          column(6, ui_metric_tile("Vendor total cost", ra_gbp(r$vendor_total), paste0(ra_months(r$vendor_months), " to live"), color = "#1e7a46"))
        ),
        ui_metric_tile("Cheaper over this horizon", r$cheaper, paste0("by ", ra_gbp(r$savings)),
                       color = if (r$cheaper == "Vendor licence") "#1e7a46" else "#002C3C"),
        ui_context(tags$b("Not just cost: "),
                   if (r$months_faster > 0) paste0("the vendor route reaches a working system about ", ra_months(r$months_faster), " sooner")
                   else if (r$months_faster < 0) paste0("the in-house route would be about ", ra_months(abs(r$months_faster)), " faster")
                   else "both routes take about the same time to go live",
                   " \u2014 relevant against the 12-month track-record clock on the Hedge Fund / Wealth tab.")
      )
    })

    output$adCostChart <- plotly::renderPlotly({
      i <- ad_inputs()
      d <- ad_cumulative_costs(i$dev, i$maint, i$setup, i$fee, 10)
      p <- plotly::plot_ly(d, x = ~Year) |>
        plotly::add_trace(y = ~InHouse, name = "In-house", type = "scatter", mode = "lines+markers", line = list(color = "#002C3C", width = 2.5)) |>
        plotly::add_trace(y = ~Vendor, name = "Vendor licence", type = "scatter", mode = "lines+markers", line = list(color = "#008A82", width = 2.5)) |>
        plotly::layout(xaxis = list(title = "Years"), yaxis = list(title = "Cumulative cost (\u00a3)"),
                       legend = list(orientation = "h", y = 1.12), plot_bgcolor = "white", paper_bgcolor = "white",
                       shapes = list(list(type = "line", x0 = i$years, x1 = i$years, y0 = 0, y1 = 1, yref = "paper",
                                          line = list(color = "#c0392b", dash = "dot", width = 1))))
      p
    })

    output$adCrossover <- renderUI({
      i <- ad_inputs()
      x <- ad_crossover(i$dev, i$maint, i$setup, i$fee)
      msg <- if (is.na(x$year)) {
        paste0("The lines never cross: ", tolower(x$after), " is cheaper at every horizon with these inputs.")
      } else if (x$year == 0) {
        paste0("From day one the ", tolower(x$after), " option is the cheaper one.")
      } else {
        paste0(x$before, " is cheaper for the first ", round(x$year, 1), " years; after that ", tolower(x$after), " becomes the cheaper option.")
      }
      ui_result_box("Crossover", msg)
    })

    output$adQuestions <- DT::renderDataTable({
      df <- data.frame(
        Topic = c("Coverage", "Evidence", "Delivery", "Cost", "Audit trail", "Exit"),
        `Ask the vendor` = c("Are WTI, Brent and natural gas futures covered, and since when?",
                             "How were alerts validated out of sample, by whom, and can I see the full list of alerts including misses?",
                             "How is an alert delivered, with what latency, and can it be pulled into another system?",
                             "What are the setup and annual fees at this scale, and what changes as assets grow?",
                             "Are alerts timestamped and retained in a form usable in a regulatory audit trail?",
                             "What are the terms to leave, and who owns the data I generate?"),
        check.names = FALSE, stringsAsFactors = FALSE
      )
      DT::datatable(df, rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)
  })
}
