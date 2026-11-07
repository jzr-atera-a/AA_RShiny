# modules/research_academia.R
#
# "Research and Academia > Prof. Riddiough (U of T)" - a genuine analysis of how this
# app's work (energy commodities, currency pairs, external/alternative data, portfolio
# construction) connects to the actual published research of Steven J. Riddiough,
# Associate Professor of Finance, University of Toronto (Rotman/UTSC).
#
# HONESTY NOTE: Riddiough's own published work is centred on foreign exchange - currency
# risk premia, global imbalances, currency hedging and FX volume - not on energy
# commodities, satellite data or weather data specifically. This tab does not pretend
# otherwise. The three connections below are genuine and specific (the commodity-currency
# link his own "global imbalances" mechanism explains, the practical FX-hedging question
# any USD-priced-commodity fund actually faces, and a direct methodological parallel
# between his FX-volume finding and this app's own use of volume as a reinforcing
# indicator), not a forced topical match.

# ===========================================================================
# PURE LOGIC
# ===========================================================================

# Illustrative annual-average petrocurrency data (WTI vs USD/CAD), consistent with
# well-documented public price history (2014-16 oil crash, 2020 COVID crash, 2022 spike).
# Approximate annual averages, not exact settlement data - same "illustrative but
# directionally real" methodology used for the WTI 2011-2016 chart elsewhere in this app.
ra_petro_data <- data.frame(
  Year = 2014:2024,
  WTI = c(93, 49, 43, 51, 65, 57, 39, 68, 95, 78, 76),
  USDCAD = c(1.10, 1.28, 1.33, 1.30, 1.30, 1.33, 1.34, 1.25, 1.30, 1.35, 1.37)
)

ra_hedge_illustration <- function(notional_usd, home_ccy_vol_pct, hedge_ratio, forward_points_cost_pct) {
  unhedged_vol <- notional_usd * (home_ccy_vol_pct / 100)
  hedged_vol <- unhedged_vol * (1 - hedge_ratio)
  hedge_cost <- notional_usd * hedge_ratio * (forward_points_cost_pct / 100)
  list(unhedged_vol = unhedged_vol, hedged_vol = hedged_vol,
       variance_reduction_pct = (1 - hedged_vol / unhedged_vol) * 100,
       annual_hedge_cost = hedge_cost)
}

ra_business_cycle <- data.frame(
  Phase = c("Early expansion", "Late expansion", "Slowdown / peak", "Recession / trough"),
  Typical_Currency_Carry = c("Positive - risk appetite supports high-yielders", "Positive but fragile - crowded positioning",
                              "Negative - carry unwinds as risk appetite falls", "Negative - flight to safe-haven funding currencies"),
  Typical_Energy_Trend = c("Building - demand recovery not yet priced", "Strong uptrend - demand growth confirmed",
                            "Topping - demand growth decelerating first", "Downtrend - demand destruction confirmed"),
  Riddiough_Link = c("Colacito, Riddiough and Sarno (2020): currency returns track the global business cycle",
                     "Colacito, Riddiough and Sarno (2020): high-carry currencies most exposed to cycle risk",
                     "Della Corte, Riddiough and Sarno (2016): imbalance risk repricing begins here",
                     "Della Corte, Riddiough and Sarno (2016): net-debtor currency premia peak"),
  stringsAsFactors = FALSE
)

# ===========================================================================
# UI HELPERS (reuses u3_context / u3_metric_tile / de_ref-style pattern)
# ===========================================================================

ra_ref <- function(text) {
  tags$li(HTML(text), style = "font-size:11.5px; color:#4a5560; line-height:1.6; margin-bottom:6px;")
}

# ===========================================================================
# UI
# ===========================================================================

