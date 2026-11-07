# IG Trading & Technical Analysis Dashboard — Handoff Documentation

**Purpose of this document:** a complete technical and contextual briefing so a fresh Claude
session can understand this R Shiny application well enough to keep extending it — especially
the **Weekly Activity** tabs, which are ongoing work (currently 3 of an eventual larger set of
weeks). Read this fully before making changes; several conventions here exist specifically
*because* earlier mistakes were made and fixed, and repeating them will reintroduce bugs.

---

## 1. What this app is and why it exists

This is a Shiny (R) web application built for a trading course (London Academy of Trading,
Level 5 Diploma in Applied Financial Trading). It serves two purposes at once:

1. **A live multi-asset technical-analysis dashboard** — real price data (Yahoo Finance +
   IG's REST API for CFDs), real economic calendars (Trading Economics + Financial Modeling
   Prep), and a course-aligned set of calculators/visualisations covering the curriculum's
   derivatives, hedging, technical-indicator, and macro content.
2. **A "Weekly Activity" practice section** — reproduces the exact chart-pattern-identification
   exercises from the course's weekly activity sheets (Word documents), using **simulated**
   OHLC data deterministically shaped to exhibit each named pattern, since sourcing ~90+ real
   historical examples of very specific pattern combinations (e.g. "a CONFIRMED Shooting Star"
   vs "a FAILED Shooting Star") isn't practical.

The person building this (Joseph Francisco Zubizarreta, Technical & Commercial Director at
Atera Analytics — see the About & Overview tab) is iterating on it interactively with Claude,
adding tabs and fixing issues incrementally. There is no single "finished" state — assume more
weeks, more fixes, and more feature requests are coming.

---

## 2. High-level architecture

**Framework:** R Shiny, `shinydashboard` package for the UI shell.

**Module pattern: one file per tab, both UI and server together.** This was a deliberate
simplification requested partway through development — an earlier version used separate
`ui.R`/`server.R` pairs per module plus a YAML-manifest-driven dynamic loader (copying a more
complex reference architecture). That was explicitly abandoned in favour of the current
simpler pattern after the user pointed at a *different* reference app
(`CompComm_v7`/`MetaMLPrep_v3`) whose real, functional pattern — verified by checking what
`app.R` actually sources and calls, not just what files exist in the zip — is:

- Every module is a **single `.R` file** in `modules/`, defining exactly two functions:
  `<module_id>_ui <- function(id) { ns <- NS(id); ... }` and
  `<module_id>_server <- function(id, data_manager) { moduleServer(id, function(input, output, session) { ... }) }`
- `app.R` is **explicit, not dynamic**: it `source()`s every file in `modules/` via a loop,
  then **hand-writes** the full `sidebarMenu()`, `tabItems()`, and the list of `_server()`
  calls. There is no manifest YAML, no dynamic module-discovery loop, no registry file. This
  was a deliberate choice — don't reintroduce that complexity.
- `global.R` is minimal: it sources the shared R6 utility classes and constructs the two
  singleton manager objects (`data_manager`, `ig_manager`) used across the whole app.

**Sidebar navigation: nested `menuItem()` / `menuSubItem()` groups.** The sidebar is organised
into **collapsible topic groups** — click a group name, it expands to reveal its individual
tabs, each a fully separate page (not a `tabsetPanel` sharing one page — that was an earlier,
now-abandoned pattern). This uses shinydashboard's native support: a parent `menuItem(...)`
containing `menuSubItem(...)` children automatically renders as an expandable tree. **Parent
`menuItem()`s must NOT have a `tabName` argument** — only leaf `menuSubItem()`s get `tabName`,
each matching exactly one `tabItem()` in the body. (A parent given a stray `tabName` with no
matching `tabItem` was a real bug caught during development — see §7.)

**Shared reactive state via R6 classes**, not passed-around reactiveValues:

- **`DataManager`** (`R/utils_data.R`) — holds the currently-selected asset's OHLCV
  data.frame, the current asset class/symbol/resolution, and a `state_trigger` (a
  `reactiveVal` counter) that bumps every time new data is fetched. Every module that displays
  asset data reads `data_manager$get_data()` for the data.frame and depends on
  `data_manager$state_trigger()` for reactivity (see the critical gotcha in §7).
