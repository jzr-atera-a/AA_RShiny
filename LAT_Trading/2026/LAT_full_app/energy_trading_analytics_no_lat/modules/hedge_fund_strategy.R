# modules/hedge_fund_strategy.R
#
# "Strategy for Business > Hedge Fund / Wealth" - turns the business-planning
# discussion (regulatory pathway, portfolio allocation, business structure,
# technology roadmap, financial projections) into working tools rather than
# static reading material. Energy-commodity focused, to match the rest of this
# app (Commodities for Mobility, External Sources > Satellite Data).
#
# Built from two sources: an earlier standalone version of this tab (its
# optimisation and business-projection engines, kept where they were sound)
# and improvements made on review - see the "IMPROVEMENTS" note below.
#
# IMPORTANT: nothing here is legal, regulatory, tax or investment advice. Every
# figure is an illustrative planning assumption, not a forecast. Regulatory
# facts link to the FCA's own pages where they were checked; figures that
# could not be verified are labelled as unverified placeholders. Anyone acting
# on this must get advice from an FCA-authorised compliance consultant or
# financial services lawyer first.
#
# IMPROVEMENTS over the first version of this tab:
#   * Correlation matrix is validated on every edit (clamped to [-1, 1],
#     symmetrised, forced to unit diagonal, and repaired to the nearest valid
#     positive-semi-definite matrix if the edits describe an impossible
#     structure) - an editable matrix otherwise silently produces a plausible-
#     looking but meaningless answer. The user is told when this happens.
#   * Sharpe uses a risk-free rate (input), and max-Sharpe is multi-start.
#   * Strategies can be added/removed, correlation grid resizes with them.
#   * Risk-contribution chart, so "risk parity equalises risk" is visible.
#   * Business projection adds an operating cost base, new capital raised per
#     year, breakeven year, the AUM at which management fees alone cover costs,
#     a stress year (shows the high-water mark suppressing performance fees),
#     and a return x capital sensitivity grid.
#   * Business Structure corrected: discretionary "managed accounts" are still
#     a regulated activity; adds the small authorised AIFM route and
#     prudential-capital point, with FCA source links.

# ===========================================================================
# PURE LOGIC - portfolio optimisation and business projection engines
# (base R only: no new package dependencies)
# ===========================================================================

hf_softmax <- function(x) { e <- exp(x - max(x)); e / sum(e) }

# Turns whatever is in the editable correlation grid into a valid correlation
# matrix. Returns list(corr, adjusted). "adjusted" is TRUE only when the edits
# described an impossible structure (not positive semi-definite) and had to be
# repaired - simple tidying (symmetrising, clamping) is not flagged.
hf_make_valid_corr <- function(corr) {
  m <- as.matrix(corr)
  storage.mode(m) <- "numeric"
  dn <- dimnames(m)
  m[is.na(m)] <- 0
  m <- pmax(pmin(m, 1), -1)
  m <- (m + t(m)) / 2
  diag(m) <- 1

  adjusted <- FALSE
  ev <- eigen(m, symmetric = TRUE)
  # Only repair when clearly NOT positive semi-definite. A zero eigenvalue is a
  # legitimate (degenerate) matrix - e.g. two perfectly correlated strategies,
  # rho = 1 - and must not be reported to the user as an impossible structure.
  if (min(ev$values) < -1e-8) {
    vals <- pmax(ev$values, 1e-6)
    m2 <- ev$vectors %*% diag(vals, nrow = length(vals)) %*% t(ev$vectors)
    d <- sqrt(diag(m2))
    m2 <- m2 / outer(d, d)
    m2 <- (m2 + t(m2)) / 2
    diag(m2) <- 1
    m <- m2
    adjusted <- TRUE
  }
  dimnames(m) <- dn
  list(corr = m, adjusted = adjusted)
}

hf_build_covariance <- function(sigma, corr) outer(sigma, sigma) * corr

hf_port_stats <- function(w, mu, Sigma, rf = 0) {
  ret <- sum(w * mu)
  vol <- sqrt(max(0, as.numeric(t(w) %*% Sigma %*% w)))
  list(ret = ret, vol = vol, sharpe = if (vol > 1e-12) (ret - rf) / vol else NA_real_)
}

hf_risk_contributions <- function(w, Sigma) {
  port_var <- as.numeric(t(w) %*% Sigma %*% w)
  if (port_var <= 0) return(rep(0, length(w)))
  as.numeric(w * (Sigma %*% w)) / port_var
}

# Risk parity: weights such that every strategy contributes 1/n of total risk.
# Solved directly on that objective (squared deviation of each risk
# contribution from 1/n) over a softmax parameterisation, which keeps weights
# long-only and summing to 1 without a quadratic-programming solver. Starts
# from inverse-volatility weights, which is already close for low correlations.
hf_solve_risk_parity <- function(Sigma) {
  n <- nrow(Sigma)
  start <- -log(sqrt(diag(Sigma)))
  obj <- function(par) sum((hf_risk_contributions(hf_softmax(par), Sigma) - 1 / n)^2)
  fit <- tryCatch(optim(start, obj, method = "BFGS", control = list(maxit = 3000, reltol = 1e-14)),
                  error = function(e) NULL)
  if (is.null(fit)) return(rep(1 / n, n))
  hf_softmax(fit$par)
}

