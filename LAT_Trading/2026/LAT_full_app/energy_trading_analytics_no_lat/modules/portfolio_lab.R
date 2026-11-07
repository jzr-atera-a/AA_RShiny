# modules/portfolio_lab.R
#
# "Strategy for Business > Portfolio Optimisation Lab" - a learning platform
# combining the two things this app's Research and Academia group already
# covers: AlgoDynamiX-style systematic signal/anomaly thinking and Prof.
# Riddiough's FX-hedging research, applied to real portfolios of public
# equities across four themed 10-company groups.
#
# Deliberately reuses existing engines rather than re-implementing them:
#   - Portfolio optimisation (equal weight, inverse vol, risk parity,
#     max-Sharpe, efficient frontier): hf_solve_risk_parity(), 
#     hf_solve_max_sharpe(), hf_port_stats(), hf_build_covariance(),
#     hf_make_valid_corr(), hf_random_portfolios() - all from
#     modules/hedge_fund_strategy.R, applied here to REAL computed
#     return/volatility/correlation figures instead of typed assumptions.
#   - FX hedging: ra_hedge_illustration() / ra_hedge_ladder() from
#     modules/research_academia.R (Prof. Riddiough's tab).
#   - Regime detection pattern: same ADX-based approach as
#     modules/unit3_live_signals.R.
# All of these are sourced into the same environment as this module by
# app.R's for (f in list.files("modules", ...)) source(f) loop, so calling
# them here needs no extra wiring - the same pattern hedge_fund_strategy.R
# and research_academia.R already rely on (e.g. ua_task, ui_metric_tile).
#
# DATA: uses the exact same quantmod::getSymbols(..., src = "yahoo") call
# this app's own DataManager already uses successfully elsewhere
# (R/utils_data.R fetch_yahoo_daily()) - not a new, untested integration.
# The live network call itself could NOT be exercised while building this
# (outbound access to Yahoo is not available in the build sandbox); the
# fetch/parse/combine/partial-failure logic was tested against a
# synthetic feed standing in for quantmod (see pl_get_symbol_xts below),
# in exactly the same style as the Data Enrichment tab's weather fetch.
# Please confirm a real group load works the first time you run this.
#
# LEARNING TOOL, NOT ADVICE: nothing here is investment advice. Backtests
# use simple, transparent rules on real historical prices with no
# transaction costs, slippage or taxes, and past performance says nothing
# about future results.

# ===========================================================================
# COMPANY GROUPS
# ===========================================================================
# Tickers checked for real, current, correctly-spelled companies as of the
# most recent available information; the Nasdaq Top 10 list reflects widely
# reported large-cap Nasdaq names, not a live, continuously-updated ranking -
# treat it as illustrative. Several tickers appear in more than one group
# (e.g. NVDA, AVGO, AMD, MSFT, GOOGL) because the categories genuinely
# overlap in the real market; that is expected, not a bug.

pl_groups <- list(
  "AI Accelerator Chip Manufacturing" = data.frame(
    Ticker = c("NVDA", "AMD", "AVGO", "TSM", "QCOM", "MRVL", "ASML", "MU", "ARM", "INTC"),
    Name = c("NVIDIA", "Advanced Micro Devices", "Broadcom", "Taiwan Semiconductor Manufacturing", "Qualcomm",
             "Marvell Technology", "ASML Holding", "Micron Technology", "Arm Holdings", "Intel"),
    stringsAsFactors = FALSE
  ),
  "Quantum Technologies" = data.frame(
    Ticker = c("IONQ", "RGTI", "QBTS", "ARQQ", "QUBT", "IBM", "GOOGL", "MSFT", "HON", "INTC"),
    Name = c("IonQ", "Rigetti Computing", "D-Wave Quantum", "Arqit Quantum", "Quantum Computing Inc.",
             "IBM", "Alphabet (Google Quantum AI)", "Microsoft (Azure Quantum)", "Honeywell (Quantinuum)", "Intel"),
    stringsAsFactors = FALSE
  ),
  "Defense Technology" = data.frame(
    Ticker = c("LMT", "RTX", "NOC", "GD", "LHX", "HII", "TXT", "BWXT", "KTOS", "PLTR"),
    Name = c("Lockheed Martin", "RTX Corporation", "Northrop Grumman", "General Dynamics", "L3Harris Technologies",
             "Huntington Ingalls Industries", "Textron", "BWX Technologies", "Kratos Defense & Security", "Palantir Technologies"),
    stringsAsFactors = FALSE
  ),
  "Nasdaq Top 10 Tech" = data.frame(
    Ticker = c("NVDA", "AAPL", "GOOGL", "MSFT", "AMZN", "META", "AVGO", "TSLA", "NFLX", "AMD"),
    Name = c("NVIDIA", "Apple", "Alphabet", "Microsoft", "Amazon", "Meta Platforms", "Broadcom", "Tesla", "Netflix", "Advanced Micro Devices"),
    stringsAsFactors = FALSE
  )
)

# ===========================================================================
# DATA FETCH - isolated network seam (pl_get_symbol_xts) so everything
# else here is testable without a live connection.
# ===========================================================================

