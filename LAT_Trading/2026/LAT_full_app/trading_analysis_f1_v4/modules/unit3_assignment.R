# modules/unit3_assignment.R
# Unit 3: Practical Applications of Financial Market Trading — model answer covering all
# 3 assignment tasks. This unit is inherently personal/practical (a real 4-week trading
# plan and its real performance), so rather than fabricate a specific invented trade
# history, this tab presents the STRUCTURED FRAMEWORK and methodology a student's real
# plan should follow, reusing the app's existing Risk & Advanced Metrics concepts
# (Sortino/Sharpe/max drawdown) and an illustrative equity curve to show how the
# evaluation in Task 2/3 should be read once real trades are logged in the app's
# Trade Journal tab.

# Illustrative equity curve for a 4-week trading plan: a mix of winning and losing
# trades producing a realistic (not smoothly upward) curve, with drawdown visible —
# purely illustrative, generated from the same syn_path() primitive as every other
# chart in the app, NOT a claim about any real account's performance.
u3_equity_curve_chart <- function(seed = 9301) {
  set.seed(seed)
  df <- syn_path(28, start = 10000, drift = 25, vol = 140, seed = seed)
  df$Date <- seq(as.Date("2026-01-05"), by = "day", length.out = 28)
  peak <- cummax(df$Close)
  dd <- (df$Close - peak) / peak
  trough_idx <- which.min(dd)

  p <- plot_ly(df, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
               line = list(color = "#008A82", width = 2.5), fill = "tozeroy",
               fillcolor = "rgba(0,138,130,0.08)", name = "Account Equity") %>%
    layout(
      title = list(text = "Illustrative 4-Week Equity Curve", font = list(size = 13)),
      xaxis = list(title = ""), yaxis = list(title = "Account Equity (\u00a3)", rangemode = "tozero"),
      shapes = list(list(type = "line", x0 = df$Date[1], x1 = tail(df$Date,1),
                          y0 = df$Close[1], y1 = df$Close[1],
                          line = list(color = "#bdc3c7", width = 1, dash = "dot"))),
      annotations = list(list(x = df$Date[trough_idx], y = df$Close[trough_idx],
                               text = paste0("Max Drawdown: ", round(min(dd) * 100, 1), "%"),
                               showarrow = TRUE, ax = 0, ay = -30, font = list(size = 10, color = "#e74c3c"))),
      plot_bgcolor = "white", paper_bgcolor = "white", margin = list(t = 40), showlegend = FALSE
    )
  list(plot = p, df = df, dd = min(dd))
}

