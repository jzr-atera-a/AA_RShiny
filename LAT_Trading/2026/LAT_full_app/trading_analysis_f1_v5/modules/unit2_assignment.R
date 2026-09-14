# modules/unit2_assignment.R
# Unit 2: Financial Market Trading Theory — model answer covering all 4 assignment
# tasks (trading psychology, bull/bear cycle, price pattern analysis, trading
# strategies). Deliberately reuses the app's EXISTING generator functions wherever the
# task maps onto a Step tab, rather than re-deriving new charts: w4_market_cycle() for
# the Wyckoff cycle, w2_triangle()/w2_hs() for price patterns, w6_pivot_bounce(),
# w6_morning_straddle(), w6_news_straddle() and w6_holy_grail() for Task 4's strategies.

# ══════════════════════════════════════════════════════════════════════════
# TASK 1 CHART — Prospect Theory value function (Kahneman & Tversky, 1979)
# A genuine mathematical plot, not a candlestick chart: v(x) = x^a for gains,
# v(x) = -lambda*(-x)^b for losses, the standard prospect-theory value function.
# ══════════════════════════════════════════════════════════════════════════

u2_prospect_theory_chart <- function() {
  a <- 0.88; b <- 0.88; lambda <- 2.25  # Kahneman & Tversky's (1992) fitted parameters
  x <- seq(-10, 10, length.out = 400)
  v <- ifelse(x >= 0, x^a, -lambda * (-x)^b)
  plot_ly(x = x, y = v, type = "scatter", mode = "lines", line = list(color = "#008A82", width = 3)) %>%
    layout(
      title = list(text = "Prospect Theory Value Function (Kahneman &amp; Tversky, 1979)", font = list(size = 13)),
      xaxis = list(title = "Gain / Loss Relative to Reference Point", zeroline = TRUE),
      yaxis = list(title = "Subjective Value v(x)", zeroline = TRUE),
      shapes = list(
        list(type = "line", x0 = -10, x1 = 10, y0 = 0, y1 = 0, line = list(color = "#bdc3c7", width = 1)),
        list(type = "line", x0 = 0, x1 = 0, y0 = min(v), y1 = max(v), line = list(color = "#bdc3c7", width = 1))
      ),
      annotations = list(
        list(x = 6, y = 5, text = "Gains: concave\n(risk-averse)", showarrow = FALSE, font = list(size = 10, color = "#27ae60")),
        list(x = -6, y = -14, text = "Losses: convex &amp; steeper\n(risk-seeking, loss aversion)", showarrow = FALSE, font = list(size = 10, color = "#e74c3c"))
      ),
      plot_bgcolor = "white", paper_bgcolor = "white", margin = list(t = 40)
    )
}

# ══════════════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════════════