- **`IGSessionManager`** (`R/utils_ig.R`) — holds the IG REST API login/session state
  (auth token, login time), linked onto `data_manager$ig` after both are constructed in
  `global.R`, so any module can reach IG state via `data_manager$ig$...` without needing its
  own extra constructor argument. Every module's server function has the same 2-argument
  signature `(id, data_manager)` — kept deliberately uniform.

**Global (non-namespaced) sidebar controls**, defined once in `app.R`'s `dashboardSidebar()`,
outside any module: asset class selector (5 classes — Crypto/Equity/Commodity/Forex/IG CFDs),
a Yahoo-only data-resolution selector (1m/5m/15m/30m/60m/Daily), and per-class instance
selectors (ticker/pair/EPIC pickers). A `observe({...})` block in `app.R`'s `server` resolves
whichever asset is currently selected and calls `data_manager$set_current_asset(...)`, which
internally decides whether to hit Yahoo Finance (daily via `quantmod`, intraday via a direct
call to Yahoo's public chart API through `httr`/`jsonlite` — no `webshot2`/headless-browser
dependency anywhere in this app, by design, for portability) or IG's REST API (via the
`igfetchr` CRAN package, only once logged in via the IG Login tab).

---

## 3. Complete file structure (as of this handoff)

```
app_ig_ta_v2/
├── app.R                        # Entry point: sources everything, hardcodes sidebar/tabs/server wiring
├── global.R                     # Constructs data_manager + ig_manager, links them, defines %||%
├── R/
│   ├── utils_data.R             # DataManager R6 class — asset data fetch/state (5 asset classes)
│   ├── utils_ig.R               # IGSessionManager R6 class — IG REST API login/session
│   └── utils_synthetic.R        # Synthetic pattern-generation engine — THE Weekly Activity backbone
├── modules/                     # 33 files, each with matching _ui()/_server() functions
│   ├── price_analysis.R         # Intro Tabs group
│   ├── market_overview.R
│   ├── technical_indicators.R
│   ├── ig_login.R
│   ├── futures_mechanics.R      # Futures, Options & FX group
│   ├── pricing_basis_carry.R
│   ├── yield_curves.R
│   ├── options_pnl.R
│   ├── fx_fundamentals.R
│   ├── hedge_ratio_calculator.R # Hedging Strategies group
│   ├── basis_risk_simulator.R
│   ├── long_hedge_concept.R
│   ├── moving_averages.R        # Extended Indicators group
│   ├── momentum_roc.R
│   ├── volume_indicators.R
│   ├── parabolic_sar.R
│   ├── pivot_points.R
│   ├── ten_steps.R              # Psychology & Macro group
│   ├── macro_calendar_reference.R
│   ├── economic_calendar_te.R   # Economic Calendars group
│   ├── economic_calendar_fmp.R
│   ├── volatility_analysis.R    # Risk & Portfolio Analytics group
│   ├── risk_metrics.R
│   ├── advanced_metrics.R
│   ├── composite_analysis.R
│   ├── about_overview.R         # About & Feedback group
│   ├── feedback_tab.R
│   ├── weekly_activity_week1.R  # Weekly Activity group — SEE §5, THE ACTIVE WORK AREA
│   ├── weekly_activity_week2.R
│   └── weekly_activity_week3.R
└── www/css/global.css           # Extracted verbatim from the app's original single-file version
```

30 leaf tabs total, in 9 sidebar groups (4 standalone-feeling tabs under "Intro Tabs" + 7
proper collapsible groups). Every `tabName` string appears **exactly twice** in `app.R` — once
in a `menuSubItem()`, once in a `tabItem()` — this is a cheap, valuable sanity check to re-run
after any sidebar edit (see the validation snippet in §7).

---

## 4. Tab-by-tab reference (everything except Weekly Activity)