pl_get_symbol_xts <- function(ticker, from, to) {
  quantmod::getSymbols(ticker, src = "yahoo", from = from, to = to, auto.assign = FALSE)
}

pl_xts_to_df <- function(data) {
  df <- data.frame(
    Date  = zoo::index(data),
    Open  = as.numeric(quantmod::Op(data)), High = as.numeric(quantmod::Hi(data)),
    Low   = as.numeric(quantmod::Lo(data)), Close = as.numeric(quantmod::Cl(data)),
    stringsAsFactors = FALSE
  )
  vol <- tryCatch(as.numeric(quantmod::Vo(data)), error = function(e) rep(NA_real_, nrow(df)))
  df$Volume <- ifelse(is.na(vol), 0, vol)
  df[order(df$Date), ]
}

# Fetches every ticker in a group; one failure does not stop the rest. Returns
# list(data = named list of per-ticker data.frames, failed = character vector).
pl_fetch_group <- function(tickers, months_back = 12) {
  cat("\n=== [Portfolio Lab] Fetching group:", paste(tickers, collapse = ", "), "===\n")
  start_date <- Sys.Date() - months(months_back)
  end_date <- Sys.Date()
  out <- list(); failed <- character(0)
  for (tk in tickers) {
    cat("[Portfolio Lab] Fetching", tk, "...\n")
    df <- tryCatch(pl_xts_to_df(pl_get_symbol_xts(tk, start_date, end_date)),
                   error = function(e) { cat("[Portfolio Lab]", tk, "FAILED:", conditionMessage(e), "\n"); NULL })
    if (is.null(df) || nrow(df) < 30) { failed <- c(failed, tk) } else { out[[tk]] <- df }
  }
  cat("[Portfolio Lab] Fetched", length(out), "of", length(tickers), "tickers.",
      if (length(failed) > 0) paste("Failed:", paste(failed, collapse = ", ")) else "", "\n")
  cat("=== [Portfolio Lab] Fetch complete ===\n")
  list(data = out, failed = failed)
}

# ===========================================================================
# RETURN / RISK STATISTICS - pure functions, no Shiny
# ===========================================================================

# Simple (arithmetic) returns, not log returns: a strategy's actual P&L from
# holding a position is the simple return, and cumprod(1 + r) only
# reconstructs a genuine price/equity path for simple returns - compounding
# log returns that way (an earlier version of this file did) silently
# understates gains and overstates losses over any multi-period stretch.
pl_returns <- function(prices) c(NA_real_, diff(prices) / head(prices, -1))

pl_annualised_return <- function(returns, periods_per_year = 252) mean(returns, na.rm = TRUE) * periods_per_year
pl_annualised_vol     <- function(returns, periods_per_year = 252) sd(returns, na.rm = TRUE) * sqrt(periods_per_year)

pl_sharpe <- function(returns, rf = 0, periods_per_year = 252) {
  v <- pl_annualised_vol(returns, periods_per_year)
  if (!is.finite(v) || v <= 0) return(NA_real_)
  (pl_annualised_return(returns, periods_per_year) - rf) / v
}

# Downside deviation uses only returns below the minimum acceptable return
# (mar, a DAILY figure), squared and averaged over ALL observations (the
# standard Sortino convention), then annualised.
pl_sortino <- function(returns, rf = 0, periods_per_year = 252, mar = 0) {
  r <- returns[!is.na(returns)]
  if (length(r) == 0) return(NA_real_)
  downside_sq <- pmin(r - mar, 0)^2
  dd <- sqrt(mean(downside_sq)) * sqrt(periods_per_year)
  if (!is.finite(dd) || dd <= 0) return(NA_real_)
  (pl_annualised_return(returns, periods_per_year) - rf) / dd
}

pl_max_drawdown <- function(prices) {
  p <- prices[!is.na(prices)]
  if (length(p) < 2) return(NA_real_)
  running_max <- cummax(p)
  min((p - running_max) / running_max)
}

pl_var_historical <- function(returns, conf = 0.95) unname(quantile(returns, probs = 1 - conf, na.rm = TRUE))
pl_var_parametric  <- function(returns, conf = 0.95) {
  mu <- mean(returns, na.rm = TRUE); sigma <- sd(returns, na.rm = TRUE)
  mu + sigma * qnorm(1 - conf)
}

# Standard "moment coefficient" (g1/g2) definitions: BOTH the moment and the
# standard deviation in the denominator use the POPULATION convention
# (dividing by n, not n-1) - mixing a population third moment with R's
# sample sd() (n-1) would be internally inconsistent.
pl_skewness <- function(x) {
  x <- x[!is.na(x)]; n <- length(x); if (n < 3) return(NA_real_)
  m <- mean(x); pop_sd <- sqrt(mean((x - m)^2))
  if (pop_sd <= 0) return(NA_real_)
  mean((x - m)^3) / pop_sd^3
}
pl_excess_kurtosis <- function(x) {
  x <- x[!is.na(x)]; n <- length(x); if (n < 4) return(NA_real_)
  m <- mean(x); pop_sd <- sqrt(mean((x - m)^2))
  if (pop_sd <= 0) return(NA_real_)
  mean((x - m)^4) / pop_sd^4 - 3
}