research_academia_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE, collapsed = FALSE,
          title = "Prof. Steven J. Riddiough \u2014 Associate Professor of Finance, University of Toronto",
        tags$p(paste0(
          "Rotman School of Management / University of Toronto Scarborough. Research spans international ",
          "finance, empirical asset pricing and household finance, with a specific focus on what drives currency ",
          "risk premia \u2014 published in the Journal of Financial Economics and the Review of Financial Studies. ",
          "Winner of the Kepos Capital Award for Best Paper on Investments (Western Finance Association)."
        ), style = "font-size:13px; color:#4a5560; line-height:1.6; margin:0;"),
        tags$a(href = "https://discover.research.utoronto.ca/11359-steven-j-riddiough/publications", target = "_blank",
               "Full publication list \u2192", style = "font-size:12px;")
      )
    ),

    fluidRow(
      box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
          title = "Honest starting point: his research is FX, not energy or satellite data",
        tags$p(paste0(
          "Prof. Riddiough does not publish on energy commodities, satellite imagery or weather data. His work is ",
          "centred on foreign exchange risk premia. The three connections below are genuine and specific, not a ",
          "forced topical match: (1) the commodity-currency link his own global-imbalances mechanism explains, ",
          "(2) the practical FX-hedging question any fund trading USD-priced commodities from a non-USD base ",
          "actually faces, and (3) a direct methodological parallel between his FX-volume finding and this app's ",
          "own use of volume as a reinforcing indicator (Unit 2, Task 3ii)."
        ), style = "font-size:12.5px; color:#7d4a00; line-height:1.65; margin:0;")
      )
    ),

    fluidRow(
      box(width = 6, status = "info", solidHeader = TRUE, title = "1. Commodity currencies & global imbalances",
        tags$p(paste0(
          "Della Corte, Riddiough and Sarno (2016) show a country's external imbalance (trade + capital account) ",
          "explains cross-sectional currency risk premia \u2014 net debtor currencies pay a premium because they ",
          "depreciate in bad times. CAD is a textbook case: Canada's trade balance is heavily oil-linked, so a WTI ",
          "move is, mechanically, an input into the exact imbalance channel their model prices."
        ), style = "font-size:12px; color:#4a5560; line-height:1.6;")
      ),
      box(width = 6, status = "info", solidHeader = TRUE, title = "2. Currency hedging for the fund itself",
        tags$p(paste0(
          "Opie and Riddiough (2020) study how to hedge FX exposure using common risk factors rather than a naive ",
          "1:1 hedge. Directly actionable: the Hedge Fund / Wealth tab's WTI and Natural Gas strategies are priced ",
          "in USD \u2014 a non-US-based fund carries FX exposure on top of the commodity exposure, and this is the ",
          "academic basis for hedging it properly rather than ignoring it."
        ), style = "font-size:12px; color:#4a5560; line-height:1.6;")
      )
    ),
    fluidRow(
      box(width = 6, status = "info", solidHeader = TRUE, title = "3. Volume as a predictive signal",
        tags$p(paste0(
          "Cespa, Gargano, Riddiough and Sarno (2022) find FX trading volume genuinely predicts next-day currency ",
          "returns using a novel OTC dataset. This is the same underlying principle already used in this app's own ",
          "Unit 2, Task 3(ii) reinforcing indicators (volume confirming a pattern breakout) \u2014 his paper is ",
          "academic evidence that the same logic holds in a completely different market (FX, not equities/energy)."
        ), style = "font-size:12px; color:#4a5560; line-height:1.6;")
      ),
      box(width = 6, status = "info", solidHeader = TRUE, title = "4. Business cycles and currency returns",
        tags$p(paste0(
          "Colacito, Riddiough and Sarno (2020) show currency returns track the global business cycle in a ",
          "predictable way. Energy commodity demand is famously pro-cyclical too \u2014 the interactive table below ",
          "lines up his currency-carry cycle phases against typical energy trend behaviour in the same phase."
        ), style = "font-size:12px; color:#4a5560; line-height:1.6;")
      )
    ),

    fluidRow(
      box(width = 7, status = "success", solidHeader = TRUE, title = "Interactive: WTI vs. USD/CAD, the petrocurrency link",
        withSpinner(plotlyOutput(ns("petroChart"), height = "340px")),
        uiOutput(ns("petroStat")),
        u3_context(style = "margin-top:10px;", tags$b("Reading this: "), "a negative correlation here is exactly what ",
                   "Della Corte, Riddiough and Sarno's (2016) global-imbalances mechanism predicts \u2014 stronger oil ",
                   "improves Canada's external balance, which their model links directly to a lower currency risk premium ",
                   "on CAD (i.e. a stronger, lower USD/CAD).")
      ),
      box(width = 5, status = "success", solidHeader = TRUE, title = "Interactive: should the fund hedge its FX exposure?",
        tags$p("Operationalises Opie and Riddiough (2020) for this fund's own USD-priced energy positions.", style="font-size:11.5px; color:#8a97a0;"),
        numericInput(ns("hedgeNotional"), "USD commodity exposure (\u00a3-equivalent notional)", value = 1000000, min = 0, step = 100000),
        sliderInput(ns("hedgeFxVol"), "Assumed annual USD/GBP volatility (%)", min = 2, max = 20, value = 8, step = 0.5),
        sliderInput(ns("hedgeRatio"), "Hedge ratio", min = 0, max = 1, value = 0.75, step = 0.05),
        numericInput(ns("hedgeCost"), "Annual forward hedge cost (%, carry differential)", value = 0.5, min = 0, step = 0.1),
        uiOutput(ns("hedgeResult"))
      )
    ),

    fluidRow(
      box(width = 12, status = "primary", solidHeader = TRUE, title = "Interactive: business cycle phase \u2014 currency carry vs. energy trend",
        DT::dataTableOutput(ns("cycleTable")),
        u3_context(style="margin-top:10px;", "Cross-references the Wyckoff/economic-cycle table already built for Unit 2, ",
                   "Task 2 \u2014 the same underlying idea (the market leads the cycle) applies to both asset classes, just ",
                   "through different risk premia.")
      )
    ),

    fluidRow(
      box(width = 12, status = NULL, solidHeader = FALSE, title = "References",
        tags$ul(style="padding-left:18px; margin:0;",
          ra_ref("Della Corte, P., Riddiough, S.J. and Sarno, L. (2016) \u2018Currency Premia and Global Imbalances\u2019, <i>Review of Financial Studies</i>, 29(8), pp. 2161\u20132193. <a href='https://doi.org/10.1093/rfs/hhw038' target='_blank'>https://doi.org/10.1093/rfs/hhw038</a>"),
          ra_ref("Colacito, R., Riddiough, S.J. and Sarno, L. (2020) \u2018Business Cycles and Currency Returns\u2019, <i>Journal of Financial Economics</i>, 137(3), pp. 659\u2013678. <a href='https://doi.org/10.1016/j.jfineco.2020.03.001' target='_blank'>https://doi.org/10.1016/j.jfineco.2020.03.001</a>"),
          ra_ref("Opie, W. and Riddiough, S.J. (2020) \u2018Global Currency Hedging with Common Risk Factors\u2019, <i>Journal of Financial Economics</i>, 136(3), pp. 780\u2013805. <a href='https://doi.org/10.1016/j.jfineco.2019.11.006' target='_blank'>https://doi.org/10.1016/j.jfineco.2019.11.006</a>"),
          ra_ref("Cespa, G., Gargano, A., Riddiough, S.J. and Sarno, L. (2022) \u2018Foreign Exchange Volume\u2019, <i>Review of Financial Studies</i>, 35(5), pp. 2386\u20132427. <a href='https://doi.org/10.1093/rfs/hhab082' target='_blank'>https://doi.org/10.1093/rfs/hhab082</a>")
        )
      )
    )
  )
}