### Intro Tabs
- **Price Analysis** — configurable price chart, OHLC candlestick chart, and a **20-pattern
  candlestick detection engine**: detects Doji/Hammer/Engulfing/Morning-Evening Star/etc. via
  hand-rolled rule-based thresholds (no reliable CRAN package exists for this), and **draws a
  box around exactly the candles involved** (1/2/3 bars depending on pattern) with the pattern
  name labelled above it — this was a deliberate redesign from an earlier version that just put
  distant arrow markers near the chart, which the user found unclear.
- **Market Overview** — value boxes (price/change/volume/range), combined price+volume chart,
  summary stats, returns/price distribution histograms.
- **Technical Indicators** — SMA/EMA/Bollinger Bands overlay, RSI/MACD/Stochastic subtabs
  (`conditionalPanel` gated on checkbox selection — note the JS-condition namespacing gotcha in
  §7), plain-language signal summary.
- **IG Login** — IG REST API auth (Demo/Live), session status, test-connection, EPIC/market
  search. Credentials pre-fill from `IG_SERVICE_USERNAME`/`PASSWORD`/`API_KEY`/`ACC_NUMBER` env
  vars if set. Deliberately placed last-ish in menu order and not auto-selected on load (per
  explicit user request — it's a one-time setup step, not something to see on every visit).

### Futures, Options & FX
Five tabs implementing the Futures & Options and Introduction to FX reference manuals closely:
**Futures Mechanics** (long/short P&L diagrams), **Pricing, Basis & Carry** (fair value / cost
of carry / cash-and-carry arbitrage calculator), **Yield Curves** (visualiser + Normal/
Inverted/Flat classifier, defaults reproduce the manual's own Dec-2013 UK Gilt/US Treasury
dataset), **Options P&L Profiles** (4 basic positions + a Contingent Liability classifier),
**FX Fundamentals** (pip/margin calculator + a Cross-Rate calculator reproducing the manual's
EUR/USD × GBP/USD → EUR/GBP worked example).

### Hedging Strategies
Built specifically to reproduce the reference manual's **exact worked numeric examples** (not
generic hedging theory): **Hedge Ratio Calculator** (FTSE 100 short-hedge example — defaults
reproduce the manual's ~£4,980 futures profit almost exactly), **Basis Risk Simulator** (wheat/
barley farmer example — three scenario presets reproduce the manual's £0/−£1/+£1 per-tonne
outcomes exactly), **Long Hedge Concept** (conceptual only — the manual gives no numeric
example for this side, unlike the other two).

### Extended Indicators
Implements the Technical Analysis Indicator Formulae manual's content not already covered
elsewhere: Moving Averages (SMA/WMA/EMA comparison), Momentum & ROC, Volume Indicators (OBV +
Weighted OBV), Parabolic SAR, Pivot Points. **Note:** `pivot_points.R`'s `pivot_levels` reactive
had the same reactivity bug described in §7 — already fixed, but if you copy this pattern
elsewhere, watch for it.

### Psychology & Macro
**Ten Steps to Successful Trading** (static reference cards) and **US Macro Calendar**
(static reference table + a beat/miss reaction simulator — illustrative historical tendencies,
not live data; contrast with the *live* Economic Calendars group below).

