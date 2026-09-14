# modules/hedge_fund_strategy.R
#
# "Strategy for Business > Hedge Fund / Wealth" - turns the business-planning discussion
# (regulatory pathway, portfolio allocation, business structure, tech roadmap, financial
# projections) into a working set of tools, not just static reading material.
#
# Reuses u3_context() / u3_metric_tile() / u3_status_pill() from unit3_live_signals.R -
# both files are sourced into the same environment by app.R, so these are already
# available here without re-defining them.
#
# IMPORTANT: nothing here is legal, regulatory, tax or investment advice. The figures on
# the Reality Check and Business Structure tabs are general, publicly reported ranges as
# of when this was written and can change; anyone actually pursuing this must get advice
# from an FCA-authorised compliance consultant / financial services lawyer before doing
# anything else. This tab is a planning and simulation aid, nothing more.

# ===========================================================================
# PURE LOGIC - portfolio optimisation and business projection engines
# ===========================================================================

hf_softmax <- function(x) { e <- exp(x - max(x)); e / sum(e) }

hf_port_stats <- function(w, mu, Sigma, rf = 0) {
  ret <- sum(w * mu)
  vol <- sqrt(as.numeric(t(w) %*% Sigma %*% w))
  sharpe <- if (vol > 0) (ret - rf) / vol else NA
  list(ret = ret, vol = vol, sharpe = sharpe)
}

hf_risk_contributions <- function(w, Sigma) {
  port_var <- as.numeric(t(w) %*% Sigma %*% w)
  if (port_var <= 0) return(rep(0, length(w)))
  mrc <- as.numeric(Sigma %*% w)
  (w * mrc) / port_var
}

hf_solve_risk_parity <- function(mu, Sigma) {
  n <- length(mu)
  obj <- function(par) {
    w <- hf_softmax(par)
    rc <- hf_risk_contributions(w, Sigma)
    sum((rc - 1 / n)^2)
  }
  fit <- tryCatch(optim(rep(0, n), obj, method = "BFGS", control = list(maxit = 2000)),
                   error = function(e) NULL)
  if (is.null(fit)) return(rep(1 / n, n))
  hf_softmax(fit$par)
}

hf_solve_max_sharpe <- function(mu, Sigma, rf = 0) {
  n <- length(mu)
  obj <- function(par) {
    w <- hf_softmax(par)
    s <- hf_port_stats(w, mu, Sigma, rf)
    if (is.na(s$sharpe)) return(1e6)
    -s$sharpe
  }
  fit <- tryCatch(optim(rep(0, n), obj, method = "BFGS", control = list(maxit = 2000)),
                   error = function(e) NULL)
  if (is.null(fit)) return(rep(1 / n, n))
  hf_softmax(fit$par)
}

# Builds a covariance matrix from a volatility vector and a correlation matrix, forcing
# symmetry (averages a cell with its transpose) so a lopsided manual edit in the
# correlation grid can't silently produce a non-symmetric, invalid matrix.
hf_build_covariance <- function(sigma, corr) {
  corr <- (corr + t(corr)) / 2
  diag(corr) <- 1
  diag(sigma) %*% corr %*% diag(sigma)
}

hf_random_portfolios <- function(mu, Sigma, n_portfolios = 400) {
  n <- length(mu)
  do.call(rbind, lapply(seq_len(n_portfolios), function(i) {
    w <- hf_softmax(rnorm(n))
    s <- hf_port_stats(w, mu, Sigma)
    data.frame(vol = s$vol, ret = s$ret)
  }))
}

