# modules/quant_trading_case_study.R
# Case Study: ML-Driven Mid-Frequency Equity Alpha Signals
# Applies Chip Huyen's full ML lifecycle to systematic quantitative trading

quant_trading_case_study_ui <- function(id) {
  ns <- NS(id)

  css <- "
  .qt-selector {
    display:flex; gap:5px; flex-wrap:wrap; margin-bottom:14px;
  }
  .qt-btn {
    padding:5px 15px; border-radius:18px; border:2px solid #b2dfdb;
    background:#fff; color:#008A82; font-size:11px; font-weight:700;
    cursor:pointer; transition:all 0.16s; letter-spacing:0.3px; white-space:nowrap;
  }
  .qt-btn:hover  { background:#e0f4f2; border-color:#008A82; }
  .qt-btn.active { background:#002C3C; border-color:#002C3C; color:#fff; }
  .qt-panel { display:none; animation:qtFade 0.18s ease; }
  .qt-panel.show { display:block; }
  @keyframes qtFade { from{opacity:0;transform:translateY(-5px)} to{opacity:1;transform:translateY(0)} }
  .qt-arch-node {
    display:inline-block; padding:7px 14px; border-radius:7px; margin:3px;
    font-size:11px; font-weight:700; border:2px solid;
  }
  .qt-arch-arr { color:#008A82; font-size:18px; font-weight:700; vertical-align:middle; margin:0 4px; }
  .qt-kpi-card {
    background:linear-gradient(135deg,#002C3C,#008A82);
    border-radius:10px; padding:14px; text-align:center; color:#fff; margin-bottom:10px;
  }
  .qt-kpi-val { font-size:1.8em; font-weight:800; display:block; font-family:'JetBrains Mono',monospace; }
  .qt-kpi-lbl { font-size:10px; text-transform:uppercase; letter-spacing:1px; opacity:0.75; margin-top:4px; }
  "

  js <- "
<script>
function qtShow(boxId, panelId) {
  document.querySelectorAll('#' + boxId + ' .qt-panel').forEach(function(p){ p.classList.remove('show'); });
  document.querySelectorAll('#' + boxId + ' .qt-btn').forEach(function(b){ b.classList.remove('active'); });
  var panel = document.getElementById(panelId);
  if (panel) panel.classList.add('show');
  var btn = document.querySelector('#' + boxId + ' [data-panel=\"' + panelId + '\"]');
  if (btn) btn.classList.add('active');
}
(function(){
  function init(){
    ['qt-box1','qt-box2','qt-box3','qt-box4','qt-box5'].forEach(function(boxId){
      var firstBtn = document.querySelector('#' + boxId + ' .qt-btn');
      if (firstBtn) firstBtn.click();
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else setTimeout(init, 120);
})();
</script>
"

  qtBtn <- function(boxId, panelId, label, active=FALSE) {
    tags$button(
      class=paste0("qt-btn", if(active)" active"else""),
      `data-panel`=panelId,
      onclick=sprintf("qtShow('%s','%s')", boxId, panelId),
      label
    )
  }
  qtPanel <- function(panelId, ...) div(id=panelId, class="qt-panel", ...)

  tagList(
    tags$head(tags$style(HTML(css))),
    HTML(js),

    # ── Hero ────────────────────────────────────────────────────────────────
    div(class="meta-hero",
      tags$h1("Case Study — ML-Driven Quantitative Trading"),
      tags$h2("Alpha signal research, low signal-to-noise ML, and full concept-to-production lifecycle for mid-frequency equity strategies"),
      div(
        span(class="hero-badge","Alpha Signals"),
        span(class="hero-badge","Mid-Frequency Equity"),
        span(class="hero-badge","Low SNR ML"),
        span(class="hero-badge","Backtest to Live"),
        span(class="hero-badge","Portfolio Construction"),
        span(class="hero-badge","Execution-Aware")
      ),
      tags$p(style="color:rgba(255,255,255,0.75);font-size:12px;margin-top:10px;",
        "The hardest ML environment in existence: non-stationary labels, adversarial market participants, regulatory constraints, and where a 0.05 Sharpe improvement can be worth millions. Every section maps to Chip Huyen's ML lifecycle.")
    ),

    # ── Architecture Overview ─────────────────────────────────────────────
    fluidRow(
      box(title="🏗️ Systematic Trading ML System Architecture", status="primary", solidHeader=TRUE, width=12,
        div(style="text-align:center;padding:16px;",
          div(style="margin-bottom:8px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","RAW DATA SOURCES"),
          div(
            span(class="qt-arch-node",style="background:#e3f2fd;border-color:#2980b9;color:#2980b9;","Price & Volume (OHLCV)"),
            span(class="qt-arch-node",style="background:#e3f2fd;border-color:#2980b9;color:#2980b9;","Order Book (L2/L3)"),
            span(class="qt-arch-node",style="background:#fff3e0;border-color:#e67e22;color:#e67e22;","Fundamentals & Earnings"),
            span(class="qt-arch-node",style="background:#fff3e0;border-color:#e67e22;color:#e67e22;","News & Sentiment NLP"),
            span(class="qt-arch-node",style="background:#e8f5e9;border-color:#27ae60;color:#27ae60;","Alternative Data"),
            span(class="qt-arch-node",style="background:#f3e5f5;border-color:#8e44ad;color:#8e44ad;","Macro & Risk Factors")
          ),
          div(style="font-size:22px;color:#008A82;margin:5px 0;","↓"),
          div(style="margin-bottom:6px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","FEATURE ENGINEERING PIPELINE"),
          div(
            span(class="qt-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Alpha Factor Library"),
            span(class="qt-arch-arr","→"),
            span(class="qt-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Cross-Sectional Normalisation"),
            span(class="qt-arch-arr","→"),
            span(class="qt-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Orthogonalisation"),
            span(class="qt-arch-arr","→"),
            span(class="qt-arch-node",style="background:#e0f4f2;border-color:#008A82;color:#008A82;","Feature Store")
          ),
          div(style="font-size:22px;color:#008A82;margin:5px 0;","↓"),
          div(style="margin-bottom:6px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","ML ALPHA RESEARCH"),
          div(
            span(class="qt-arch-node",style="background:#e8f5e9;border-color:#1a9b6b;color:#1a9b6b;","Signal Research"),
            span(class="qt-arch-arr","→"),
            span(class="qt-arch-node",style="background:#e8f5e9;border-color:#1a9b6b;color:#1a9b6b;","Walk-Forward Backtest"),
            span(class="qt-arch-arr","→"),
            span(class="qt-arch-node",style="background:#e8f5e9;border-color:#1a9b6b;color:#1a9b6b;","Execution Simulation"),
            span(class="qt-arch-arr","→"),
            span(class="qt-arch-node",style="background:#e8f5e9;border-color:#1a9b6b;color:#1a9b6b;","Portfolio Construction")
          ),
          div(style="font-size:22px;color:#008A82;margin:5px 0;","↓"),
          div(style="margin-bottom:6px;font-size:11px;font-weight:700;color:#546e7a;letter-spacing:1px;","LIVE PRODUCTION"),
          div(
            span(class="qt-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","Live Signal Generation"),
            span(class="qt-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","Risk Limits & Position Sizing"),
            span(class="qt-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","Execution Algorithm"),
            span(class="qt-arch-node",style="background:#fce4ec;border-color:#c0392b;color:#c0392b;","P&L Attribution")
          ),
          div(style="font-size:22px;color:#e67e22;margin:5px 0;","↺"),
          div(style="font-size:11px;color:#546e7a;font-weight:700;letter-spacing:1px;","LIVE PERFORMANCE → SIGNAL DECAY MONITORING → RETRAIN OR RETIRE"),
          br(),
          fluidRow(
            column(3, div(class="qt-kpi-card", span(class="qt-kpi-val","~0.05"), span(class="qt-kpi-lbl","Typical R² on returns"))),
            column(3, div(class="qt-kpi-card", span(class="qt-kpi-val","Sharpe"), span(class="qt-kpi-lbl","Primary live metric"))),
            column(3, div(class="qt-kpi-card", span(class="qt-kpi-val","Hours"), span(class="qt-kpi-lbl","Mid-freq holding period"))),
            column(3, div(class="qt-kpi-card", span(class="qt-kpi-val","<SNR"), span(class="qt-kpi-lbl","Signal-to-noise challenge")))
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 1: Ch.1-2 — Problem Definition & System Design
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="📋 Box 1 — Ch.1-2: Problem Definition & Trading System Design",
          status="primary", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 1 & 2 applied:</strong> Quantitative trading is one of the hardest ML problem framings in existence. The objective function, label definition, success metrics, and system constraints are all fundamentally different from standard ML — and getting them wrong destroys capital.")),
        br(),
        div(id="qt-box1",
          div(class="qt-selector",
            qtBtn("qt-box1","qt1-framing","Business → ML Framing", TRUE),
            qtBtn("qt-box1","qt1-tasks","ML Task Decomposition"),
            qtBtn("qt-box1","qt1-metrics","Alpha Metrics"),
            qtBtn("qt-box1","qt1-constraints","System Constraints"),
            qtBtn("qt-box1","qt1-loop","Iterative Research Loop")
          ),

          qtPanel("qt1-framing",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Business Goal → ML Objective Translation (Ch.1)"),
                  tags$p("The business goal is clear: generate risk-adjusted returns (alpha) above a benchmark. The ML framing is treacherous:"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Business Goal"),tags$th("Naive ML Objective"),tags$th("Problem"),tags$th("Correct Framing"))),
                    tags$tbody(
                      tags$tr(tags$td("Generate alpha"),        tags$td("Maximise return prediction R²"), tags$td("R²~0.001 is useless"), tags$td("Maximise Information Coefficient (IC)")),
                      tags$tr(tags$td("Maximise Sharpe"),       tags$td("Minimise MSE on next-day return"),tags$td("Ignores transaction costs"),tags$td("Maximise IC net of costs")),
                      tags$tr(tags$td("Diversify signals"),     tags$td("Best single model"),             tags$td("Overfitting on one regime"),tags$td("Ensemble of orthogonal signals")),
                      tags$tr(tags$td("Live deployment"),       tags$td("Best backtest Sharpe"),          tags$td("Look-ahead bias, overfitting"),tags$td("Walk-forward OOS Sharpe")),
                      tags$tr(tags$td("Portfolio construction"),tags$td("Maximise signal strength"),      tags$td("Ignores risk, correlation"),  tags$td("Mean-variance optimisation with signal"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Why Quant Trading is the Hardest ML Problem (Ch.1)"),
                  tags$ul(
                    tags$li(tags$b("Non-stationary labels:"), " stock returns are not drawn from a stable distribution. The relationship between features and returns changes continuously as markets evolve and participants adapt."),
                    tags$li(tags$b("Adversarial environment:"), " unlike medical imaging, your model's predictions become part of the market. As others discover the same signal, it decays. The data-generating process changes because of your model."),
                    tags$li(tags$b("Extremely low signal-to-noise:"), " a model with R²=0.005 on next-day equity returns is commercially valuable. Most ML models would be discarded at this performance level."),
                    tags$li(tags$b("Label contamination:"), " your execution affects the price you get. The label (return) is partly determined by your own behaviour."),
                    tags$li(tags$b("Small effective sample:"), " mid-frequency equity strategies may have 10 years of daily data across 500 stocks — far less than it appears due to cross-sectional correlation.")
                  ),
                  div(class="warn-box", HTML("<strong>Huyen Ch.1:</strong> The gap between ML objective and business objective is larger in quant trading than almost any other domain. A model that maximises validation Sharpe in backtesting frequently loses money live due to overfitting, signal decay, and execution costs not modelled in research."))
                )
              )
            )
          ),

          qtPanel("qt1-tasks",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Task 1 — Cross-Sectional Return Prediction"),
                  tags$p(tags$b("Framing:"), " at each rebalancing period t, rank all N stocks by predicted forward return. The prediction is relative (ranking), not absolute (price target)."),
                  tags$p(tags$b("Label:"), " cross-sectionally demeaned and volatility-normalised return over holding period H (hours to days for mid-frequency)."),
                  tags$p(tags$b("Model output:"), " a score per stock per period; stocks are ranked and the top/bottom deciles are long/short."),
                  tags$p(tags$b("Key difference from standard regression:"), " it does not matter if the model predicts +1.2% when the true return is +0.8%. What matters is whether it ranks the stock correctly relative to its peers.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Task 2 — Alpha Factor Research"),
                  tags$p(tags$b("Framing:"), " design individual predictive features (alpha factors) that each carry a small amount of information about future returns. The ML task is to combine them optimally."),
                  tags$p(tags$b("Classic factor families:"), ),
                  tags$ul(
                    tags$li(tags$b("Momentum:"), " 12-1 month return (skip last month to avoid reversal)"),
                    tags$li(tags$b("Value:"), " book-to-market, earnings yield, cashflow yield"),
                    tags$li(tags$b("Quality:"), " ROE, earnings stability, accruals ratio"),
                    tags$li(tags$b("Low volatility:"), " realised vol, idiosyncratic vol"),
                    tags$li(tags$b("Short-term reversal:"), " 1-week return (microstructure noise)"),
                    tags$li(tags$b("ML-discovered:"), " nonlinear combinations of the above")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Task 3 — Portfolio Construction"),
                  tags$p(tags$b("Framing:"), " given ML signal scores, build a portfolio that maximises risk-adjusted return while respecting constraints."),
                  tags$p(tags$b("This is a constrained optimisation problem, not pure ML:"),),
                  tags$ul(
                    tags$li("Maximise: signal × expected return"),
                    tags$li("Subject to: gross exposure limit, net exposure limit, sector neutrality, factor neutrality (no unintended beta bets), turnover limit (controls transaction costs), individual position limits")
                  ),
                  tags$p(tags$b("Execution-aware construction:"), " expected transaction cost must be modelled in the optimiser, not added as an afterthought. Signal strength must exceed expected round-trip cost to be worth trading.")
                )
              )
            )
          ),

          qtPanel("qt1-metrics",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Alpha Research Metrics (Offline — Ch.1)"),
                  tags$p("Standard ML metrics (R², MSE, AUC) are inadequate for trading. Purpose-built financial metrics:"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Metric"),tags$th("Definition"),tags$th("Target"),tags$th("Notes"))),
                    tags$tbody(
                      tags$tr(tags$td("IC (Information Coefficient)"),tags$td("Spearman rank corr: predicted vs realised rank"),tags$td("> 0.04"),tags$td("0.05 is commercially strong")),
                      tags$tr(tags$td("ICIR (IC Information Ratio)"),tags$td("Mean IC / Std(IC) over time"),                  tags$td("> 0.50"), tags$td("Stability measure")),
                      tags$tr(tags$td("Sharpe (backtest OOS)"),        tags$td("Annualised mean return / annualised vol"),      tags$td("> 1.0"),  tags$td("After costs, OOS only")),
                      tags$tr(tags$td("Max Drawdown"),                  tags$td("Peak-to-trough loss"),                        tags$td("< 15%"),  tags$td("Risk constraint")),
                      tags$tr(tags$td("Turnover"),                      tags$td("% portfolio replaced per period"),            tags$td("Depends"),tags$td("Higher = higher costs")),
                      tags$tr(tags$td("Hit Rate"),                      tags$td("% of trades profitable"),                     tags$td("> 51%"),  tags$td("Not sufficient alone")),
                      tags$tr(tags$td("Profit Factor"),                 tags$td("Gross profit / Gross loss"),                  tags$td("> 1.5"),  tags$td("Combined with hit rate"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Live Production Metrics (Online — Ch.1)"),
                  tags$ul(
                    tags$li(tags$b("Realised Sharpe ratio:"), " the primary live metric. Rolling 63-day Sharpe falling below 0.5 triggers review."),
                    tags$li(tags$b("Signal decay:"), " IC computed daily on live predictions. Declining trend over 30 days = signal alpha being arbitraged away."),
                    tags$li(tags$b("Execution quality:"), " slippage vs model (implementation shortfall). If slippage exceeds modelled cost, execution must be reviewed."),
                    tags$li(tags$b("Factor attribution:"), " decompose live P&L into: signal contribution, market beta, sector, and residual. Unexpected factor exposure = model risk."),
                    tags$li(tags$b("Capacity:"), " at what AUM does the strategy stop working because market impact erodes alpha? This is an online metric that cannot be measured in research.")
                  ),
                  div(class="warn-box", HTML("<strong>Huyen Ch.1 offline-online gap:</strong> In quant trading, the offline-online metric gap is guaranteed and can be large. Backtest Sharpe=2.0 frequently becomes live Sharpe=0.6 due to overfitting, signal decay, and unmodelled execution costs. Never deploy based on backtest metrics alone."))
                )
              )
            )
          ),

          qtPanel("qt1-constraints",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("System Constraints Unique to Trading (Ch.1)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Constraint"),tags$th("Description"),tags$th("ML Implication"))),
                    tags$tbody(
                      tags$tr(tags$td("Lookahead bias"),          tags$td("Using future data in features"),          tags$td("Temporal split is mandatory — no exceptions")),
                      tags$tr(tags$td("Survivorship bias"),       tags$td("Only training on stocks that survived"),  tags$td("Must include delisted stocks in training universe")),
                      tags$tr(tags$td("Transaction costs"),       tags$td("Bid-ask spread + market impact"),         tags$td("Net-of-cost IC is the only valid metric")),
                      tags$tr(tags$td("Market impact"),           tags$td("Trading moves the price against you"),    tags$td("Signal must be sized below impact threshold")),
                      tags$tr(tags$td("Short-selling limits"),    tags$td("Not all stocks borrowable"),              tags$td("Short side of signal may be inaccessible")),
                      tags$tr(tags$td("Regulatory"),              tags$td("FCA/SEC: no insider information"),        tags$td("Data sourcing must be compliance-approved")),
                      tags$tr(tags$td("Latency"),                 tags$td("Mid-freq: minutes to hours acceptable"),  tags$td("Batch inference at rebalancing time sufficient")),
                      tags$tr(tags$td("Capital constraints"),     tags$td("Position limits, gross/net exposure"),    tags$td("Optimiser must respect all constraints"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Mid-Frequency Strategy Scope"),
                  tags$p(tags$b("Mid-frequency definition:"), " holding periods of hours to several days. Trades at open/close or intraday based on signals that update daily or intraday. Distinguishable from:"),
                  tags$ul(
                    tags$li(tags$b("High-frequency (HFT):"), " microsecond to millisecond; pure microstructure; different ML problems (order flow prediction, market making)"),
                    tags$li(tags$b("Low-frequency:"), " weeks to months; fundamental-driven; longer signal horizon; lower turnover, lower transaction cost burden")
                  ),
                  tags$p(tags$b("Mid-frequency sweet spot:"), " frequent enough to capture short-term predictability; slow enough that fundamental data is usable; fast enough that ML features from price/volume carry real information."),
                  tags$p(tags$b("Equity universe:"), " typically 500-3000 liquid stocks (Russell 1000 / MSCI World). Liquidity filter ensures transaction costs are manageable. Illiquid small caps have stronger signals but are not scalable.")
                )
              )
            )
          ),

          qtPanel("qt1-loop",
            fluidRow(
              column(12,
                div(class="framework-card",
                  tags$h5("Huyen's 6-Step Iterative Loop Applied to Alpha Research (Ch.2)"),
                  fluidRow(
                    column(6,
                      timeline_entry("1","Project Scoping","Define: mid-frequency equity alpha for liquid US/European stocks. Universe: Russell 1000 + FTSE 350. Holding period: 1-5 days. Rebalancing: daily at close. Risk budget: target Sharpe > 1.5 net of costs. Capacity: scalable to $500M+ AUM."),
                      timeline_entry("2","Data Engineering","Price/volume (vendor: Bloomberg/Refinitiv), fundamentals (Compustat/WorldScope), news/NLP (RavenPack/Refinitiv News), alternative data (satellite, credit card). Point-in-time database mandatory to prevent lookahead bias. Store as columnar (Parquet/Arctic)."),
                      timeline_entry("3","Model Development","Start: single-factor IC analysis (rank correlation, t-stat). Baseline 2: linear combination of 5 factors. Target: gradient boosted tree on 50+ features with walk-forward validation. Feature importance via SHAP to understand which factors are driving predictions.")
                    ),
                    column(6,
                      timeline_entry("4","Evaluation","Walk-forward out-of-sample IC, ICIR, Sharpe net of costs. Sliced by sector, market cap, regime (bull/bear/volatile). Monte Carlo permutation test to confirm signal is not random. Backtest must include realistic transaction cost model."),
                      timeline_entry("5","Deployment","Paper trading first: generate signals without capital for 30 days. Compare live IC vs backtest IC. Then live with 10% of target capital. Ramp if live IC within 2σ of expected. Full position at 100% capital after 60-day validation."),
                      timeline_entry("6","Monitoring","Daily IC computation, rolling Sharpe, P&L attribution. Signal decay curve: plot IC vs time since model last retrained. Retrain trigger: 30-day IC falls below 50% of historical mean. Hard kill: drawdown exceeds 2× expected monthly loss.")
                    )
                  )
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 2: Ch.3-4-5 — Data Engineering, Training Data & Feature Engineering
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🗄️ Box 2 — Ch.3-4-5: Data Engineering, Training Data & Alpha Features",
          status="warning", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 3, 4 & 5 applied:</strong> Financial data has unique engineering challenges: point-in-time correctness to prevent lookahead bias, survivorship bias in stock universes, label construction from noisy returns, and feature normalisation specific to cross-sectional equity ML.")),
        br(),
        div(id="qt-box2",
          div(class="qt-selector",
            qtBtn("qt-box2","qt2-sources","Data Sources (Ch.3)", TRUE),
            qtBtn("qt-box2","qt2-labels","Label Construction (Ch.4)"),
            qtBtn("qt-box2","qt2-imbalance","Low SNR & Imbalance (Ch.4)"),
            qtBtn("qt-box2","qt2-features","Alpha Feature Engineering (Ch.5)"),
            qtBtn("qt-box2","qt2-skew","Train-Serve Skew in Trading")
          ),

          qtPanel("qt2-sources",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Structured Market Data (Ch.3)"),
                  tags$p(tags$b("Price & Volume (OHLCV):"), " daily and intraday bars. Sources: Bloomberg, Refinitiv, Interactive Brokers. Adjusted for splits and dividends (back-adjusted prices are mandatory — unadjusted prices create spurious discontinuities in features)."),
                  tags$p(tags$b("Order book (L2):"), " bid/ask spread, depth at each price level. Used for transaction cost modelling and microstructure features. Much larger data volume than OHLCV."),
                  tags$p(tags$b("Fundamentals:"), " Compustat/Worldscope. Earnings, book value, cashflow. Critical requirement: point-in-time database (as-reported, not restated). Restatements introduce lookahead bias."),
                  tags$p(tags$b("Storage:"), " columnar format (Parquet) for analytical queries. Arctic (MongoDB-based time-series store) commonly used in quant funds for versioned, point-in-time financial data.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Alternative & Unstructured Data (Ch.3)"),
                  tags$p(tags$b("News & NLP signals:"), " RavenPack, Refinitiv News Analytics. Pre-computed sentiment scores and event tags. Raw text requires NLP pipeline: FinBERT fine-tuned on financial news for entity-level sentiment."),
                  tags$p(tags$b("Satellite imagery:"), " parking lot occupancy (retail store traffic), oil tank fill levels (energy supply), shipping vessel positions (trade flows). Alpha from satellite imagery decays quickly as more funds adopt it."),
                  tags$p(tags$b("Credit card transaction data:"), " aggregated consumer spending by merchant category. Predictive for retail earnings surprises. Typically sourced from data vendors (Second Measure, Bloomberg 2nd Measure)."),
                  tags$p(tags$b("Social sentiment:"), " Reddit (WallStreetBets), Twitter/X aggregate sentiment. High noise, short-lived signal. Mostly useful for detecting retail-driven momentum."),
                  div(class="tip-box", HTML("<strong>Huyen Ch.3 — data freshness:</strong> Alternative data value degrades rapidly as it becomes widely used. A satellite data signal worth 0.06 IC in 2018 may yield 0.01 IC by 2023 as it becomes crowded."))
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Point-in-Time Database — Critical (Ch.3)"),
                  tags$p("The single most important data engineering concept in quantitative finance. Every feature used in training must reflect only information that was available at prediction time."),
                  tags$p(tags$b("Earnings restatements:"), " a company reports EPS=1.00 in Q1, later restates to EPS=0.85. A naive database stores 0.85. The model trained on this data uses future information."),
                  tags$p(tags$b("Index constituency:"), " S&P 500 stocks today are different from 10 years ago. Training on current constituents only creates survivorship bias — the model never sees stocks that went bankrupt."),
                  tags$p(tags$b("Data vendor delays:"), " fundamental data from Compustat is available 2-3 days after earnings announcement. Features must be computed with appropriate lag."),
                  div(class="warn-box", HTML("<strong>Huyen Ch.3 — data pipeline correctness:</strong> A single lookahead bias in any feature can inflate backtest Sharpe from 1.2 to 3.0. It is the most dangerous silent failure mode in quant research."))
                )
              )
            )
          ),

          qtPanel("qt2-labels",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Label Construction for Return Prediction (Ch.4)"),
                  tags$p("Label definition in quantitative trading is non-trivial and has a large impact on model performance:"),
                  tags$p(tags$b("Raw forward return:"), " price at t+H / price at t - 1. Problems: dominated by market beta (S&P 500 returns); volatile stocks have larger absolute returns masking relative performance."),
                  tags$p(tags$b("Market-adjusted return:"), " stock return minus index return. Removes systematic market beta. Better for cross-sectional models."),
                  tags$p(tags$b("Industry-adjusted return:"), " stock return minus sector/industry average return. Removes sector bets. Forces model to predict stock-specific alpha."),
                  tags$p(tags$b("Volatility-normalised return (z-score):"), " (return - cross-sectional mean) / cross-sectional std. Standard in academic factor research. Ensures equal weighting across stocks with different volatility."),
                  tags$p(tags$b("Holding period choice:"), " 1-day labels are noisier but more numerous. 5-day labels have better SNR but fewer non-overlapping samples. Overlapping labels (Fama-French approach) increase sample size but require HAC standard errors.")
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Label Delay & Temporal Structure (Ch.4)"),
                  tags$p(tags$b("Prediction at t, label at t+H:"), " the label is always in the future. This is the only valid temporal structure. Any feature that contains information from after time t is lookahead bias."),
                  tags$p(tags$b("Label delay is beneficial here:"), " unlike banking (where label delay is a problem), in trading the label delay IS the holding period. A 5-day holding period means labels are available 5 days after each prediction."),
                  tags$p(tags$b("Overlapping labels issue:"), " if using 5-day returns recomputed daily, adjacent days share 4 days of return overlap. Standard errors are misleadingly small — use Newey-West or block bootstrap."),
                  tags$p(tags$b("Transaction cost adjustment:"), " the true label for portfolio construction is return net of transaction costs. Gross IC misleads — a model that trades every day may have IC=0.05 but IC after costs = -0.01."),
                  div(class="success-box", HTML("<strong>Best practice:</strong> Use 5-day non-overlapping forward returns as primary label (better SNR than 1-day, less overlap). Additionally validate on 1-day and 21-day to confirm signal horizon is as expected."))
                )
              )
            )
          ),

          qtPanel("qt2-imbalance",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("The Low Signal-to-Noise Problem (Ch.4)"),
                  tags$p("Equity return prediction has one of the lowest SNRs of any commercial ML application:"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Domain"),tags$th("Typical R²"),tags$th("Noise Level"))),
                    tags$tbody(
                      tags$tr(tags$td("Image classification"), tags$td("> 0.90"), tags$td("Very Low")),
                      tags$tr(tags$td("Churn prediction"),     tags$td("0.10-0.30"),tags$td("Low")),
                      tags$tr(tags$td("Credit scoring"),       tags$td("0.10-0.25"),tags$td("Low")),
                      tags$tr(tags$td("NLP sentiment"),        tags$td("0.30-0.70"),tags$td("Low")),
                      tags$tr(tags$td("Daily equity returns"), tags$td("0.001-0.01"),tags$td("Extremely High")),
                      tags$tr(tags$td("5-day equity returns"), tags$td("0.002-0.02"),tags$td("Very High"))
                    )
                  ),
                  div(class="warn-box", HTML("<strong>Implication for Huyen Ch.4:</strong> Standard class imbalance techniques (oversampling, SMOTE) do not apply. The challenge is not class imbalance but pure noise. Cross-validation results have high variance — a model that backtests Sharpe=1.5 might have a 95% confidence interval of [0.3, 2.7]."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Overfitting in Low-SNR Environments (Ch.4)"),
                  tags$p("In quant ML, overfitting is the primary risk, not underfitting. Techniques specific to trading:"),
                  tags$ul(
                    tags$li(tags$b("Multiple comparison correction:"), " if you test 100 signal ideas and keep the best 5, you are selecting for noise. Apply Bonferroni or Benjamini-Hochberg correction to IC t-statistics."),
                    tags$li(tags$b("Deflated Sharpe Ratio:"), " Bailey & Lopez de Prado (2016). Adjusts backtest Sharpe downward based on number of trials. A strategy tested 100 times must achieve Sharpe=2.5 to be equivalent to Sharpe=1.0 from a single test."),
                    tags$li(tags$b("Walk-forward validation only:"), " k-fold cross-validation is invalid for time series. Use expanding window (train up to year Y, test year Y+1) or rolling window. No random shuffling."),
                    tags$li(tags$b("Minimum description length:"), " prefer simpler models. A 3-factor linear model that explains 60% of a 10-factor gradient boosted tree's backtest performance is more likely to work live."),
                    tags$li(tags$b("Feature stability test:"), " if feature importance changes dramatically between train periods, the model is overfitting to a specific regime.")
                  )
                )
              )
            )
          ),

          qtPanel("qt2-features",
            fluidRow(
              column(3,
                div(class="framework-card",
                  tags$h5("Price & Volume Features (Ch.5)"),
                  tags$ul(
                    tags$li("Momentum: 12-1 month return"),
                    tags$li("Short-term reversal: 5-day return"),
                    tags$li("52-week high proximity"),
                    tags$li("Realised volatility (21-day)"),
                    tags$li("Idiosyncratic volatility vs factor model"),
                    tags$li("Volume trend (OBV, VWAP deviation)"),
                    tags$li("Amihud illiquidity ratio"),
                    tags$li("Bid-ask spread (transaction cost proxy)"),
                    tags$li("Intraday range / close-to-open gap"),
                    tags$li("Beta to market (market risk exposure)")
                  )
                )
              ),
              column(3,
                div(class="framework-card",
                  tags$h5("Fundamental Features (Ch.5)"),
                  tags$ul(
                    tags$li("Earnings yield (E/P)"),
                    tags$li("Book-to-market (B/P)"),
                    tags$li("Cashflow yield (CF/P)"),
                    tags$li("Sales growth YoY"),
                    tags$li("ROE, ROA (profitability)"),
                    tags$li("Accruals ratio (earnings quality)"),
                    tags$li("Debt-to-equity (leverage)"),
                    tags$li("Earnings surprise vs consensus"),
                    tags$li("Earnings revision: FY1 vs prior month"),
                    tags$li("Analyst recommendation changes")
                  )
                )
              ),
              column(3,
                div(class="framework-card",
                  tags$h5("NLP & Sentiment Features (Ch.5)"),
                  tags$ul(
                    tags$li("News sentiment score (FinBERT)"),
                    tags$li("Earnings call tone (positive/negative)"),
                    tags$li("Insider buying/selling signal"),
                    tags$li("Short interest ratio (days-to-cover)"),
                    tags$li("Analyst text sentiment delta"),
                    tags$li("Social media sentiment z-score"),
                    tags$li("ESG controversy flag"),
                    tags$li("Patent filing rate (innovation proxy)"),
                    tags$li("SEC 10-K readability score"),
                    tags$li("Conference call uncertainty language")
                  )
                )
              ),
              column(3,
                div(class="framework-card",
                  tags$h5("Feature Normalisation (Ch.5)"),
                  tags$p(tags$b("Cross-sectional z-score (mandatory):"), " for each feature at each time t, compute (x - mean(x)) / std(x) across all stocks. This removes any time-series trend in the feature level."),
                  tags$p(tags$b("Winsorisation:"), " clip extreme values at ±3σ or 1st/99th percentile. Financial features have fat tails — outliers dominated by earnings surprises, index additions, and M&A."),
                  tags$p(tags$b("Sector neutralisation:"), " demean features within each GICS sector. Prevents model from learning sector rotation rather than stock selection."),
                  div(class="tip-box", HTML("<strong>Huyen Ch.5 — feature store:</strong> Cross-sectional normalisation must be computed consistently between training and live inference. A feature z-scored on training-set mean/std at inference time (using live cross-section mean/std) is the correct approach."))
                )
              )
            )
          ),

          qtPanel("qt2-skew",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Skew 1 — Lookahead Bias (Most Dangerous)"),
                  tags$p(tags$b("Training:"), " feature computed using restated fundamental data from point-in-time database. EPS as reported on filing date."),
                  tags$p(tags$b("Serving (live):"), " feature computed using preliminary earnings release (before 10-Q filing, before auditor review)."),
                  tags$p(tags$b("Effect:"), " training uses more accurate data than available live. Backtest Sharpe is inflated. Live performance disappoints immediately."),
                  tags$p(tags$b("Fix:"), " use the same data vendor's point-in-time API at both training and inference time. Version-control the data snapshot used for each training run.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Skew 2 — Normalisation Difference"),
                  tags$p(tags$b("Training:"), " cross-sectional z-score computed on the full training universe (e.g., Russell 1000 as of training date)."),
                  tags$p(tags$b("Serving:"), " z-score computed on the live universe (Russell 1000 as of today — different constituents due to index changes)."),
                  tags$p(tags$b("Effect:"), " model receives differently-scaled features. Predictions shift. Signals on stocks near the index inclusion boundary are most affected."),
                  tags$p(tags$b("Fix:"), " feature store must store normalisation parameters (mean, std) per time period. Live inference uses the same normalisation pipeline as training, applied to the live cross-section.).")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Skew 3 — Transaction Cost Model Mismatch"),
                  tags$p(tags$b("Research:"), " backtest uses simplified cost model: fixed 5bps per trade regardless of position size."),
                  tags$p(tags$b("Live:"), " actual transaction cost is a function of order size, market impact, bid-ask spread, and timing. Larger positions cost disproportionately more."),
                  tags$p(tags$b("Effect:"), " model selects high-turnover strategies that look attractive net of modelled costs but are unprofitable net of real costs."),
                  tags$p(tags$b("Fix:"), " use a realistic market impact model in the backtest (e.g., Almgren-Chriss square-root impact model: cost ~ sigma * sqrt(participation_rate)). Validate cost model against live execution data."),
                  div(class="warn-box", HTML("<strong>Huyen Ch.5 — train-serve skew:</strong> In trading, cost model mismatch is a form of train-serve skew. The optimisation objective in research (net-of-simplified-cost Sharpe) differs from what is achievable live (net-of-real-cost Sharpe)."))
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 3: Ch.6 — Model Development & Evaluation
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🧠 Box 3 — Ch.6: Model Development — From Single Factors to ML Ensembles",
          status="success", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapter 6 applied:</strong> Baseline hierarchy specific to quant research, model selection for low-SNR tabular data, HPO pitfalls in walk-forward validation, the critical importance of sliced evaluation by regime, and why ensemble methods dominate in alpha signal research.")),
        br(),
        div(id="qt-box3",
          div(class="qt-selector",
            qtBtn("qt-box3","qt3-baselines","Baseline Hierarchy", TRUE),
            qtBtn("qt-box3","qt3-models","Model Selection"),
            qtBtn("qt-box3","qt3-hpo","HPO & Overfitting"),
            qtBtn("qt-box3","qt3-nlp","NLP for Alpha"),
            qtBtn("qt-box3","qt3-eval","Evaluation Strategy")
          ),

          qtPanel("qt3-baselines",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Huyen's Baseline Hierarchy Applied to Quant Research"),
                  div(class="framework-card", style="border-left-color:#c0392b;",
                    tags$h5("Tier 1 — Zero-Signal Baseline"),
                    tags$p("Buy-and-hold equal-weight portfolio. IC=0 by construction. Sharpe ≈ market Sharpe (~0.4 for equities historically). Any alpha model must demonstrate positive IC net of costs above this. Establishes the absolute floor.")
                  ),
                  div(class="framework-card", style="border-left-color:#e67e22;",
                    tags$h5("Tier 2 — Single Factor (Linear)"),
                    tags$p("Single best-known factor: 12-1 month momentum. Long top quintile, short bottom quintile. IC ≈ 0.03-0.05 historically. This is the production baseline that any ML model must beat. Extensively published and largely arbitraged.")
                  ),
                  div(class="framework-card", style="border-left-color:#f39c12;",
                    tags$h5("Tier 3 — Linear Multi-Factor Model"),
                    tags$p("OLS regression of 5-factor combination: momentum + value + quality + low-vol + short-term reversal. IC ≈ 0.05-0.08. Interpretable. Fama-French 5-factor is the canonical example. Standard for academic research.")
                  ),
                  div(class="framework-card", style="border-left-color:#27ae60;",
                    tags$h5("Tier 4 — ML Model (Gradient Boosted Trees)"),
                    tags$p("LightGBM/XGBoost on 50+ features including fundamental + price + NLP + alternative data. IC ≈ 0.06-0.10. Captures nonlinear interactions between factors. Current production standard at mid-size quant funds.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Why Linear Baselines Matter More Here Than Anywhere (Ch.6)"),
                  tags$p("In quant research, the baseline hierarchy has a specific implication: each tier represents a benchmark that is widely known and largely traded away. A model must justify its complexity:"),
                  tags$ul(
                    tags$li("An ML model with IC=0.06 vs a linear model with IC=0.05 may not justify the operational overhead, risk of overfitting, and monitoring cost"),
                    tags$li("The incremental IC from ML over linear must be stable across time periods — not just a historical artifact"),
                    tags$li("A complex model that works in bull markets but fails in bear markets is worse than a simple model that works consistently")
                  ),
                  div(class="success-box", HTML("<strong>Huyen Ch.6 baseline principle applied:</strong> Never skip the linear multi-factor baseline. At least 60% of the ML model's backtest IC should be explainable by the linear model. If not, the ML model is likely overfitting to the training period's idiosyncrasies."))
                )
              )
            )
          ),

          qtPanel("qt3-models",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Gradient Boosted Trees (Primary Model)"),
                  tags$p(tags$b("Why GBDTs dominate quant ML:"), " tabular data, mixed feature types (fundamental + price + NLP), naturally handles missing values (fundamental data has many NAs), feature importance via SHAP, robust to outliers with appropriate regularisation."),
                  tags$p(tags$b("LightGBM configuration:"), " num_leaves=31, min_data_in_leaf=50 (prevents overfitting on small stocks), learning_rate=0.05, n_estimators=300 with early stopping."),
                  tags$p(tags$b("Key regularisation:"), " bagging_fraction=0.8 (subsample stocks per tree), feature_fraction=0.7 (subsample features), lambda_l1=0.1. Aggressive regularisation preferred — better to underfit than overfit in low-SNR environments."),
                  tags$p(tags$b("Target:"), " cross-sectionally normalised 5-day return. Not a classification problem — rank correlation (Spearman IC) is the evaluation metric, not accuracy.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Deep Learning for Alpha"),
                  tags$p(tags$b("When DL adds value over GBDTs:"), " when raw unstructured data is the signal source (text, images, order book sequences). GBDTs cannot process raw sequences."),
                  tags$p(tags$b("LSTM / Transformer for time series:"), " model multi-step price/volume sequences. Capture regime-dependent patterns. Risk: much more parameters → greater overfitting risk in low-SNR environment. Requires larger dataset than typical quant fund has."),
                  tags$p(tags$b("FinBERT for news:"), " BERT fine-tuned on financial news corpora. Entity-level sentiment per stock. Earnings call tone extraction. Key advantage: captures context that rule-based sentiment scores miss."),
                  tags$p(tags$b("Graph Neural Networks:"), " model supply chain relationships between companies. If a key supplier is struggling, predict impact on downstream manufacturer. Sector-level contagion modelling.")
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Ensemble Methods (Production Standard)"),
                  tags$p("Mid-frequency quant funds typically run ensembles of signals rather than a single model. Huyen Ch.6 — ensemble rationale fully applicable:"),
                  tags$ul(
                    tags$li(tags$b("Orthogonal signals:"), " combine momentum-based and value-based signals that are uncorrelated. When momentum drawdowns, value often compensates."),
                    tags$li(tags$b("Regime-dependent ensemble:"), " HMM or regime detection model identifies market state (trending/mean-reverting/volatile). Weight individual signals based on expected performance in current regime."),
                    tags$li(tags$b("Signal IC weighting:"), " in the ensemble, weight each signal proportional to its recent ICIR. Signals with stable IC get higher weight. Declining IC signals are down-weighted dynamically."),
                    tags$li(tags$b("Capacity management:"), " combine high-IC but low-capacity signals (short-term reversal) with lower-IC but high-capacity signals (momentum). Diversifies execution risk.")
                  )
                )
              )
            )
          ),

          qtPanel("qt3-hpo",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("HPO in Quant Research — The Overfitting Trap (Ch.6)"),
                  tags$p("Standard HPO (Bayesian optimisation, Optuna) applied naively to quant models is highly dangerous:"),
                  tags$p(tags$b("The multiple testing problem:"), " if you run HPO across 200 hyperparameter combinations on walk-forward validation, and select the best, you are effectively running 200 backtests and choosing the winner. The resulting Sharpe is biased upward."),
                  tags$p(tags$b("Deflated Sharpe Ratio correction:"), ),
                  tags$p(style="font-family:monospace;background:#f8fffe;padding:8px;border-radius:6px;font-size:11px;",
"DSR = SR * (1 - rho) / sqrt(1 + T/N * (skew - 0.25*kurt))
# rho = autocorrelation of returns
# T = number of observations
# N = number of trials tested
# SR must exceed DSR threshold to be statistically significant"),
                  tags$p(tags$b("Safe HPO approach:"), " use a fixed, small search space motivated by domain knowledge. Do not search more than 20-30 combinations. Reserve a final held-out test period that was never used in HPO.")
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Walk-Forward Validation (Mandatory in Trading)"),
                  tags$p("k-fold cross-validation is invalid for financial time series due to temporal dependency. The only valid approach:"),
                  tags$p(tags$b("Expanding window:"),),
                  tags$ul(
                    tags$li("Fold 1: Train 2010-2014, Test 2015"),
                    tags$li("Fold 2: Train 2010-2015, Test 2016"),
                    tags$li("Fold 3: Train 2010-2016, Test 2017"),
                    tags$li("... continue to present")
                  ),
                  tags$p(tags$b("Rolling window (alternative):"), " fixed training window size (e.g., 3 years). Prevents model from being dominated by distant history when market structure has changed."),
                  tags$p(tags$b("Purging and embargo:"), " when using overlapping labels (e.g., 5-day returns computed daily), the training fold must exclude a purge period before the test fold to prevent leakage. Embargo period = label horizon (5 days)."),
                  div(class="tip-box", HTML("<strong>Huyen Ch.6 — temporal split:</strong> In trading, temporal split is not just a best practice — it is the only way to measure whether the model has genuine predictive power vs having memorised historical patterns."))
                )
              )
            )
          ),

          qtPanel("qt3-nlp",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("NLP Alpha Signal Pipeline (Ch.6)"),
                  tags$p(tags$b("Data sources:"), " earnings call transcripts, 10-K/10-Q filings, news wire, analyst reports, central bank speeches, earnings guidance."),
                  tags$p(tags$b("FinBERT fine-tuning:"), " pre-trained BERT fine-tuned on financial PhraseBank dataset (50K labelled sentences: positive/negative/neutral). Fine-tuning takes 2-3 hours on single GPU. Inference: batch process all earnings calls nightly."),
                  tags$p(tags$b("Features extracted:"),),
                  tags$ul(
                    tags$li("Overall call sentiment score (-1 to +1)"),
                    tags$li("Uncertainty language density (hedging words: 'could', 'may', 'uncertain')"),
                    tags$li("Tone change vs prior quarter (momentum in management confidence)"),
                    tags$li("Specificity score: vague vs specific forward guidance"),
                    tags$li("Q&A sentiment delta vs prepared remarks (management under questioning)")
                  ),
                  div(class="success-box", HTML("<strong>IC of NLP signals:</strong> Earnings call sentiment IC ≈ 0.03-0.05 standalone. Combined with price momentum, the NLP signal provides orthogonal information because it captures qualitative information not yet reflected in price."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Large Language Models in Quant Research"),
                  tags$p(tags$b("Emerging use cases (2024-2025):"),),
                  tags$ul(
                    tags$li(tags$b("Earnings call Q&A extraction:"), " GPT-4/Claude extracts specific forward guidance statements, quantitative targets, and management tone. More nuanced than FinBERT's sentence-level classification."),
                    tags$li(tags$b("Regulatory filing analysis:"), " 10-K risk factor changes year-over-year. LLM identifies new risk disclosures added vs removed. New risks = negative signal."),
                    tags$li(tags$b("Supply chain extraction:"), " LLM reads 10-K supplier/customer disclosures to build proprietary supply chain graph for GNN signal generation."),
                    tags$li(tags$b("Macro interpretation:"), " Fed meeting minutes, ECB statements. LLM summarises policy stance change → feeds macro regime model.")
                  ),
                  div(class="warn-box", HTML("<strong>Huyen Ch.6 caution:</strong> LLM-generated signals are expensive to compute (API cost), hard to validate (hallucination risk), and may violate data vendor terms of service. Treat as experimental until carefully validated with out-of-sample IC testing."))
                )
              )
            )
          ),

          qtPanel("qt3-eval",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Offline Evaluation Strategy (Ch.6)"),
                  tags$p(tags$b("Primary evaluation: walk-forward IC and ICIR"),),
                  tags$ul(
                    tags$li("IC t-statistic > 2.0 required for signal to be considered statistically significant"),
                    tags$li("ICIR > 0.50 for stable, tradeable signal"),
                    tags$li("IC must be positive in at least 55% of individual months (consistency)")
                  ),
                  tags$p(tags$b("Sliced evaluation — Huyen's non-negotiable applied to trading:"),),
                  tags$ul(
                    tags$li(tags$b("By market cap:"), " large-cap (S&P 500), mid-cap, small-cap. Signals often work in small-cap but are not capacity-scalable."),
                    tags$li(tags$b("By sector:"), " IC in Technology vs Utilities vs Financials. A signal with high aggregate IC driven entirely by one sector may fail when sector allocation changes."),
                    tags$li(tags$b("By market regime:"), " trending (2017, 2021), volatile (2020, 2022), mean-reverting (2015-2016). Model must perform across regimes."),
                    tags$li(tags$b("By liquidity:"), " IC in most liquid quintile only — illiquid positions are untradeable at scale."),
                    tags$li(tags$b("By time period:"), " pre/post 2008, pre/post 2020 COVID. Structural breaks in market microstructure affect signal validity.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Backtest Realism Checklist (Ch.6 — Evaluation Quality)"),
                  tags$p("A backtest is only as good as its assumptions. Checklist for a credible backtest:"),
                  tags$ul(
                    tags$li(tags$b("Point-in-time data:"), " confirmed no lookahead bias in any feature"),
                    tags$li(tags$b("Survivorship-free universe:"), " includes all stocks that existed, including delistings"),
                    tags$li(tags$b("Realistic transaction costs:"), " bid-ask spread + market impact model (not fixed bps)"),
                    tags$li(tags$b("Short-sell constraints:"), " not all stocks shortable; apply borrowing cost to short positions"),
                    tags$li(tags$b("Corporate actions:"), " dividend reinvestment, splits, mergers handled correctly"),
                    tags$li(tags$b("Capacity analysis:"), " how does Sharpe degrade as AUM increases? What is the capacity limit?"),
                    tags$li(tags$b("OOS only metrics:"), " never report in-sample metrics; all reported metrics are from hold-out periods"),
                    tags$li(tags$b("Deflated Sharpe:"), " adjust for number of trials to confirm statistical significance")
                  )
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 4: Ch.7-9 — Deployment, Live Trading & Continual Learning
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🚀 Box 4 — Ch.7-9: Deployment, Live Trading & Continual Learning",
          status="danger", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 7, 8 & 9 applied:</strong> The concept-to-production pipeline in quant trading maps precisely to Huyen's deployment lifecycle. Serving architecture, execution-aware deployment, paper trading as shadow mode, capital ramp as canary deployment, and signal decay as the primary drift signal.")),
        br(),
        div(id="qt-box4",
          div(class="qt-selector",
            qtBtn("qt-box4","qt4-serving","Serving Architecture (Ch.7)", TRUE),
            qtBtn("qt-box4","qt4-compression","Execution & Optimisation"),
            qtBtn("qt-box4","qt4-deployment","Deployment Strategies (Ch.9)"),
            qtBtn("qt-box4","qt4-portfolio","Portfolio Construction"),
            qtBtn("qt-box4","qt4-continual","Signal Decay & Retraining (Ch.9)")
          ),

          qtPanel("qt4-serving",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Signal Generation Serving Pipeline (Ch.7)"),
                  tags$p("Mid-frequency equity signals are batch systems — predictions are generated at each rebalancing event (daily at market close for daily rebalancing). This is pure batch serving with no real-time latency requirement:"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Step"),tags$th("Time"),tags$th("Description"))),
                    tags$tbody(
                      tags$tr(tags$td("Data ingestion"),     tags$td("16:30-17:00"), tags$td("Closing prices, volume, fundamentals refreshed")),
                      tags$tr(tags$td("Feature computation"),tags$td("17:00-17:30"), tags$td("All 50+ features computed for full universe")),
                      tags$tr(tags$td("Model inference"),    tags$td("17:30-17:45"), tags$td("GBT/ensemble scores for all N stocks")),
                      tags$tr(tags$td("Portfolio optimisation"),tags$td("17:45-18:00"),tags$td("Constrained optimiser: signal → target weights")),
                      tags$tr(tags$td("Order generation"),   tags$td("18:00-18:15"), tags$td("Target weights → trades to get from current to target")),
                      tags$tr(tags$td("Execution"),          tags$td("09:00-11:00"), tags$td("Next day: orders worked via execution algorithm"))
                    )
                  ),
                  div(class="tip-box", HTML("<strong>Huyen Ch.7 — batch prediction:</strong> Mid-frequency quant is the canonical batch prediction use case. Pre-compute scores for all stocks daily. No latency SLO below minutes. This is fundamentally different from HFT where microsecond inference matters."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Live Feature Store Requirements (Ch.7)"),
                  tags$p("The live feature store for quant trading has two tiers, mirroring Huyen's offline/online feature store pattern:"),
                  tags$ul(
                    tags$li(tags$b("Offline store (historical):"), " full history of all features for training and research. Point-in-time correct. Arctic/Parquet. Updated nightly with latest data."),
                    tags$li(tags$b("Online store (live inference):"), " latest feature values for all universe stocks, updated at market close. Redis or in-memory dataframe. Consumed by live signal generation pipeline."),
                    tags$li(tags$b("Consistency guarantee:"), " normalisation parameters (mean, std) used in live inference must exactly match those used in the most recent training run. Stored alongside model artefacts in model registry."),
                    tags$li(tags$b("Version control:"), " every live prediction must be traceable to: model version, feature set version, normalisation parameters version, data snapshot version. Required for P&L attribution and regulatory review.")
                  )
                )
              )
            )
          ),

          qtPanel("qt4-compression",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Execution-Aware Signal Generation (Ch.7)"),
                  tags$p("Model compression in trading takes a different form than in deep learning. The key 'compression' is making signals execution-aware:"),
                  tags$p(tags$b("Signal strength vs cost threshold:"), " each predicted return must exceed the round-trip transaction cost to justify a trade. Suppress trades where |signal| < cost_threshold."),
                  tags$p(tags$b("Turnover regularisation:"), " add a term to the optimiser penalising deviation from the prior portfolio: lambda * ||w_new - w_old||². Higher lambda = lower turnover = lower costs but slower signal incorporation."),
                  tags$p(tags$b("Almgren-Chriss market impact model:"), ),
                  tags$p(style="font-family:monospace;background:#f8fffe;padding:8px;border-radius:6px;font-size:11px;",
"impact = sigma * sqrt(Q / ADV) * sign(Q)
# sigma = daily volatility
# Q = order size
# ADV = average daily volume
# Impact grows as sqrt of participation rate"),
                  tags$p("This model shows why signals with high turnover become unprofitable above a capacity threshold: market impact grows superlinearly with order size.")
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Knowledge Distillation in Quant (Ch.7)"),
                  tags$p("The equivalent of model distillation in quant trading is signal simplification:"),
                  tags$p(tags$b("SHAP-based factor extraction:"), " train the full 50-feature GBT model, then use SHAP to identify the 5 features responsible for 80% of IC. Build a simplified linear model on those 5 features. The simplified model is more robust, more interpretable, and easier to monitor."),
                  tags$p(tags$b("Rule extraction:"), " convert GBT decision trees into human-readable trading rules: 'Buy when momentum > 1σ AND earnings surprise > 0 AND short interest < 5%'. Rules can be validated by trading intuition, not just backtest."),
                  tags$p(tags$b("Why simplify:"), " a complex model that cannot be explained to the portfolio manager or risk committee may be rejected regardless of IC. Interpretability has direct business value in asset management.")
                )
              )
            )
          ),

          qtPanel("qt4-deployment",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Deployment Strategies — Huyen Ch.9 in Trading"),
                  tags$p("The concept-to-production pipeline in quant trading maps directly to Huyen's deployment strategies:"),
                  div(class="framework-card", style="border-left-color:#27ae60;",
                    tags$h5("Shadow Mode = Paper Trading"),
                    tags$p("Generate live signals and hypothetical positions without committing capital. Run for 30-60 days. Compare live IC vs backtest IC. If live IC is within 2σ of expected, proceed. Shadow mode catches: data feed issues, feature computation bugs, model loading errors.")
                  ),
                  div(class="framework-card", style="border-left-color:#f39c12;",
                    tags$h5("Canary Deployment = Capital Ramp"),
                    tags$p("Deploy with 10% of target capital allocation. Monitor Sharpe, drawdown, and execution quality for 30 days. If metrics match expectations, increase to 25% → 50% → 100%. Canary ramp limits maximum loss if the model has a previously unseen flaw.")
                  ),
                  div(class="framework-card", style="border-left-color:#c0392b;",
                    tags$h5("Champion-Challenger = Live A/B Test"),
                    tags$p("Run incumbent model (champion) at 80% allocation, new model version (challenger) at 20%. Compare realised Sharpe and IC after 60 days. Statistical test: t-test on difference in daily P&L. Replace champion only if challenger outperforms at p<0.10.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Risk Controls as Deployment Gates (Ch.9)"),
                  tags$p("Every model deployment must pass through pre-defined risk gates. These are the quantitative trading equivalent of Huyen's guardrail metrics:"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Gate"),tags$th("Trigger"),tags$th("Action"))),
                    tags$tbody(
                      tags$tr(tags$td("IC gate"),            tags$td("Live IC < 0 for 5 consecutive days"),tags$td("Reduce position to 50%")),
                      tags$tr(tags$td("Drawdown limit"),     tags$td("Strategy down > 1.5× expected monthly loss"),tags$td("Hard stop: close all positions")),
                      tags$tr(tags$td("Execution quality"),  tags$td("Slippage > 2× model cost"),         tags$td("Halt trading, review execution algo")),
                      tags$tr(tags$td("Correlation spike"),  tags$td("Strategy correlation to market > 0.6"),tags$td("Hedge with index futures")),
                      tags$tr(tags$td("Concentration"),      tags$td("Single stock > 5% of gross"),        tags$td("Automatic trim to limit")),
                      tags$tr(tags$td("Vol regime"),         tags$td("VIX > 35"),                          tags$td("Reduce gross exposure 30%"))
                    )
                  )
                )
              )
            )
          ),

          qtPanel("qt4-portfolio",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Portfolio Construction — From Signal to Position (Ch.7)"),
                  tags$p(tags$b("Mean-variance optimisation (Markowitz):"), " maximise expected return (signal × predicted return) subject to volatility constraint. In practice, the covariance matrix estimation is the bottleneck — with 1000 stocks, estimating a 1000×1000 matrix from 252 observations is highly unstable."),
                  tags$p(tags$b("Covariance shrinkage:"), " Ledoit-Wolf shrinkage or factor model covariance (Barra/Axioma risk model). Factor model: decompose stock returns into factor returns + idiosyncratic. Covariance = B × F × B' + D where B=factor loadings, F=factor covariance, D=diagonal idiosyncratic variance."),
                  tags$p(tags$b("Black-Litterman:"), " Bayesian approach combining prior (market equilibrium weights) with ML model views (expected returns). More stable than pure ML-driven optimisation. Particularly useful when ML signal is weak.")
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Execution Algorithm — Last Mile ML (Ch.7)"),
                  tags$p("Once target portfolio weights are determined, the execution algorithm minimises market impact:"),
                  tags$ul(
                    tags$li(tags$b("TWAP (Time-Weighted Average Price):"), " slice order uniformly over the day. Simple, predictable, but ignores intraday volume patterns."),
                    tags$li(tags$b("VWAP (Volume-Weighted Average Price):"), " slice order proportional to historical volume profile. Participates more when market is more liquid."),
                    tags$li(tags$b("Implementation Shortfall (IS):"), " optimise trade-off between urgency (execute fast to capture signal before it decays) and impact (execute slowly to reduce market impact). ML predicts signal decay curve — urgency is a function of expected signal half-life."),
                    tags$li(tags$b("Reinforcement Learning:"), " train RL agent to execute orders by interacting with a simulated order book. Learns adaptive strategies beyond fixed TWAP/VWAP. Research-stage at most funds; deployed at some large quant shops.")
                  )
                )
              )
            )
          ),

          qtPanel("qt4-continual",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Signal Decay — The Core Drift Problem (Ch.9)"),
                  tags$p("Signal decay is the central challenge of live quantitative trading and maps directly to Huyen's distribution shift framework:"),
                  tags$p(tags$b("Why signals decay:"),),
                  tags$ul(
                    tags$li(tags$b("Crowding:"), " as more funds discover and trade a signal, their combined trading pushes prices to reflect the signal faster, reducing its predictive horizon"),
                    tags$li(tags$b("Concept drift:"), " the relationship between features and returns changes as market structure evolves (new regulations, new instruments, algorithmic market-making)"),
                    tags$li(tags$b("Covariate shift:"), " the distribution of stocks (sector composition, market cap distribution) changes over time — the Russell 1000 of 2024 is very different from 2014"),
                    tags$li(tags$b("Regime change:"), " signals calibrated in low-volatility trending markets perform differently in high-volatility mean-reverting markets")
                  ),
                  tags$p(tags$b("Signal decay detection:"), " plot rolling 63-day IC. If trend is declining and IC falls below 50% of historical mean, initiate retraining review.")
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Retraining Strategy (Ch.9)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Model"),tags$th("Frequency"),tags$th("Method"),tags$th("Trigger"))),
                    tags$tbody(
                      tags$tr(tags$td("GBT alpha model"),     tags$td("Quarterly"),  tags$td("Stateless — full retrain on expanding window"), tags$td("Scheduled + IC decay below 50% of mean")),
                      tags$tr(tags$td("FinBERT NLP"),         tags$td("Annually"),   tags$td("Stateless fine-tune from base checkpoint"),    tags$td("Vocab drift in financial language")),
                      tags$tr(tags$td("Cost model"),          tags$td("Monthly"),    tags$td("Recalibrate on recent execution data"),        tags$td("Slippage > 2× model prediction")),
                      tags$tr(tags$td("Risk model covariance"),tags$td("Weekly"),    tags$td("Rolling window update"),                       tags$td("Continuous — covariance non-stationary")),
                      tags$tr(tags$td("Portfolio optimiser"), tags$td("Daily"),      tags$td("Re-solve with updated signals + covariance"),  tags$td("Market close every day")),
                      tags$tr(tags$td("Regime classifier"),   tags$td("Real-time"),  tags$td("HMM update on new observations"),             tags$td("VIX spike or market structure change"))
                    )
                  ),
                  div(class="tip-box", HTML("<strong>Ch.9 stateless retraining is correct:</strong> Expanding window retraining on all available data is preferred in quant ML. Financial data accumulates slowly (one trading day per day). The full history contains regime diversity that a short rolling window would miss."))
                )
              )
            )
          )
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # BOX 5: Ch.8-10-11 — Monitoring, Infrastructure & Responsible AI
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title="🔍 Box 5 — Ch.8-10-11: Monitoring, Infrastructure & Responsible AI in Trading",
          status="info", solidHeader=TRUE, width=12,
        div(class="info-box-plain", HTML("<strong>Chapters 8, 10 & 11 applied:</strong> Distribution shift monitoring for live alpha signals, the quant fund MLOps stack, build vs buy decisions for trading infrastructure, team structure in a systematic fund, and the unique responsible AI challenges of automated trading systems.")),
        br(),
        div(id="qt-box5",
          div(class="qt-selector",
            qtBtn("qt-box5","qt5-monitoring","Monitoring (Ch.8)", TRUE),
            qtBtn("qt-box5","qt5-drift","Distribution Shift in Markets"),
            qtBtn("qt-box5","qt5-infra","Quant MLOps Stack (Ch.10)"),
            qtBtn("qt-box5","qt5-team","Team Structure (Ch.11)"),
            qtBtn("qt-box5","qt5-responsible","Responsible AI in Trading (Ch.11)")
          ),

          qtPanel("qt5-monitoring",
            fluidRow(
              column(4,
                div(class="framework-card",
                  tags$h5("Live Signal Monitoring (Ch.8)"),
                  tags$ul(
                    tags$li(tags$b("Daily IC:"), " Spearman rank correlation between predicted scores and next-day returns. Plot rolling 63-day IC with ±2σ band. Alert if IC < 0 for 3 consecutive days."),
                    tags$li(tags$b("ICIR trend:"), " declining ICIR over 90 days = signal crowding or regime change"),
                    tags$li(tags$b("Feature distribution:"), " daily PSI on each feature vs training distribution. PSI > 0.20 = feature has shifted significantly"),
                    tags$li(tags$b("Prediction distribution:"), " histogram of raw model scores. Compression toward zero = signal is dying. Bimodal distribution = regime instability"),
                    tags$li(tags$b("Factor exposure:"), " ensure model is not inadvertently taking on large market beta, sector, or style factor bets")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Execution & Risk Monitoring"),
                  tags$ul(
                    tags$li(tags$b("Implementation shortfall:"), " actual fill price vs decision price. Track daily. Rising trend = market impact growing, signal being front-run."),
                    tags$li(tags$b("Strategy P&L attribution:"), " decompose daily P&L into: alpha signal contribution, market beta, sector bets, individual stock idiosyncratic. Signal contribution should dominate."),
                    tags$li(tags$b("Drawdown dashboard:"), " current drawdown vs maximum allowed. Rolling 21-day Sharpe. Rolling 63-day Sharpe."),
                    tags$li(tags$b("Position limit breach:"), " alert if any single stock exceeds limit. Alert if net/gross exposure breaches risk budget."),
                    tags$li(tags$b("Correlation monitor:"), " strategy correlation to market (SPX), size factor (Russell 2000 vs 1000), value/growth. Unexpected correlations signal model has developed unintended factor bets.")
                  )
                )
              ),
              column(4,
                div(class="framework-card",
                  tags$h5("Data Quality Monitoring (Ch.8)"),
                  tags$ul(
                    tags$li(tags$b("Missing data rate:"), " % of stocks with NULL features. Sudden spike = data vendor issue"),
                    tags$li(tags$b("Feature staleness:"), " for fundamental features, track days since last update. A company that has not filed earnings in 90+ days is a warning sign"),
                    tags$li(tags$b("Price anomalies:"), " stocks with returns > 30% in one day require manual review — likely corporate action not yet processed"),
                    tags$li(tags$b("Universe stability:"), " track stocks added/removed from trading universe. Large changes = index rebalancing event, may require model recalibration"),
                    tags$li(tags$b("Vendor feed latency:"), " data received > 30 min after market close = signal generation will be delayed")
                  )
                )
              )
            )
          ),

          qtPanel("qt5-drift",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Distribution Shift Types in Equity Markets (Ch.8)"),
                  tags$p(tags$b("Covariate shift — structural changes:"),),
                  tags$ul(
                    tags$li("Index composition changes: tech sector grew from 15% to 30% of S&P 500 in 10 years. A model trained on balanced sector weights has shifted input distribution."),
                    tags$li("Interest rate regime: zero-rate environment (2010-2022) vs positive rates (2022+). Growth/value factor relationship flips. Features based on discount rates behave differently."),
                    tags$li(tags$b("Detection:"), " KS test on feature distributions quarterly. PCA on feature space — check that principal components are stable year-over-year.")
                  ),
                  tags$p(tags$b("Concept drift — relationship changes:"),),
                  tags$ul(
                    tags$li("Momentum signal: worked strongly 2010-2019, reversed violently in 2020-2021 factor rotation. P(high return | high momentum) changed fundamentally."),
                    tags$li("Short-term reversal: predictability of short-term reversal depends on market-maker inventory and HFT behavior. Changed significantly with MiFID II regulation in 2018."),
                    tags$li(tags$b("Detection:"), " plot rolling 252-day IC. Structural break tests (Chow test) on IC stability.")
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Market Regimes as Distribution Shift (Ch.8)"),
                  tags$p("Market regimes are recurring distribution shifts that are partially predictable:"),
                  tags$table(class="table",
                    tags$thead(tags$tr(tags$th("Regime"),tags$th("VIX"),tags$th("Best Factors"),tags$th("Worst Factors"))),
                    tags$tbody(
                      tags$tr(tags$td("Bull/trending"),     tags$td("< 15"), tags$td("Momentum, Growth"), tags$td("Value, Low-vol")),
                      tags$tr(tags$td("Volatile/risk-off"), tags$td("25-40"),tags$td("Low-vol, Quality"),  tags$td("Momentum, Size")),
                      tags$tr(tags$td("Recovery"),          tags$td("20-30"),tags$td("Value, Small-cap"),   tags$td("Momentum (reversal)")),
                      tags$tr(tags$td("Range-bound"),       tags$td("15-20"),tags$td("Reversal, Value"),    tags$td("Momentum"))
                    )
                  ),
                  tags$p(tags$b("Regime-aware ML:"), " train a Hidden Markov Model (HMM) on VIX + market return + sector dispersion to classify current regime. Weight individual signal models by their historical performance in each regime. This is an example of distribution shift being used proactively rather than just detected reactively.")
                )
              )
            )
          ),

          qtPanel("qt5-infra",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Quant Fund MLOps Stack (Ch.10)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Layer"),tags$th("Quant Fund Component"),tags$th("Technology"))),
                    tags$tbody(
                      tags$tr(tags$td("Data storage"),     tags$td("Point-in-time market database"),  tags$td("Arctic (Morgan Stanley OSS), Parquet + S3")),
                      tags$tr(tags$td("Feature store"),    tags$td("Factor library"),                  tags$td("Custom: nightly batch computation + Redis for live")),
                      tags$tr(tags$td("Experiment track"), tags$td("Backtest database"),               tags$td("MLflow or custom: strategy ID, params, IC, Sharpe")),
                      tags$tr(tags$td("Model registry"),   tags$td("Signal model versioning"),         tags$td("MLflow Registry or custom + Git for code")),
                      tags$tr(tags$td("Training"),         tags$td("Walk-forward backtesting"),        tags$td("Distributed (Dask/Ray) for parallel fold computation")),
                      tags$tr(tags$td("Serving"),          tags$td("Daily signal generation"),         tags$td("Batch Python pipeline; no model server needed")),
                      tags$tr(tags$td("Orchestration"),    tags$td("Nightly pipeline DAG"),            tags$td("Airflow or Prefect; triggered at market close")),
                      tags$tr(tags$td("Monitoring"),       tags$td("IC dashboard + risk monitor"),     tags$td("Custom + Grafana; P&L attribution daily")),
                      tags$tr(tags$td("Execution"),        tags$td("OMS / EMS"),                       tags$td("FIX protocol; proprietary or vendor (Fidessa, Flextrade)"))
                    )
                  )
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Build vs Buy in a Quant Fund (Ch.10)"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Component"),tags$th("Decision"),tags$th("Rationale"))),
                    tags$tbody(
                      tags$tr(tags$td("Alpha models"),      tags$td("Build"),       tags$td("Core IP — differentiates the fund")),
                      tags$tr(tags$td("Factor library"),    tags$td("Build"),       tags$td("Proprietary signal construction is the edge")),
                      tags$tr(tags$td("Market data"),       tags$td("Buy"),         tags$td("Bloomberg/Refinitiv — commodity")),
                      tags$tr(tags$td("Risk model"),        tags$td("Buy"),         tags$td("Barra/Axioma — validated, regulatory accepted")),
                      tags$tr(tags$td("Execution (OMS)"),   tags$td("Buy"),         tags$td("FIX connectivity, prime broker integration")),
                      tags$tr(tags$td("Execution algo"),    tags$td("Build+Buy"),   tags$td("Basic TWAP/VWAP buy; custom IS algo build")),
                      tags$tr(tags$td("Portfolio optimiser"),tags$td("Buy+Customise"),tags$td("CVXPY/Gurobi solver; custom objective function")),
                      tags$tr(tags$td("Backtesting engine"),tags$td("Build"),       tags$td("Must match live production pipeline exactly")),
                      tags$tr(tags$td("Alternative data"),  tags$td("Buy"),         tags$td("Satellite, credit card — expensive to collect"))
                    )
                  )
                )
              )
            )
          ),

          qtPanel("qt5-team",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Team Structure in a Systematic Equity Pod (Ch.11)"),
                  tags$p("A 'scaling pod' (as described in the job description) is a self-contained research and trading unit within a larger quant fund. Structure:"),
                  tags$table(class="table table-hover",
                    tags$thead(tags$tr(tags$th("Role"),tags$th("Primary Responsibility"),tags$th("ML vs Finance Weight"))),
                    tags$tbody(
                      tags$tr(tags$td("Quant Researcher"),     tags$td("Alpha signal research, factor discovery"),      tags$td("60% ML / 40% Finance")),
                      tags$tr(tags$td("Quant Developer"),      tags$td("Production system, backtesting infra, OMS"),    tags$td("20% ML / 80% Engineering")),
                      tags$tr(tags$td("Portfolio Manager"),    tags$td("Capital allocation, risk management, P&L"),     tags$td("20% ML / 80% Finance")),
                      tags$tr(tags$td("Risk Analyst"),         tags$td("Factor exposure, drawdown, compliance"),        tags$td("30% ML / 70% Finance")),
                      tags$tr(tags$td("Data Engineer"),        tags$td("Data pipelines, vendor management, PIT data"),  tags$td("40% ML / 60% Engineering"))
                    )
                  ),
                  div(class="tip-box", HTML("<strong>Huyen Ch.11 — ML engineer role:</strong> The Quant Researcher role is the closest to Huyen's 'ML Engineer' — responsible for the full lifecycle from data to production signal. Unlike pure ML engineering, the quant researcher must deeply understand market microstructure, portfolio construction, and risk."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Research vs Production — The Quant Handoff (Ch.11)"),
                  tags$p("The handoff from research (Quant Researcher) to production (Quant Developer) is a critical friction point, analogous to Huyen's research vs applied ML split:"),
                  tags$ul(
                    tags$li(tags$b("Research environment:"), " Jupyter notebooks, pandas, exploratory. Prioritises speed of iteration. May have subtle bugs (survivorship bias, lookahead) that invalidate results."),
                    tags$li(tags$b("Production environment:"), " modular Python, unit tested, peer-reviewed, logged, version-controlled. Must be byte-for-byte identical to research in all data transformations."),
                    tags$li(tags$b("Divergence risk:"), " a signal researched in notebooks that is re-implemented in production often performs differently due to subtle implementation differences in normalisation, universe construction, or data handling."),
                    tags$li(tags$b("Best practice:"), " research code and production code share the same feature computation library. The backtest engine uses the same code path as the live signal generation pipeline. No reimplementation at deployment.")
                  )
                )
              )
            )
          ),

          qtPanel("qt5-responsible",
            fluidRow(
              column(6,
                div(class="framework-card",
                  tags$h5("Responsible AI in Automated Trading (Ch.11)"),
                  tags$p(tags$b("Market stability:"), " ML models can amplify market instability. If many funds run similar models and all receive the same signal to sell simultaneously, this creates flash crashes. Huyen's feedback loop concept applies: model actions → market prices → model inputs → model actions. Known examples: August 2007 quant factor unwind, March 2020 COVID volatility."),
                  tags$p(tags$b("Model risk:"), " over-reliance on a single ML model creates concentration risk. Regulatory concern: if systemically important firms run correlated AI-driven trading strategies, they may amplify shocks. FCA and SEC are actively monitoring."),
                  tags$p(tags$b("Transparency obligation:"), " MiFID II (EU) and SEC regulations require that algorithmic trading strategies are documented, tested, and can be explained to regulators. A fully opaque GBT model may not satisfy the 'algorithm description' requirement without SHAP-based documentation."),
                  div(class="warn-box", HTML("<strong>Huyen Ch.11:</strong> The feedback loop between ML trading models and market prices is a systemic risk, not just a product quality issue. A model that works correctly in isolation may contribute to market instability when deployed at scale alongside similar models at other firms."))
                )
              ),
              column(6,
                div(class="framework-card",
                  tags$h5("Data Ethics & Regulatory Compliance (Ch.11)"),
                  tags$ul(
                    tags$li(tags$b("Material non-public information (MNPI):"), " ML models must not inadvertently train on MNPI. Alternative data vendors (satellite, credit card) must certify their data does not constitute MNPI. Legal review required before use."),
                    tags$li(tags$b("Market manipulation:"), " strategies that artificially move prices (spoofing, layering) are illegal under MAR (EU) and Dodd-Frank (US). ML strategies must be reviewed to ensure they cannot exhibit these patterns even accidentally."),
                    tags$li(tags$b("Model documentation (MiFID II Article 9):"), " all algorithmic trading strategies must have pre-deployment testing, risk controls, and an annual review. Model cards directly satisfy this requirement."),
                    tags$li(tags$b("Kill switch:"), " regulatory requirement for a hard kill switch that immediately cancels all outstanding orders and closes positions. The ML monitoring system must be able to trigger this automatically."),
                    tags$li(tags$b("Bias in ML signals:"), " if NLP signals systematically penalise stocks with female or minority CEOs based on language patterns in coverage, the fund may inadvertently create discriminatory market signals. Audit NLP models for demographic bias in predictions.")
                  )
                )
              )
            )
          )
        )
      )
    ),

    # ── Self-Assessment ─────────────────────────────────────────────────────
    fluidRow(
      box(title="📊 Self-Assessment: Quantitative Trading Case Study",
          status="success", solidHeader=TRUE, width=12,
        fluidRow(
          column(4,
            sliderInput(ns("sc_qt1"), "Problem framing & alpha metrics",      0,10,5),
            sliderInput(ns("sc_qt2"), "Point-in-time data & feature eng.",    0,10,5),
            sliderInput(ns("sc_qt3"), "Walk-forward eval & overfitting",      0,10,5),
            sliderInput(ns("sc_qt4"), "Deployment lifecycle & signal decay",  0,10,5),
            sliderInput(ns("sc_qt5"), "Monitoring & market regime drift",     0,10,5),
            actionButton(ns("save_qt"), "Save Assessment", class="btn-meta", width="100%")
          ),
          column(8, br(), uiOutput(ns("qt_result")))
        )
      )
    )
  )
}

quant_trading_case_study_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_qt, {
      avg <- mean(c(input$sc_qt1, input$sc_qt2, input$sc_qt3, input$sc_qt4, input$sc_qt5))
      pct <- round(avg * 10)
      prep_manager$update_progress("quant_trading_case_study", pct)
      output$qt_result <- renderUI({
        div(class=if(pct>=70)"success-box"else"tip-box",
          tags$h3(style=paste0("color:",progress_colour(pct)), paste0(pct,"% ready")),
          if(pct>=80) tags$p("Strong quant trading ML knowledge. Key interview talking points: information coefficient as the correct offline metric (not R² or accuracy), walk-forward validation as the only valid backtest, point-in-time data to prevent lookahead bias, and signal decay monitoring as the production equivalent of distribution shift detection.")
          else tags$p("Review: why standard ML metrics (R², accuracy) are inadequate for alpha research (use IC/ICIR), why k-fold cross-validation is invalid for time series (use walk-forward), and the three train-serve skew sources in quant systems (lookahead, normalisation mismatch, cost model divergence).")
        )
      })
      showNotification(paste0("Quant Trading: ",pct,"% saved"), type="message")
    })
  })
}