### Economic Calendars
Two independent live data sources, deliberately kept separate for cross-checking:
- **Trading Economics** — guest access (`c=guest:guest`, no signup) or a registered free API
  key. **Important fix history:** originally called
  `api.tradingeconomics.com/calendar/country/{x}`, which started returning **HTTP 410 (Gone)**
  — TE's current official docs only show the base `/calendar?c=...` endpoint with no country
  path segment. Fixed by always hitting the base endpoint and filtering by country
  client-side. This fix is **untested live** (couldn't be verified from the sandbox) — if 410s
  recur, re-check TE's current docs.
- **Financial Modeling Prep** — requires a free registered API key (no guest mode). Tries
  `financialmodelingprep.com/stable/economic-calendar` first, **falls back automatically** to
  the legacy `api/v3/economic_calendar` path if that fails, and uses **defensive column-name
  matching** rather than assuming an exact JSON schema (FMP's schema was never confirmed via a
  live capture, unlike TE's).

### Risk & Portfolio Analytics
Four tabs of general quantitative tooling (less tightly course-aligned than the other groups
— flagged as such in its own intro box): **Volatility Analysis** (Realized/Parkinson/
Garman-Klass estimators — all three genuinely wired to the method selector now, see §7 bug
history), **Risk Metrics** (VaR/Expected Shortfall/stress tests), **Advanced Metrics**
(Sharpe/Sortino/Calmar/Omega, rolling versions), **Composite Analysis** (multi-asset
correlation/comparison — **known limitation**: only offers the original 9 Crypto/Equity/
Commodity presets, not Forex/IG, since it fetches its own independent dataset via
`data_manager$fetch_yahoo_daily()` in a loop rather than using the sidebar's single-asset
selection, and extending it to IG would mean threading login-gated fetch logic through that
loop).

### About & Feedback
**About & Overview** — branding + an accurate tab-by-tab description of the *current* sidebar
structure (this gets stale fast when tabs are added — **update this when you add tabs**, don't
leave it describing an old layout, which happened once already and had to be caught and fixed).
**Feedback** — static contact/feedback content.

---

## 5. Weekly Activity — the active work area (READ THIS CAREFULLY)

### 5.1 What it is

Reproduces the exact exercises from three uploaded Word documents (`New_Week_1_Activity_Sheet
.docx`, `New_Week_2_Activity_Sheet.docx`, `Week_3_Activity_Sheet.docx`) — each document lists
a set of chart-pattern-identification exercises ("identify a confirmed Shooting Star", "a
Symmetrical Triangle that hit its target", "an RSI bullish divergence", etc.). The
instruction from the user was explicit and important: **cover literally every single point in
each document**, using simulated data if needed, 2 boxes per row, however long the tab needs to
be — completeness matters more than brevity here.

**Exact current coverage (verified by counting, not estimating):**
- **Week 1** — 34 charts: Support & Resistance (4: 2 FX pairs + 1 stock index + 1 commodity,
  each showing Daily/Weekly/Monthly S/R together), Trend Lines/Channels/Countertrend Lines (10:
  2 uptrend examples, 2 downtrend, broken uptrend, broken downtrend, broken countertrend in an
  uptrend, broken countertrend in a downtrend, bullish channel, bearish channel), Japanese
  Candlesticks (20: 9 named patterns × Confirmed/Failed pairs + 2 Marubozu breakout examples).
- **Week 2** — 36 charts: Fibonacci (8: down/up retracement to 50%/61.8% × 2 each, down/up
  100% expansion × 2 each), Price Patterns (28: 14 named patterns × Hit-Target/Failed-to-Reach-
  Target pairs — Symmetrical Triangle in a downtrend, Symmetrical Triangle in an uptrend,
  Ascending Triangle, Inverse H&S, Double Top with retest, Bearish Flag, Bullish Flag, Bearish
  Pennant [note: **not** Bullish Pennant — the source doc only asks for Bearish Pennant],
  Rising Wedge × down/up context, Falling Wedge × down/up context, Head & Shoulders, Double
  Bottom).
- **Week 3** — 24 charts: RSI (6: overbought rejection, oversold bounce, bullish divergence,
  bearish divergence, sell-near-top-of-range, buy-near-bottom-of-range), Stochastics (4:
  bullish divergence in a downtrend, bearish divergence in an uptrend, overbought sell,
  oversold buy), Moving Averages (4: single-SMA buy/sell, dual-MA-cross buy/sell), MACD (2:
  sell-in-uptrend-with-reversal, buy-in-downtrend-with-reversal), OBV (4: rising-through-
  consolidation-then-breakout, breaks-a-triangle-ahead-of-price, bullish divergence, bearish
  divergence — the source doc says "OBV bullish **and** bearish divergence" as one bullet,
  deliberately expanded to 2 separate charts for genuine coverage of both), Bollinger Bands (4:
  range-trading buy/sell, inside/outside buy/sell that hit target).

**Total: 94 chart examples across the 3 weeks.**

### 5.2 The synthetic pattern engine (`R/utils_synthetic.R`) — read this before writing any new pattern generator

This is the shared infrastructure every Weekly Activity module depends on. Core concepts:

**Primitives:**
- `syn_path(n, start, drift, vol, seed)` — a seeded random-walk-with-drift OHLC series. The
  basic building block for every trend leg.
- `syn_candle(base, vol, type, up)` — overwrites a single bar's OHLC to match a named
  candlestick shape (doji variants, hammer, shooting star, marubozu, etc.) — used by Week 1's
  candlestick generators.
- `syn_concat(...)` — concatenates OHLC segments end-to-end, re-sequencing dates so each
  segment continues immediately after the previous one. **Use this for every multi-phase
  pattern** (lead-in trend → pattern formation → breakout/outcome) rather than hand-managing
  date arithmetic — it eliminates a whole class of date-stitching bugs.
- `syn_outcome_tail(breakout_price, direction, target_distance, hit, seed, n)` — the shared
  "does it reach its measured-move target or not" tail generator used across almost every
  Week 2 chart-pattern function. `hit=TRUE` overshoots the target slightly; `hit=FALSE` falls
  short at ~45% of the distance. Reuse this rather than writing bespoke hit/miss logic per
  pattern.
- `syn_line`/`syn_hline`/`syn_label`/`syn_tag` — build plotly-shape/annotation list structures
  for trendlines, horizontal S/R lines, and text labels/tags respectively.

**The spec pattern — the single most important convention here:**

Every chart is built as a **spec**: `list(id=, title=, desc=, gen=function() {...})` where
`gen()` returns the output of `syn_chart(df, title, shapes, annotations, yrange, indicator)` —
itself just a **plain list**, not a plotly object (`list(df=, title=, shapes=, annotations=,
yrange=, indicator=)`). This is deliberate: the same spec drives **both** the interactive
on-screen plotly chart **and** the static PDF export, without building the chart twice.

- `spec_to_plotly(spec)` — turns a spec into an interactive `plotly` candlestick widget (used
  by `renderPlotly()` on screen). Uses `subplot()` with 2 rows when `spec$indicator` is present
  (Week 3's RSI/Stochastic/MACD/OBV panels).
- `base_candlestick_plot(spec, caption)` — turns a spec into a **static base-R graphics**
  candlestick plot (used for the PDF). Deliberately dependency-free — no `webshot2`/headless
  Chrome, no `kaleido`/Python — just `plot()`/`rect()`/`segments()`/`text()`, so it works on any
  plain R server without extra system dependencies. When `spec$indicator` is present, the
  indicator is drawn as a **rescaled inset** in the bottom ~26% of the same panel (not a
  separate sub-panel — base R's `par(mfrow=)` doesn't support nested sub-layouts within one
  cell, and a full re-architecture to `layout()` matrices wasn't worth it for a secondary/
  reference export format).

**Each week's module file follows the same 3-part structure:**
1. **Generator functions** — `w1_*`/`w2_*`/`w3_*` prefixed, each building one *family* of
   pattern (e.g. `w1_candle(pattern, confirmed, seed)` handles all 9 Week-1 candlestick
   patterns via a `switch`, rather than 9 separate top-level functions — this parameterized-
   family approach is what made ~90 examples tractable to write; keep using it for new weeks).
2. **A canonical `w<N>_sections()` function** — the **single source of truth** for that week's
   full spec list, called by *both* the `_ui` function (to build the boxes) and the `_server`
   function (to render charts + wire the PDF export) and by nothing else. This eliminates the
   ID-mismatch bug class that existed in an earlier draft of Week 1 (before this refactor,
   UI-side and server-side spec lists were separately hand-written and could drift out of
   sync). **When adding a new week or new patterns to an existing week, always add to the
   `sections()` function, never write separate UI/server spec lists.**
3. **`_ui`/`_server` functions** — thin wrappers: `_ui` calls `weekly_download_ui(ns)` then
   `lapply(sections, function(sec) weekly_grid_ui(ns, sec$specs, sec$title))`; `_server` loops
   `sections` calling `weekly_grid_server(output, sec$specs)` for each, then calls
   `weekly_download_server(output, "Week N Activity Sheet", sections, "weekN_activity")` once.

**Shared UI/server helpers (also in `utils_synthetic.R`):**
- `weekly_grid_ui(ns, specs, section_title)` — renders a section header + specs arranged 2
  boxes per row (`fluidRow` pairs), each box a `plotlyOutput` + description text.
- `weekly_grid_server(output, specs)` — loops specs, wiring `output[[id]] <- renderPlotly({
  spec_to_plotly(spec$gen()) })` for each (with a `local({})` closure to avoid the classic R
  loop-variable-capture bug).
- `weekly_download_ui(ns)` / `weekly_download_server(output, week_title, sections,
  filename_prefix)` — the "Download PDF" button + its `downloadHandler`, calling
  `export_weekly_pdf()`.
- `export_weekly_pdf(file, week_title, sections)` — multi-page portrait A4 PDF (8.27×11.69in),
  **4 charts per page in a 2×2 grid** (`par(mfrow=c(2,2))`), one page-spanning section header
  per page (`mtext(..., outer=TRUE)`), paginating within each section as needed.

### 5.3 Known caveats specific to Weekly Activity — test these before trusting them

- **The PDF layout has never been visually verified** — no R runtime was available in the
  building sandbox to actually render a PDF and inspect it. The margin/font-size/pagination
  math (`par(mar=c(1.2,1.2,2.4,0.6))`, `cex.main=0.65`, 4-per-page) was chosen carefully but is
  untested. **Generate one PDF per week and check for box overlap or text clipping before
  relying on this.**
- **Week 3's indicator-subplot mechanism is newer/more complex** than the pure price-pattern
  code in Weeks 1–2 — both the plotly `subplot()` path and the base-R rescaled-inset path are
  novel code with no live testing. Test this tab specifically.
- **Performance**: 94 candlestick charts rendering across 3 tabs may make initial tab-load
  noticeably slower than the rest of the app. Not yet addressed — possible future work: lazy
  rendering (only render visible boxes), pagination within a tab, or reducing chart count.
- **More weeks are coming** ("we would add a few more later on" — direct user statement). When
  adding Week 4+: follow the exact 3-part module structure in §5.2, add a `menuSubItem()` to
  the existing "Weekly Activity" `menuItem()` group in `app.R`, add a matching `tabItem()`, add
  the `_server()` call, and re-run the validation checks in §7. You'll need the source Word
  document(s) for that week's activity sheet — read them in full with the docx extraction tool
  before writing any generator code, and enumerate every single bullet point before starting
  (this is what made 94/94 coverage achievable for Weeks 1–3 — a literal point-by-point count
  against the source document, not an estimate).

---

## 6. Data sources summary

| Source | Used by | Auth | Notes |
|---|---|---|---|
| Yahoo Finance (`quantmod`, daily) | Crypto/Equity/Commodity/Forex classes | None | Proven, stable path |
| Yahoo Finance (direct chart API via `httr`) | Same classes, intraday resolutions | None | Bypasses `quantmod`'s inconsistent intraday support; 1m→~7d, 5-30m→~60d, 60m→~2y lookback limits (Yahoo's own limits, not app-imposed) |
| IG REST API (`igfetchr`) | IG (CFDs) asset class | Demo/Live login via IG Login tab | Column-name detection is defensive (regex-based), since `igfetchr`'s exact tibble schema was never verified live |
| Trading Economics API | Economic Calendars → Trading Economics tab | Guest (no signup) or free registered key | See §4 fix history re: HTTP 410 |
| Financial Modeling Prep API | Economic Calendars → FMP tab | Free registered key required | Endpoint + schema handling is defensive/fallback-based |
| Synthetic (seeded RNG) | Weekly Activity tabs only | N/A | Explicitly simulated, labelled as such in every tab's intro box |

---

## 7. Critical gotchas — read before touching reactive code

**1. `data_manager$get_data()` is a plain R6 field read — it creates NO reactive dependency.**
Only reading `data_manager$state_trigger()` (a `reactiveVal`) does. **Every** `render*()` or
`reactive()` that displays/uses asset data must call `data_manager$state_trigger()` as
literally the first line inside its own body. A single `observe({ data_manager$state_trigger()
})` elsewhere in the module does **NOT** give other outputs a dependency — this exact mistake
was made (and had to be found and fixed) across 34 outputs in 3 modules during development.
The same bug independently affects any `reactive()` expression that reads `get_data()` without
also reading `state_trigger()` inside itself — a `reactive()` only recomputes when *its own*
tracked dependencies change, so it will silently cache its first-ever result forever otherwise
(found and fixed in `pivot_points.R`'s `pivot_levels` reactive). **When you add any new output
that reads asset data, put `data_manager$state_trigger()` as its first line. When in doubt,
grep the codebase for this exact pattern in an existing, working module and copy it.**

**2. `conditionalPanel()` JS conditions inside a module need explicit `ns()` interpolation.**
`conditionalPanel` conditions are evaluated as raw JavaScript in the browser and have no
automatic access to Shiny's module namespacing — write
`sprintf("input['%s'].includes('rsi')", ns("technicalIndicators"))`, not a plain string
referencing the bare input ID (see `technical_indicators.R` for a working example).

**3. Parent `menuItem()`s in the sidebar must NOT have a `tabName`.** Only `menuSubItem()`
leaves get one. A parent given a stray `tabName` with no matching `tabItem` was a real bug
caught during development.

**4. Validation checklist to run after any structural change** (all pure Python, no R needed —
useful since this environment has no R runtime):
```python
# Bracket balance per file (run for every .R file touched)
def bal(text, o, c):
    d = m = 0
    for ch in text:
        if ch == o: d += 1
        elif ch == c:
            d -= 1
            if d < m: m = d
    return d, m   # both should be (0, >=0)

# Every tabName should appear exactly twice in app.R (once in menu, once in tabItem)
import re
from collections import Counter
app = open('app.R', encoding='utf-8').read()
counts = Counter(re.findall(r'tabName\s*=\s*"([^"]+)"', app))
print({k: v for k, v in counts.items() if v != 2})   # should print {}

# Per-module output/input cross-check (UI ns("x") defs vs server output$x/input$x uses)
# — split each module file on "<module>_server", regex-extract ns("...") IDs from the UI half
#   and output$.../input$... from the server half, diff the sets both directions.
```
These checks caught real bugs multiple times during development (a false regex match aside,
they're reliable) — always run them before considering a change complete, and always mention
in your response to the user which checks passed, since there's no way to actually execute R
in most sandboxed environments.

**5. `%||%` (null-coalesce) is defined redundantly** in `global.R` and inside
`utils_synthetic.R` — harmless (R just uses the last/either identical definition), consistent
with how the rest of the codebase already handles this helper. Don't worry about it, don't
remove either copy without checking both are truly unused elsewhere.

**6. About & Overview tab goes stale.** It contains a hand-written description of every
sidebar tab/group. **Update it whenever you add or restructure tabs** — this was missed once
already (it described an old, pre-restructure layout) and had to be rewritten from scratch
rather than blindly ported forward.

---

## 8. Suggested next steps (not committed to, just the obvious candidates)

- Verify the PDF export visually (layout untested — see §5.3).
- Verify Trading Economics' HTTP 410 fix actually resolved the issue live (untested — see §4).
- Build Week 4+ as source documents become available, following §5.2's structure exactly.
- Consider lazy-loading/pagination for Weekly Activity tabs if load time becomes a problem.
- Consider extending Composite Analysis to Forex/IG (currently Yahoo-only, 9 presets — see §4).
- Confirm FMP's actual JSON schema from a live key and tighten the defensive column-matching
  in `economic_calendar_fmp.R` once confirmed (currently falls back to showing raw columns if
  its guesses don't match).

---

*This document reflects the app's state as of the point it was written. If significant changes
have been made since, treat specific line-level/count-level claims here with appropriate
skepticism and verify against the actual current codebase — but the architectural conventions
and gotchas in §2, §5.2, and §7 should remain valid regardless of how many more tabs get added.*