unit3_assignment_ui <- function(id) {
  ns <- NS(id)

  plan_table <- data.frame(
    Element = c("Asset Justification", "Objective", "Decision Process", "Trigger Events", "Profit Targets", "Trade Management"),
    `What It Should Cover` = c(
      "Why these specific instruments (liquidity, familiarity, volatility profile, alignment with account size) rather than any others available on the platform.",
      "A single, measurable goal for the period \u2014 e.g. a target Sortino ratio or a maximum acceptable drawdown \u2014 not simply \u201cmake money.\u201d",
      "The exact analytical steps taken before every trade: which Step 1\u20136 signals must align (trend, pattern, oscillator confirmation) before an entry is considered valid.",
      "The precise, pre-defined condition that triggers entry \u2014 e.g. a confirmed close beyond a valid trend line with RSI confirmation \u2014 removing discretion at the moment of execution.",
      "Where profit will be taken, expressed as a measured price objective (MPO) or a fixed risk\u2013reward multiple, decided before entry, not adjusted mid-trade.",
      "Rules for adjusting the position once open \u2014 stop-loss trailing, partial profit-taking, and the specific conditions under which the original thesis is considered invalidated."
    ), check.names = FALSE
  )

  eval_metrics <- data.frame(
    Metric = c("Win Rate", "Average Risk\u2013Reward Ratio", "Sortino Ratio", "Maximum Drawdown", "Plan Adherence Rate"),
    `Why It Matters for Task 2` = c(
      "The proportion of trades closed in profit \u2014 read alongside risk\u2013reward, since a low win rate can still be profitable with a favourable ratio.",
      "Average profit on winners divided by average loss on losers \u2014 a plan can be profitable with a win rate below 50% if this ratio is high enough.",
      "Downside-risk-adjusted return (see the app's Advanced Metrics tab) \u2014 the most appropriate risk-adjusted measure for a strategy with an asymmetric target payoff.",
      "The largest peak-to-trough decline in account equity during the period \u2014 directly comparable to the drawdown limit set in the original plan's objective.",
      "The proportion of trades that followed the pre-defined decision process and trigger rules exactly, versus discretionary deviations \u2014 essential evidence for Task 2's second requirement."
    ), check.names = FALSE
  )

  swot <- data.frame(
    Dimension = c("Strengths", "Weaknesses", "Opportunities", "Threats"),
    `Evaluate Against` = c(
      "Which specific rule(s) in the plan produced the best risk-adjusted outcomes, and why (e.g. a particular Step signal proved consistently reliable on the chosen assets).",
      "Which rule(s) underperformed or were most often the source of discretionary deviation \u2014 distinguish a flawed rule from a correctly-followed rule that simply lost.",
      "Refinements suggested by the evaluation \u2014 e.g. tightening a trigger condition, adding a confirming indicator, or narrowing the traded asset universe.",
      "External factors that could undermine the strategy going forward \u2014 a regime change (e.g. ADX-confirmed trending conditions giving way to a sustained sideways range) that the strategy is not designed for."
    ), check.names = FALSE
  )

  tagList(
    ua_intro("Unit 3", "Practical Applications of Financial Market Trading", "40%", "3,150\u20133,850 words (excl. references)",
             "Develop a structured trading plan and apply it to trading financial assets using a real-time trading platform."),

    ua_task(1, "Develop a Structured 4-Week Trading Plan", 35,
      tags$p(paste0(
        "A structured trading plan converts trading from a series of discretionary decisions into a repeatable, ",
        "testable process \u2014 the same principle underpinning the Backtesting &amp; Walk-Forward Validation approach used ",
        "elsewhere in this platform's portfolio-optimisation engine. Every element below should be fully specified ",
        "before the four-week period begins, and logged trade-by-trade in this app's Trade Journal tab as it unfolds."
      )),
      ua_table(plan_table),
      ua_callout(HTML(paste0(
        "<strong>Practical note:</strong> position sizing should be fixed as a rule within the plan, not decided trade ",
        "by trade. A widely used academic and industry standard is risking no more than 1\u20132% of account equity per ",
        "trade (Kelly, 1956; commonly summarised in modern risk-management guidance), which allows the account to ",
        "survive a realistic losing streak without a material change to its risk profile."
      )))
    ),

    ua_task(2, "Evaluate Performance Over the Period", 45,
      tags$p(paste0(
        "Task 2 requires evaluating three linked things: how the chosen assets actually performed, whether the plan's ",
        "own rules were followed, and \u2014 where they were not \u2014 why. The chart below illustrates the KIND of equity ",
        "curve and drawdown analysis this evaluation should produce once real trade data from the Trade Journal is ",
        "available; it is a worked illustration of the methodology, not a real account's results."
      )),
      withSpinner(plotlyOutput(ns("equityCurve"), height = "340px")),
      tags$h5("Metrics to report against the original plan"),
      ua_table(eval_metrics),
      tags$p(paste0(
        "Where the plan was not followed exactly, the evaluation should separate two distinct causes: a discretionary ",
        "override of a valid signal (a process failure), versus a legitimate, pre-defined exception the plan already ",
        "allowed for (e.g. standing aside during a scheduled high-impact news release). Only the former should count ",
        "against the plan's own integrity."
      ))
    ),

    ua_task(3, "Evaluate the Chosen Strategy: Strengths &amp; Weaknesses", 20,
      tags$p(paste0(
        "A strategy evaluation should be structured, not just narrative \u2014 the SWOT framework below separates what ",
        "the strategy does well, where it breaks down, how it could be improved, and what external conditions could ",
        "undermine it going forward."
      )),
      ua_table(swot)
    ),

    ua_references(
      ua_ref("<b>Kelly, J.L. (1956)</b> \u2018A New Interpretation of Information Rate\u2019, <i>Bell System Technical Journal</i>, 35(4), pp. 917\u2013926.",
             "https://www.princeton.edu/~wbialek/rome/refs/kelly_56.pdf"),
      ua_ref("<b>Markowitz, H. (1959)</b> <i>Portfolio Selection: Efficient Diversification of Investments</i>. Cited in: AlfaTactix, Trading Risk Management Guide.",
             "https://alfatactix.com/academy/risk-management"),
      ua_ref("<b>Financial Conduct Authority (2019)</b> <i>FCA confirms permanent restrictions on the sale of CFDs and CFD-like options to retail consumers</i>.",
             "https://www.fca.org.uk/news/press-releases/fca-confirms-permanent-restrictions-sale-cfds-and-cfd-options-retail-consumers"),
      ua_ref("<b>TradeZella (2026)</b> <i>Risk Management in Trading: The Complete Guide</i> \u2014 position sizing, drawdown and daily loss-limit frameworks.",
             "https://www.tradezella.com/blog/risk-management-trading"),
      ua_ref("<b>FundedFast (2026)</b> <i>Trading Risk Management: Protecting Your Capital</i> \u2014 summarises Barber et al. (2011) on day-trader profitability.",
             "https://fundedfast.com/learn/risk-management")
    )
  )
}

unit3_assignment_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    output$equityCurve <- renderPlotly({ u3_equity_curve_chart()$plot })
    session$onSessionEnded(function() {})
  })
}