# One row of summary statistics for a single ticker's price series.
pl_stock_summary <- function(prices, rf = 0) {
  r <- pl_returns(prices)
  list(
    last_price = tail(prices, 1), ann_return = pl_annualised_return(r), ann_vol = pl_annualised_vol(r),
    sharpe = pl_sharpe(r, rf), sortino = pl_sortino(r, rf), max_drawdown = pl_max_drawdown(prices),
    var95_hist = pl_var_historical(r, 0.95), skew = pl_skewness(r), kurtosis = pl_excess_kurtosis(r),
    n_obs = sum(!is.na(r))
  )
}

# ===========================================================================
# TECHNICAL / REGIME / TRIGGER (mirrors unit3_live_signals.R's ADX pattern)
# ===========================================================================

pl_regime <- function(high, low, close, n = 14) {
  if (length(close) < n * 2) return(list(regime = "Insufficient data", adx = NA_real_))
  adx <- tryCatch(TTR::ADX(cbind(High = high, Low = low, Close = close), n = n), error = function(e) NULL)
  if (is.null(adx)) return(list(regime = "ADX unavailable", adx = NA_real_))
  last_adx <- tail(adx[, "ADX"], 1)
  if (is.na(last_adx)) return(list(regime = "Warming up", adx = NA_real_))
  list(regime = if (last_adx >= 25) "Trending" else "Ranging", adx = round(unname(last_adx), 1))
}

# Detects a crossover that fired on the MOST RECENT bar only (not "currently
# above/below", which would stay "active" for weeks).
pl_ma_crossover_trigger <- function(prices, fast = 20, slow = 50) {
  if (length(prices) < slow + 2) return(list(active = FALSE, direction = NA_character_, detail = "Insufficient data"))
  sf <- TTR::SMA(prices, fast); ss <- TTR::SMA(prices, slow)
  n <- length(prices)
  if (any(is.na(c(sf[n], sf[n - 1], ss[n], ss[n - 1]))))
    return(list(active = FALSE, direction = NA_character_, detail = "Insufficient data"))
  golden <- sf[n - 1] <= ss[n - 1] && sf[n] > ss[n]
  death  <- sf[n - 1] >= ss[n - 1] && sf[n] < ss[n]
  if (golden) return(list(active = TRUE, direction = "Golden", detail = sprintf("Golden cross just fired: %d-day MA crossed above %d-day MA.", fast, slow)))
  if (death)  return(list(active = TRUE, direction = "Death",  detail = sprintf("Death cross just fired: %d-day MA crossed below %d-day MA.", fast, slow)))
  list(active = FALSE, direction = NA_character_,
       detail = sprintf("No new crossover \u2014 currently %s (%d-day %s %d-day).", if (sf[n] > ss[n]) "bullish" else "bearish", fast, if (sf[n] > ss[n]) ">" else "<", slow))
}

# ===========================================================================
# BACKTEST - simple, transparent, long/flat SMA-crossover trend rule.
# Trades on the NEXT bar's return using today's signal (lag 1), so there is
# no look-ahead bias: the position you'd have taken on day t is only known at
# the close of day t, so it earns day t+1's return.
# ===========================================================================

pl_backtest_sma_crossover <- function(dates, prices, fast = 20, slow = 50) {
  n <- length(prices)
  sf <- TTR::SMA(prices, fast); ss <- TTR::SMA(prices, slow)
  raw_signal <- ifelse(sf > ss, 1, 0)
  raw_signal[is.na(raw_signal)] <- 0
  signal <- c(0, head(raw_signal, -1))   # yesterday's signal governs today's return - no look-ahead
  ret <- pl_returns(prices); ret[is.na(ret)] <- 0
  strat_ret <- signal * ret
  data.frame(
    Date = dates, Price = prices, Signal = signal,
    StrategyReturn = strat_ret, BuyHoldReturn = ret,
    StrategyEquity = cumprod(1 + strat_ret), BuyHoldEquity = cumprod(1 + ret)
  )
}

pl_backtest_summary <- function(bt, rf = 0) {
  list(
    strategy_total_return = tail(bt$StrategyEquity, 1) - 1, buyhold_total_return = tail(bt$BuyHoldEquity, 1) - 1,
    strategy_sharpe = pl_sharpe(bt$StrategyReturn, rf), buyhold_sharpe = pl_sharpe(bt$BuyHoldReturn, rf),
    strategy_sortino = pl_sortino(bt$StrategyReturn, rf), buyhold_sortino = pl_sortino(bt$BuyHoldReturn, rf),
    strategy_max_dd = pl_max_drawdown(bt$StrategyEquity), buyhold_max_dd = pl_max_drawdown(bt$BuyHoldEquity),
    pct_time_in_market = mean(bt$Signal), n_trades = sum(abs(diff(bt$Signal)) > 0)
  )
}