# ===========================================================================
# SERVER
# ===========================================================================

research_academia_server <- function(id, data_manager = NULL) {
  moduleServer(id, function(input, output, session) {

    output$petroChart <- renderPlotly({
      d <- ra_petro_data
      plot_ly(d, x = ~Year, y = ~WTI, type = "scatter", mode = "lines+markers", name = "WTI ($/bbl)",
              line = list(color = "#008A82", width = 2.5), yaxis = "y") %>%
        add_trace(y = ~USDCAD, name = "USD/CAD", line = list(color = "#c0392b", width = 2.5, dash="dot"), yaxis = "y2") %>%
        layout(yaxis = list(title = "WTI ($/bbl)"), yaxis2 = list(title = "USD/CAD", overlaying = "y", side = "right"),
               legend = list(orientation = "h", y = 1.15), plot_bgcolor = "white", paper_bgcolor = "white")
    })

    output$petroStat <- renderUI({
      d <- ra_petro_data
      r <- cor(d$WTI, d$USDCAD)
      u3_metric_tile("Correlation, WTI vs USD/CAD (2014\u20132024)", round(r, 3),
                     "negative confirms the petrocurrency link", color = if (r < 0) "#1e7a46" else "#c0392b")
    })

    output$hedgeResult <- renderUI({
      req(input$hedgeNotional, input$hedgeFxVol, input$hedgeRatio, input$hedgeCost)
      r <- ra_hedge_illustration(input$hedgeNotional, input$hedgeFxVol, input$hedgeRatio, input$hedgeCost)
      tagList(
        fluidRow(
          column(6, u3_metric_tile("Unhedged FX volatility (\u00a3/yr)", paste0("\u00a3", format(round(r$unhedged_vol), big.mark=",")), "1 std. dev. illustrative")),
          column(6, u3_metric_tile("Hedged FX volatility (\u00a3/yr)", paste0("\u00a3", format(round(r$hedged_vol), big.mark=",")), paste0(round(r$variance_reduction_pct), "% reduction"), color="#1e7a46"))
        ),
        tags$div(style="margin-top:8px;", u3_metric_tile("Annual cost of hedging", paste0("\u00a3", format(round(r$annual_hedge_cost), big.mark=",")), "the price of that volatility reduction", color="#9c6b26"))
      )
    })

    output$cycleTable <- DT::renderDataTable({
      df <- ra_business_cycle
      names(df) <- c("Business Cycle Phase", "Typical Currency Carry Return", "Typical Energy Trend", "Riddiough Link")
      DT::datatable(df, rownames = FALSE, options = list(dom = 't', paging = FALSE))
    }, server = FALSE)

  })
}

