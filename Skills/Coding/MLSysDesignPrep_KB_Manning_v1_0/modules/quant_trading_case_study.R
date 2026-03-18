# modules/quant_trading_case_study.R
# Use Case: ML Quant Trading — Mid-Frequency Equity Alpha Signals
# Kravchenko & Babushkin (Manning 2025) Framework Applied
# JS namespace: qtShow(), .qt-btn, .qt-panel

quant_trading_case_study_ui <- function(id) {
  ns <- NS(id)

  js <- "
<script>
function qtShow(boxId, panelId) {
  var box = document.getElementById(boxId);
  if (!box) return;
  box.querySelectorAll('.qt-panel').forEach(function(p){ p.style.display='none'; });
  box.querySelectorAll('.qt-btn').forEach(function(b){ b.classList.remove('active'); });
  var panel = document.getElementById(panelId);
  if (panel) panel.style.display='block';
  event.target.classList.add('active');
}
window.addEventListener('load', function(){
  ['qt-box1','qt-box2','qt-box3','qt-box4','qt-box5','qt-box6','qt-box7'].forEach(function(boxId){
    var box = document.getElementById(boxId);
    if (!box) return;
    var btn = box.querySelector('.qt-btn');
    var pnl = box.querySelector('.qt-panel');
    if (btn) btn.classList.add('active');
    if (pnl) pnl.style.display='block';
  });
});
</script>"

  qtBtn <- function(boxId, panelId, label) {
    tags$button(class="qt-btn",
      style="margin:2px 4px 2px 0;padding:5px 12px;border:none;border-radius:4px;cursor:pointer;font-size:12px;background:#1a2332;color:#cdd6e0;transition:all .2s;",
      onclick=paste0("qtShow('",boxId,"','",panelId,"')"), label)
  }
  qtPanel <- function(panelId, ...) {
    div(id=panelId, class="qt-panel", style="display:none;padding-top:10px;", ...)
  }

  tagList(
    HTML(js),

    # ── Hero ──────────────────────────────────────────────────────────────────
    div(class="meta-hero",
        tags$h1("ML Quant Trading — Equity Alpha Signals"),
        tags$h2("Mid-Frequency Systematic Equities · Alpha Research · Execution-Aware · K&B Manning 2025 Framework"),
        div(
          span(class="hero-badge","Alpha Signals"),
          span(class="hero-badge","Mid-Frequency Equity"),
          span(class="hero-badge","Low SNR Environment"),
          span(class="hero-badge","Walk-Forward Validation"),
          span(class="hero-badge","MiFID II · FCA"),
          span(class="hero-badge","Execution-Aware ML")
        )
    ),

    # ── Architecture Overview ─────────────────────────────────────────────────
    fluidRow(
      box(title="ML Alpha Signal Pipeline — Concept to Production", status="primary", solidHeader=TRUE, width=12,
          div(style="overflow-x:auto;",
              HTML('
<svg viewBox="0 0 900 195" xmlns="http://www.w3.org/2000/svg" style="width:100%;max-width:900px;font-family:Inter,sans-serif;">
  <defs>
    <marker id="qt-arr" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0,8 3,0 6" fill="#e8410a"/>
    </marker>
  </defs>
  <!-- Data Sources -->
  <rect x="8"  y="10" width="105" height="26" rx="4" fill="#1a2332" stroke="#3b82f6" stroke-width="1.3"/>
  <text x="60" y="27" text-anchor="middle" fill="#93c5fd" font-size="8.5">OHLCV / Tick Data</text>
  <rect x="123" y="10" width="105" height="26" rx="4" fill="#1a2332" stroke="#3b82f6" stroke-width="1.3"/>
  <text x="175" y="27" text-anchor="middle" fill="#93c5fd" font-size="8.5">Fundamentals (SEC)</text>
  <rect x="238" y="10" width="105" height="26" rx="4" fill="#1a2332" stroke="#6b7280" stroke-width="1.3"/>
  <text x="290" y="27" text-anchor="middle" fill="#d1d5db" font-size="8.5">Alt Data (Sentiment)</text>
  <rect x="353" y="10" width="105" height="26" rx="4" fill="#1a2332" stroke="#6b7280" stroke-width="1.3"/>
  <text x="405" y="27" text-anchor="middle" fill="#d1d5db" font-size="8.5">Macro / Economic</text>
  <rect x="468" y="10" width="105" height="26" rx="4" fill="#1a2332" stroke="#f59e0b" stroke-width="1.3"/>
  <text x="520" y="27" text-anchor="middle" fill="#fcd34d" font-size="8.5">Options Flow / Dark Pool</text>
  <!-- Arrows to Feature Engine -->
  <line x1="60"  y1="36" x2="148" y2="68" stroke="#3b82f6" stroke-width="1.1" marker-end="url(#qt-arr)"/>
  <line x1="175" y1="36" x2="190" y2="68" stroke="#3b82f6" stroke-width="1.1" marker-end="url(#qt-arr)"/>
  <line x1="290" y1="36" x2="240" y2="68" stroke="#6b7280" stroke-width="1.1" marker-end="url(#qt-arr)"/>
  <line x1="405" y1="36" x2="292" y2="68" stroke="#6b7280" stroke-width="1.1" marker-end="url(#qt-arr)"/>
  <line x1="520" y1="36" x2="340" y2="68" stroke="#f59e0b" stroke-width="1.1" marker-end="url(#qt-arr)"/>
  <!-- Point-in-Time Feature Store -->
  <rect x="140" y="68" width="210" height="30" rx="6" fill="#0c1f3a" stroke="#3b82f6" stroke-width="1.6"/>
  <text x="245" y="83" text-anchor="middle" fill="#93c5fd" font-size="9" font-weight="bold">Point-in-Time Feature Store</text>
  <text x="245" y="94" text-anchor="middle" fill="#6b7280" font-size="7.5">No lookahead bias · Universe screening · Factor computation</text>
  <!-- Arrow to Model Training -->
  <line x1="245" y1="98" x2="245" y2="116" stroke="#e8410a" stroke-width="1.4" marker-end="url(#qt-arr)"/>
  <!-- Model Training / Research -->
  <rect x="140" y="116" width="210" height="28" rx="6" fill="#0a1f18" stroke="#10b981" stroke-width="1.6"/>
  <text x="245" y="130" text-anchor="middle" fill="#6ee7b7" font-size="9" font-weight="bold">Purged Walk-Forward Training</text>
  <text x="245" y="142" text-anchor="middle" fill="#6b7280" font-size="7.5">Embargo period · No future leakage · Regime-aware CV</text>
  <!-- Arrow to Signal Gen -->
  <line x1="245" y1="144" x2="245" y2="158" stroke="#e8410a" stroke-width="1.4" marker-end="url(#qt-arr)"/>
  <!-- Alpha Signal Layer -->
  <rect x="20"  y="158" width="100" height="24" rx="4" fill="#1a2332" stroke="#f59e0b" stroke-width="1.2"/>
  <text x="70"  y="174" text-anchor="middle" fill="#fcd34d" font-size="8.5">Return Prediction</text>
  <rect x="132" y="158" width="100" height="24" rx="4" fill="#1a2332" stroke="#f59e0b" stroke-width="1.2"/>
  <text x="182" y="174" text-anchor="middle" fill="#fcd34d" font-size="8.5">Volatility Forecast</text>
  <rect x="244" y="158" width="100" height="24" rx="4" fill="#1a2332" stroke="#f59e0b" stroke-width="1.2"/>
  <text x="294" y="174" text-anchor="middle" fill="#fcd34d" font-size="8.5">Factor Signals</text>
  <rect x="356" y="158" width="100" height="24" rx="4" fill="#1a2332" stroke="#f59e0b" stroke-width="1.2"/>
  <text x="406" y="174" text-anchor="middle" fill="#fcd34d" font-size="8.5">Risk Model</text>
  <!-- Portfolio construction + Execution -->
  <line x1="300" y1="182" x2="586" y2="182" stroke="#e8410a" stroke-width="1.4" marker-end="url(#qt-arr)"/>
  <rect x="586" y="148" width="175" height="42" rx="6" fill="#0d0f14" stroke="#e8410a" stroke-width="1.8"/>
  <text x="673" y="166" text-anchor="middle" fill="#fca5a5" font-size="10" font-weight="bold">Portfolio Construction</text>
  <text x="673" y="179" text-anchor="middle" fill="#9ca3af" font-size="8">Mean-variance · Risk constraints</text>
  <text x="673" y="190" text-anchor="middle" fill="#6b7280" font-size="7.5">Factor neutralisation · TCM</text>
  <!-- Execution -->
  <line x1="761" y1="169" x2="808" y2="152" stroke="#6b7280" stroke-width="1" marker-end="url(#qt-arr)"/>
  <text x="820" y="140" fill="#d1d5db" font-size="8">VWAP / TWAP</text>
  <text x="820" y="153" fill="#d1d5db" font-size="8">Smart Routing</text>
  <text x="820" y="166" fill="#d1d5db" font-size="8">DMA / Algo</text>
  <!-- Feedback loop -->
  <path d="M 673 190 Q 673 210 400 210 Q 127 210 127 98" stroke="#374151" stroke-width="1" fill="none" stroke-dasharray="4,3" marker-end="url(#qt-arr)"/>
  <text x="400" y="207" text-anchor="middle" fill="#374151" font-size="7">Signal decay monitoring · Live P&amp;L feedback · Regime detection</text>
</svg>'
              ))
      )
    ),

    # ── Box 1: Ch.1-2 Requirements ────────────────────────────────────────────
    fluidRow(
      box(title="Box 1 — Ch.1–2: Requirements & Problem Scoping (K&B)", status="primary", solidHeader=TRUE, width=12,
          id="qt-box1",
          div(qtBtn("qt-box1","qt1p1","K&B 6-Step Applied"),
              qtBtn("qt-box1","qt1p2","ML Task Decomposition"),
              qtBtn("qt-box1","qt1p3","SLOs & Constraints"),
              qtBtn("qt-box1","qt1p4","Regulatory Framework")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          qtPanel("qt1p1",
            div(class="success-box", HTML("<strong>K&amp;B Ch.1 Applied:</strong> The key translation is business goal → precise ML specification. In quant trading, the business goal is <em>generating risk-adjusted excess returns (alpha)</em>. K&amp;B insist: before touching any data, define exactly what you are predicting, over what horizon, with what evaluation metric.")),
            br(),
            div(class="framework-card",
              tags$h5("K&B 6-Step Loop — Mid-Frequency Equity Alpha"),
              tags$p(tags$b("1. Clarify requirements:"), " Predict forward equity returns over 1-5 day horizon. Universe: liquid mid-cap equities (Russell 1000). Minimum Sharpe > 1.0 net of costs. MiFID II reporting obligations."),
              tags$p(tags$b("2. Data pipeline:"), " Point-in-time correct OHLCV (daily + intraday). Fundamentals (quarterly, as-reported). Alternative data (NLP sentiment, satellite). Corporate actions handling critical."),
              tags$p(tags$b("3. Feature engineering:"), " Price-based factors (momentum, mean-reversion, volatility). Fundamental factors (quality, value, growth). Cross-sectional normalisation within sector/market-cap quintiles."),
              tags$p(tags$b("4. Model architecture:"), " Cross-sectional linear (Ridge/Lasso) for interpretable baseline. LightGBM for non-linear factor interactions. LSTM for sequential intraday patterns."),
              tags$p(tags$b("5. Evaluation:"), " Purged walk-forward cross-validation with embargo. Financial metrics: IC (Information Coefficient), IR (Information Ratio), Sharpe, max drawdown. Sliced by sector/regime."),
              tags$p(tags$b("6. Serving & monitoring:"), " Daily EOD signal generation (batch). Intraday signal refresh for execution. Factor decay monitoring. Crowding detection.")
            )
          ),

          qtPanel("qt1p2",
            div(class="section-heading-dark", "ML Task Decomposition — K&B Ch.1 Business→ML Translation"),
            fluidRow(
              column(6,
                tags$table(class="table table-hover",
                  tags$thead(tags$tr(tags$th("Business Goal"), tags$th("ML Task"), tags$th("Output"), tags$th("Metric"))),
                  tags$tbody(
                    tags$tr(tags$td("Generate alpha"), tags$td("Cross-sectional return prediction"), tags$td("Rank signal (z-score)"), tags$td("IC, ICIR")),
                    tags$tr(tags$td("Size positions correctly"), tags$td("Volatility forecasting"), tags$td("Predicted σ(r)"), tags$td("QLIKE loss")),
                    tags$tr(tags$td("Avoid risk factor bets"), tags$td("Factor exposure estimation"), tags$td("Beta per factor"), tags$td("Tracking error")),
                    tags$tr(tags$td("Minimise market impact"), tags$td("Execution cost modelling"), tags$td("Expected slippage"), tags$td("Realised vs predicted cost")),
                    tags$tr(tags$td("Portfolio construction"), tags$td("Covariance matrix estimation"), tags$td("Σ for optimiser"), tags$td("Out-of-sample Sharpe"))
                  )
                )
              ),
              column(6,
                div(class="warn-box", HTML("<strong>K&amp;B Ch.1 — The Quant ML Translation Problem:</strong> 'Predict stock returns' is not a well-specified ML task. You must specify: cross-sectional vs time-series, horizon (1d / 5d / 21d), universe, whether you are predicting absolute or relative returns, and what the loss function is (MSE is rarely the right choice).")),
                div(class="framework-card",
                  tags$h5("Mid-Frequency Definition (K&B Freshness Framework)"),
                  tags$ul(
                    tags$li(tags$b("High-frequency (HFT):"), " < 1 minute hold. Requires co-location, tick data, sub-millisecond latency."),
                    tags$li(tags$b("Mid-frequency:"), " Hours to ~5 days. EOD signals acceptable. This use case."),
                    tags$li(tags$b("Low-frequency:"), " Weeks to months. Fundamental investing. Monthly rebalance."),
                    tags$li(tags$b("K&B freshness implication:"), " Mid-frequency allows daily batch signal generation. Real-time streaming not required for signal, only for execution.")
                  )
                )
              )
            )
          ),

          qtPanel("qt1p3",
            div(class="section-heading-dark", "Non-Functional Requirements & SLOs — K&B Ch.2"),
            fluidRow(
              column(6,
                tags$table(class="table table-hover",
                  tags$thead(tags$tr(tags$th("Component"), tags$th("Mode"), tags$th("SLO"), tags$th("Why"))),
                  tags$tbody(
                    tags$tr(tags$td("EOD signal generation"), tags$td("Batch"), tags$td("Complete by 6:30 PM"), tags$td("Before Asian market open")),
                    tags$tr(tags$td("Intraday signal refresh"), tags$td("Near real-time"), tags$td("< 5 min lag"), tags$td("Execution window")),
                    tags$tr(tags$td("Portfolio optimiser"), tags$td("Batch"), tags$td("< 2 min runtime"), tags$td("Pre-market open")),
                    tags$tr(tags$td("Risk model update"), tags$td("Daily"), tags$td("EOD"), tags$td("Covariance estimation")),
                    tags$tr(tags$td("Backtest run"), tags$td("Research"), tags$td("< 30 min"), tags$td("Rapid iteration speed")),
                    tags$tr(tags$td("Factor decay check"), tags$td("Daily"), tags$td("Automated alert"), tags$td("Signal health monitoring"))
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("K&B Constraint Taxonomy Applied to Quant Trading"),
                  tags$ul(
                    tags$li(tags$b("Data constraints:"), " Survivorship bias (historical universe must include delisted stocks). Look-ahead bias (point-in-time correctness). Label noise: forward returns are noisy in low-SNR environment."),
                    tags$li(tags$b("Compute constraints:"), " Backtesting over 15 years × 1000 stocks = large. GPU acceleration for neural nets. Daily retraining feasibility."),
                    tags$li(tags$b("Market constraints:"), " Transaction costs erode alpha (commissions, bid-ask spread, market impact). Position limits. Sector concentration limits."),
                    tags$li(tags$b("Regulatory:"), " MiFID II algo trading registration. Best execution obligations. FCA algorithmic trading controls. Short-selling restrictions.")
                  )
                )
              )
            )
          ),

          qtPanel("qt1p4",
            div(class="section-heading-dark", "Regulatory Framework — MiFID II & FCA Algo Trading"),
            fluidRow(
              column(6,
                tags$table(class="table table-sm",
                  tags$thead(tags$tr(tags$th("Regulation"), tags$th("ML Implication"), tags$th("Implementation"))),
                  tags$tbody(
                    tags$tr(tags$td("MiFID II Art.17"), tags$td("Algorithmic trading requires pre/post-trade controls"), tags$td("Position limits in portfolio optimiser; kill switch in execution")),
                    tags$tr(tags$td("MiFID II RTS 6"), tags$td("Annual self-assessment of algos"), tags$td("Backtesting documentation; stress testing reports")),
                    tags$tr(tags$td("Best Execution"), tags$td("Must demonstrate order routing is optimal"), tags$td("TCM model evaluation; venue analysis logs")),
                    tags$tr(tags$td("MAR (Market Abuse)"), tags$td("Signals cannot be based on inside information"), tags$td("Data source compliance review; NLP model input audit")),
                    tags$tr(tags$td("EMIR"), tags$td("Derivatives reporting"), tags$td("If using futures/options for hedging")),
                    tags$tr(tags$td("FCA SYSC"), tags$td("Risk management framework for systematic trading"), tags$td("Model risk policy; independent model validation"))
                  )
                )
              ),
              column(6,
                div(class="warn-box", HTML("<strong>K&amp;B Responsible AI in Quant Context:</strong> Model risk in quant trading is direct financial and systemic risk. A miscalibrated model doesn't just harm a user — it can move markets, harm other participants, and create systemic risk (see: August 2007 Quant Meltdown — factor crowding caused simultaneous drawdowns across systematic funds when one fund deleveraged).")),
                div(class="framework-card",
                  tags$h5("Model Risk Management (MRM) for Quant Models"),
                  tags$ol(
                    tags$li("Independent validation: backtest results reviewed by risk team, not researcher"),
                    tags$li("Stress testing: model performance during 2008 GFC, 2020 COVID, 2022 rates shock"),
                    tags$li("Sensitivity analysis: how much does signal change if input data is perturbed ±5%?"),
                    tags$li("Challenger model: previous version always maintained for comparison"),
                    tags$li("Production limits: new models deployed at reduced capital allocation until track record established")
                  )
                )
              )
            )
          )
      )
    ),

    # ── Box 2: Ch.3 Data Pipeline ─────────────────────────────────────────────
    fluidRow(
      box(title="Box 2 — Ch.3: Data Pipeline Design — Point-in-Time Correctness (K&B)", status="warning", solidHeader=TRUE, width=12,
          id="qt-box2",
          div(qtBtn("qt-box2","qt2p1","Data Sources"),
              qtBtn("qt-box2","qt2p2","The Lookahead Bias Problem"),
              qtBtn("qt-box2","qt2p3","Pipeline Architecture"),
              qtBtn("qt-box2","qt2p4","Data Quality")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          qtPanel("qt2p1",
            fluidRow(
              column(6,
                div(class="section-heading-dark", "Data Source Taxonomy"),
                tags$table(class="table table-sm",
                  tags$thead(tags$tr(tags$th("Source"), tags$th("Type"), tags$th("Freq"), tags$th("Key Risk"))),
                  tags$tbody(
                    tags$tr(tags$td("Price / Volume (OHLCV)"), tags$td("Market"), tags$td("Daily/Tick"), tags$td("Survivorship bias")),
                    tags$tr(tags$td("Fundamentals (SEC 10-Q/K)"), tags$td("Fundamental"), tags$td("Quarterly"), tags$td("Restatements (as-reported vs restated)")),
                    tags$tr(tags$td("Analyst Estimates (IBES)"), tags$td("Sentiment"), tags$td("Daily"), tags$td("Revision timing contamination")),
                    tags$tr(tags$td("News NLP Sentiment"), tags$td("Alternative"), tags$td("Real-time"), tags$td("Event-driven contamination")),
                    tags$tr(tags$td("Short Interest"), tags$td("Market microstructure"), tags$td("Bi-weekly"), tags$td("Reporting lag")),
                    tags$tr(tags$td("Options Flow (IV, skew)"), tags$td("Derivatives"), tags$td("Daily"), tags$td("Market impact of large strikes")),
                    tags$tr(tags$td("Satellite (foot traffic)"), tags$td("Alternative"), tags$td("Weekly"), tags$td("Expensive; coverage gaps")),
                    tags$tr(tags$td("Macro (CPI, PMI, NFP)"), tags$td("Macro"), tags$td("Monthly"), tags$td("Revision contamination"))
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Alternative Data — K&B Data Sourcing Framework"),
                  tags$p("K&B distinguish between data that is available before prediction time vs data that is revised after. In quant finance this is called the", tags$b("as-reported vs point-in-time"), "distinction."),
                  tags$ul(
                    tags$li(tags$b("Fundamentals:"), " Use as-reported EPS, not restated. If Q3 2019 EPS was revised in Q1 2020, the model in Q3 2019 did not know the revised figure."),
                    tags$li(tags$b("Analyst estimates:"), " Use the estimate as it was on the prediction date — not the final consensus after revisions."),
                    tags$li(tags$b("NLP sentiment:"), " Timestamps must be verified — many data vendors backfill article publish times."),
                    tags$li(tags$b("Macro:"), " Use preliminary release, not final revision.")
                  )
                ),
                div(class="tip-box", HTML("<strong>K&amp;B Ch.3 interview point:</strong> In quant ML, lookahead bias is the #1 backtest inflation risk. A model that appears to have Sharpe 2.5 in backtest but Sharpe 0.3 live is almost always suffering from lookahead — point-in-time data infrastructure is the fix."))
              )
            )
          ),

          qtPanel("qt2p2",
            div(class="warn-box", HTML("<strong>K&amp;B Ch.3 — The Quant Lookahead Bias Problem:</strong> This is the most destructive data quality issue in quant ML. It is a form of train-serve skew (K&amp;B Ch.4) applied at the data ingestion layer. There are four distinct types, each requiring a different fix.")),
            br(),
            fluidRow(
              column(6,
                tags$table(class="table table-hover",
                  tags$thead(tags$tr(tags$th("Bias Type"), tags$th("Mechanism"), tags$th("Example"), tags$th("Detection"))),
                  tags$tbody(
                    tags$tr(tags$td("Survivorship bias"), tags$td("Historical universe only includes stocks that survived"), tags$td("Testing on S&P 500 today but calling it historical"), tags$td("Check: delisting events in universe")),
                    tags$tr(tags$td("Look-ahead in fundamentals"), tags$td("Using restated EPS instead of as-reported"), tags$td("Q3 EPS revised +15% in Q4 — model 'knew' this"), tags$td("Compare as-reported vs restated datasets")),
                    tags$tr(tags$td("Feature timestamp leak"), tags$td("Feature computed at t uses data from t+1"), tags$td("Closing price used before market close"), tags$td("Strict timestamp audit on all features")),
                    tags$tr(tags$td("Label contamination"), tags$td("Training label leaks into features"), tags$td("Future returns used as input to normalisation"), tags$td("Embargo period between features and labels"))
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Point-in-Time Database Architecture"),
                  tags$p("Solution: A", tags$b("bi-temporal database"), "where every record stores both:"),
                  tags$ul(
                    tags$li(tags$b("valid_time:"), " When the event occurred in the real world (e.g., Q3 earnings reported)"),
                    tags$li(tags$b("transaction_time:"), " When the data was entered into our database (i.e., when we knew it)")
                  ),
                  tags$p("When constructing a training sample for prediction at time T, we query: 'What did we know as of T?' — not 'What do we know now?'"),
                  div(class="success-box", HTML("<strong>K&amp;B pattern:</strong> The point-in-time feature store is the single most important infrastructure investment in quant ML. Everything else is downstream."))
                )
              )
            )
          ),

          qtPanel("qt2p3",
            div(class="section-heading-dark", "Data Pipeline Architecture — K&B Batch Pattern"),
            div(style="overflow-x:auto;",
              HTML('
<svg viewBox="0 0 800 240" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <text x="400" y="16" text-anchor="middle" fill="#e8410a" font-size="11" font-weight="bold">Quant ML Data Pipeline — K&B Ch.3 Architecture</text>
  <!-- Raw data sources -->
  <rect x="10"  y="28" width="100" height="28" rx="4" fill="#1a2332" stroke="#3b82f6" stroke-width="1.2"/>
  <text x="60"  y="42" text-anchor="middle" fill="#93c5fd" font-size="8">Market Data</text>
  <text x="60"  y="52" text-anchor="middle" fill="#6b7280" font-size="7">Refinitiv/Bloomberg</text>
  <rect x="120" y="28" width="100" height="28" rx="4" fill="#1a2332" stroke="#3b82f6" stroke-width="1.2"/>
  <text x="170" y="42" text-anchor="middle" fill="#93c5fd" font-size="8">Fundamentals</text>
  <text x="170" y="52" text-anchor="middle" fill="#6b7280" font-size="7">Compustat / EDGAR</text>
  <rect x="230" y="28" width="100" height="28" rx="4" fill="#1a2332" stroke="#6b7280" stroke-width="1.2"/>
  <text x="280" y="42" text-anchor="middle" fill="#d1d5db" font-size="8">Alt Data</text>
  <text x="280" y="52" text-anchor="middle" fill="#6b7280" font-size="7">NLP / Satellite</text>
  <rect x="340" y="28" width="100" height="28" rx="4" fill="#1a2332" stroke="#6b7280" stroke-width="1.2"/>
  <text x="390" y="42" text-anchor="middle" fill="#d1d5db" font-size="8">Corporate Actions</text>
  <text x="390" y="52" text-anchor="middle" fill="#6b7280" font-size="7">Splits/Divs/M&amp;A</text>
  <!-- Raw store -->
  <line x1="60"  y1="56" x2="130" y2="88" stroke="#3b82f6" stroke-width="1.1" marker-end="url(#qt-arr)"/>
  <line x1="170" y1="56" x2="180" y2="88" stroke="#3b82f6" stroke-width="1.1" marker-end="url(#qt-arr)"/>
  <line x1="280" y1="56" x2="235" y2="88" stroke="#6b7280" stroke-width="1.1" marker-end="url(#qt-arr)"/>
  <line x1="390" y1="56" x2="285" y2="88" stroke="#6b7280" stroke-width="1.1" marker-end="url(#qt-arr)"/>
  <rect x="100" y="88" width="195" height="28" rx="5" fill="#0f2444" stroke="#3b82f6" stroke-width="1.5"/>
  <text x="197" y="102" text-anchor="middle" fill="#93c5fd" font-size="9" font-weight="bold">Raw Time-Stamped Store</text>
  <text x="197" y="112" text-anchor="middle" fill="#6b7280" font-size="7.5">Bi-temporal: valid_time + transaction_time</text>
  <!-- Adjustment engine -->
  <line x1="197" y1="116" x2="197" y2="132" stroke="#e8410a" stroke-width="1.4" marker-end="url(#qt-arr)"/>
  <rect x="100" y="132" width="195" height="28" rx="5" fill="#1a2332" stroke="#f59e0b" stroke-width="1.5"/>
  <text x="197" y="146" text-anchor="middle" fill="#fcd34d" font-size="9" font-weight="bold">Adjustment Engine</text>
  <text x="197" y="157" text-anchor="middle" fill="#6b7280" font-size="7.5">Split/div adjust · Currency normalise · Delisting handle</text>
  <!-- PIT Feature Store -->
  <line x1="197" y1="160" x2="197" y2="174" stroke="#e8410a" stroke-width="1.4" marker-end="url(#qt-arr)"/>
  <rect x="100" y="174" width="195" height="28" rx="5" fill="#0a1f18" stroke="#10b981" stroke-width="1.8"/>
  <text x="197" y="188" text-anchor="middle" fill="#6ee7b7" font-size="9" font-weight="bold">Point-in-Time Feature Store</text>
  <text x="197" y="199" text-anchor="middle" fill="#6b7280" font-size="7.5">Cross-sectional normalisation · Universe filtering</text>
  <!-- Training -->
  <line x1="197" y1="202" x2="197" y2="216" stroke="#e8410a" stroke-width="1.4" marker-end="url(#qt-arr)"/>
  <rect x="130" y="216" width="135" height="20" rx="4" fill="#1a2332" stroke="#10b981" stroke-width="1.2"/>
  <text x="197" y="230" text-anchor="middle" fill="#6ee7b7" font-size="8.5">Training Samples (no leakage)</text>
  <!-- Right side: embargo + walk-forward -->
  <rect x="450" y="88" width="170" height="48" rx="5" fill="#0c1f3a" stroke="#e8410a" stroke-width="1.5"/>
  <text x="535" y="107" text-anchor="middle" fill="#fca5a5" font-size="9" font-weight="bold">Embargo Period</text>
  <text x="535" y="120" text-anchor="middle" fill="#9ca3af" font-size="8">Gap between train end</text>
  <text x="535" y="131" text-anchor="middle" fill="#9ca3af" font-size="8">and test start (e.g. 21 days)</text>
  <line x1="295" y1="102" x2="450" y2="110" stroke="#e8410a" stroke-width="1" stroke-dasharray="4,3" marker-end="url(#qt-arr)"/>
  <rect x="450" y="155" width="170" height="64" rx="5" fill="#1a2332" stroke="#6b7280" stroke-width="1.5"/>
  <text x="535" y="173" text-anchor="middle" fill="#d1d5db" font-size="9" font-weight="bold">Walk-Forward Folds</text>
  <text x="535" y="187" text-anchor="middle" fill="#6b7280" font-size="7.5">Train [T0 → T-embargo]</text>
  <text x="535" y="198" text-anchor="middle" fill="#6b7280" font-size="7.5">Test  [T → T+horizon]</text>
  <text x="535" y="209" text-anchor="middle" fill="#6b7280" font-size="7.5">Roll forward by N months</text>
  <text x="535" y="220" text-anchor="middle" fill="#374151" font-size="7">Typically 5-10 folds × 15yr</text>
  <line x1="295" y1="188" x2="450" y2="188" stroke="#6b7280" stroke-width="1" stroke-dasharray="4,3" marker-end="url(#qt-arr)"/>
</svg>'
              ))
          ),

          qtPanel("qt2p4",
            div(class="section-heading-dark", "Data Quality — K&B Ch.3 Applied to Financial Data"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Financial Data Quality Checks"),
                  tags$ul(
                    tags$li(tags$b("Price continuity:"), " Flag gaps > 5 standard deviations. Check against exchange halts/suspensions."),
                    tags$li(tags$b("Corporate action completeness:"), " Missing dividend adjustment inflates apparent returns. Every split/div must be reflected."),
                    tags$li(tags$b("Delisting tracking:"), " Stocks delisted due to bankruptcy must remain in historical universe — ignoring them creates survivorship bias of ~1-2% annualised."),
                    tags$li(tags$b("Fundamental timeliness:"), " Flag filings arriving > 90 days after quarter end (regulatory maximum is 40 days for accelerated filers — late = potential quality signal)."),
                    tags$li(tags$b("Cross-asset consistency:"), " Options implied vol should not diverge > 50% from realised vol without explanation.")
                  )
                )
              ),
              column(6,
                div(class="warn-box", HTML("<strong>K&amp;B Exactly-Once Semantics in Quant Context:</strong> When an EOD price file is delivered and partially processed before a crash, re-processing must not double-count prices. Use idempotent feature computation keyed by (ticker, date, data_version). Critical: duplicate rows in training data create phantom factor exposures.")),
                div(class="framework-card",
                  tags$h5("Schema Evolution — Quant Data"),
                  tags$ul(
                    tags$li("S&P index constituent changes require universe recomputation"),
                    tags$li("GICS sector reclassification can shift cross-sectional z-scores"),
                    tags$li("Ticker changes (M&A, spin-offs): maintain CUSIP/ISIN mapping"),
                    tags$li("K&B data contract: vendor schema changes require 30-day notice + parallel validation")
                  )
                )
              )
            )
          )
      )
    ),

    # ── Box 3: Ch.4 Feature Engineering ──────────────────────────────────────
    fluidRow(
      box(title="Box 3 — Ch.4: Feature Engineering — Alpha Factors & Feature Store (K&B)", status="success", solidHeader=TRUE, width=12,
          id="qt-box3",
          div(qtBtn("qt-box3","qt3p1","Alpha Factor Taxonomy"),
              qtBtn("qt-box3","qt3p2","Cross-Sectional Normalisation"),
              qtBtn("qt-box3","qt3p3","Feature Store Design"),
              qtBtn("qt-box3","qt3p4","Factor Decay Chart")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          qtPanel("qt3p1",
            div(class="section-heading-dark", "Alpha Factor Taxonomy — K&B Ch.4 Feature Groups"),
            fluidRow(
              column(3,
                div(class="framework-card",
                  tags$h5("📈 Price-Based Factors"),
                  tags$ul(
                    tags$li(tags$b("Momentum 12-1:"), " 12m return, skip last month (reversal noise)"),
                    tags$li(tags$b("Short-term reversal:"), " 1-month return (mean reversion)"),
                    tags$li(tags$b("Volatility (realised):"), " 21d rolling σ of daily returns"),
                    tags$li(tags$b("Idiosyncratic vol:"), " Residual volatility after market beta"),
                    tags$li(tags$b("Illiquidity (Amihud):"), " |return| / dollar volume — price impact proxy"),
                    tags$li(tags$b("Beta:"), " 60d rolling market beta — risk model input")
                  )
                )
              ),
              column(3,
                div(class="framework-card",
                  tags$h5("📊 Fundamental Factors"),
                  tags$ul(
                    tags$li(tags$b("Value (B/P, E/P, CF/P):"), " Book, earnings, cashflow to price"),
                    tags$li(tags$b("Quality (ROE, ROIC):"), " Return on equity/invested capital"),
                    tags$li(tags$b("Growth:"), " EPS growth, revenue growth acceleration"),
                    tags$li(tags$b("Leverage:"), " Debt-to-equity, interest coverage"),
                    tags$li(tags$b("Earnings quality:"), " Accruals ratio, cash conversion"),
                    tags$li(tags$b("Profitability (Gross margin):"), " Gross profit / assets")
                  )
                )
              ),
              column(3,
                div(class="framework-card",
                  tags$h5("📡 Sentiment Factors"),
                  tags$ul(
                    tags$li(tags$b("Analyst revision:"), " EPS estimate change (FY1/FY2)"),
                    tags$li(tags$b("Earnings surprise:"), " Actual - expected (SUE)"),
                    tags$li(tags$b("Short interest:"), " % shares outstanding shorted"),
                    tags$li(tags$b("NLP news score:"), " Sentiment extracted from articles"),
                    tags$li(tags$b("Earnings call tone:"), " Management language NLP"),
                    tags$li(tags$b("Options activity:"), " Put/call ratio, IV skew change")
                  )
                )
              ),
              column(3,
                div(class="framework-card",
                  tags$h5("🌐 Market Microstructure"),
                  tags$ul(
                    tags$li(tags$b("Bid-ask spread:"), " Transaction cost proxy"),
                    tags$li(tags$b("Volume profile:"), " Intraday volume distribution"),
                    tags$li(tags$b("Order flow imbalance:"), " Buy vs sell order imbalance"),
                    tags$li(tags$b("Dark pool activity:"), " Off-exchange volume ratio"),
                    tags$li(tags$b("Short-term price impact:"), " Own order fill analysis"),
                    tags$li(tags$b("Intraday momentum:"), " Opening return vs close")
                  )
                )
              )
            )
          ),

          qtPanel("qt3p2",
            div(class="section-heading-dark", "Cross-Sectional Normalisation — K&B Train-Serve Consistency"),
            fluidRow(
              column(6,
                div(class="warn-box", HTML("<strong>K&amp;B Ch.4 Critical Point:</strong> Cross-sectional normalisation is the most common source of train-serve skew in quant ML. If you normalise using the current universe at serving time but used a historical universe at training time, the z-scores are computed on different distributions.")),
                br(),
                div(class="framework-card",
                  tags$h5("Normalisation Pipeline"),
                  tags$ol(
                    tags$li(tags$b("Winsorise:"), " Cap extreme values at ±3σ to prevent outlier domination"),
                    tags$li(tags$b("Cross-sectional z-score:"), " μ and σ computed within sector × market-cap quintile on that day's universe"),
                    tags$li(tags$b("Rank transform:"), " Convert to percentile rank (0-1) — makes distribution uniform"),
                    tags$li(tags$b("Neutralise:"), " Demean within sector and market cap to remove systematic tilts"),
                    tags$li(tags$b("Orthogonalise:"), " Remove exposure to risk factors (market, size, value) from alpha signal")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Sector/Market-Cap Relative Normalisation"),
                  tags$p("Why within-group z-scoring?"),
                  tags$ul(
                    tags$li("P/E ratio of 15× is expensive for a utility, cheap for a biotech"),
                    tags$li("Momentum in small caps has different distributional properties to large caps"),
                    tags$li("K&B principle: features must be comparable across the prediction universe")
                  ),
                  br(),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Factor"), tags$th("Raw"), tags$th("After Sector Z-score"), tags$th("After Mkt-Cap Z-score"))),
                    tags$tbody(
                      tags$tr(tags$td("P/E ratio"), tags$td("14.2"), tags$td("+0.8σ (Tech sector)"), tags$td("+0.5σ (Large cap)")),
                      tags$tr(tags$td("12M Momentum"), tags$td("+23%"), tags$td("+1.1σ (Sector)"), tags$td("+0.9σ (Large cap)")),
                      tags$tr(tags$td("ROE"), tags$td("18%"), tags$td("+0.6σ (Sector)"), tags$td("+0.7σ (Large cap)"))
                    )
                  )
                )
              )
            )
          ),

          qtPanel("qt3p3",
            div(class="section-heading-dark", "Feature Store Design — K&B Offline/Online Pattern"),
            fluidRow(
              column(6,
                div(class="framework-card", style="border-left:3px solid #3b82f6;",
                  tags$h5("Offline Feature Store (Research/Training)"),
                  tags$ul(
                    tags$li(tags$b("Storage:"), " Parquet files partitioned by (date, universe). ~15 years × 1000 stocks × 300 features = ~50GB"),
                    tags$li(tags$b("Point-in-time join:"), " For label at date T, use features available strictly before T minus embargo period"),
                    tags$li(tags$b("Backfill:"), " When new factor added, must backfill entire 15-year history consistently"),
                    tags$li(tags$b("Versioning:"), " Factor definition changes create new version — never overwrite historical"),
                    tags$li(tags$b("K&B pattern:"), " Feature hash in every training run — ensures reproducibility")
                  )
                )
              ),
              column(6,
                div(class="framework-card", style="border-left:3px solid #10b981;",
                  tags$h5("Online Feature Store (Live Signal Generation)"),
                  tags$ul(
                    tags$li(tags$b("Storage:"), " Redis / Aerospike for sub-millisecond lookup (intraday refresh)"),
                    tags$li(tags$b("EOD batch:"), " Nightly Spark job recomputes all factors for next day's signal"),
                    tags$li(tags$b("Intraday:"), " Streaming pipeline updates price-based factors on tick data"),
                    tags$li(tags$b("Consistency check:"), " Compare live feature values to expected historical distribution daily — PSI alert if drift > 0.1"),
                    tags$li(tags$b("K&B warning:"), " Training used daily OHLCV; live system uses intraday — check normalisation consistency")
                  )
                )
              )
            )
          ),

          qtPanel("qt3p4",
            div(class="section-heading-dark", "Factor Decay — K&B Concept Drift Applied to Alpha Factors"),
            div(class="tip-box", HTML("<strong>K&amp;B Ch.4 / Ch.8:</strong> Alpha factors decay as they become crowded (more funds trade them) or as market regimes change. IC decay analysis is the quant equivalent of concept drift monitoring.")),
            br(),
            HTML('
<svg viewBox="0 0 700 200" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <text x="350" y="16" text-anchor="middle" fill="#e8410a" font-size="11" font-weight="bold">Factor IC Decay — Holding Period vs Predictive Power</text>
  <text x="350" y="30" text-anchor="middle" fill="#9ca3af" font-size="8.5">Information Coefficient (Rank Correlation of Signal vs Forward Return) by Lag</text>
  <line x1="60" y1="155" x2="660" y2="155" stroke="#374151" stroke-width="1.5"/>
  <line x1="60" y1="155" x2="60" y2="40" stroke="#374151" stroke-width="1.5"/>
  <line x1="60" y1="100" x2="660" y2="100" stroke="#1f2d3d" stroke-width="1" stroke-dasharray="3,3"/>
  <text x="55" y="100" text-anchor="end" fill="#6b7280" font-size="7">IC=0</text>
  <text x="55" y="70" text-anchor="end" fill="#6b7280" font-size="7">0.04</text>
  <text x="55" y="55" text-anchor="end" fill="#6b7280" font-size="7">0.06</text>
  <text x="55" y="155" text-anchor="end" fill="#6b7280" font-size="7">-0.02</text>
  <!-- Momentum decay curve -->
  <polyline points="60,62 120,65 180,70 240,78 300,88 360,97 420,102 480,105 540,107 600,108 660,109" fill="none" stroke="#3b82f6" stroke-width="2"/>
  <text x="665" y="112" fill="#3b82f6" font-size="7.5">Momentum</text>
  <!-- Mean-reversion curve -->
  <polyline points="60,55 120,70 180,92 240,108 300,118 360,126 420,130 480,132 540,133 600,134 660,134" fill="none" stroke="#ef4444" stroke-width="2"/>
  <text x="665" y="137" fill="#ef4444" font-size="7.5">Short-term Rev.</text>
  <!-- Quality factor -->
  <polyline points="60,72 120,73 180,73 240,74 300,75 360,76 420,77 480,79 540,81 600,83 660,86" fill="none" stroke="#10b981" stroke-width="2"/>
  <text x="665" y="90" fill="#10b981" font-size="7.5">Quality (slow decay)</text>
  <!-- NLP Sentiment -->
  <polyline points="60,52 120,82 180,107 240,118 300,125 360,128 420,130 480,131 540,132 600,133 660,133" fill="none" stroke="#f59e0b" stroke-width="2"/>
  <text x="665" y="65" fill="#f59e0b" font-size="7.5">NLP Sentiment (fast decay)</text>
  <!-- X-axis labels -->
  <text x="60"  y="167" text-anchor="middle" fill="#6b7280" font-size="7.5">1d</text>
  <text x="120" y="167" text-anchor="middle" fill="#6b7280" font-size="7.5">2d</text>
  <text x="180" y="167" text-anchor="middle" fill="#6b7280" font-size="7.5">3d</text>
  <text x="240" y="167" text-anchor="middle" fill="#6b7280" font-size="7.5">5d</text>
  <text x="300" y="167" text-anchor="middle" fill="#6b7280" font-size="7.5">10d</text>
  <text x="360" y="167" text-anchor="middle" fill="#6b7280" font-size="7.5">21d</text>
  <text x="420" y="167" text-anchor="middle" fill="#6b7280" font-size="7.5">42d</text>
  <text x="480" y="167" text-anchor="middle" fill="#6b7280" font-size="7.5">63d</text>
  <text x="540" y="167" text-anchor="middle" fill="#6b7280" font-size="7.5">126d</text>
  <text x="600" y="167" text-anchor="middle" fill="#6b7280" font-size="7.5">252d</text>
  <text x="355" y="185" text-anchor="middle" fill="#9ca3af" font-size="8">Prediction Horizon (trading days)</text>
  <text x="30" y="100" fill="#9ca3af" font-size="8" transform="rotate(-90,30,100)">IC</text>
  <!-- Annotation -->
  <rect x="65" y="175" width="280" height="18" rx="3" fill="#1a2332" stroke="#374151" stroke-width="1"/>
  <text x="205" y="187" text-anchor="middle" fill="#9ca3af" font-size="7.5">Mid-freq sweet spot: NLP decays by 5d; Momentum persists to 21d+</text>
</svg>'
            )
          )
      )
    ),

    # ── Box 4: Ch.5 Modelling ─────────────────────────────────────────────────
    fluidRow(
      box(title="Box 4 — Ch.5: Modelling in Low Signal-to-Noise Environments (K&B)", status="info", solidHeader=TRUE, width=12,
          id="qt-box4",
          div(qtBtn("qt-box4","qt4p1","Model Selection"),
              qtBtn("qt-box4","qt4p2","Purged Walk-Forward CV"),
              qtBtn("qt-box4","qt4p3","Ensemble Architecture"),
              qtBtn("qt-box4","qt4p4","Experiment Tracking")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          qtPanel("qt4p1",
            div(class="section-heading-dark", "K&B Model Selection Framework — Quant Low-SNR Context"),
            div(class="warn-box", HTML("<strong>K&amp;B Ch.5 Critical Warning:</strong> In low SNR environments (expected IC ~0.03-0.06), complex models do NOT necessarily outperform simple ones. The regularisation requirement increases with model complexity. An overfit LightGBM with IC=0.05 in backtest may deliver IC=-0.01 live. Start with interpretable baselines.")),
            br(),
            fluidRow(
              column(7,
                tags$table(class="table table-hover",
                  tags$thead(tags$tr(tags$th("Model"), tags$th("IC (backtest)"), tags$th("IC (live est.)"), tags$th("Pros"), tags$th("K&B Verdict"))),
                  tags$tbody(
                    tags$tr(tags$td("Rank IC baseline"), tags$td("0.03"), tags$td("0.03"), tags$td("No parameters; honest floor"), tags$td(tags$span(class="badge-green","Baseline"))),
                    tags$tr(tags$td("Ridge Regression"), tags$td("0.045"), tags$td("0.038"), tags$td("Interpretable; well-regularised"), tags$td(tags$span(class="badge-blue","Step 2"))),
                    tags$tr(tags$td("Lasso"), tags$td("0.048"), tags$td("0.040"), tags$td("Sparse; automatic factor selection"), tags$td(tags$span(class="badge-blue","Step 2"))),
                    tags$tr(tags$td("LightGBM (tuned)"), tags$td("0.062"), tags$td("0.044"), tags$td("Non-linear interactions; fast"), tags$td(tags$span(class="badge-blue","Champion"))),
                    tags$tr(tags$td("LSTM"), tags$td("0.071"), tags$td("0.030"), tags$td("Sequential patterns"), tags$td(tags$span(class="stage-pill","Caution: overfit risk"))),
                    tags$tr(tags$td("Transformer"), tags$td("0.078"), tags$td("0.018"), tags$td("Cross-asset attention"), tags$td(tags$span(class="warn-box","Backtest inflation likely")))
                  )
                )
              ),
              column(5,
                div(class="framework-card",
                  tags$h5("Why Simple Models Often Win in Quant"),
                  tags$ul(
                    tags$li(tags$b("Signal is genuinely weak:"), " Expected IC of 0.03-0.06 means 3-6% rank correlation. Complex models cannot extract more signal than exists."),
                    tags$li(tags$b("Sample size problem:"), " 15 years × 1000 stocks = 15,000 × 252 = ~3.7M training samples, but regime correlation means effective sample size is much smaller."),
                    tags$li(tags$b("Non-stationarity:"), " Market regimes shift. A model trained on 2010-2018 may fail in 2022's rate environment."),
                    tags$li(tags$b("K&B baseline hierarchy:"), " Rank IC → Ridge → LightGBM → ensemble. Each step must justify additional complexity with out-of-sample improvement.")
                  )
                )
              )
            )
          ),

          qtPanel("qt4p2",
            div(class="section-heading-dark", "Purged Walk-Forward Cross-Validation — K&B Ch.5 Time Series"),
            fluidRow(
              column(6,
                div(class="warn-box", HTML("<strong>K&amp;B Ch.5 — Standard k-Fold CV Is INVALID for financial time series.</strong> Standard k-fold shuffles data randomly. Financial data is serially correlated — a training sample from 2019 and a test sample from 2018 creates information leakage through overlapping return horizons.")),
                br(),
                div(class="framework-card",
                  tags$h5("Purged k-Fold with Embargo"),
                  tags$ul(
                    tags$li(tags$b("Purging:"), " Remove training samples whose labels overlap in time with any test sample. If predicting 5-day forward return, purge 5 days before test period."),
                    tags$li(tags$b("Embargo:"), " Additional gap between train end and test start to account for feature autocorrelation. Typical: 21 trading days (1 month)."),
                    tags$li(tags$b("Walk-forward structure:"), " Train on oldest data, test on next period. Advance forward. Never test on data before training data."),
                    tags$li(tags$b("Combinatorial purged k-fold (CPCV):"), " López de Prado (2018) method: multiple train/test splits with all pairs purged. More exhaustive backtest coverage.")
                  )
                )
              ),
              column(6,
                HTML('
<svg viewBox="0 0 380 200" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <text x="190" y="14" text-anchor="middle" fill="#e8410a" font-size="9.5" font-weight="bold">Walk-Forward CV with Embargo</text>
  <!-- Fold 1 -->
  <rect x="10" y="25" width="200" height="18" rx="3" fill="#0c1f3a" stroke="#3b82f6" stroke-width="1.2"/>
  <text x="110" y="38" text-anchor="middle" fill="#93c5fd" font-size="8">Train Fold 1</text>
  <rect x="212" y="25" width="14" height="18" rx="2" fill="#1a2332" stroke="#ef4444" stroke-width="1"/>
  <text x="219" y="38" text-anchor="middle" fill="#ef4444" font-size="7">E</text>
  <rect x="228" y="25" width="60" height="18" rx="3" fill="#0a1f18" stroke="#10b981" stroke-width="1.2"/>
  <text x="258" y="38" text-anchor="middle" fill="#6ee7b7" font-size="8">Test 1</text>
  <!-- Fold 2 -->
  <rect x="10" y="52" width="260" height="18" rx="3" fill="#0c1f3a" stroke="#3b82f6" stroke-width="1.2"/>
  <text x="135" y="65" text-anchor="middle" fill="#93c5fd" font-size="8">Train Fold 2</text>
  <rect x="272" y="52" width="14" height="18" rx="2" fill="#1a2332" stroke="#ef4444" stroke-width="1"/>
  <text x="279" y="65" text-anchor="middle" fill="#ef4444" font-size="7">E</text>
  <rect x="288" y="52" width="60" height="18" rx="3" fill="#0a1f18" stroke="#10b981" stroke-width="1.2"/>
  <text x="318" y="65" text-anchor="middle" fill="#6ee7b7" font-size="8">Test 2</text>
  <!-- Fold 3 -->
  <rect x="10" y="79" width="320" height="18" rx="3" fill="#0c1f3a" stroke="#3b82f6" stroke-width="1.2"/>
  <text x="170" y="92" text-anchor="middle" fill="#93c5fd" font-size="8">Train Fold 3</text>
  <rect x="332" y="79" width="14" height="18" rx="2" fill="#1a2332" stroke="#ef4444" stroke-width="1"/>
  <text x="339" y="92" text-anchor="middle" fill="#ef4444" font-size="7">E</text>
  <rect x="348" y="79" width="28" height="18" rx="3" fill="#0a1f18" stroke="#10b981" stroke-width="1.2"/>
  <text x="362" y="92" text-anchor="middle" fill="#6ee7b7" font-size="8">T3</text>
  <!-- Legend -->
  <rect x="10"  y="112" width="12" height="9" rx="2" fill="#0c1f3a" stroke="#3b82f6" stroke-width="1.2"/>
  <text x="26"  y="120" fill="#9ca3af" font-size="7.5">Training window (expanding)</text>
  <rect x="10"  y="128" width="12" height="9" rx="2" fill="#1a2332" stroke="#ef4444" stroke-width="1"/>
  <text x="26"  y="136" fill="#9ca3af" font-size="7.5">Embargo (21 trading days)</text>
  <rect x="10"  y="144" width="12" height="9" rx="2" fill="#0a1f18" stroke="#10b981" stroke-width="1.2"/>
  <text x="26"  y="152" fill="#9ca3af" font-size="7.5">Test window (OOS evaluation)</text>
  <rect x="10"  y="168" width="360" height="24" rx="4" fill="#1a2332" stroke="#374151" stroke-width="1"/>
  <text x="190" y="183" text-anchor="middle" fill="#6b7280" font-size="7.5">Critical: never test on data chronologically before training data. No shuffling.</text>
</svg>'
                )
              )
            )
          ),

          qtPanel("qt4p3",
            div(class="section-heading-dark", "Ensemble Architecture — K&B Ch.5"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Signal Ensemble (Stacking Approach)"),
                  tags$p("K&B: ensembles reduce variance at the cost of interpretability. In quant, the key question is whether the ensemble preserves factor orthogonality."),
                  tags$ol(
                    tags$li(tags$b("Layer 1 — Factor signals:"), " Ridge regression per factor group (price, fundamental, sentiment, microstructure)"),
                    tags$li(tags$b("Layer 2 — Regime-conditional:"), " Separate LightGBM models for bull/bear/high-volatility regimes"),
                    tags$li(tags$b("Layer 3 — Combiner:"), " Weighted average by OOS IC from last 63d (adaptive weighting — recently performing signals get higher weight)"),
                    tags$li(tags$b("Layer 4 — Risk overlay:"), " Neutralise residual factor exposures before portfolio construction")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Regime-Conditional Modelling"),
                  tags$p("K&B Ch.5: model selection should be informed by the deployment context. Quant markets have non-stationary regimes:"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Regime"), tags$th("Indicator"), tags$th("Best Factors"), tags$th("Worst Factors"))),
                    tags$tbody(
                      tags$tr(tags$td("Bull trend"), tags$td("VIX < 15, SPX > MA200"), tags$td("Momentum, Quality"), tags$td("Mean-reversion")),
                      tags$tr(tags$td("High volatility"), tags$td("VIX > 25"), tags$td("Low-vol, Value"), tags$td("Momentum (crashes)")),
                      tags$tr(tags$td("Crisis (deleveraging)"), tags$td("VIX > 40, credit spreads spike"), tags$td("Defensive, Short Int"), tags$td("Almost all factors")),
                      tags$tr(tags$td("Rate rising"), tags$td("10yr > 4%, rising"), tags$td("Value, Financials"), tags$td("Growth, Duration"))
                    )
                  )
                )
              )
            )
          ),

          qtPanel("qt4p4",
            div(class="section-heading-dark", "Experiment Tracking — K&B Ch.5 Applied to Quant Research"),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("Run"), tags$th("Model"), tags$th("Features"), tags$th("OOS IC"), tags$th("Sharpe (net)"), tags$th("Max DD"), tags$th("Status"))),
              tags$tbody(
                tags$tr(style="color:#6b7280;", tags$td("R-01"), tags$td("Rank IC"), tags$td("Momentum only"), tags$td("0.031"), tags$td("0.68"), tags$td("-8.2%"), tags$td("Baseline")),
                tags$tr(tags$td("R-02"), tags$td("Ridge"), tags$td("20 price factors"), tags$td("0.042"), tags$td("0.89"), tags$td("-7.1%"), tags$td("Improved")),
                tags$tr(tags$td("R-03"), tags$td("Ridge"), tags$td("+ Fundamentals"), tags$td("0.048"), tags$td("0.97"), tags$td("-6.8%"), tags$td("Improved")),
                tags$tr(tags$td("R-04"), tags$td("LightGBM"), tags$td("All 120 factors"), tags$td("0.044"), tags$td("0.91"), tags$td("-7.9%"), tags$td("Overfit: BT IC 0.072")),
                tags$tr(tags$td("R-05"), tags$td("LightGBM (reg.)"), tags$td("Top 60 factors"), tags$td("0.052"), tags$td("1.08"), tags$td("-6.3%"), tags$td("Improved")),
                tags$tr(style="background:rgba(16,185,129,0.1);font-weight:bold;",
                  tags$td("R-06"), tags$td("Ensemble (R02+R03+R05)"), tags$td("All, regime-conditional"), tags$td("0.058"), tags$td("1.24"), tags$td("-5.8%"), tags$td(HTML("\U0001F3C6 Champion")))
              )
            ),
            div(class="tip-box", HTML("<strong>K&amp;B Experiment Tracking in Quant:</strong> Every run must log: data snapshot hash, universe definition, transaction cost assumption used, embargo period, train/test split dates, and whether the result is in-sample or out-of-sample. Backtest inflation is the #1 research dishonesty risk."))
          )
      )
    ),

    # ── Box 5: Ch.6 Evaluation ────────────────────────────────────────────────
    fluidRow(
      box(title="Box 5 — Ch.6: Evaluation — Financial Metrics & Walk-Forward (K&B)", status="danger", solidHeader=TRUE, width=12,
          id="qt-box5",
          div(qtBtn("qt-box5","qt5p1","Financial Evaluation Metrics"),
              qtBtn("qt-box5","qt5p2","Sliced Evaluation"),
              qtBtn("qt-box5","qt5p3","Backtest vs Live Gap"),
              qtBtn("qt-box5","qt5p4","Transaction Cost Reality")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          qtPanel("qt5p1",
            fluidRow(
              column(6,
                div(class="section-heading-dark", "K&B Metric Selection Applied to Quant"),
                div(class="tip-box", HTML("<strong>K&amp;B Ch.6:</strong> Choose metrics that reflect the real cost of errors. In quant ML, the cost of a bad prediction is financial loss and opportunity cost. Standard ML metrics (RMSE, AUC) are necessary but not sufficient — you must translate to financial metrics.")),
                tags$table(class="table table-sm",
                  tags$thead(tags$tr(tags$th("ML Metric"), tags$th("Financial Equivalent"), tags$th("Why Financial Metric?"))),
                  tags$tbody(
                    tags$tr(tags$td("R² of return pred."), tags$td("IC (rank correlation)"), tags$td("R² rewards large-magnitude predictions; IC rewards rank ordering — what matters for long/short")),
                    tags$tr(tags$td("RMSE"), tags$td("Mean Absolute Return (MAR)"), tags$td("Symmetric loss; but we care more about direction than magnitude")),
                    tags$tr(tags$td("Hit rate (accuracy)"), tags$td("Hit rate at portfolio level"), tags$td("Stock-level 52% hit rate → portfolio Sharpe depends heavily on sizing")),
                    tags$tr(tags$td("AUC-ROC"), tags$td("ICIR (IC / std(IC))"), tags$td("ICIR captures consistency of alpha, not just average — critical for Sharpe estimation")),
                    tags$tr(tags$td("Log loss"), tags$td("—"), tags$td("Not used — no calibration requirement in return prediction")
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Core Quant Evaluation Metrics (K&B Financial Translation)"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Metric"), tags$th("Formula"), tags$th("Target"))),
                    tags$tbody(
                      tags$tr(tags$td("IC (daily)"), tags$td("Rank corr(signal, forward return)"), tags$td("> 0.03")),
                      tags$tr(tags$td("ICIR"), tags$td("mean(IC) / std(IC)"), tags$td("> 0.5")),
                      tags$tr(tags$td("Sharpe Ratio (net)"), tags$td("(R_ann - Rf) / σ_ann after costs"), tags$td("> 1.0")),
                      tags$tr(tags$td("Information Ratio"), tags$td("α / TE (tracking error)"), tags$td("> 0.8")),
                      tags$tr(tags$td("Max Drawdown"), tags$td("Peak-to-trough % loss"), tags$td("< 15%")),
                      tags$tr(tags$td("Calmar Ratio"), tags$td("CAGR / Max Drawdown"), tags$td("> 0.5")),
                      tags$tr(tags$td("Turnover"), tags$td("Portfolio replaced per year"), tags$td("< 500% (cost aware)"))
                    )
                  )
                )
              )
            )
          ),

          qtPanel("qt5p2",
            div(class="section-heading-dark", "Sliced Evaluation — K&B Ch.6 Applied to Equities"),
            div(class="warn-box", HTML("<strong>K&amp;B Ch.6 Mandatory:</strong> Aggregate Sharpe can look strong while signal completely fails in certain sectors (e.g., financials during crisis) or market-cap segments. Sliced evaluation is required for risk management.")),
            br(),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("Slice"), tags$th("Segment"), tags$th("OOS IC"), tags$th("Sharpe"), tags$th("Action"))),
              tags$tbody(
                tags$tr(tags$td("Overall"), tags$td("Full universe (Russell 1000)"), tags$td("0.058"), tags$td("1.24"), tags$td(tags$span(class="badge-green","Champion"))),
                tags$tr(tags$td("Sector"), tags$td("Technology"), tags$td("0.071"), tags$td("1.42"), tags$td("✅ Strong")),
                tags$tr(tags$td("Sector"), tags$td("Financials"), tags$td("0.038"), tags$td("0.72"), tags$td("⚠ Reduce allocation")),
                tags$tr(tags$td("Sector"), tags$td("Energy (volatile)"), tags$td("0.022"), tags$td("0.48"), tags$td("❌ Drop from universe")),
                tags$tr(tags$td("Market cap"), tags$td("Large cap (> $10B)"), tags$td("0.055"), tags$td("1.18"), tags$td("✅ Good")),
                tags$tr(tags$td("Market cap"), tags$td("Mid cap ($2B-$10B)"), tags$td("0.063"), tags$td("1.31"), tags$td("✅ Best")),
                tags$tr(tags$td("Regime"), tags$td("2008 GFC"), tags$td("-0.018"), tags$td("-0.41"), tags$td("❌ Factor breakdown")),
                tags$tr(tags$td("Regime"), tags$td("2020 COVID crash"), tags$td("-0.008"), tags$td("-0.12"), tags$td("⚠ Partial breakdown")),
                tags$tr(tags$td("Regime"), tags$td("2022 rate shock"), tags$td("0.031"), tags$td("0.61"), tags$td("⚠ Degraded")),
                tags$tr(tags$td("Time"), tags$td("Recent 2 years (OOS)"), tags$td("0.044"), tags$td("0.93"), tags$td("⚠ Some decay — monitor"))
              )
            )
          ),

          qtPanel("qt5p3",
            div(class="section-heading-dark", "Backtest vs Live Gap — K&B Offline-Online Gap in Quant Context"),
            div(class="warn-box", HTML("<strong>K&amp;B Ch.6 — The Quant Offline-Online Gap is the industry's biggest problem.</strong> The average backtest Sharpe at hedge funds is ~2.5. The average live Sharpe of launched strategies is ~0.8. This factor-of-3 gap has well-documented sources.")),
            br(),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("Gap Source"), tags$th("K&B Parallel"), tags$th("Mechanism"), tags$th("Magnitude"), tags$th("Fix"))),
              tags$tbody(
                tags$tr(tags$td("Lookahead bias"), tags$td("Label contamination"), tags$td("Using data not available at prediction time"), tags$td("Very large (0.5-1.5 Sharpe)"), tags$td("Strict point-in-time data infrastructure")),
                tags$tr(tags$td("Overfitting"), tags$td("Feedback loop"), tags$td("Model fit to historical noise patterns"), tags$td("Large (0.3-0.8 Sharpe)"), tags$td("Purged CV; regularisation; fewer parameters")),
                tags$tr(tags$td("Transaction costs"), tags$td("Distribution shift"), tags$td("Backtest uses 0 or 1bp costs; live = 5-20bp + market impact"), tags$td("Moderate (0.2-0.5 Sharpe)"), tags$td("Realistic TCM in backtest")),
                tags$tr(tags$td("Market impact"), tags$td("Position shift"), tags$td("Moving price when executing large orders"), tags$td("Moderate (0.1-0.3 Sharpe)"), tags$td("Capacity analysis; Kyle lambda model")),
                tags$tr(tags$td("Factor crowding"), tags$td("Concept drift"), tags$td("Other funds trade the same signal → alpha erodes"), tags$td("Growing over time"), tags$td("Crowding indicator monitoring")),
                tags$tr(tags$td("Data snooping"), tags$td("Feedback loop"), tags$td("Same dataset used to generate and test hypotheses"), tags$td("Small but cumulative"), tags$td("Reserve final OOS period — never revisit"))
              )
            )
          ),

          qtPanel("qt5p4",
            div(class="section-heading-dark", "Transaction Cost Modelling — K&B Serving Constraints"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Cost Components in Mid-Frequency Equities"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Cost Type"), tags$th("Typical bps"), tags$th("Driver"))),
                    tags$tbody(
                      tags$tr(tags$td("Commission"), tags$td("0.5-2 bps"), tags$td("Broker agreement")),
                      tags$tr(tags$td("Bid-ask spread (1/2)"), tags$td("2-10 bps"), tags$td("Stock liquidity, volatility")),
                      tags$tr(tags$td("Market impact"), tags$td("5-50 bps"), tags$td("Order size / ADV ratio")),
                      tags$tr(tags$td("Timing risk"), tags$td("1-5 bps"), tags$td("VWAP deviation during execution")),
                      tags$tr(tags$td("Short borrow cost"), tags$td("25-500 bps/yr"), tags$td("Hard-to-borrow stocks")),
                      tags$tr(tags$td("Total (round-trip)"), tags$td(tags$b("15-70 bps"), style="font-weight:bold"), tags$td("Depends on stock, size"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Kyle Lambda Market Impact Model"),
                  tags$p("Market impact scales with order size relative to average daily volume (ADV):"),
                  tags$p(tags$b("Impact (bps) ≈ λ × √(participation_rate)")),
                  tags$p("Where participation_rate = order_size / ADV"),
                  tags$ul(
                    tags$li("At 1% participation: ~5 bps impact"),
                    tags$li("At 5% participation: ~11 bps impact"),
                    tags$li("At 20% participation: ~22 bps impact — avoid")
                  ),
                  div(class="success-box", HTML("<strong>K&amp;B Ch.6 practical implication:</strong> A signal with IC=0.05 generates gross Sharpe ~1.5 at low turnover. After 15-25 bps round-trip costs at typical participation, net Sharpe drops to ~0.8-1.0. A signal must be strong enough to survive realistic costs."))
                )
              )
            )
          )
      )
    ),

    # ── Box 6: Ch.7 Serving ───────────────────────────────────────────────────
    fluidRow(
      box(title="Box 6 — Ch.7: Serving — Execution-Aware Signal Deployment (K&B)", status="warning", solidHeader=TRUE, width=12,
          id="qt-box6",
          div(qtBtn("qt-box6","qt6p1","Signal Generation Pipeline"),
              qtBtn("qt-box6","qt6p2","Portfolio Construction"),
              qtBtn("qt-box6","qt6p3","Execution Integration"),
              qtBtn("qt-box6","qt6p4","Deployment Strategy")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          qtPanel("qt6p1",
            div(class="section-heading-dark", "Signal Generation Pipeline — K&B Batch + Streaming Hybrid"),
            fluidRow(
              column(6,
                div(class="framework-card", style="border-left:3px solid #3b82f6;",
                  tags$h5("EOD Batch Pipeline (Primary)"),
                  tags$p("After market close, the nightly batch runs:"),
                  tags$ol(
                    tags$li("Ingest EOD prices, volume, corporate actions from data vendors (~6:00 PM)"),
                    tags$li("Recompute all daily features for full universe (1000+ stocks)"),
                    tags$li("Run ML model inference → raw alpha scores"),
                    tags$li("Apply cross-sectional normalisation → z-scores"),
                    tags$li("Portfolio optimiser: mean-variance with constraints"),
                    tags$li("Generate order target weights → order generation"),
                    tags$li("SLO: Complete by 9:00 PM (before overnight risk limits)")
                  )
                )
              ),
              column(6,
                div(class="framework-card", style="border-left:3px solid #10b981;",
                  tags$h5("Intraday Signal Refresh (Execution)"),
                  tags$p("During trading day for execution optimisation:"),
                  tags$ul(
                    tags$li(tags$b("30-min refresh:"), " Update short-term momentum, intraday volume profile, bid-ask spread estimate"),
                    tags$li(tags$b("Execution signal:"), " When to trade — not whether. Uses microstructure features."),
                    tags$li(tags$b("Urgency model:"), " Predict end-of-day price direction → adjusts execution schedule (more urgent = faster fill)"),
                    tags$li(tags$b("K&B freshness SLO:"), " Intraday signal lag < 5 minutes. Not sub-millisecond — mid-frequency does not need HFT infrastructure.")
                  )
                )
              )
            )
          ),

          qtPanel("qt6p2",
            div(class="section-heading-dark", "Portfolio Construction — K&B Serving with Business Constraints"),
            fluidRow(
              column(5,
                div(class="framework-card",
                  tags$h5("Mean-Variance Optimiser with Constraints"),
                  div(style="background:#0a0d0f;padding:10px;border-radius:4px;font-family:'JetBrains Mono',monospace;font-size:10px;color:#6ee7b7;",
                    HTML("maximise:<br>&nbsp;&nbsp;α^T w - (λ/2) w^T Σ w<br><br>subject to:<br>&nbsp;&nbsp;sum(w) = 1 (long-short)<br>&nbsp;&nbsp;|w_i| &le; 0.05 (max 5% per stock)<br>&nbsp;&nbsp;|sector_exposure| &le; 0.10<br>&nbsp;&nbsp;|factor_exposure| &le; 0.30<br>&nbsp;&nbsp;turnover &le; 20% per day<br>&nbsp;&nbsp;beta_exposure in [-0.1, 0.1]<br>&nbsp;&nbsp;gross_leverage &le; 2.0")
                  )
                )
              ),
              column(7,
                div(class="framework-card",
                  tags$h5("K&B Constraint Taxonomy Applied to Portfolio Construction"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Constraint"), tags$th("K&B Category"), tags$th("Rationale"))),
                    tags$tbody(
                      tags$tr(tags$td("Max position 5%"), tags$td("Business constraint"), tags$td("Concentration risk; liquidity limit")),
                      tags$tr(tags$td("Sector neutrality ±10%"), tags$td("Risk constraint"), tags$td("Avoid unintended macro bets")),
                      tags$tr(tags$td("Factor neutrality"), tags$td("Feature neutralisation"), tags$td("Alpha should not just be value/momentum/size tilt")),
                      tags$tr(tags$td("Beta neutral ±0.1"), tags$td("Risk constraint"), tags$td("Avoid implicit market direction bet")),
                      tags$tr(tags$td("Max turnover 20%/day"), tags$td("Serving SLO"), tags$td("Transaction cost control")),
                      tags$tr(tags$td("Long-short balance"), tags$td("Regulatory"), tags$td("Market neutral mandate; FCA leverage rules"))
                    )
                  )
                )
              )
            )
          ),

          qtPanel("qt6p3",
            div(class="section-heading-dark", "Execution Integration — K&B Serving Architecture for Quant"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Execution Algorithm Selection"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Algorithm"), tags$th("Use Case"), tags$th("When to Use"))),
                    tags$tbody(
                      tags$tr(tags$td("VWAP"), tags$td("Participate at volume"), tags$td("Low urgency; large orders; &gt; 1% ADV")),
                      tags$tr(tags$td("TWAP"), tags$td("Time-slice execution"), tags$td("Specific window; avoid market impact")),
                      tags$tr(tags$td("POV (15%)"), tags$td("Percentage of volume"), tags$td("Medium urgency; 0.5-2% ADV")),
                      tags$tr(tags$td("IS (Implementation Shortfall)"), tags$td("Minimize decision price gap"), tags$td("High urgency; time-sensitive alpha")),
                      tags$tr(tags$td("Smart Limit Order"), tags$td("Passive fill seeking"), tags$td("Very low urgency; days to fill")
                      )
                    )
                  )
                )
              ),
              column(6,
                div(class="tip-box", HTML("<strong>K&B Ch.7 — Execution Awareness:</strong> The signal tells you WHAT to buy/sell. The execution algorithm tells you HOW. A strong alpha signal with poor execution can deliver negative net P&amp;L. K&amp;B's lesson: serving constraints (cost, latency) are as important as model quality.")),
                div(class="framework-card",
                  tags$h5("Capacity Analysis"),
                  tags$p("K&B: every model has a capacity limit beyond which market impact overwhelms alpha."),
                  tags$ul(
                    tags$li("Mid-frequency equity signal: typical capacity $50M-$500M AUM"),
                    tags$li("Capacity = f(IC, universe liquidity, turnover, market impact)"),
                    tags$li("At $500M: 1% ADV participation → significant market impact for small caps"),
                    tags$li("Scale = enemy of alpha: larger AUM → slower execution → alpha decay")
                  )
                )
              )
            )
          ),

          qtPanel("qt6p4",
            div(class="section-heading-dark", "Deployment Strategy — K&B Shadow → Paper → Live"),
            div(class="phase-cards",
              div(class="phase-card phase-blue",
                tags$h5("Phase 1 — Paper Trading (Shadow)"),
                tags$p(tags$b("Duration:"), " 3-6 months"),
                tags$ul(tags$li("Signal generated and logged but no real orders"), tags$li("All costs modelled (bid-ask, market impact)"), tags$li("Risk model validated against hypothetical P&L"), tags$li("K&B: shadow mode is mandatory for new models"))
              ),
              div(class="phase-card phase-amber",
                tags$h5("Phase 2 — Partial Capital"),
                tags$p(tags$b("Duration:"), " 6-12 months"),
                tags$ul(tags$li("10-25% of target capital allocated"), tags$li("Live fills vs model price: slippage analysis"), tags$li("Live IC vs backtest IC comparison"), tags$li("Independent risk sign-off required"))
              ),
              div(class="phase-card phase-green",
                tags$h5("Phase 3 — Full Deployment"),
                tags$p(tags$b("Trigger:"), " Paper + partial track record"),
                tags$ul(tags$li("Live Sharpe within 30% of OOS backtest"), tags$li("No unexpected factor exposure"), tags$li("Crowding indicators below threshold"), tags$li("Capital allocated up to capacity limit"))
              )
            )
          )
      )
    ),

    # ── Box 7: Ch.8 Monitoring ────────────────────────────────────────────────
    fluidRow(
      box(title="Box 7 — Ch.8: Monitoring — Signal Health, Crowding & Drift (K&B)", status="success", solidHeader=TRUE, width=12,
          id="qt-box7",
          div(qtBtn("qt-box7","qt7p1","Signal Health Monitoring"),
              qtBtn("qt-box7","qt7p2","Factor Crowding Detection"),
              qtBtn("qt-box7","qt7p3","Regime Drift"),
              qtBtn("qt-box7","qt7p4","MLOps Stack")),
          hr(style="border-color:#2d3748;margin:8px 0;"),

          qtPanel("qt7p1",
            div(class="section-heading-dark", "Signal Health Monitoring — K&B Ch.8 Drift Detection"),
            fluidRow(
              column(6,
                tags$table(class="table table-hover",
                  tags$thead(tags$tr(tags$th("Monitor Signal"), tags$th("Freq"), tags$th("Alert Threshold"), tags$th("Action"))),
                  tags$tbody(
                    tags$tr(tags$td("Rolling 21d IC"), tags$td("Daily"), tags$td("< 0.015 (half of target)"), tags$td("Research review; reduce capital")),
                    tags$tr(tags$td("ICIR (63d)"), tags$td("Daily"), tags$td("< 0.3"), tags$td("Reduce allocation")),
                    tags$tr(tags$td("Feature PSI (top factors)"), tags$td("Daily"), tags$td("> 0.1"), tags$td("Investigate data pipeline")),
                    tags$tr(tags$td("Prediction distribution"), tags$td("Daily"), tags$td("Mean shift > 0.5σ"), tags$td("Check normalisation logic")),
                    tags$tr(tags$td("Live vs paper slippage"), tags$td("Daily"), tags$td("Actual > model × 1.5"), tags$td("Reduce turnover; switch algo")),
                    tags$tr(tags$td("Drawdown"), tags$td("Real-time"), tags$td("> 8% from peak"), tags$td("Auto reduce position 50%")),
                    tags$tr(tags$td("Max drawdown"), tags$td("Real-time"), tags$td("> 12% from peak"), tags$td("Full stop; risk review"))
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("IC Rolling Window Chart"),
                  HTML('
<svg viewBox="0 0 320 140" xmlns="http://www.w3.org/2000/svg" style="width:100%;font-family:Inter,sans-serif;">
  <text x="160" y="12" text-anchor="middle" fill="#e8410a" font-size="8.5" font-weight="bold">21-Day Rolling IC — Live Monitoring</text>
  <line x1="25" y1="108" x2="310" y2="108" stroke="#374151" stroke-width="1.2"/>
  <line x1="25" y1="108" x2="25" y2="22" stroke="#374151" stroke-width="1.2"/>
  <line x1="25" y1="70" x2="310" y2="70" stroke="#1f2d3d" stroke-width="1" stroke-dasharray="3,3"/>
  <text x="22" y="70" text-anchor="end" fill="#6b7280" font-size="6.5">IC=0</text>
  <line x1="25" y1="47" x2="310" y2="47" stroke="rgba(16,185,129,0.3)" stroke-width="1" stroke-dasharray="3,3"/>
  <text x="22" y="47" text-anchor="end" fill="#10b981" font-size="6.5">0.03</text>
  <line x1="25" y1="90" x2="310" y2="90" stroke="rgba(239,68,68,0.3)" stroke-width="1" stroke-dasharray="3,3"/>
  <text x="22" y="90" text-anchor="end" fill="#ef4444" font-size="6.5">-0.01</text>
  <!-- IC line with crisis dip -->
  <polyline points="25,52 52,48 79,42 106,38 133,44 160,50 187,32 214,62 241,90 268,82 295,54 310,46" fill="none" stroke="#3b82f6" stroke-width="1.8"/>
  <!-- Alert zone fill -->
  <rect x="214" y="70" width="54" height="38" rx="0" fill="rgba(239,68,68,0.08)" stroke="none"/>
  <text x="241" y="130" text-anchor="middle" fill="#ef4444" font-size="7">Alert zone</text>
  <text x="50"  y="120" fill="#6b7280" font-size="6.5">2022</text>
  <text x="160" y="120" fill="#6b7280" font-size="6.5">2023</text>
  <text x="270" y="120" fill="#6b7280" font-size="6.5">2024</text>
</svg>'
                  )
                )
              )
            )
          ),

          qtPanel("qt7p2",
            div(class="section-heading-dark", "Factor Crowding Detection — K&B Feedback Loop in Quant Markets"),
            div(class="warn-box", HTML("<strong>K&amp;B Ch.8 — The Quant Feedback Loop (Crowding):</strong> When many systematic funds trade the same alpha signal, the signal erodes. Worse: in a market stress event (like the August 2007 Quant Meltdown), crowded positions unwind simultaneously — creating correlated losses across all funds trading the same factors. This is systemic risk caused by model homogeneity.")),
            br(),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Crowding Indicators"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Indicator"), tags$th("Measure"), tags$th("Alert Level"))),
                    tags$tbody(
                      tags$tr(tags$td("Short interest concentration"), tags$td("% float short in signal longs vs shorts"), tags$td("> 8% on longs")),
                      tags$tr(tags$td("13F overlap"), tags$td("Cosine similarity of our portfolio to HF 13F filings"), tags$td("> 0.35 similarity")),
                      tags$tr(tags$td("Factor return correlation"), tags$td("Cross-sectional IC vs market peers"), tags$td("Rising trend")),
                      tags$tr(tags$td("Bid-ask spread widening"), tags$td("Spread vs 90d average on signal stocks"), tags$td("> 1.5× normal")),
                      tags$tr(tags$td("Momentum factor vol"), tags$td("Abnormal volatility in factor returns"), tags$td("3σ spike"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Crowding Response Protocol"),
                  tags$ul(
                    tags$li(tags$b("Level 1 (amber):"), " Reduce position sizes 20% in most crowded decile of holdings. Shift to less-traded signal variants."),
                    tags$li(tags$b("Level 2 (red):"), " Reduce gross exposure 40%. Widen spread between target and current portfolio to slow rebalancing."),
                    tags$li(tags$b("Level 3 (crisis):"), " Drawdown trigger activates. Reduce to 20% of normal gross. Begin orderly unwind prioritising most liquid names.")
                  )
                ),
                div(class="success-box", HTML("<strong>K&amp;B diversification principle:</strong> Signal diversification — combining price, fundamental, sentiment, and microstructure factors reduces crowding risk because fewer competing funds will have identical factor exposure. No single factor should contribute &gt;30% of signal variance."))
              )
            )
          ),

          qtPanel("qt7p3",
            div(class="section-heading-dark", "Regime Drift — K&B Distribution Shift in Financial Markets"),
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Quant Drift Types — K&B Ch.8 Applied"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("K&B Drift Type"), tags$th("Quant Equivalent"), tags$th("Example"))),
                    tags$tbody(
                      tags$tr(tags$td("Covariate shift"), tags$td("Factor distribution shift"), tags$td("Post-QE: value factor P/E ratios compressed — 'cheap' stock redefined")),
                      tags$tr(tags$td("Concept drift"), tags$td("Alpha decay / regime change"), tags$td("2022 rate rise: growth/momentum factor negative; value re-emerges")),
                      tags$tr(tags$td("Label shift"), tags$td("Base rate shift"), tags$td("In crisis, expected return of all stocks is negative — cross-sectional ranking still works but absolute calibration fails")),
                      tags$tr(tags$td("Feature feedback"), tags$td("Factor crowding"), tags$td("As more funds use momentum, momentum signal erodes — training data predates crowding")
                      )
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Retraining Strategy"),
                  tags$table(class="table table-sm",
                    tags$thead(tags$tr(tags$th("Trigger"), tags$th("Action"), tags$th("Cadence"))),
                    tags$tbody(
                      tags$tr(tags$td("Scheduled"), tags$td("Expand training window by 3 months"), tags$td("Quarterly")),
                      tags$tr(tags$td("IC drift (PSI > 0.1)"), tags$td("Retrain with regime-weighted samples"), tags$td("Triggered")),
                      tags$tr(tags$td("Regime change"), tags$td("Activate regime-specific sub-model"), tags$td("Real-time switch")),
                      tags$tr(tags$td("New data source"), tags$td("Full retrain with new feature set"), tags$td("As needed")),
                      tags$tr(tags$td("Drawdown > 8%"), tags$td("Emergency retrain + risk review"), tags$td("Immediate"))
                    )
                  )
                ),
                div(class="tip-box", HTML("<strong>K&amp;B Stateless vs Stateful:</strong> Full stateless retrain every quarter (best for regime-change resilience). Stateful incremental update on recent 30 days (best for fast signal decay adaptation). K&amp;B recommendation: use both — quarterly stateless + monthly incremental fine-tune."))
              )
            )
          ),

          qtPanel("qt7p4",
            div(class="section-heading-dark", "Quant ML MLOps Stack — K&B Ch.8 Infrastructure"),
            tags$table(class="table table-hover",
              tags$thead(tags$tr(tags$th("Layer"), tags$th("K&B Category"), tags$th("Tool"), tags$th("Notes"))),
              tags$tbody(
                tags$tr(tags$td("Market data"), tags$td("Data layer"), tags$td("Refinitiv / Bloomberg API"), tags$td("Daily feed + historical backfill")),
                tags$tr(tags$td("PIT feature store"), tags$td("Feature layer"), tags$td("Arctic (MongoDB) or Parquet/S3"), tags$td("Bi-temporal; mandatory in quant")),
                tags$tr(tags$td("Factor library"), tags$td("Feature layer"), tags$td("Custom Python + NumPy/Pandas"), tags$td("Versioned; reproducible")),
                tags$tr(tags$td("Backtest engine"), tags$td("Training layer"), tags$td("Zipline / Backtrader / custom"), tags$td("Must model costs + slippage")),
                tags$tr(tags$td("Experiment tracking"), tags$td("Training layer"), tags$td("MLflow"), tags$td("Log: IC, Sharpe, drawdown, data hash")),
                tags$tr(tags$td("Model registry"), tags$td("Training layer"), tags$td("MLflow Registry"), tags$td("Champion + challenger always maintained")),
                tags$tr(tags$td("Signal generation"), tags$td("Serving layer"), tags$td("Airflow + Python batch"), tags$td("EOD pipeline; SLO: by 9 PM")),
                tags$tr(tags$td("Portfolio optimiser"), tags$td("Serving layer"), tags$td("CVXPY / custom solver"), tags$td("Constraints as K&B serving limits")),
                tags$tr(tags$td("Order management"), tags$td("Serving layer"), tags$td("FIX protocol → broker OMS"), tags$td("MiFID II algo registration")),
                tags$tr(tags$td("Monitoring"), tags$td("Monitoring layer"), tags$td("Custom dashboard + Grafana"), tags$td("IC decay, crowding, drawdown alerts"))
              )
            )
          )
      )
    ),

    # ── Self-Assessment ───────────────────────────────────────────────────────
    fluidRow(
      box(title="Self-Assessment — ML Quant Trading", status="primary", solidHeader=TRUE, width=12,
          fluidRow(
            column(4, sliderInput(ns("sc1"), "Requirements & Alpha Framing (Ch.1-2)", 1, 10, 5)),
            column(4, sliderInput(ns("sc2"), "PIT Data Pipeline & Lookahead Bias (Ch.3)", 1, 10, 5)),
            column(4, sliderInput(ns("sc3"), "Factor Engineering & Feature Store (Ch.4)", 1, 10, 5))
          ),
          fluidRow(
            column(4, sliderInput(ns("sc4"), "Low-SNR Modelling & Walk-Forward CV (Ch.5)", 1, 10, 5)),
            column(4, sliderInput(ns("sc5"), "Financial Metrics & Backtest Realism (Ch.6)", 1, 10, 5)),
            column(4, sliderInput(ns("sc6"), "Execution-Aware Serving & Monitoring (Ch.7-8)", 1, 10, 5))
          ),
          fluidRow(
            column(4, actionButton(ns("save_self"), "Save Assessment", class="btn-meta", width="100%")),
            column(8, uiOutput(ns("self_result")))
          )
      )
    )
  )
}

quant_trading_case_study_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_self, {
      avg <- mean(c(input$sc1, input$sc2, input$sc3, input$sc4, input$sc5, input$sc6))
      pct <- round(avg * 10)
      prep_manager$update_progress("quant_trading_case_study", pct)
      output$self_result <- renderUI({
        col <- progress_colour(pct)
        div(class = if(pct >= 80) "success-box" else "tip-box",
            tags$h5(style = paste0("color:", col), paste0("Quant ML Readiness: ", pct, "%")),
            if(pct < 50) tags$p("Focus: K&B Ch.3 (point-in-time data — the #1 quant interview test) and Ch.5 (purged walk-forward CV — standard k-fold is invalid for financial time series)."),
            if(pct >= 50 && pct < 80) tags$p("Good foundation. Deepen on: backtest-to-live gap sources, transaction cost modelling, and factor crowding as K&B concept drift."),
            if(pct >= 80) tags$p("\u2705 Strong quant ML command. You can connect K&B framework chapters to production equity alpha signal systems end-to-end.")
        )
      })
      showNotification("Quant trading assessment saved!", type="message")
    })
  })
}