# Simplified NAV-index business projection: management fee + performance fee above a
# high-water mark and hurdle. Illustrative for business planning only - a real fund
# administrator calculates this per-investor, per-subscription; this collapses the
# whole fund into one NAV series, which is the standard simplification for this kind
# of planning tool.
hf_project_business <- function(start_aum, annual_new_capital, gross_return_pct,
                                  mgmt_fee_pct, perf_fee_pct, hurdle_pct,
                                  annual_cost_base, years = 5) {
  nav <- 100; hwm <- 100; aum <- start_aum
  out <- vector("list", years)
  for (yr in seq_len(years)) {
    aum_start <- aum
    gross_nav <- nav * (1 + gross_return_pct)
    mgmt_fee_amt <- aum_start * mgmt_fee_pct

    hurdle_nav <- nav * (1 + hurdle_pct)
    perf_fee_pct_amt <- 0
    if (gross_nav > hwm && gross_nav > hurdle_nav) {
      excess_nav <- gross_nav - max(hwm, hurdle_nav)
      perf_fee_pct_amt <- (excess_nav / nav) * perf_fee_pct
    }
    perf_fee_amt <- aum_start * perf_fee_pct_amt

    net_return_pct <- gross_return_pct - mgmt_fee_pct - perf_fee_pct_amt
    net_nav <- nav * (1 + net_return_pct)
    hwm <- max(hwm, net_nav)

    total_revenue <- mgmt_fee_amt + perf_fee_amt
    net_profit <- total_revenue - annual_cost_base
    aum_end <- aum_start * (1 + net_return_pct) + annual_new_capital

    out[[yr]] <- data.frame(Year = yr, AUM_Start = aum_start, AUM_End = aum_end,
      MgmtFee = mgmt_fee_amt, PerfFee = perf_fee_amt, TotalRevenue = total_revenue,
      NetProfit = net_profit, NAV = net_nav)

    nav <- net_nav; aum <- aum_end
  }
  do.call(rbind, out)
}

# ===========================================================================
# UI
# ===========================================================================