# ===========================================================================
# SUB-TAB 2: "AlgoDynamiX - Research & Commercial Opportunities"
# ===========================================================================
#
# Reviewed algodynamix.com directly (Home, Our Technology, FAQ pages), plus
# independent third-party sources: Cambridge Judge Business School's own Ventures
# page (confirms the Accelerate Cambridge affiliation and team background - Goldman
# Sachs, McKinsey, Bank of America Merrill Lynch), Crunchbase, and CTMfile. No
# independent, peer-reviewed academic paper authored by AlgoDynamiX's own team was
# found publicly - their "Cambridge research" claim is their own, not independently
# verified here, and that gap is stated plainly rather than glossed over.

ad_build_vs_partner <- function(inhouse_dev_cost, inhouse_dev_months, inhouse_annual_maint,
                                  vendor_setup_cost, vendor_annual_fee, years = 3) {
  inhouse_total <- inhouse_dev_cost + inhouse_annual_maint * years
  vendor_total <- vendor_setup_cost + vendor_annual_fee * years
  list(inhouse_total = inhouse_total, vendor_total = vendor_total,
       cheaper = if (inhouse_total < vendor_total) "In-house build" else "Vendor (AlgoDynamiX)",
       savings = abs(inhouse_total - vendor_total),
       inhouse_months = inhouse_dev_months, vendor_months = 1)
}

ad_flow_box <- function(label, text, color = "#002C3C", bg = "#fff") {
  tags$div(style = paste0("border:1.5px solid ", color, "; border-radius:4px; padding:12px 16px; ",
                           "background:", bg, "; margin-bottom:10px;"),
    tags$div(label, style = paste0("font-family:monospace; font-size:10.5px; font-weight:700; ",
                                    "color:", color, "; letter-spacing:.03em; margin-bottom:4px;")),
    tags$div(text, style = "font-size:12.5px; color:#4a5560; line-height:1.5;")
  )
}
ad_flow_arrow <- function() tags$div("\u2193", style = "text-align:center; font-size:18px; color:#8a97a0; margin:2px 0;")