# Applies the same rule to a WEIGHTED blend of several tickers' returns (the
# portfolio-level backtest), given a data.frame of aligned per-ticker daily
# log returns (columns = tickers) and a named weight vector.
pl_backtest_portfolio <- function(dates, returns_df, weights) {
  w <- weights[colnames(returns_df)]
  port_ret <- as.numeric(as.matrix(returns_df) %*% w)
  port_ret[is.na(port_ret)] <- 0
  # Reuse the same crossover rule, applied to the portfolio's own cumulative price level.
  port_price <- 100 * cumprod(1 + port_ret)
  pl_backtest_sma_crossover(dates, port_price, fast = 20, slow = 50)
}

pl_pct <- function(x, digits = 1) if (is.na(x)) "n/a" else paste0(round(x * 100, digits), "%")

# ===========================================================================
# UI
# ===========================================================================

portfolio_lab_ui <- function(id) {
  ns <- NS(id)

  tagList(
    ui_banner("Strategy for Business", "Portfolio Optimisation Lab",
              "A learning platform combining AlgoDynamiX-style systematic signals and Prof. Riddiough's FX-hedging research, applied to real portfolios across four themed equity groups."),

    ua_callout("Learning tool, not advice. Backtests use simple rules on real historical prices with no transaction costs, slippage or taxes; past performance says nothing about future results."),

    fluidRow(
      box(width = 12, status = "primary", solidHeader = TRUE, title = "1. Select a group and load data",
        fluidRow(
          column(5, selectInput(ns("groupChoice"), "Company group:", choices = names(pl_groups))),
          column(3, style = "padding-top:25px;", actionButton(ns("loadGroup"), "Load 12 Months of Data", icon = icon("cloud-arrow-down"), class = "btn-primary", width = "100%")),
          column(4, numericInput(ns("riskFree"), "Risk-free rate (%/yr, for Sharpe/Sortino)", value = 4, min = 0, max = 20, step = 0.25))
        ),
        uiOutput(ns("loadStatus")),
        DT::dataTableOutput(ns("groupTable"))
      )
    ),

    fluidRow(
      tabBox(id = ns("subtabs"), width = 12, selected = "2. Technical Analysis",

        tabPanel("2. Technical Analysis", icon = icon("chart-line"),
          fluidRow(
            column(4, selectInput(ns("taTicker"), "Company:", choices = NULL)),
            column(4, sliderInput(ns("taFast"), "Fast MA (days)", min = 5, max = 50, value = 20)),
            column(4, sliderInput(ns("taSlow"), "Slow MA (days)", min = 20, max = 200, value = 50))
          ),
          withSpinner(plotly::plotlyOutput(ns("taPriceChart"), height = "380px")),
          withSpinner(plotly::plotlyOutput(ns("taRsiChart"), height = "200px")),
          ui_context(tags$b("Reading this: "), "the RSI panel uses the standard 14-day Relative Strength Index \u2014 conventionally read as overbought above 70 and oversold below 30.")
        ),

        tabPanel("3. Algorithmic Trading", icon = icon("robot"),
          box(width = 12, status = "info", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE, title = "The rule being tested",
            tags$p("Long the full position whenever the fast moving average is above the slow one, flat (in cash) otherwise. Trades on the NEXT day's return using the prior day's signal, so there is no look-ahead bias.", style = "font-size:12.5px; color:#4a5560;")
          ),
          fluidRow(
            column(4, radioButtons(ns("btScope"), "Backtest:", choices = c("Single company" = "single", "Optimised portfolio (from tab 6)" = "portfolio"))),
            column(4, selectInput(ns("btTicker"), "Company (if single):", choices = NULL)),
            column(4, selectInput(ns("btMethod"), "Portfolio weights to use (if portfolio):", choices = c("Equal Weight", "Inverse Volatility", "Risk Parity", "Max Sharpe")))
          ),
          actionButton(ns("runBacktest"), "Run Backtest", icon = icon("play"), class = "btn-primary"),
          uiOutput(ns("btSummary")),
          withSpinner(plotly::plotlyOutput(ns("btEquityChart"), height = "360px"))
        ),

        tabPanel("4. Statistical Analysis", icon = icon("chart-simple"),
          withSpinner(plotly::plotlyOutput(ns("corrHeatmap"), height = "420px")),
          DT::dataTableOutput(ns("statsTable")),
          fluidRow(
            column(6, selectInput(ns("distTicker"), "Return distribution for:", choices = NULL)),
            column(6, uiOutput(ns("normalityResult")))
          ),
          withSpinner(plotly::plotlyOutput(ns("distChart"), height = "280px"))
        ),

        tabPanel("5. Risk Analysis", icon = icon("triangle-exclamation"),
          DT::dataTableOutput(ns("riskTable")),
          fluidRow(
            column(6, withSpinner(plotly::plotlyOutput(ns("sharpeChart"), height = "320px"))),
            column(6, withSpinner(plotly::plotlyOutput(ns("drawdownChart"), height = "320px")))
          ),
          ui_context(tags$b("VaR (95%, historical, 1-day): "), "the loss level that historical daily returns exceeded 5% of the time \u2014 read as a downside reference point, not a hard cap.")
        ),

        tabPanel("6. Portfolio Optimizer", icon = icon("chart-pie"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE, title = "About this",
            tags$p("Same engine as the Hedge Fund / Wealth tab's Portfolio Optimizer \u2014 equal weight, inverse volatility, risk parity (equalised risk contribution) and max-Sharpe \u2014 applied here to the REAL annualised return, volatility and correlation computed from the loaded group's actual price history, not typed assumptions.", style = "font-size:12.5px; color:#7d4a00;")
          ),
          DT::dataTableOutput(ns("optWeightsTable")),
          fluidRow(
            column(6, withSpinner(plotly::plotlyOutput(ns("optWeightsChart"), height = "320px"))),
            column(6, withSpinner(plotly::plotlyOutput(ns("optFrontierChart"), height = "320px")))
          )
        ),

        tabPanel("7. FX / Currency Hedging", icon = icon("money-bill-transfer"),
          tags$p("Every company in every group is USD-listed. This reuses the Prof. Riddiough tab's FX-hedging calculator for an investor whose base currency is not USD.", style = "font-size:12.5px; color:#4a5560;"),
          fluidRow(
            column(4, numericInput(ns("fxNotional"), "Total USD exposure to this portfolio ($)", value = 1000000, min = 0, step = 100000)),
            column(4, sliderInput(ns("fxVol"), "Assumed annual USD/base-currency FX volatility (%)", min = 2, max = 20, value = 8, step = 0.5)),
            column(4, numericInput(ns("fxCost"), "Annual forward hedge cost (%, carry differential)", value = 0.5, min = 0, step = 0.1))
          ),
          sliderInput(ns("fxRatio"), "Hedge ratio", min = 0, max = 1, value = 0.75, step = 0.05),
          uiOutput(ns("fxResult")),
          DT::dataTableOutput(ns("fxLadder"))
        ),

        tabPanel("8. Live Signals", icon = icon("bolt"),
          tags$p("Current trend regime (ADX) and whether a moving-average crossover fired on the most recent bar, for every company in the loaded group.", style = "font-size:12.5px; color:#4a5560;"),
          DT::dataTableOutput(ns("liveSignalsTable"))
        )
      )
    )
  )
}