hedge_fund_strategy_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(width = 12, status = "danger", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
        title = "Not legal, regulatory, tax or investment advice",
        tags$p(paste0(
          "Everything on this tab is a planning and simulation aid built for coursework, not a substitute ",
          "for advice from an FCA-authorised compliance consultant or financial services lawyer. Managing ",
          "other people's money without authorisation is a criminal offence under FSMA 2000 in the UK - the ",
          "figures below are general, publicly reported ranges and will date; verify everything independently ",
          "before acting on any of it."
        ), style = "font-size:12.5px; color:#7d1a1a; margin:0; line-height:1.6;")
      )
    ),

    fluidRow(
      tabBox(id = ns("subtabs"), width = 12, selected = "1. Reality Check",

        # ---------------------------------------------------------------
        tabPanel("1. Reality Check", icon = icon("scale-balanced"),
          box(width = 12, status = "warning", solidHeader = TRUE, title = "The regulatory gate",
              collapsible = TRUE, collapsed = FALSE,
            tags$p(paste0(
              "You cannot legally manage other people's money - even friends and family beyond narrow ",
              "exemptions - without authorisation. In the UK this means FCA authorisation as an investment ",
              "manager/AIFM. Current publicly reported ranges: authorisation typically costs "),
              tags$b("\u00a330,000\u2013\u00a375,000"), " (including FCA fees of \u00a32,720\u2013\u00a310,880) and takes ",
              tags$b("6\u201312 months"), ", and requires at least two approved Senior Managers (compliance ",
              "oversight + MLRO). The FCA's AIFM regime itself is mid-overhaul as of 2026 (final rules expected ",
              "2027, live 2028), so exact tiers/thresholds are still moving.",
              style = "font-size:13px; color:#4a5560; line-height:1.65; margin:0;")
          ),
          box(width = 12, status = "info", solidHeader = TRUE, title = "Which path fits you \u2014 a rough decision helper",
            fluidRow(
              column(6, sliderInput(ns("rcCapital"), "Capital available for setup/legal costs (\u00a3)",
                       min = 0, max = 100000, value = 20000, step = 5000, pre = "\u00a3")),
              column(6, sliderInput(ns("rcControl"), "How much independence do you need (1 = happy under someone else's permissions, 5 = fully independent)",
                       min = 1, max = 5, value = 3, step = 1))
            ),
            uiOutput(ns("rcRecommendation"))
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("2. Track Record Plan", icon = icon("chart-line"),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "What you can legally do right now",
              collapsible = TRUE, collapsed = FALSE,
            tags$p(paste0(
              "Trade your own capital, and (only under narrow, lawyer-checked exemptions) very close friends/",
              "family. A genuine 12+ month track record across different market regimes, honestly logged, is ",
              "worth more to a family office than any pitch deck \u2014 which is exactly what the Unit 3 Live ",
              "Plan Signals tab is for: its regime engine, trade log and Sharpe/Sortino dashboard are the real ",
              "track-record tools, not just coursework."
            ), style = "font-size:13px; color:#4a5560; line-height:1.65; margin:0;")
          ),
          box(width = 12, status = "info", solidHeader = TRUE, title = "0\u201312 month roadmap",
            tags$ol(style = "font-size:12.8px; color:#4a5560; padding-left:20px; line-height:2;",
              tags$li(tags$b("Months 1\u20133: "), "Finalise the systematic process across multiple strategies (see the Portfolio Optimizer tab) and start logging every trade, good and bad, without exception."),
              tags$li(tags$b("Months 3\u20136: "), "Widen beyond a single asset/strategy pair \u2014 a real allocator wants to see genuinely diversified, low-correlation return streams, not one trade idea repeated."),
              tags$li(tags$b("Months 6\u201312: "), "Maintain the record through at least one adverse regime (a real drawdown, not just a winning streak) \u2014 how you behave in it is the actual product you're selling."),
              tags$li(tags$b("Month 12+: "), "Take the audited (by you, honestly) track record, the Sharpe/Sortino/drawdown numbers, and the deviation log to a compliance consultant to scope the regulatory path.")
            )
          ),
          box(width = 12, status = "info", solidHeader = TRUE, title = "Where are you in the 12 months?",
            dateInput(ns("trStartDate"), "Track record start date", value = Sys.Date()),
            uiOutput(ns("trProgress"))
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("3. Portfolio Optimizer", icon = icon("chart-pie"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
              title = "About this simulator",
            tags$p(paste0(
              "A real multi-client allocation needs genuinely uncorrelated strategies, not one idea sized up. ",
              "Enter your own expected return/volatility assumptions and correlations below (defaults are a ",
              "plausible illustrative starting point, not a forecast), and compare four ways of weighting them: ",
              "equal weight, inverse-volatility, true risk parity (equalised risk contribution), and max-Sharpe."
            ), style = "font-size:12.5px; color:#7d4a00; margin:0; line-height:1.6;")
          ),
          fluidRow(
            box(width = 6, status = "info", solidHeader = TRUE, title = "Strategy assumptions (annualised, %)",
              tags$p("Double-click a cell to edit. Add a row for another strategy.", style = "font-size:11px; color:#8a97a0;"),
              DT::dataTableOutput(ns("hfAssumptions")),
              actionButton(ns("hfAddStrategy"), "Add Strategy", icon = icon("plus"), class = "btn-sm", style = "margin-top:8px;")
            ),
            box(width = 6, status = "info", solidHeader = TRUE, title = "Correlation matrix",
              tags$p("Double-click a cell to edit. Diagonal is always 1.", style = "font-size:11px; color:#8a97a0;"),
              DT::dataTableOutput(ns("hfCorrelation")),
              numericInput(ns("hfRiskFree"), "Risk-free rate (%)", value = 4, min = 0, max = 20, step = 0.25)
            )
          ),
          box(width = 12, status = "success", solidHeader = TRUE, title = "Allocation comparison",
            DT::dataTableOutput(ns("hfWeightsTable")),
            fluidRow(
              column(6, withSpinner(plotlyOutput(ns("hfWeightsChart"), height = "300px"))),
              column(6, withSpinner(plotlyOutput(ns("hfFrontierChart"), height = "300px")))
            ),
            u3_context(tags$b("Reading this: "), "risk parity equalises each strategy's ",
                       tags$i("contribution to portfolio risk"), " rather than its capital weight \u2014 low-vol, ",
                       "low-correlation strategies get sized up. Max-Sharpe instead directly maximises risk-",
                       "adjusted return given your assumptions, which makes it the most sensitive of the four ",
                       "to how accurate those assumptions actually are.")
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("4. Business Structure", icon = icon("building-columns"),
          box(width = 12, status = "info", solidHeader = TRUE, title = "Three realistic routes",
            DT::dataTableOutput(ns("hfStructureTable"))
          ),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Decision inputs",
            fluidRow(
              column(6, sliderInput(ns("bsCapital"), "Capital available for setup (\u00a3)",
                       min = 0, max = 100000, value = 15000, step = 5000, pre = "\u00a3")),
              column(6, sliderInput(ns("bsAUMInterest"), "Realistic AUM interest lined up already (\u00a3, approx.)",
                       min = 0, max = 20000000, value = 500000, step = 100000, pre = "\u00a3"))
            ),
            uiOutput(ns("bsRecommendation"))
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("5. Technology Roadmap", icon = icon("server"),
          box(width = 12, status = "info", solidHeader = TRUE, title = "Prototype (this app) vs. production requirement",
            DT::dataTableOutput(ns("hfTechTable"))
          ),
          box(width = 12, status = "warning", solidHeader = FALSE,
            tags$p(paste0(
              "The underlying discipline carries over directly \u2014 the trade-log-everything habit built in Unit ",
              "3 is exactly what a real audit trail requires, just against institutional infrastructure instead ",
              "of a local R session."
            ), style = "font-size:12.5px; color:#7d4a00; margin:0;")
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("6. Financial Projections", icon = icon("sack-dollar"),
          box(width = 12, status = "info", solidHeader = TRUE, title = "Assumptions",
            fluidRow(
              column(4, numericInput(ns("fpStartAUM"), "Starting AUM (\u00a3)", value = 2000000, step = 100000)),
              column(4, numericInput(ns("fpNewCapital"), "New capital raised per year (\u00a3)", value = 3000000, step = 100000)),
              column(4, sliderInput(ns("fpYears"), "Projection horizon (years)", min = 3, max = 10, value = 5))
            ),
            fluidRow(
              column(3, numericInput(ns("fpGrossReturn"), "Expected gross return (%/yr)", value = 12, step = 0.5)),
              column(3, numericInput(ns("fpMgmtFee"), "Management fee (%/yr)", value = 1.5, step = 0.1)),
              column(3, numericInput(ns("fpPerfFee"), "Performance fee (%)", value = 20, step = 1)),
              column(3, numericInput(ns("fpHurdle"), "Hurdle rate (%/yr)", value = 5, step = 0.5))
            ),
            numericInput(ns("fpCostBase"), "Annual operating cost base (\u00a3) \u2014 compliance, admin, data, salaries",
                         value = 150000, step = 10000)
          ),
          box(width = 12, status = "success", solidHeader = TRUE, title = "Projection",
            uiOutput(ns("fpSummary")),
            fluidRow(
              column(6, withSpinner(plotlyOutput(ns("fpAumChart"), height = "280px"))),
              column(6, withSpinner(plotlyOutput(ns("fpRevenueChart"), height = "280px")))
            ),
            DT::dataTableOutput(ns("fpTable")),
            u3_context(tags$b("Simplification note: "), "this collapses the whole fund into a single NAV series ",
                       "with one high-water mark \u2014 a real fund administrator tracks this per investor, per ",
                       "subscription. Fine for rough business planning; not a substitute for real fund accounting.")
          )
        )
      )
    )
  )
}

# ===========================================================================
# SERVER
# ===========================================================================

hedge_fund_strategy_server <- function(id, data_manager = NULL) {
  moduleServer(id, function(input, output, session) {

    # -- Tab 1: Reality Check --
    output$rcRecommendation <- renderUI({
      cap <- input$rcCapital %||% 20000
      ctrl <- input$rcControl %||% 3
      rec <- if (cap < 15000) {
        list(name = "Appointed Representative (AR)", reason = "Setup capital is below typical full authorisation costs \u2014 an AR arrangement under an existing principal firm is the realistic entry point.")
      } else if (ctrl <= 2) {
        list(name = "Appointed Representative (AR)", reason = "You're comfortable operating under someone else's permissions/oversight \u2014 AR gets you trading client money fastest.")
      } else if (cap < 50000 || ctrl == 3) {
        list(name = "Managed Accounts (discretionary)", reason = "A lighter regulatory lift than a full fund, while keeping more independence than an AR arrangement \u2014 each client keeps their own account.")
      } else {
        list(name = "Full AIFM Authorisation + Fund Vehicle", reason = "You have both meaningful setup capital and want full independence \u2014 the real \"hedge fund\" structure, only sensible once real AUM interest is lined up.")
      }
      tags$div(style = "margin-top:10px; padding:14px; background:#eef7f5; border-left:3px solid #008A82; border-radius:0 3px 3px 0;",
        tags$div(paste0("Suggested starting point: ", rec$name), style = "font-weight:700; color:#002C3C; font-size:14px;"),
        tags$div(rec$reason, style = "font-size:12.5px; color:#4a5560; margin-top:6px;")
      )
    })

    # -- Tab 2: Track Record Plan --
    output$trProgress <- renderUI({
      req(input$trStartDate)
      days_elapsed <- as.numeric(Sys.Date() - input$trStartDate)
      months_elapsed <- round(days_elapsed / 30.44, 1)
      pct_to_12mo <- min(100, max(0, months_elapsed / 12 * 100))
      tagList(
        fluidRow(
          column(4, u3_metric_tile("Days into track record", max(0, round(days_elapsed)), "since start date")),
          column(4, u3_metric_tile("Months elapsed", months_elapsed, "of 12 minimum")),
          column(4, u3_metric_tile("Progress to 12mo milestone", paste0(round(pct_to_12mo), "%"),
                                    "keep logging through at least one drawdown",
                                    color = if (pct_to_12mo >= 100) "#1e7a46" else "#9c6b26"))
        )
      )
    })

    # -- Tab 3: Portfolio Optimizer --
    hf_assumptions <- reactiveVal(data.frame(
      Strategy = c("Trend Following", "Mean Reversion", "Carry", "Short Volatility"),
      `Return %` = c(10, 8, 6, 12), `Vol %` = c(15, 10, 6, 20),
      check.names = FALSE, stringsAsFactors = FALSE
    ))
    hf_correlation <- reactiveVal({
      m <- matrix(c(
        1.00, -0.30, 0.10, 0.20,
       -0.30,  1.00, 0.05, -0.10,
        0.10,  0.05, 1.00, 0.15,
        0.20, -0.10, 0.15, 1.00), nrow = 4, byrow = TRUE)
      rownames(m) <- colnames(m) <- c("Trend Following", "Mean Reversion", "Carry", "Short Volatility")
      as.data.frame(m, check.names = FALSE)
    })

    output$hfAssumptions <- DT::renderDataTable({
      DT::datatable(hf_assumptions(), rownames = FALSE, editable = TRUE,
                    options = list(dom = 't', paging = FALSE, ordering = FALSE))
    }, server = FALSE)
    hf_assump_proxy <- DT::dataTableProxy("hfAssumptions")
    observeEvent(input$hfAssumptions_cell_edit, {
      info <- input$hfAssumptions_cell_edit
      df <- hf_assumptions()
      df[info$row, info$col + 1] <- DT::coerceValue(info$value, df[info$row, info$col + 1])
      hf_assumptions(df)
      DT::replaceData(hf_assump_proxy, df, resetPaging = FALSE, rownames = FALSE)
    })
    observeEvent(input$hfAddStrategy, {
      df <- hf_assumptions()
      new_name <- paste("Strategy", nrow(df) + 1)
      df[nrow(df) + 1, ] <- list(new_name, 8, 12)
      hf_assumptions(df)

      cm <- hf_correlation()
      cm[[new_name]] <- 0
      cm[new_name, ] <- 0
      cm[new_name, new_name] <- 1
      hf_correlation(cm)
    })

    output$hfCorrelation <- DT::renderDataTable({
      DT::datatable(hf_correlation(), editable = TRUE, options = list(dom = 't', paging = FALSE, ordering = FALSE))
    }, server = FALSE)
    hf_corr_proxy <- DT::dataTableProxy("hfCorrelation")
    observeEvent(input$hfCorrelation_cell_edit, {
      info <- input$hfCorrelation_cell_edit
      df <- hf_correlation()
      df[info$row, info$col] <- DT::coerceValue(info$value, df[info$row, info$col])
      hf_correlation(df)
      DT::replaceData(hf_corr_proxy, df, resetPaging = FALSE)
    })

    hf_computed <- reactive({
      assump <- hf_assumptions()
      req(nrow(assump) >= 2)
      mu <- assump$`Return %` / 100
      sigma <- assump$`Vol %` / 100
      names(mu) <- names(sigma) <- assump$Strategy
      corr <- as.matrix(hf_correlation())
      storage.mode(corr) <- "numeric"
      rf <- (input$hfRiskFree %||% 4) / 100

      Sigma <- hf_build_covariance(sigma, corr)
      w_eq  <- rep(1 / length(mu), length(mu))
      w_ivp <- (1 / sigma) / sum(1 / sigma)
      w_rp  <- hf_solve_risk_parity(mu, Sigma)
      w_ms  <- hf_solve_max_sharpe(mu, Sigma, rf)

      list(strategies = assump$Strategy, mu = mu, Sigma = Sigma, rf = rf,
           weights = list(`Equal Weight` = w_eq, `Inverse Volatility` = w_ivp,
                           `Risk Parity` = w_rp, `Max Sharpe` = w_ms))
    })

    output$hfWeightsTable <- DT::renderDataTable({
      hc <- hf_computed()
      rows <- lapply(names(hc$weights), function(method) {
        w <- hc$weights[[method]]
        s <- hf_port_stats(w, hc$mu, hc$Sigma, hc$rf)
        c(list(Method = method), setNames(as.list(round(w * 100, 1)), hc$strategies),
          list(`Return %` = round(s$ret * 100, 2), `Vol %` = round(s$vol * 100, 2), Sharpe = round(s$sharpe, 3)))
      })
      df <- do.call(rbind.data.frame, lapply(rows, function(r) as.data.frame(r, check.names = FALSE)))
      DT::datatable(df, rownames = FALSE, options = list(dom = 't', paging = FALSE))
    }, server = FALSE)

    output$hfWeightsChart <- renderPlotly({
      hc <- hf_computed()
      df <- do.call(rbind, lapply(names(hc$weights), function(m) {
        data.frame(Method = m, Strategy = hc$strategies, Weight = hc$weights[[m]] * 100)
      }))
      plot_ly(df, x = ~Method, y = ~Weight, color = ~Strategy, type = "bar") %>%
        layout(barmode = "stack", yaxis = list(title = "Weight (%)"), title = list(text = "Allocation by method", font = list(size = 12)),
               plot_bgcolor = "white", paper_bgcolor = "white", legend = list(font = list(size = 9)))
    })

    output$hfFrontierChart <- renderPlotly({
      hc <- hf_computed()
      rp <- hf_random_portfolios(hc$mu, hc$Sigma, 400)
      pts <- do.call(rbind, lapply(names(hc$weights), function(m) {
        s <- hf_port_stats(hc$weights[[m]], hc$mu, hc$Sigma, hc$rf)
        data.frame(Method = m, vol = s$vol, ret = s$ret)
      }))
      plot_ly() %>%
        add_trace(data = rp, x = ~(vol*100), y = ~(ret*100), type = "scatter", mode = "markers",
                  marker = list(color = "#d8dee3", size = 5), name = "Random portfolios") %>%
        add_trace(data = pts, x = ~(vol*100), y = ~(ret*100), type = "scatter", mode = "markers+text",
                  text = ~Method, textposition = "top center", textfont = list(size = 9),
                  marker = list(color = "#008A82", size = 11, symbol = "diamond"), name = "Your 4 methods") %>%
        layout(xaxis = list(title = "Volatility (%)"), yaxis = list(title = "Return (%)"),
               title = list(text = "Illustrative efficient frontier", font = list(size = 12)),
               showlegend = FALSE, plot_bgcolor = "white", paper_bgcolor = "white")
    })

    # -- Tab 4: Business Structure --
    output$hfStructureTable <- DT::renderDataTable({
      df <- data.frame(
        Route = c("Appointed Representative (AR)", "Managed Accounts (discretionary)", "Full AIFM + Fund Vehicle"),
        `Typical Cost` = c("Low (principal firm's onboarding fee)", "Low\u2013Medium (broker/platform setup)", "\u00a330,000\u2013\u00a375,000+"),
        `Typical Timeline` = c("Weeks\u2013few months", "1\u20133 months", "6\u201312 months"),
        `Independence` = c("Low \u2014 under principal's permissions", "Medium \u2014 your process, client keeps own account", "High \u2014 your own authorisation"),
        `Best For` = c("Fastest legal route to client money", "Family offices wanting a fund-of-one before committing", "Real scale, once AUM interest is lined up"),
        check.names = FALSE, stringsAsFactors = FALSE
      )
      DT::datatable(df, rownames = FALSE, options = list(dom = 't', paging = FALSE))
    }, server = FALSE)

    output$bsRecommendation <- renderUI({
      cap <- input$bsCapital %||% 15000
      aum <- input$bsAUMInterest %||% 500000
      rec <- if (aum < 250000) {
        "With interest this early-stage, an AR arrangement or informal managed account keeps costs proportionate until real commitments materialise."
      } else if (cap >= 30000 && aum >= 2000000) {
        "You likely have both the capital and the AUM interest to justify starting the full AIFM authorisation process now, in parallel with onboarding first clients as managed accounts."
      } else {
        "Managed accounts are the sensible middle path here \u2014 enough AUM interest to be worth formalising, without yet committing to full authorisation costs."
      }
      tags$div(style = "margin-top:10px; padding:14px; background:#eef7f5; border-left:3px solid #008A82; border-radius:0 3px 3px 0; font-size:12.5px; color:#2d4a45;",
        rec)
    })

    # -- Tab 5: Technology Roadmap --
    output$hfTechTable <- DT::renderDataTable({
      df <- data.frame(
        Dimension = c("Data feeds", "Execution", "Custody & reconciliation", "Monitoring", "Compliance & audit trail"),
        `This App (Prototype)` = c("Yahoo Finance / manual entry", "Manual (signal-and-log, no execution)",
                                     "None \u2014 no real assets held", "Live signal dashboard, single session",
                                     "Session trade log, CSV export"),
        `Production Requirement` = c("Institutional feed (Bloomberg/Refinitiv or broker API)", "Broker/prime-broker execution API with proper order management",
                                       "Independent fund administrator + prime broker \u2014 never self-custody client assets",
                                       "Hosted, monitored, redundant system with alerting", "Immutable, timestamped audit log meeting regulatory retention rules"),
        check.names = FALSE, stringsAsFactors = FALSE
      )
      DT::datatable(df, rownames = FALSE, options = list(dom = 't', paging = FALSE))
    }, server = FALSE)

    # -- Tab 6: Financial Projections --
    fp_results <- reactive({
      hf_project_business(
        start_aum = input$fpStartAUM %||% 2000000,
        annual_new_capital = input$fpNewCapital %||% 3000000,
        gross_return_pct = (input$fpGrossReturn %||% 12) / 100,
        mgmt_fee_pct = (input$fpMgmtFee %||% 1.5) / 100,
        perf_fee_pct = (input$fpPerfFee %||% 20) / 100,
        hurdle_pct = (input$fpHurdle %||% 5) / 100,
        annual_cost_base = input$fpCostBase %||% 150000,
        years = input$fpYears %||% 5
      )
    })

    output$fpSummary <- renderUI({
      res <- fp_results()
      breakeven <- if (any(res$NetProfit > 0)) min(res$Year[res$NetProfit > 0]) else NA
      fluidRow(
        column(3, u3_metric_tile("Breakeven year", if (is.na(breakeven)) "Beyond horizon" else paste0("Year ", breakeven), "first year net profit turns positive")),
        column(3, u3_metric_tile("Ending AUM", paste0("\u00a3", format(round(tail(res$AUM_End, 1)), big.mark = ",")), paste0("after ", nrow(res), " years"))),
        column(3, u3_metric_tile("Cumulative net profit", paste0("\u00a3", format(round(sum(res$NetProfit)), big.mark = ",")), "sum across the horizon",
                                  color = if (sum(res$NetProfit) >= 0) "#1e7a46" else "#c0392b")),
        column(3, u3_metric_tile("Final year revenue", paste0("\u00a3", format(round(tail(res$TotalRevenue, 1)), big.mark = ",")), "management + performance fees"))
      )
    })

    output$fpAumChart <- renderPlotly({
      res <- fp_results()
      plot_ly(res, x = ~Year, y = ~AUM_End, type = "scatter", mode = "lines+markers",
              line = list(color = "#008A82", width = 2.5), fill = "tozeroy", fillcolor = "rgba(0,138,130,0.08)") %>%
        layout(title = list(text = "AUM growth", font = list(size = 12)), yaxis = list(title = "AUM (\u00a3)"),
               plot_bgcolor = "white", paper_bgcolor = "white")
    })

    output$fpRevenueChart <- renderPlotly({
      res <- fp_results()
      plot_ly(res, x = ~Year, y = ~MgmtFee, type = "bar", name = "Management Fee", marker = list(color = "#002C3C")) %>%
        add_trace(y = ~PerfFee, name = "Performance Fee", marker = list(color = "#008A82")) %>%
        layout(barmode = "stack", title = list(text = "Revenue composition", font = list(size = 12)),
               yaxis = list(title = "Revenue (\u00a3)"), plot_bgcolor = "white", paper_bgcolor = "white")
    })

    output$fpTable <- DT::renderDataTable({
      res <- fp_results()
      res[] <- lapply(res, function(col) if (is.numeric(col)) round(col, 0) else col)
      DT::datatable(res, rownames = FALSE, options = list(dom = 't', paging = FALSE))
    }, server = FALSE)

  })
}