algodynamix_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE, collapsed = FALSE,
          title = "AlgoDynamiX \u2014 Company Overview (verified against algodynamix.com and independent sources)",
        tags$p(paste0(
          "Founded 2013 (incorporated 2014) by Jeremy Sosabowski and Wei Yin Teo. Offices in Cambridge (UK) and ",
          "London; a Cambridge Judge Business School venture supported by the Accelerate Cambridge programme, ",
          "which independently confirms the team's background includes 30+ years of software development at ",
          "Goldman Sachs, McKinsey & Company and Bank of America Merrill Lynch. Clients include investment banks, ",
          "asset managers, CTAs, hedge funds and family offices."
        ), style = "font-size:13px; color:#4a5560; line-height:1.65;"),
        tags$p(paste0(
          "Core technology: agent-based, unsupervised machine learning that clusters market participants by ",
          "real-time order book behaviour, explicitly designed to need no historical data or prior similar events ",
          "- a genuinely different approach to this app's own regime/pattern engine, which is built entirely on ",
          "historical OHLC bars (ADX, moving averages, pivot points)."
        ), style = "font-size:13px; color:#4a5560; line-height:1.65; margin-bottom:0;")
      )
    ),

    fluidRow(
      box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
          title = "One honest gap",
        tags$p(paste0(
          "No independent, peer-reviewed academic paper authored by AlgoDynamiX's own team was found publicly. ",
          "Their \u2018Cambridge research\u2019 pedigree and performance claims (e.g. \u2018up to 15 Flag pairs a ",
          "year\u2019) come from their own marketing material and a Cambridge Judge Business School venture ",
          "listing, not an independently verified track record - worth confirming directly with them before ",
          "treating any specific performance number as established."
        ), style = "font-size:12.5px; color:#7d4a00; line-height:1.65; margin:0;")
      )
    ),

    fluidRow(
      box(width = 12, status = "info", solidHeader = TRUE, title = "Product line (from algodynamix.com/our-technology)",
        DT::dataTableOutput(ns("productTable"))
      )
    ),

    fluidRow(
      box(width = 6, status = "success", solidHeader = TRUE, title = "1. A complementary early-warning layer",
        tags$p(paste0(
          "Their order-book anomaly detection needs no historical pattern to fire, so it could sit as a Step 0 ",
          "check ahead of this app's own regime engine \u2014 flagging that something unusual is happening in the ",
          "market microstructure before ADX or a pivot level ever moves. Worth exploring as a confirming layer, ",
          "not a replacement, for the Unit 3 Live Signals cards."
        ), style = "font-size:12px; color:#4a5560; line-height:1.6;")
      ),
      box(width = 6, status = "success", solidHeader = TRUE, title = "2. Downside hedging for the fund itself",
        tags$p(paste0(
          "PI-X\u2122 is specifically a directional volatility/downside-protection tool built around put-option ",
          "hedging. This maps directly onto the Trade Management rules in the Unit 3 plan and the risk budget in ",
          "the Hedge Fund tab's Financial Projections \u2014 a genuine candidate for the actual downside-protection ",
          "mechanism a real fund would need, rather than building one from scratch."
        ), style = "font-size:12px; color:#4a5560; line-height:1.6;")
      )
    ),
    fluidRow(
      box(width = 6, status = "success", solidHeader = TRUE, title = "3. Same target client, real build-vs-partner question",
        tags$p(paste0(
          "Their RAP Platform\u2122 is explicitly built for smaller organisations \u2014 family offices and smaller ",
          "hedge funds \u2014 with no API/integration needed. That is the exact client segment the Hedge Fund / ",
          "Wealth tab's Business Structure work is planning around, which makes licensing their risk layer, ",
          "rather than building an equivalent in-house, a genuine, calculable option (see the calculator below)."
        ), style = "font-size:12px; color:#4a5560; line-height:1.6;")
      ),
      box(width = 6, status = "success", solidHeader = TRUE, title = "4. A bridge back to the academic side",
        tags$p(paste0(
          "Their approach (real-time order-flow behaviour predicting near-term price moves) is methodologically ",
          "adjacent to Cespa, Gargano, Riddiough and Sarno's (2022) finding that FX volume predicts next-day ",
          "currency returns, on the Prof. Riddiough sub-tab \u2014 a genuine, specific link between a commercial ",
          "product and a peer-reviewed academic result, not just two unrelated ideas sitting side by side."
        ), style = "font-size:12px; color:#4a5560; line-height:1.6;")
      )
    ),

    fluidRow(
      box(width = 6, status = "primary", solidHeader = TRUE, title = "Interactive: where an anomaly flag would sit in our process",
        ad_flow_box("EXTERNAL SIGNAL", "AlgoDynamiX order-book anomaly flag fires (hours to days ahead of a move, independent of historical pattern).", color = "#8e44ad"),
        ad_flow_arrow(),
        ad_flow_box("STEP 1 (existing)", "Unit 3 Live Signals regime read: ADX confirms trending or range-bound.", color = "#002C3C"),
        ad_flow_arrow(),
        ad_flow_box("STEP 2 (existing)", "Holy Grail / Pivot Point Bounce / Straddle trigger checked against the flagged instrument specifically.", color = "#002C3C"),
        ad_flow_arrow(),
        ad_flow_box("STEP 3 (existing)", "Position sized per the fixed 1-2% risk rule; PI-X-style put hedge considered for the downside leg.", color = "#1e7a46", bg = "#f0f9f4")
      ),
      box(width = 6, status = "primary", solidHeader = TRUE, title = "Interactive: build our own layer, or license theirs?",
        numericInput(ns("adInhouseCost"), "In-house build cost (\u00a3, one-off)", value = 80000, min = 0, step = 5000),
        sliderInput(ns("adInhouseMonths"), "In-house build time (months)", min = 1, max = 18, value = 9),
        numericInput(ns("adInhouseMaint"), "In-house annual maintenance (\u00a3)", value = 40000, min = 0, step = 5000),
        numericInput(ns("adVendorSetup"), "Vendor setup cost (\u00a3, one-off)", value = 5000, min = 0, step = 1000),
        numericInput(ns("adVendorFee"), "Vendor annual licence fee (\u00a3)", value = 30000, min = 0, step = 1000),
        sliderInput(ns("adYears"), "Comparison horizon (years)", min = 1, max = 5, value = 3),
        uiOutput(ns("adResult"))
      )
    ),

    fluidRow(
      box(width = 12, status = NULL, solidHeader = FALSE, title = "References",
        tags$ul(style="padding-left:18px; margin:0;",
          ra_ref("AlgoDynamiX (2026) <i>Home</i>. Available at: <a href='https://www.algodynamix.com/' target='_blank'>https://www.algodynamix.com/</a>"),
          ra_ref("AlgoDynamiX (2026) <i>Our Technology</i>. Available at: <a href='https://www.algodynamix.com/our-technology/' target='_blank'>https://www.algodynamix.com/our-technology/</a>"),
          ra_ref("AlgoDynamiX (2026) <i>Frequently Asked Questions</i>. Available at: <a href='https://www.algodynamix.com/frequently-asked-questions/' target='_blank'>https://www.algodynamix.com/frequently-asked-questions/</a>"),
          ra_ref("Cambridge Judge Business School, University of Cambridge (2026) <i>AlgoDynamiX \u2014 Ventures</i>. Available at: <a href='https://www.jbs.cam.ac.uk/ventures/algodynamix/' target='_blank'>https://www.jbs.cam.ac.uk/ventures/algodynamix/</a>")
        )
      )
    )
  )
}