# Max-Sharpe (long-only). Multi-start (equal weight plus one start tilted to
# each single strategy) and keeps the best: a single BFGS start can settle in a
# poor local optimum when returns/vols are far apart.
hf_solve_max_sharpe <- function(mu, Sigma, rf = 0) {
  n <- length(mu)
  obj <- function(par) {
    s <- hf_port_stats(hf_softmax(par), mu, Sigma, rf)
    if (is.na(s$sharpe)) return(1e6)
    -s$sharpe
  }
  starts <- c(list(rep(0, n)), lapply(seq_len(n), function(i) { z <- rep(-2, n); z[i] <- 2; z }))
  fits <- lapply(starts, function(s0)
    tryCatch(optim(s0, obj, method = "BFGS", control = list(maxit = 3000)), error = function(e) NULL))
  fits <- Filter(function(f) !is.null(f) && is.finite(f$value), fits)
  if (length(fits) == 0) return(rep(1 / n, n))
  best <- fits[[which.min(vapply(fits, function(f) f$value, numeric(1)))]]
  hf_softmax(best$par)
}

# Uniformly random long-only portfolios (normalised exponentials are uniform on
# the weight simplex) for the illustrative frontier cloud.
hf_random_portfolios <- function(mu, Sigma, n_portfolios = 1500) {
  n <- length(mu)
  do.call(rbind, lapply(seq_len(n_portfolios), function(i) {
    w <- rexp(n); w <- w / sum(w)
    s <- hf_port_stats(w, mu, Sigma)
    data.frame(vol = s$vol, ret = s$ret)
  }))
}

# Simplified NAV-index business projection: management fee, plus performance
# fee above BOTH the high-water mark and the hurdle. Collapses the whole fund
# into one NAV series - the standard planning simplification; a real fund
# administrator does this per investor, per subscription.
# gross_return_pct may be a single number or a vector (one per year), which is
# how the stress-year scenario is expressed.
hf_project_business <- function(start_aum, annual_new_capital, gross_return_pct,
                                 mgmt_fee_pct, perf_fee_pct, hurdle_pct,
                                 annual_cost_base, years = 5) {
  gross_vec <- rep_len(gross_return_pct, years)
  nav <- 100; hwm <- 100; aum <- start_aum
  out <- vector("list", years)
  for (yr in seq_len(years)) {
    aum_start <- aum
    gross_nav <- nav * (1 + gross_vec[yr])
    mgmt_fee_amt <- aum_start * mgmt_fee_pct

    hurdle_nav <- nav * (1 + hurdle_pct)
    perf_pct <- 0
    if (gross_nav > hwm && gross_nav > hurdle_nav) {
      excess_nav <- gross_nav - max(hwm, hurdle_nav)
      perf_pct <- (excess_nav / nav) * perf_fee_pct
    }
    perf_fee_amt <- aum_start * perf_pct

    net_return_pct <- gross_vec[yr] - mgmt_fee_pct - perf_pct
    net_nav <- nav * (1 + net_return_pct)
    hwm <- max(hwm, net_nav)

    total_revenue <- mgmt_fee_amt + perf_fee_amt
    aum_end <- aum_start * (1 + net_return_pct) + annual_new_capital

    out[[yr]] <- data.frame(Year = yr, GrossReturn = gross_vec[yr], AUM_Start = aum_start, AUM_End = aum_end,
                            MgmtFee = mgmt_fee_amt, PerfFee = perf_fee_amt, TotalRevenue = total_revenue,
                            NetProfit = total_revenue - annual_cost_base, NAV = net_nav, HWM = hwm)
    nav <- net_nav; aum <- aum_end
  }
  do.call(rbind, out)
}

# Cumulative net profit over the horizon for every (gross return, new capital)
# pair - a business-planning sensitivity grid, not a forecast.
hf_sensitivity_grid <- function(returns, new_caps, start_aum, mgmt, perf, hurdle, cost, years) {
  m <- matrix(NA_real_, nrow = length(returns), ncol = length(new_caps))
  for (i in seq_along(returns)) for (j in seq_along(new_caps)) {
    m[i, j] <- sum(hf_project_business(start_aum, new_caps[j], returns[i], mgmt, perf, hurdle, cost, years)$NetProfit)
  }
  m
}

# AUM at which the management fee alone covers the operating cost base.
hf_breakeven_aum <- function(cost_base, mgmt_fee_pct) if (mgmt_fee_pct > 0) cost_base / mgmt_fee_pct else NA_real_

# Fixed palette so each strategy keeps its colour across charts, and so plotly never
# runs out of colours (its default palette needs at least 3 levels).
hf_palette <- c("#002C3C", "#008A82", "#e67e22", "#8e44ad", "#2980b9", "#c0392b", "#7f8c8d", "#27ae60")

hf_gbp <- function(x) paste0("\u00a3", format(round(x), big.mark = ",", scientific = FALSE))

# ===========================================================================
# UI
# ===========================================================================