unit2_assignment_ui <- function(id) {
  ns <- NS(id)

  bias_table <- data.frame(
    Bias = c("Loss Aversion", "Overconfidence", "Disposition Effect", "Herding / Confirmation Bias"),
    Definition = c(
      "Losses are felt roughly twice as intensely as equivalent gains (Kahneman and Tversky, 1979).",
      "Traders systematically overestimate the accuracy of their own predictions and abilities.",
      "The tendency to sell winning positions too early and hold losing positions too long (Shefrin and Statman, 1985).",
      "Following the crowd's positioning, and selectively seeking information that confirms an existing view."
    ),
    `Effect on Trading Behaviour` = c(
      "Holding losing trades far past the original stop-loss level, hoping to \u201cavoid\u201d realising the loss.",
      "Excessive trade frequency, oversized positions, and under-diversification (Barber and Odean, 2000).",
      "A skewed distribution of outcomes \u2014 many small realised gains offset by a few large unrealised losses.",
      "Chasing extended trends late (herding) or ignoring technical signals that contradict a held bias (confirmation)."
    ), check.names = FALSE
  )

  phase_table <- data.frame(
    Phase = c("Accumulation", "Mark-Up (Bull)", "Distribution", "Mark-Down (Bear)"),
    `Retail Trader Behaviour` = c(
      "Largely absent or fearful after the preceding decline; sentiment surveys remain negative.",
      "Enters progressively as the trend becomes obvious, often heaviest buying occurs late in the phase.",
      "Continues buying \u201cthe dip,\u201d interpreting the sideways range as a pause rather than distribution.",
      "Sells in panic near the lows, crystallising losses after the bulk of the decline has occurred."
    ),
    `Professional / Institutional Behaviour` = c(
      "Accumulates a position quietly while price is range-bound and unattractive to retail flow.",
      "Holds the core position built in accumulation, adding on shallow pullbacks.",
      "Distributes (sells) the position into retail-driven strength, without visibly crashing the price.",
      "Remains in cash or short exposure, re-engaging only once a new accumulation range forms."
    ), check.names = FALSE
  )

  indicator_table <- data.frame(
    Indicator = c("Trading Volume", "Relative Strength Index (RSI)", "Moving Averages"),
    `How It Reinforces Price Pattern Analysis` = c(
      "A pattern breakout on rising volume is considered far more reliable than one on thin volume, since volume reflects the conviction behind the move.",
      "Bullish/bearish divergence between RSI and price during pattern formation (e.g. price makes a lower low but RSI makes a higher low) strengthens a reversal-pattern signal.",
      "A pattern breakout that coincides with price crossing above/below a key moving average (e.g. the 50- or 200-period) adds a second, independent trend-confirmation layer."
    ), check.names = FALSE
  )

  tagList(
    ua_intro("Unit 2", "Financial Market Trading Theory", "30%", "3,150\u20133,850 words (excl. references)",
             "Assess how psychology affects trader behaviour and examine how technical analysis can be used to identify trading opportunities."),

    ua_task(1, "Causes &amp; Effects of Psychological Bias on Trading Behaviour", 20,
      tags$p(paste0(
        "Behavioural finance emerged to explain the systematic, predictable ways in which real investors deviate from ",
        "the purely rational \u201cHomo economicus\u201d assumed by classical finance theory. Its foundation is Prospect Theory ",
        "(Kahneman and Tversky, 1979), which showed experimentally that people evaluate outcomes relative to a reference ",
        "point rather than in absolute terms, and that the pain of a loss is felt roughly twice as strongly as the ",
        "pleasure of an equivalent gain \u2014 a phenomenon called loss aversion."
      )),
      withSpinner(plotlyOutput(ns("prospectChart"), height = "340px")),
      tags$p(class = "ua-task-body", style = "font-size:12px; margin-top:6px;", paste0(
        "The value function is concave for gains (diminishing sensitivity produces risk-averse behaviour when ahead) ",
        "but convex and steeper for losses (producing risk-seeking behaviour when behind) \u2014 which is precisely why ",
        "traders so often cut winning trades early and let losing trades run, the opposite of a sound risk/reward rule."
      )),
      tags$h5("Four biases with a direct effect on trading behaviour"),
      ua_table(bias_table)
    ),

    ua_task(2, "The Bull/Bear Stock Market Cycle", 20,
      tags$p(paste0(
        "The most widely used framework for the stock market cycle is the Wyckoff Method, developed by Richard D. ",
        "Wyckoff in the early twentieth century (Wyckoff Analytics, n.d.). It describes four repeating phases driven by ",
        "the behaviour of large (\u201csmart money\u201d) operators relative to the retail crowd: Accumulation, Mark-Up, ",
        "Distribution and Mark-Down (CMC Markets, 2026)."
      )),
      withSpinner(plotlyOutput(ns("cycleChart"), height = "360px")),
      tags$h5("Retail vs professional behaviour through the cycle"),
      ua_table(phase_table),
      tags$h5("Relationship to the economic cycle"),
      tags$p(paste0(
        "The stock market cycle typically leads the underlying economic (business) cycle by several months, because ",
        "equity prices are forward-looking and discount expected future earnings rather than reporting current ",
        "conditions. Mark-up phases commonly begin while economic data still looks weak (anticipating recovery), and ",
        "distribution phases often begin while headline economic data still looks strong (anticipating a slowdown) \u2014 ",
        "which is why the stock market is frequently cited as a leading economic indicator."
      ))
    ),

    ua_task(3, "Price Pattern Analysis &amp; Reinforcing Technical Indicators", 30,
      tags$p(paste0(
        "Price pattern analysis identifies recurring geometric structures in price action \u2014 continuation patterns ",
        "(flags, pennants, triangles) and reversal patterns (head &amp; shoulders, double tops/bottoms) \u2014 and uses the ",
        "pattern's own geometry to project a Measured Price Objective (MPO): typically the height of the pattern's ",
        "formation projected from the breakout point."
      )),
      fluidRow(
        column(6, withSpinner(plotlyOutput(ns("patternChart1"), height = "320px"))),
        column(6, withSpinner(plotlyOutput(ns("patternChart2"), height = "320px")))
      ),
      tags$h5("Three technical tools that reinforce price pattern analysis"),
      ua_table(indicator_table)
    ),

    ua_task(4, "Trading Strategies: Pivot Points, Straddle Trading, Holy Grail", 30,
      tags$h5("Pivot Point Trading"),
      tags$p("Pivot points are calculated from the prior session's High, Low and Close, and used as intraday support/resistance reference levels:"),
      ua_formula("Pivot Point &amp; First Support/Resistance",
                 "PP = (H + L + C) / 3", tags$br(),
                 "R1 = (2 \u00d7 PP) \u2212 L    S1 = (2 \u00d7 PP) \u2212 H"),
      withSpinner(plotlyOutput(ns("pivotChart"), height = "320px")),
      tags$p(class = "ua-task-body", style = "font-size:12px;", "A Pivot Point Bounce trade enters as price rejects S1/R1 and targets the central Pivot Point as a first objective."),

      tags$h5("Straddle Trading"),
      tags$p(paste0(
        "A straddle combines a long call and a long put at the same strike, profiting from a large move in either ",
        "direction once the move exceeds the combined premium paid. Three common variants:"
      )),
      tags$ul(
        tags$li(tags$b("Morning Straddle: "), "placed around the opening-range extremes, triggering when price breaks decisively out of the first session range."),
        tags$li(tags$b("News Straddle: "), "placed ahead of a scheduled high-impact release, aiming to capture the volatility spike regardless of direction."),
        tags$li(tags$b("Options Straddle: "), "the literal options-market implementation \u2014 buying a call and a put at the same strike and expiry.")
      ),
      fluidRow(
        column(6, withSpinner(plotlyOutput(ns("straddleMorning"), height = "300px"))),
        column(6, withSpinner(plotlyOutput(ns("straddleNews"), height = "300px")))
      ),

      tags$h5("Holy Grail Trade"),
      tags$p(paste0(
        "The Holy Grail setup (popularised by trader Linda Bradford Raschke) enters in the direction of a strong, ADX-",
        "confirmed trend once price pulls back to a rising (or falling) short-term moving average, then resumes the ",
        "primary trend \u2014 combining trend strength confirmation with a favourable, low-risk entry point on the pullback."
      )),
      withSpinner(plotlyOutput(ns("holyGrailChart"), height = "320px"))
    ),

    ua_references(
      ua_ref("<b>Kahneman, D. and Tversky, A. (1979)</b> \u2018Prospect theory: An analysis of decision under risk\u2019, <i>Econometrica</i>, 47(2), pp. 263\u2013291.",
             "https://www.jstor.org/stable/1914185"),
      ua_ref("<b>Shefrin, H. and Statman, M. (1985)</b> \u2018The disposition to sell winners too early and ride losers too long: Theory and evidence\u2019, discussed in: Persona-Trained Monte Carlo research overview.",
             "https://arxiv.org/pdf/2606.29556"),
      ua_ref("<b>Wyckoff Analytics (n.d.)</b> <i>Wyckoff Method</i>.",
             "https://www.wyckoffanalytics.com/wyckoff-method/"),
      ua_ref("<b>CMC Markets (2026)</b> <i>Wyckoff method explained: accumulation &amp; distribution</i>.",
             "https://www.cmcmarkets.com/en-gb/trading-strategy/what-is-wyckoff-method"),
      ua_ref("<b>Boston Institute of Analytics (2025)</b> <i>Behavioral Finance In 2025: How Psychology Is Driving Market Trends</i>.",
             "https://bostoninstituteofanalytics.org/blog/behavioral-finance-in-2025-how-psychology-is-driving-market-trends/"),
      ua_ref("<b>arXiv / Persona-Trained Monte Carlo research (2026)</b> Overview citing Barber and Odean (2000) on overconfidence and active-trading underperformance.",
             "https://arxiv.org/pdf/2606.29556")
    )
  )
}

unit2_assignment_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    output$prospectChart   <- renderPlotly({ u2_prospect_theory_chart() })
    output$cycleChart      <- renderPlotly({ spec_to_plotly(w4_market_cycle(701)) })
    output$patternChart1   <- renderPlotly({ spec_to_plotly(w2_triangle("symmetrical", "down", TRUE, 301)) })
    output$patternChart2   <- renderPlotly({ spec_to_plotly(w2_hs(FALSE, TRUE, 341)) })
    output$pivotChart      <- renderPlotly({ spec_to_plotly(w6_pivot_bounce(TRUE, 611)) })
    output$straddleMorning <- renderPlotly({ spec_to_plotly(w6_morning_straddle(TRUE, 601)) })
    output$straddleNews    <- renderPlotly({ spec_to_plotly(w6_news_straddle("hit_2r", 603)) })
    output$holyGrailChart  <- renderPlotly({ spec_to_plotly(w6_holy_grail(TRUE, 621)) })
    session$onSessionEnded(function() {})
  })
}