algodynamix_server <- function(id, data_manager = NULL) {
  moduleServer(id, function(input, output, session) {

    output$productTable <- DT::renderDataTable({
      df <- data.frame(
        Product = c("ALDX PI\u2122", "PI-X\u2122", "RAP Platform\u2122", "Enterprise Solutions"),
        Purpose = c("Flagship directional forecasting \u2014 advance warning of major directional market moves.",
                    "Volatility/downside risk forecasting with put-option-based portfolio hedging.",
                    "Self-service, no-integration deployment aimed at smaller organisations.",
                    "Bespoke projects: proprietary OTC anomaly analytics, robo-advisory, \u2018hedge fund in a box\u2019, GARCH/VaR engines."),
        Best_Fit_Here = c("Confirming layer ahead of the Unit 3 regime/pattern signals.",
                          "The fund's actual downside-hedging mechanism (Hedge Fund tab).",
                          "Fastest realistic route to a working risk layer for a small fund.",
                          "Longer-term partnership once the track record justifies it."),
        stringsAsFactors = FALSE
      )
      names(df) <- c("Product", "Purpose", "Best fit here")
      DT::datatable(df, rownames = FALSE, options = list(dom = 't', paging = FALSE))
    }, server = FALSE)

    output$adResult <- renderUI({
      req(input$adInhouseCost, input$adInhouseMonths, input$adInhouseMaint,
          input$adVendorSetup, input$adVendorFee, input$adYears)
      r <- ad_build_vs_partner(input$adInhouseCost, input$adInhouseMonths, input$adInhouseMaint,
                                 input$adVendorSetup, input$adVendorFee, input$adYears)
      tagList(
        fluidRow(
          column(6, u3_metric_tile("In-house total cost", paste0("\u00a3", format(r$inhouse_total, big.mark=",")),
                                    paste0(r$inhouse_months, " months to live"))),
          column(6, u3_metric_tile("Vendor total cost", paste0("\u00a3", format(r$vendor_total, big.mark=",")),
                                    paste0(r$vendor_months, " month to live"), color = "#1e7a46"))
        ),
        tags$div(style="margin-top:8px;",
          u3_metric_tile("Cheaper option over this horizon", r$cheaper,
                         paste0("by \u00a3", format(r$savings, big.mark=",")),
                         color = if (r$cheaper == "Vendor (AlgoDynamiX)") "#1e7a46" else "#002C3C")
        ),
        u3_context(style="margin-top:10px;", tags$b("Not just cost: "), "the vendor route is also ~", r$inhouse_months - r$vendor_months,
                   " months faster to a working system \u2014 relevant given the Hedge Fund tab's own 12-month track-record clock.")
      )
    })

  })
}