hedge_fund_strategy_ui <- function(id) {
  ns <- NS(id)

  tagList(
    ui_banner("Strategy for Business", "Hedge Fund / Wealth",
              "A business-planning simulator for turning this app's signal and risk work into a managed-money offering, scoped to energy commodities."),

    fluidRow(
      box(width = 12, status = "danger", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
        title = "Not legal, regulatory, tax or investment advice",
        tags$p(paste0(
          "Everything on this tab is a planning and simulation aid. Every figure is an illustrative assumption, not a ",
          "forecast. Managing other people's money without authorisation is a criminal offence under FSMA 2000 in the ",
          "UK. Regulatory facts link to the FCA's own pages where they were checked; anything marked unverified could ",
          "not be confirmed and is a placeholder. Get advice from an FCA-authorised compliance consultant or financial ",
          "services lawyer before acting on any of it."
        ), style = "font-size:12.5px; color:#7d1a1a; margin:0; line-height:1.6;")
      )
    ),

    fluidRow(
      tabBox(id = ns("subtabs"), width = 12, selected = "1. Reality Check",

        # ---------------------------------------------------------------
        tabPanel("1. Reality Check", icon = icon("scale-balanced"),
          box(width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE, collapsed = FALSE,
              title = "Positioning: an energy commodities specialist, not a generalist",
            tags$p(paste0(
              "This plan is deliberately scoped to energy commodities (WTI crude and natural gas) rather than a generic ",
              "multi-asset offering. A specialist is easier to explain to a family office and easier to build a ",
              "differentiated edge in, and it lines up with the rest of this app: External Sources holds the Satellite Data ",
              "map and Data Enrichment (weather degree days, storage-tank shadows, the EIA release calendar), and the ",
              "Extended Indicators and Risk & Portfolio Analytics groups would supply the signals and risk reporting."
            ), style = "font-size:12.5px; color:#4a5560; line-height:1.65; margin:0;")
          ),
          box(width = 12, status = "warning", solidHeader = TRUE, title = "The regulatory gate", collapsible = TRUE, collapsed = FALSE,
            tags$p(paste0(
              "You cannot legally manage other people's money \u2014 even friends and family beyond narrow exemptions \u2014 ",
              "without authorisation or an Appointed Representative arrangement. What the FCA's own pages confirm: an ",
              "authorised AIFM application falls in application-fee pricing category 6, as do most MiFID investment ",
              "managers; authorised AIFMs must hold prudential capital (\u201cown funds\u201d, including an amount linked to ",
              "assets under management) and liquid assets; and there is a lighter small authorised AIFM route below the ",
              "FCA's AuM thresholds."
            ), style = "font-size:13px; color:#4a5560; line-height:1.65;"),
            tags$p(HTML(paste0(
              "<b>Unverified planning placeholders</b> (commonly quoted, could not be confirmed here): total setup cost of ",
              "roughly \u00a330,000\u2013\u00a375,000, a 6\u201312 month timeline, and at least two approved Senior Managers ",
              "(compliance oversight and MLRO). Treat these as a budget starting point to replace with a real quote. The ",
              "FCA's AIFM regime is also under review, so tiers and thresholds may change."
            )), style = "font-size:12.5px; color:#7d4a00; line-height:1.6; margin:0;"),
            tags$p(style = "margin:10px 0 0 0; font-size:12px;",
              "FCA sources: ",
              tags$a(href = "https://www.fca.org.uk/firms/authorisation/apply/fees", target = "_blank", "application fees"), " \u00b7 ",
              tags$a(href = "https://www.fca.org.uk/firms/aifmd/apply-authorised-aifm", target = "_blank", "apply to be an authorised AIFM"), " \u00b7 ",
              tags$a(href = "https://www.fca.org.uk/firms/aifmd/apply-registered-aifm", target = "_blank", "small registered AIFM"))
          ),
          box(width = 12, status = "info", solidHeader = TRUE, title = "Which path fits you \u2014 a rough decision helper",
            fluidRow(
              column(6, sliderInput(ns("rcCapital"), "Capital available for setup/legal costs (\u00a3)",
                       min = 0, max = 100000, value = 20000, step = 5000, pre = "\u00a3")),
              column(6, sliderInput(ns("rcControl"), "How much independence do you need? (1 = happy under someone else's permissions, 5 = fully independent)",
                       min = 1, max = 5, value = 3, step = 1))
            ),
            uiOutput(ns("rcRecommendation"))
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("2. Track Record Plan", icon = icon("chart-line"),
          box(width = 12, status = "primary", solidHeader = TRUE, collapsible = TRUE, collapsed = FALSE,
              title = "What you can legally do right now",
            tags$p(paste0(
              "Trade your own capital, and (only under narrow, lawyer-checked exemptions) very close friends and family. ",
              "A genuine 12+ month track record across different market regimes, honestly logged, is worth more to a ",
              "family office than any pitch deck. The signals behind it can come from the Extended Indicators and ",
              "Technical Indicators tabs, weather and release-timing context from External Sources > Data Enrichment, ",
              "and the risk reporting from Risk & Portfolio Analytics."
            ), style = "font-size:13px; color:#4a5560; line-height:1.65; margin:0;")
          ),
          box(width = 12, status = "info", solidHeader = TRUE, title = "0\u201312 month roadmap",
            tags$ol(style = "font-size:12.8px; color:#4a5560; padding-left:20px; line-height:2;",
              tags$li(tags$b("Months 1\u20133: "), "Finalise the systematic process across several energy strategies (see the Portfolio Optimizer tab) and start logging every trade, good and bad, without exception."),
              tags$li(tags$b("Months 3\u20136: "), "Widen beyond WTI alone into natural gas and spread/carry strategies \u2014 an allocator wants genuinely diversified, low-correlation return streams within the energy complex, not one idea repeated."),
              tags$li(tags$b("Months 6\u201312: "), "Maintain the record through at least one adverse regime (a real drawdown, not just a winning streak) \u2014 how you behave in it is the actual product you are selling."),
              tags$li(tags$b("Month 12+: "), "Take the track record, the risk numbers and the deviation log to a compliance consultant to scope the regulatory path.")
            )
          ),
          fluidRow(
            box(width = 6, status = "info", solidHeader = TRUE, title = "Where are you in the 12 months?",
              dateInput(ns("trStartDate"), "Track record start date", value = Sys.Date()),
              uiOutput(ns("trProgress"))
            ),
            box(width = 6, status = "success", solidHeader = TRUE, title = "Readiness checklist",
              checkboxGroupInput(ns("trChecklist"), NULL, choices = c(
                "Every trade logged with entry, exit and reasoning",
                "Position sizing follows a written fixed-risk rule",
                "At least two uncorrelated energy strategies running",
                "Track record has survived a real drawdown",
                "Risk metrics (Sharpe, Sortino, drawdown) reported monthly",
                "Compliance consultant consulted on the regulatory route")),
              uiOutput(ns("trChecklistScore"))
            )
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("3. Portfolio Optimizer", icon = icon("chart-pie"),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
              title = "About this simulator",
            tags$p(paste0(
              "A real multi-client allocation needs genuinely uncorrelated strategies, not one idea sized up. The defaults ",
              "are four energy strategies: trend following on WTI; a weather-driven seasonal approach on natural gas (the ",
              "Data Enrichment > Weather Patterns tab supplies live heating and cooling degree days for it); crack-spread ",
              "carry; and mean reversion around EIA inventory surprises (Data Enrichment > Release Calendar shows exactly ",
              "when those reports land). Edit the return, volatility and ",
              "correlation assumptions (illustrative starting points, not a forecast), then compare four ways of ",
              "weighting them: equal weight, inverse volatility, risk parity (equalised risk contribution), and max-Sharpe."
            ), style = "font-size:12.5px; color:#7d4a00; margin:0; line-height:1.6;")
          ),
          fluidRow(
            box(width = 6, status = "info", solidHeader = TRUE, title = "Strategy assumptions (annualised, %)",
              tags$p("Double-click a cell to edit.", style = "font-size:11px; color:#6b7883;"),
              DT::dataTableOutput(ns("hfAssumptions")),
              actionButton(ns("hfAddStrategy"), "Add strategy", icon = icon("plus"), class = "btn-sm", style = "margin-top:8px;"),
              actionButton(ns("hfRemoveStrategy"), "Remove last", icon = icon("minus"), class = "btn-sm", style = "margin-top:8px;"),
              numericInput(ns("hfRiskFree"), "Risk-free rate (%)", value = 4, min = 0, max = 20, step = 0.25)
            ),
            box(width = 6, status = "info", solidHeader = TRUE, title = "Correlation matrix",
              tags$p("Double-click a cell to edit. Kept symmetric with a diagonal of 1; impossible combinations are repaired and flagged.",
                     style = "font-size:11px; color:#6b7883;"),
              DT::dataTableOutput(ns("hfCorrelation")),
              uiOutput(ns("hfCorrWarning"))
            )
          ),
          box(width = 12, status = "success", solidHeader = TRUE, title = "Allocation comparison",
            uiOutput(ns("hfSharpeNote")),
            DT::dataTableOutput(ns("hfWeightsTable")),
            fluidRow(
              column(6, withSpinner(plotly::plotlyOutput(ns("hfWeightsChart"), height = "300px"))),
              column(6, withSpinner(plotly::plotlyOutput(ns("hfRiskChart"), height = "300px")))
            ),
            fluidRow(
              column(6, withSpinner(plotly::plotlyOutput(ns("hfFrontierChart"), height = "320px"))),
              column(6, ui_context(tags$b("Reading this: "),
                "the left chart is capital weight, the right chart is each strategy's share of total portfolio risk. ",
                "Risk parity makes the right chart flat (equal risk from every strategy) by sizing low-volatility, ",
                "low-correlation strategies up. Max-Sharpe maximises risk-adjusted return directly, which makes it the ",
                "method most sensitive to how accurate your return assumptions are \u2014 and often concentrated in one ",
                "or two strategies. The scatter shows 1,500 random long-only portfolios for context; it is illustrative, ",
                "not a computed efficient frontier."))
            )
          )
        ),

        # ---------------------------------------------------------------
        tabPanel("4. Business Structure", icon = icon("building-columns"),
          box(width = 12, status = "info", solidHeader = TRUE, title = "Four realistic routes",
            DT::dataTableOutput(ns("hfStructureTable")),
            ui_context(tags$b("A correction worth knowing: "),
              "managing other people's money on a discretionary basis is itself a regulated activity \u2014 the FCA treats ",
              "discretionary managers as MiFID investment managers (application-fee category 6, per its fees page). What a ",
              "managed-accounts route saves compared with a fund is the fund vehicle, administration and AIFM overhead, ",
              "not the authorisation itself. Confirm the exact perimeter with a compliance consultant.")
          ),
          box(width = 12, status = "warning", solidHeader = FALSE, collapsible = TRUE, collapsed = FALSE,
              title = "Capital tied up: prudential requirements",
            tags$p(paste0(
              "An authorised AIFM must hold minimum own funds and liquid assets on an ongoing basis. For a firm managing ",
              "only an AIF, the FCA's page describes an amount linked to assets under management (0.01% of AuM as a ",
              "professional-negligence capital requirement) on top of a base requirement, or an alternative based on PI ",
              "insurance. This is capital that cannot be spent, separate from setup and running costs \u2014 read the FCA's ",
              "current requirements and budget for it."
            ), style = "font-size:12.5px; color:#7d4a00; margin:0; line-height:1.6;"),
            tags$a(href = "https://www.fca.org.uk/firms/aifmd/apply-authorised-aifm", target = "_blank", style = "font-size:12px;",
                   "FCA: apply to be an authorised AIFM \u2192")
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
              "The underlying discipline carries over directly \u2014 logging every trade is exactly what a real audit trail ",
              "requires, just against institutional infrastructure instead of a local R session. The last column is a ",
              "suggestion for where to spend build effort versus buying or partnering; the AlgoDynamiX tab works through ",
              "one build-versus-license decision in detail."
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
            fluidRow(
              column(4, numericInput(ns("fpCostBase"), "Annual operating cost base (\u00a3): compliance, admin, data, salaries",
                                      value = 150000, step = 10000)),
              column(4, sliderInput(ns("fpStressYear"), "Stress year (0 = none)", min = 0, max = 10, value = 0, step = 1)),
              column(4, numericInput(ns("fpStressReturn"), "Gross return in the stress year (%)", value = -15, step = 1))
            ),
            tags$p("A stress year shows the high-water mark at work: after a loss, no performance fee is earned until the fund recovers past its previous peak, while the operating costs carry on.",
                   style = "font-size:11.5px; color:#6b7883; margin:0;")
          ),
          box(width = 12, status = "success", solidHeader = TRUE, title = "Projection",
            uiOutput(ns("fpSummary")),
            fluidRow(
              column(6, withSpinner(plotly::plotlyOutput(ns("fpAumChart"), height = "280px"))),
              column(6, withSpinner(plotly::plotlyOutput(ns("fpRevenueChart"), height = "280px")))
            ),
            DT::dataTableOutput(ns("fpTable")),
            ui_context(tags$b("Simplification note: "), "this collapses the whole fund into a single NAV series with one ",
                       "high-water mark \u2014 a real fund administrator tracks this per investor, per subscription. Fine for ",
                       "rough business planning; not a substitute for real fund accounting.")
          ),
          box(width = 12, status = "primary", solidHeader = TRUE, title = "Sensitivity: cumulative net profit by return and capital raised",
            withSpinner(plotly::plotlyOutput(ns("fpSensitivity"), height = "340px")),
            ui_context(tags$b("Reading this: "), "green cells are years-summed profit after operating costs, red cells are losses. ",
                       "Uses the fee, hurdle, cost and horizon assumptions above and holds the return constant across years, so it ",
                       "shows how much of the business depends on performance versus on simply raising assets.")
          )
        )
      )
    )
  )
}

# ===========================================================================
# SERVER
# ===========================================================================

hedge_fund_strategy_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # -- Tab 1: Reality Check --
    output$rcRecommendation <- renderUI({
      cap <- input$rcCapital %||% 20000
      ctrl <- input$rcControl %||% 3
      rec <- if (cap < 15000) {
        list(name = "Appointed Representative (AR)", reason = "Setup capital is below what a full authorisation typically needs \u2014 an AR arrangement under an existing authorised principal firm is the realistic entry point.")
      } else if (ctrl <= 2) {
        list(name = "Appointed Representative (AR)", reason = "You are comfortable operating under someone else's permissions and oversight \u2014 an AR gets you managing client money fastest.")
      } else if (cap < 50000 || ctrl == 3) {
        list(name = "Managed accounts under your own authorisation", reason = "Still a regulated activity, but without the fund vehicle and AIFM overhead \u2014 each client keeps their own account. Needs FCA authorisation as an investment manager.")
      } else {
        list(name = "Full authorisation, with a fund vehicle once AUM justifies it", reason = "You have meaningful setup capital and want full independence \u2014 the \"hedge fund\" structure, only sensible once real AUM interest is lined up.")
      }
      ui_result_box(paste0("Suggested starting point: ", rec$name), rec$reason)
    })

    # -- Tab 2: Track Record Plan --
    output$trProgress <- renderUI({
      req(input$trStartDate)
      days_elapsed <- as.numeric(Sys.Date() - input$trStartDate)
      months_elapsed <- round(days_elapsed / 30.44, 1)
      pct_to_12mo <- min(100, max(0, months_elapsed / 12 * 100))
      tagList(
        fluidRow(
          column(4, ui_metric_tile("Days in", max(0, round(days_elapsed)), "since start date")),
          column(4, ui_metric_tile("Months", months_elapsed, "of 12 minimum")),
          column(4, ui_metric_tile("To 12 months", paste0(round(pct_to_12mo), "%"), "keep logging through a drawdown",
                                    color = if (pct_to_12mo >= 100) "#1e7a46" else "#9c6b26"))
        ),
        tags$div(style = "background:#e3e8ea; border-radius:6px; height:14px; overflow:hidden; margin-top:2px;",
          tags$div(style = paste0("background:", if (pct_to_12mo >= 100) "#1e7a46" else "#008A82", "; height:100%; width:", round(pct_to_12mo, 1), "%;")))
      )
    })

    output$trChecklistScore <- renderUI({
      n_done <- length(input$trChecklist)
      n_all <- 6
      ui_metric_tile("Readiness", paste0(n_done, " / ", n_all), "criteria met before approaching a compliance consultant",
                     color = if (n_done == n_all) "#1e7a46" else "#9c6b26")
    })

    # -- Tab 3: Portfolio Optimizer --
    strategy_names <- c("WTI Trend Following", "Nat Gas Weather Seasonal", "Crack Spread Carry", "Inventory Mean-Reversion")
    hf_assumptions <- reactiveVal(data.frame(
      Strategy = strategy_names, `Return %` = c(10, 9, 6, 7), `Vol %` = c(18, 25, 8, 12),
      check.names = FALSE, stringsAsFactors = FALSE
    ))
    hf_correlation <- reactiveVal({
      m <- matrix(c(
        1.00,  0.15, -0.10, -0.30,
        0.15,  1.00,  0.05,  0.00,
       -0.10,  0.05,  1.00,  0.10,
       -0.30,  0.00,  0.10,  1.00), nrow = 4, byrow = TRUE)
      rownames(m) <- colnames(m) <- strategy_names
      as.data.frame(m, check.names = FALSE)
    })
    # Bumped when the NUMBER of strategies changes: the DT widgets render once
    # from isolated data and are updated in place via a proxy on cell edits, but
    # adding/removing a strategy changes the columns of the correlation grid, so
    # that needs a full re-render.
    struct_version <- reactiveVal(0)

    output$hfAssumptions <- DT::renderDataTable({
      struct_version()
      DT::datatable(isolate(hf_assumptions()), rownames = FALSE, editable = TRUE,
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

    output$hfCorrelation <- DT::renderDataTable({
      struct_version()
      DT::datatable(isolate(hf_correlation()), editable = TRUE, options = list(dom = 't', paging = FALSE, ordering = FALSE))
    }, server = FALSE)
    hf_corr_proxy <- DT::dataTableProxy("hfCorrelation")
    observeEvent(input$hfCorrelation_cell_edit, {
      info <- input$hfCorrelation_cell_edit
      df <- hf_correlation()
      df[info$row, info$col] <- DT::coerceValue(info$value, df[info$row, info$col])
      hf_correlation(df)
      DT::replaceData(hf_corr_proxy, df, resetPaging = FALSE)
    })

    observeEvent(input$hfAddStrategy, {
      df <- hf_assumptions()
      if (nrow(df) >= 8) return()
      new_name <- paste("Strategy", nrow(df) + 1)
      df[nrow(df) + 1, ] <- list(new_name, 8, 12)
      hf_assumptions(df)

      cm <- hf_correlation()
      cm[[new_name]] <- 0
      cm[new_name, ] <- 0
      cm[new_name, new_name] <- 1
      hf_correlation(cm)
      struct_version(struct_version() + 1)
    })
    observeEvent(input$hfRemoveStrategy, {
      df <- hf_assumptions()
      if (nrow(df) <= 2) return()
      keep <- rownames(hf_correlation())[-nrow(df)]
      hf_assumptions(df[-nrow(df), , drop = FALSE])
      cm <- hf_correlation()
      hf_correlation(cm[keep, keep, drop = FALSE])
      struct_version(struct_version() + 1)
    })

    hf_computed <- reactive({
      assump <- hf_assumptions()
      req(nrow(assump) >= 2)
      mu <- assump$`Return %` / 100
      sigma <- pmax(assump$`Vol %` / 100, 1e-4)
      names(mu) <- names(sigma) <- assump$Strategy
      valid <- hf_make_valid_corr(hf_correlation())
      rf <- (input$hfRiskFree %||% 4) / 100

      Sigma <- hf_build_covariance(sigma, valid$corr)
      n <- length(mu)
      list(strategies = assump$Strategy, mu = mu, sigma = sigma, Sigma = Sigma, rf = rf,
           corr_adjusted = valid$adjusted,
           weights = list(`Equal Weight` = rep(1 / n, n),
                          `Inverse Volatility` = (1 / sigma) / sum(1 / sigma),
                          `Risk Parity` = hf_solve_risk_parity(Sigma),
                          `Max Sharpe` = hf_solve_max_sharpe(mu, Sigma, rf)))
    })

    output$hfCorrWarning <- renderUI({
      if (!isTRUE(hf_computed()$corr_adjusted)) return(NULL)
      tags$div(style = "margin-top:8px; padding:10px 12px; background:#fdebd0; border-left:3px solid #e67e22; font-size:12px; color:#7d4a00; line-height:1.5;",
        tags$b("Correlation matrix adjusted. "),
        "The values entered describe an impossible structure (for example A and B strongly positive, B and C strongly positive, ",
        "but A and C strongly negative). The results below use the nearest valid matrix instead; your entries are unchanged in the grid.")
    })

    output$hfSharpeNote <- renderUI({
      hc <- hf_computed()
      if (max(hc$mu) > hc$rf) return(NULL)
      tags$div(style = "margin-bottom:8px; padding:10px 12px; background:#fdebd0; border-left:3px solid #e67e22; font-size:12px; color:#7d4a00;",
        "No strategy's return exceeds the risk-free rate, so Sharpe ratios are negative and the Max-Sharpe weights are not meaningful.")
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
      DT::datatable(df, rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)

    output$hfWeightsChart <- plotly::renderPlotly({
      hc <- hf_computed()
      df <- do.call(rbind, lapply(names(hc$weights), function(m)
        data.frame(Method = m, Strategy = hc$strategies, Weight = hc$weights[[m]] * 100)))
      plotly::plot_ly(df, x = ~Method, y = ~Weight, color = ~Strategy, colors = hf_palette, type = "bar") |>
        plotly::layout(barmode = "stack", yaxis = list(title = "Capital weight (%)"),
                       title = list(text = "Capital weight by method", font = list(size = 12)),
                       plot_bgcolor = "white", paper_bgcolor = "white", legend = list(font = list(size = 9)))
    })

    output$hfRiskChart <- plotly::renderPlotly({
      hc <- hf_computed()
      df <- do.call(rbind, lapply(names(hc$weights), function(m)
        data.frame(Method = m, Strategy = hc$strategies,
                   Risk = hf_risk_contributions(hc$weights[[m]], hc$Sigma) * 100)))
      plotly::plot_ly(df, x = ~Method, y = ~Risk, color = ~Strategy, colors = hf_palette, type = "bar", showlegend = FALSE) |>
        plotly::layout(barmode = "stack", yaxis = list(title = "Share of portfolio risk (%)"),
                       title = list(text = "Risk contribution by method", font = list(size = 12)),
                       plot_bgcolor = "white", paper_bgcolor = "white")
    })

    output$hfFrontierChart <- plotly::renderPlotly({
      hc <- hf_computed()
      rp <- hf_random_portfolios(hc$mu, hc$Sigma, 1500)
      pts <- do.call(rbind, lapply(names(hc$weights), function(m) {
        s <- hf_port_stats(hc$weights[[m]], hc$mu, hc$Sigma, hc$rf)
        data.frame(Method = m, vol = s$vol, ret = s$ret)
      }))
      plotly::plot_ly() |>
        plotly::add_trace(data = rp, x = ~(vol * 100), y = ~(ret * 100), type = "scatter", mode = "markers",
                          marker = list(color = "#d8dee3", size = 4), name = "Random portfolios", hoverinfo = "skip") |>
        plotly::add_trace(data = pts, x = ~(vol * 100), y = ~(ret * 100), type = "scatter", mode = "markers+text",
                          text = ~Method, textposition = "top center", textfont = list(size = 9),
                          marker = list(color = "#008A82", size = 11, symbol = "diamond"), name = "Methods") |>
        plotly::layout(xaxis = list(title = "Volatility (%)"), yaxis = list(title = "Return (%)"),
                       title = list(text = "Illustrative risk / return", font = list(size = 12)),
                       showlegend = FALSE, plot_bgcolor = "white", paper_bgcolor = "white")
    })

    # -- Tab 4: Business Structure --
    output$hfStructureTable <- DT::renderDataTable({
      df <- data.frame(
        Route = c("Appointed Representative (AR)", "Managed accounts (own authorisation)",
                  "Small authorised UK AIFM", "Full-scope authorised AIFM + fund"),
        `What it means` = c("You operate under an authorised principal firm's permissions.",
                            "Discretionary management of each client's own account; regulated as investment management.",
                            "Authorised, with lighter requirements than full-scope, below the FCA's AuM thresholds.",
                            "Full authorisation to manage a fund vehicle above the thresholds."),
        `Regulatory footprint` = c("Principal firm carries the authorisation and oversight.",
                                   "FCA authorisation needed; application-fee category 6 per the FCA fees page.",
                                   "FCA authorisation needed; check the FCA page for the current AuM threshold.",
                                   "FCA authorisation (category 6); prudential own funds and liquid assets apply."),
        Independence = c("Low \u2014 under principal's permissions", "Medium \u2014 your process, client keeps own account",
                         "High \u2014 your own authorisation", "High \u2014 your own authorisation and fund"),
        `Best for` = c("Fastest legal route to client money", "Family offices wanting a fund-of-one first",
                       "A small pooled vehicle once a track record exists", "Real scale, once AUM interest is lined up"),
        check.names = FALSE, stringsAsFactors = FALSE
      )
      DT::datatable(df, rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)

    output$bsRecommendation <- renderUI({
      cap <- input$bsCapital %||% 15000
      aum <- input$bsAUMInterest %||% 500000
      rec <- if (aum < 250000) {
        "With interest this early-stage, an AR arrangement keeps costs proportionate until real commitments materialise."
      } else if (cap >= 30000 && aum >= 2000000) {
        "You may have both the capital and the AUM interest to justify starting the authorisation process now, in parallel with onboarding first clients under an AR or as managed accounts. Budget separately for prudential capital."
      } else {
        "Managed accounts (under an AR arrangement first, then your own authorisation) are the sensible middle path \u2014 enough interest to be worth formalising, without yet committing to a fund vehicle."
      }
      ui_result_box("Suggested structure", rec)
    })

    # -- Tab 5: Technology Roadmap --
    output$hfTechTable <- DT::renderDataTable({
      df <- data.frame(
        Dimension = c("Data feeds", "Execution", "Custody & reconciliation", "Monitoring", "Compliance & audit trail"),
        `This app (prototype)` = c("Yahoo Finance / manual entry", "Manual (signal-and-log, no execution)",
                                    "None \u2014 no client assets held", "Single session dashboards", "Session logs and CSV export"),
        `Production requirement` = c("Institutional feed or broker API", "Broker/prime-broker execution API with order management",
                                      "Independent administrator and prime broker \u2014 never self-custody client assets",
                                      "Hosted, monitored, redundant system with alerting",
                                      "Immutable, timestamped audit log meeting regulatory retention rules"),
        `Suggested route` = c("Buy", "Buy (broker API)", "Partner", "Build on this app, harden", "Partner (compliance consultant)"),
        check.names = FALSE, stringsAsFactors = FALSE
      )
      DT::datatable(df, rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)

    # -- Tab 6: Financial Projections --
    fp_returns <- reactive({
      years <- input$fpYears %||% 5
      base <- (input$fpGrossReturn %||% 12) / 100
      v <- rep(base, years)
      sy <- input$fpStressYear %||% 0
      if (sy >= 1 && sy <= years) v[sy] <- (input$fpStressReturn %||% -15) / 100
      v
    })

    fp_results <- reactive({
      hf_project_business(
        start_aum = input$fpStartAUM %||% 2000000,
        annual_new_capital = input$fpNewCapital %||% 3000000,
        gross_return_pct = fp_returns(),
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
      be_aum <- hf_breakeven_aum(input$fpCostBase %||% 150000, (input$fpMgmtFee %||% 1.5) / 100)
      tagList(
        fluidRow(
          column(3, ui_metric_tile("Breakeven year", if (is.na(breakeven)) "Beyond horizon" else paste0("Year ", breakeven), "first year net profit turns positive")),
          column(3, ui_metric_tile("Ending AUM", hf_gbp(tail(res$AUM_End, 1)), paste0("after ", nrow(res), " years"))),
          column(3, ui_metric_tile("Cumulative net profit", hf_gbp(sum(res$NetProfit)), "sum across the horizon",
                                    color = if (sum(res$NetProfit) >= 0) "#1e7a46" else "#c0392b")),
          column(3, ui_metric_tile("Final-year revenue", hf_gbp(tail(res$TotalRevenue, 1)), "management + performance fees"))
        ),
        fluidRow(
          column(6, ui_metric_tile("AUM for management fees to cover costs", if (is.na(be_aum)) "n/a" else hf_gbp(be_aum),
                                    "operating cost base divided by management fee rate, before any performance fee")),
          column(6, ui_metric_tile("Performance fee years", paste0(sum(res$PerfFee > 0), " of ", nrow(res)),
                                    "years the high-water mark and hurdle were both cleared"))
        )
      )
    })

    output$fpAumChart <- plotly::renderPlotly({
      res <- fp_results()
      plotly::plot_ly(res, x = ~Year, y = ~AUM_End, type = "scatter", mode = "lines+markers",
                      line = list(color = "#008A82", width = 2.5), fill = "tozeroy", fillcolor = "rgba(0,138,130,0.08)") |>
        plotly::layout(title = list(text = "AUM growth", font = list(size = 12)), yaxis = list(title = "AUM (\u00a3)"),
                       plot_bgcolor = "white", paper_bgcolor = "white")
    })

    output$fpRevenueChart <- plotly::renderPlotly({
      res <- fp_results()
      plotly::plot_ly(res, x = ~Year, y = ~MgmtFee, type = "bar", name = "Management fee", marker = list(color = "#002C3C")) |>
        plotly::add_trace(y = ~PerfFee, name = "Performance fee", marker = list(color = "#008A82")) |>
        plotly::layout(barmode = "stack", title = list(text = "Revenue composition", font = list(size = 12)),
                       yaxis = list(title = "Revenue (\u00a3)"), plot_bgcolor = "white", paper_bgcolor = "white")
    })

    output$fpTable <- DT::renderDataTable({
      res <- fp_results()
      res$GrossReturn <- paste0(round(res$GrossReturn * 100, 1), "%")
      res$NAV <- round(res$NAV, 1); res$HWM <- round(res$HWM, 1)
      money <- c("AUM_Start", "AUM_End", "MgmtFee", "PerfFee", "TotalRevenue", "NetProfit")
      res[money] <- lapply(res[money], round, 0)
      names(res) <- c("Year", "Gross return", "AUM start", "AUM end", "Mgmt fee", "Perf fee", "Revenue", "Net profit", "NAV", "High-water mark")
      DT::datatable(res, rownames = FALSE, options = list(dom = 't', paging = FALSE, scrollX = TRUE))
    }, server = FALSE)

    output$fpSensitivity <- plotly::renderPlotly({
      returns <- c(-0.05, 0, 0.05, 0.10, 0.15, 0.20, 0.25)
      caps <- c(0, 1e6, 2e6, 3e6, 5e6)
      m <- hf_sensitivity_grid(returns, caps,
                               start_aum = input$fpStartAUM %||% 2000000,
                               mgmt = (input$fpMgmtFee %||% 1.5) / 100, perf = (input$fpPerfFee %||% 20) / 100,
                               hurdle = (input$fpHurdle %||% 5) / 100, cost = input$fpCostBase %||% 150000,
                               years = input$fpYears %||% 5)
      plotly::plot_ly(z = m, x = paste0("\u00a3", caps / 1e6, "m / yr"), y = paste0(returns * 100, "%"),
                      type = "heatmap", zmid = 0,
                      colorscale = list(c(0, "#c0392b"), c(0.5, "#ffffff"), c(1, "#1e7a46")),
                      hovertemplate = "Return %{y}, raising %{x}<br>Cumulative net profit: \u00a3%{z:,.0f}<extra></extra>",
                      colorbar = list(title = "\u00a3")) |>
        plotly::layout(xaxis = list(title = "New capital raised per year"), yaxis = list(title = "Gross return"),
                       plot_bgcolor = "white", paper_bgcolor = "white")
    })
  })
}