# ===========================================================================
# SERVER
# ===========================================================================

portfolio_lab_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    group_data   <- reactiveVal(NULL)   # named list of per-ticker OHLC data.frames
    group_failed <- reactiveVal(character(0))
    opt_result   <- reactiveVal(NULL)   # cached output of the portfolio optimizer, for the backtest tab

    observeEvent(input$loadGroup, {
      grp <- pl_groups[[input$groupChoice]]
      output$loadStatus <- renderUI(tags$div(style = "color:#2980b9;", icon("spinner", class = "fa-spin"), " Loading 12 months of data for 10 companies \u2014 this can take a little while..."))
      res <- pl_fetch_group(grp$Ticker, months_back = 12)
      group_data(res$data)
      group_failed(res$failed)
      opt_result(NULL)

      choices <- names(res$data)
      updateSelectInput(session, "taTicker", choices = choices)
      updateSelectInput(session, "btTicker", choices = choices)
      updateSelectInput(session, "distTicker", choices = choices)

      if (length(res$data) == 0) {
        output$loadStatus <- renderUI(tags$div(style = "color:#c0392b;", "No tickers loaded \u2014 all fetches failed. Check the Debug Console for details."))
      } else {
        output$loadStatus <- renderUI(tags$div(style = "color:#27ae60;",
          icon("check-circle"), sprintf(" Loaded %d of %d companies.", length(res$data), nrow(grp)),
          if (length(res$failed) > 0) paste0(" Failed: ", paste(res$failed, collapse = ", ")) else ""))
      }
    })

    output$groupTable <- DT::renderDataTable({
      req(group_data())
      gd <- group_data(); grp <- pl_groups[[input$groupChoice]]
      rf <- (input$riskFree %||% 4) / 100
      rows <- lapply(names(gd), function(tk) {
        s <- pl_stock_summary(gd[[tk]]$Close, rf)
        nm <- grp$Name[grp$Ticker == tk]; if (length(nm) == 0) nm <- tk
        data.frame(Ticker = tk, Name = nm, `Last Price` = round(s$last_price, 2),
                   `Ann. Return` = pl_pct(s$ann_return), `Ann. Vol` = pl_pct(s$ann_vol),
                   Sharpe = round(s$sharpe, 2), Sortino = round(s$sortino, 2),
                   `Max Drawdown` = pl_pct(s$max_drawdown), `Trading Days` = s$n_obs, check.names = FALSE)
      })
      DT::datatable(do.call(rbind, rows), rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)

    # -- shared: aligned returns matrix across the loaded group --
    returns_matrix <- reactive({
      gd <- group_data(); req(length(gd) >= 2)
      per_ticker <- lapply(gd, function(df) {
        r <- pl_returns(df$Close)
        data.frame(Date = df$Date, Return = r)
      })
      merged <- Reduce(function(a, b) merge(a, b, by = "Date", all = TRUE), lapply(names(per_ticker), function(tk) {
        d <- per_ticker[[tk]]; names(d)[2] <- tk; d
      }))
      merged[order(merged$Date), ]
    })

    # -- Tab 2: Technical Analysis --
    output$taPriceChart <- plotly::renderPlotly({
      req(group_data(), input$taTicker %in% names(group_data()))
      df <- group_data()[[input$taTicker]]
      fast <- TTR::SMA(df$Close, input$taFast %||% 20); slow <- TTR::SMA(df$Close, input$taSlow %||% 50)
      plotly::plot_ly(df, x = ~Date, y = ~Close, type = "scatter", mode = "lines", name = "Close", line = list(color = "#002C3C")) |>
        plotly::add_trace(y = fast, name = paste0(input$taFast %||% 20, "-day MA"), line = list(color = "#008A82")) |>
        plotly::add_trace(y = slow, name = paste0(input$taSlow %||% 50, "-day MA"), line = list(color = "#e67e22", dash = "dot")) |>
        plotly::layout(yaxis = list(title = "Price ($)"), plot_bgcolor = "white", paper_bgcolor = "white",
                       legend = list(orientation = "h", y = 1.1), title = list(text = input$taTicker, font = list(size = 12)))
    })
    output$taRsiChart <- plotly::renderPlotly({
      req(group_data(), input$taTicker %in% names(group_data()))
      df <- group_data()[[input$taTicker]]
      rsi <- TTR::RSI(df$Close, 14)
      plotly::plot_ly(df, x = ~Date, y = rsi, type = "scatter", mode = "lines", name = "RSI(14)", line = list(color = "#8e44ad")) |>
        plotly::add_trace(y = rep(70, nrow(df)), mode = "lines", line = list(color = "#c0392b", dash = "dot"), name = "Overbought (70)") |>
        plotly::add_trace(y = rep(30, nrow(df)), mode = "lines", line = list(color = "#27ae60", dash = "dot"), name = "Oversold (30)") |>
        plotly::layout(yaxis = list(title = "RSI", range = c(0, 100)), plot_bgcolor = "white", paper_bgcolor = "white", showlegend = FALSE)
    })

    # -- Tab 3: Algorithmic Trading --
    backtest_result <- eventReactive(input$runBacktest, {
      if (identical(input$btScope, "single")) {
        req(group_data(), input$btTicker %in% names(group_data()))
        df <- group_data()[[input$btTicker]]
        list(scope = "single", label = input$btTicker, bt = pl_backtest_sma_crossover(df$Date, df$Close))
      } else {
        req(opt_result())
        w <- opt_result()$weights[[input$btMethod]]
        rm <- returns_matrix()
        req(all(names(w) %in% names(rm)))
        bt <- pl_backtest_portfolio(rm$Date, rm[names(w)], w)
        list(scope = "portfolio", label = input$btMethod, bt = bt)
      }
    })

    output$btSummary <- renderUI({
      req(backtest_result())
      s <- pl_backtest_summary(backtest_result()$bt, (input$riskFree %||% 4) / 100)
      tagList(
        tags$h5(paste0(if (backtest_result()$scope == "single") "Single company: " else "Portfolio (", backtest_result()$label, "): "), if (backtest_result()$scope == "single") backtest_result()$label else ""),
        fluidRow(
          column(3, ui_metric_tile("Strategy return", pl_pct(s$strategy_total_return), paste0("vs buy-and-hold ", pl_pct(s$buyhold_total_return)))),
          column(3, ui_metric_tile("Strategy Sharpe", round(s$strategy_sharpe, 2), paste0("vs buy-and-hold ", round(s$buyhold_sharpe, 2)))),
          column(3, ui_metric_tile("Strategy Sortino", round(s$strategy_sortino, 2), paste0("vs buy-and-hold ", round(s$buyhold_sortino, 2)))),
          column(3, ui_metric_tile("Strategy max drawdown", pl_pct(s$strategy_max_dd), paste0("vs buy-and-hold ", pl_pct(s$buyhold_max_dd))))
        ),
        ui_metric_tile("Time in market / trades", paste0(pl_pct(s$pct_time_in_market), " / ", s$n_trades, " trades"), "over the loaded 12-month window")
      )
    })
    output$btEquityChart <- plotly::renderPlotly({
      req(backtest_result())
      bt <- backtest_result()$bt
      plotly::plot_ly(bt, x = ~Date, y = ~StrategyEquity, type = "scatter", mode = "lines", name = "Strategy", line = list(color = "#008A82")) |>
        plotly::add_trace(y = ~BuyHoldEquity, name = "Buy & Hold", line = list(color = "#8a97a0", dash = "dot")) |>
        plotly::layout(yaxis = list(title = "Growth of $1"), plot_bgcolor = "white", paper_bgcolor = "white", legend = list(orientation = "h", y = 1.1))
    })

    # -- Tab 4: Statistical Analysis --
    output$corrHeatmap <- plotly::renderPlotly({
      rm <- returns_matrix(); tickers <- setdiff(names(rm), "Date")
      cm <- cor(rm[tickers], use = "pairwise.complete.obs")
      plotly::plot_ly(z = cm, x = tickers, y = tickers, type = "heatmap", zmin = -1, zmax = 1,
                      colorscale = list(c(0, "#c0392b"), c(0.5, "#ffffff"), c(1, "#1e7a46")), colorbar = list(title = "\u03c1")) |>
        plotly::layout(title = list(text = "Return correlation matrix", font = list(size = 12)))
    })
    output$statsTable <- DT::renderDataTable({
      rm <- returns_matrix(); tickers <- setdiff(names(rm), "Date")
      rows <- lapply(tickers, function(tk) {
        r <- rm[[tk]]
        data.frame(Ticker = tk, Mean = signif(mean(r, na.rm = TRUE), 4), SD = signif(sd(r, na.rm = TRUE), 4),
                   Skewness = round(pl_skewness(r), 2), `Excess Kurtosis` = round(pl_excess_kurtosis(r), 2), check.names = FALSE)
      })
      DT::datatable(do.call(rbind, rows), rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)
    output$distChart <- plotly::renderPlotly({
      req(group_data(), input$distTicker %in% names(group_data()))
      r <- pl_returns(group_data()[[input$distTicker]]$Close)
      plotly::plot_ly(x = r, type = "histogram", marker = list(color = "#008A82")) |>
        plotly::layout(xaxis = list(title = "Daily log return"), yaxis = list(title = "Count"), plot_bgcolor = "white", paper_bgcolor = "white")
    })
    output$normalityResult <- renderUI({
      req(group_data(), input$distTicker %in% names(group_data()))
      r <- pl_returns(group_data()[[input$distTicker]]$Close); r <- r[!is.na(r)]
      sw <- tryCatch(shapiro.test(if (length(r) > 5000) sample(r, 5000) else r), error = function(e) NULL)
      if (is.null(sw)) return(tags$p("Could not run the normality test.", style = "color:#7f8c8d;"))
      sig <- sw$p.value < 0.05
      ui_metric_tile("Shapiro-Wilk normality test", sprintf("p = %.4f", sw$p.value),
                     if (sig) "Rejects normality at 5% \u2014 as expected, daily equity returns are rarely normal (fat tails)." else "Cannot reject normality at 5%.",
                     color = if (sig) "#9c6b26" else "#1e7a46")
    })

    # -- Tab 5: Risk Analysis --
    output$riskTable <- DT::renderDataTable({
      req(group_data())
      gd <- group_data(); rf <- (input$riskFree %||% 4) / 100
      rows <- lapply(names(gd), function(tk) {
        r <- pl_returns(gd[[tk]]$Close)
        data.frame(Ticker = tk, Sharpe = round(pl_sharpe(r, rf), 2), Sortino = round(pl_sortino(r, rf), 2),
                   `Max Drawdown` = pl_pct(pl_max_drawdown(gd[[tk]]$Close)),
                   `VaR 95% (1-day, historical)` = pl_pct(pl_var_historical(r)),
                   `VaR 95% (1-day, parametric)` = pl_pct(pl_var_parametric(r)), check.names = FALSE)
      })
      DT::datatable(do.call(rbind, rows), rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)
    output$sharpeChart <- plotly::renderPlotly({
      req(group_data())
      gd <- group_data(); rf <- (input$riskFree %||% 4) / 100
      df <- data.frame(Ticker = names(gd), Sharpe = sapply(gd, function(d) pl_sharpe(pl_returns(d$Close), rf)),
                       Sortino = sapply(gd, function(d) pl_sortino(pl_returns(d$Close), rf)))
      plotly::plot_ly(df, x = ~Ticker, y = ~Sharpe, type = "bar", name = "Sharpe", marker = list(color = "#002C3C")) |>
        plotly::add_trace(y = ~Sortino, name = "Sortino", marker = list(color = "#008A82")) |>
        plotly::layout(barmode = "group", title = list(text = "Sharpe vs Sortino by company", font = list(size = 12)), plot_bgcolor = "white", paper_bgcolor = "white")
    })
    output$drawdownChart <- plotly::renderPlotly({
      req(group_data())
      gd <- group_data()
      df <- data.frame(Ticker = names(gd), MaxDrawdown = sapply(gd, function(d) pl_max_drawdown(d$Close) * 100))
      plotly::plot_ly(df, x = ~Ticker, y = ~MaxDrawdown, type = "bar", marker = list(color = "#c0392b")) |>
        plotly::layout(yaxis = list(title = "Max drawdown (%)"), title = list(text = "Max drawdown by company (12mo)", font = list(size = 12)), plot_bgcolor = "white", paper_bgcolor = "white")
    })

    # -- Tab 6: Portfolio Optimizer (reuses hf_* from hedge_fund_strategy.R) --
    observe({
      rm <- returns_matrix(); tickers <- setdiff(names(rm), "Date")
      req(length(tickers) >= 2)
      mu <- sapply(tickers, function(tk) pl_annualised_return(rm[[tk]]))
      sigma <- sapply(tickers, function(tk) pl_annualised_vol(rm[[tk]]))
      names(mu) <- tickers; names(sigma) <- tickers
      corr <- cor(rm[tickers], use = "pairwise.complete.obs")
      valid <- hf_make_valid_corr(corr)   # from hedge_fund_strategy.R; defensive - real sample correlations are already PSD
      Sigma <- hf_build_covariance(pmax(sigma, 1e-4), valid$corr)
      rf <- (input$riskFree %||% 4) / 100
      n <- length(mu)
      opt_result(list(
        tickers = tickers, mu = mu, sigma = sigma, Sigma = Sigma, rf = rf,
        weights = list(`Equal Weight` = setNames(rep(1 / n, n), tickers),
                       `Inverse Volatility` = setNames((1 / sigma) / sum(1 / sigma), tickers),
                       `Risk Parity` = setNames(hf_solve_risk_parity(Sigma), tickers),
                       `Max Sharpe` = setNames(hf_solve_max_sharpe(mu, Sigma, rf), tickers))
      ))
    })

    output$optWeightsTable <- DT::renderDataTable({
      req(opt_result()); o <- opt_result()
      rows <- lapply(names(o$weights), function(method) {
        w <- o$weights[[method]]; s <- hf_port_stats(w, o$mu, o$Sigma, o$rf)
        c(list(Method = method), setNames(as.list(round(w * 100, 1)), o$tickers),
          list(`Return %` = round(s$ret * 100, 2), `Vol %` = round(s$vol * 100, 2), Sharpe = round(s$sharpe, 3)))
      })
      DT::datatable(do.call(rbind.data.frame, lapply(rows, function(r) as.data.frame(r, check.names = FALSE))),
                    rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)
    output$optWeightsChart <- plotly::renderPlotly({
      req(opt_result()); o <- opt_result()
      df <- do.call(rbind, lapply(names(o$weights), function(m) data.frame(Method = m, Ticker = o$tickers, Weight = o$weights[[m]] * 100)))
      plotly::plot_ly(df, x = ~Method, y = ~Weight, color = ~Ticker, type = "bar") |>
        plotly::layout(barmode = "stack", yaxis = list(title = "Weight (%)"), title = list(text = "Allocation by method", font = list(size = 12)), plot_bgcolor = "white", paper_bgcolor = "white", legend = list(font = list(size = 8)))
    })
    output$optFrontierChart <- plotly::renderPlotly({
      req(opt_result()); o <- opt_result()
      rp <- hf_random_portfolios(o$mu, o$Sigma, 1500)
      pts <- do.call(rbind, lapply(names(o$weights), function(m) { s <- hf_port_stats(o$weights[[m]], o$mu, o$Sigma, o$rf); data.frame(Method = m, vol = s$vol, ret = s$ret) }))
      plotly::plot_ly() |>
        plotly::add_trace(data = rp, x = ~(vol * 100), y = ~(ret * 100), type = "scatter", mode = "markers", marker = list(color = "#d8dee3", size = 4), name = "Random", hoverinfo = "skip") |>
        plotly::add_trace(data = pts, x = ~(vol * 100), y = ~(ret * 100), type = "scatter", mode = "markers+text", text = ~Method, textposition = "top center", marker = list(color = "#008A82", size = 11, symbol = "diamond"), name = "Methods") |>
        plotly::layout(xaxis = list(title = "Volatility (%)"), yaxis = list(title = "Return (%)"), title = list(text = "Efficient frontier (real data)", font = list(size = 12)), showlegend = FALSE, plot_bgcolor = "white", paper_bgcolor = "white")
    })

    # -- Tab 7: FX / Currency Hedging (reuses ra_* from research_academia.R) --
    output$fxResult <- renderUI({
      req(input$fxNotional, input$fxVol, input$fxRatio, input$fxCost)
      r <- ra_hedge_illustration(input$fxNotional, input$fxVol, input$fxRatio, input$fxCost)
      tagList(
        fluidRow(
          column(6, ui_metric_tile("Unhedged FX risk (1 sd, per year)", ra_gbp(r$unhedged_vol), "on the USD exposure above")),
          column(6, ui_metric_tile("Hedged FX risk", ra_gbp(r$hedged_vol), paste0(round(r$reduction_pct), "% reduction"), color = "#1e7a46"))
        ),
        ui_metric_tile("Annual hedging cost", ra_gbp(r$annual_cost), "the price of that reduction", color = "#9c6b26")
      )
    })
    output$fxLadder <- DT::renderDataTable({
      req(input$fxNotional, input$fxVol, input$fxCost)
      DT::datatable(ra_hedge_ladder(input$fxNotional, input$fxVol, input$fxCost), rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)

    # -- Tab 8: Live Signals --
    output$liveSignalsTable <- DT::renderDataTable({
      req(group_data())
      gd <- group_data()
      rows <- lapply(names(gd), function(tk) {
        df <- gd[[tk]]
        reg <- pl_regime(df$High, df$Low, df$Close)
        trig <- pl_ma_crossover_trigger(df$Close)
        data.frame(Ticker = tk, Regime = reg$regime, ADX = if (is.na(reg$adx)) "\u2014" else reg$adx,
                   `Crossover (most recent bar)` = if (trig$active) trig$direction else "None", Detail = trig$detail, check.names = FALSE)
      })
      DT::datatable(do.call(rbind, rows), rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)

    output$loadStatus <- renderUI(tags$p("Choose a group and click \u201cLoad 12 Months of Data\u201d to begin.", style = "color:#6b7883;"))
  })
}
