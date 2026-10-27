# Handover: LAT Level 5 Diploma, Unit 3 trading app (R Shiny)

For the next Claude chat that continues this app. Read this first, then read the code. State as of 20 Oct 2026, day 7 of the trading period.

**Deliverable:** `trading_analysis_lat_2026_u3.zip`, always this exact name, always with `modules/`, `R/`, `www/`, `app.R` and `global.R` at the zip root (no wrapper folder).
**Student:** Jose F Zubizarreta, LAT ID D1005749 (`joseph.zr@atera-analytics.co.uk`).
**Trading period:** 12 Oct to 6 Nov 2026, IG demo spread-bet account, opening balance £10,000, all trades placed manually.
**Assessed instrument:** Brent crude (IG "Oil - Brent Crude", pip = 1 point, stake in £ per point).

---

## 0. Ground rules that must not be broken

1. **Claude only transcribes records and numbers.** It does not write the graded text: set-up (fundamental and technical), trigger, execution, reasons for stop and target, reason for exit, lessons learned, trading plan, Task 2 evaluation, SWOT. These are the student's own words. Unit 3 is individually graded and checked with Turnitin and AI detection.
2. No fabricated observations presented as the student's own. Values that cannot be read or found stay **blank** (or are flagged as approximate), never invented.
3. The student discloses AI processing of screenshots. Account names and account IDs must be cropped out of screenshots before upload (the UI says so).
4. The student asked repeatedly for **simplicity**. Do not add tables or columns unless unavoidable. Schema changes force dropping and recreating BigQuery tables, because writes check the column set.
5. Test with `LC_ALL=C.UTF-8` (the £ sign fails under the C locale). `bigrquery` is not installed in the sandbox, so BigQuery is tested through a fake store, and the Claude API through injected `vision_fn` / `text_fn` functions.

---

## 1. The app in one page

A large shinydashboard app (`app.R` + `global.R`, ~50 modules in `modules/`, helpers in `R/`). Left menu groups:

| Group | Purpose |
|---|---|
| API Configuration | BigQuery sign-in (service-account key), Claude API (key, model, max tokens, timeout capped at 3000 s), Trello/Jira, Debug Console |
| Step-by-Step Practice | Weekly activity steps 1 to 6 (earlier units' teaching material) |
| Economic Calendars | Trading Economics, Financial Modeling Prep, trend summary, parse and export to BigQuery, visualisation, live link |
| **Unit Assignments** | Unit 1, Unit 2 model answers; **Unit 3 Workbench, Unit 3, Unit 3 Live Signals, Unit 3 Execution Plan** |
| **Trade Journal** | **Individual Trade Sheet, Trading Records (BigQuery), Order Evidence (Claude + BigQuery)**. Opens on Trading Records by default |
| Intro Tabs, Futures/Options/FX, Hedging, Extended Indicators, Psychology and Macro, Risk and Portfolio Analytics | General course tools (price analysis, indicators, pivot points, volatility, and so on). They share one `data_manager` and asset selector |

Shared services in `R/utils_api_manager.R` (class `ApiManager`): BigQuery auth and read/write, `call_claude()` (streaming, web search enabled), `call_claude_vision()` (non-streaming, images, temperature 0). Claude timeout is capped at 3000 s; base64 images must contain no whitespace (this caused an HTTP 400 once).

---

## 2. Unit 3 assignment and what the app is meant to do

Unit 3 (40% weighting, 100 marks, 3150 to 3850 words) is based on the student's own four-week trading:

| Task | Marks | What the student must produce | What the app supports |
|---|---|---|---|
| Task 1: trading plan | 35 | Assets chosen and why, objective, decision process, triggers, profit targets and stops, management | Workbench (instructions, plan guide, LAT strategy rules), Live Signals (regime and trigger engine for Pivot Bounce, Straddle, Holy Grail), Execution Plan (process guide and position-size tool). **No plan text is generated.** |
| Task 2: performance | 45 | Per-asset performance, whether the plan was followed, reasons for deviations | Trading Records, Trades, Statistics (summary, by asset, strategy, exit code, weekday, hour, mood, equity series, deviations the student typed), Blotter and statistics exports (Excel). The numbers are computed; the evaluation is the student's |
| Task 3: strategy evaluation | 20 | SWOT-style evaluation with evidence | Workbench tab 7 (SWOT builder pre-populated with evidence from the trade log) |

The evidence the course wants every day: the **Morning Sheet**, one **Individual Trade Sheet** per trade, and the **Trade Blotter** (LAT Excel template). The Trade Journal tabs exist to capture the records once (screenshots → BigQuery) and fill these LAT documents from the saved data instead of by hand.

### Unit 3 tabs in detail

**Unit 3 Workbench (`modules/unit3_workbench.R`)**: 7 sub-tabs: Assignment Instructions (the three tasks at a glance), Trading Plan Guide, Strategy Rules (LAT), How to Use + Glossary, Live Signals, Trade Log and Performance (older log with real Task 2 metrics), Strategy Evaluation (SWOT). Pure guidance and computation.

**Unit 3 (`unit3_assignment.R`)**: the framework/model structure for all three tasks with an *illustrative* equity curve (synthetic, explicitly not real performance).

**Unit 3 Live Signals (`unit3_live_signals.R`)**: regime detection (ADX/DI) on the sidebar-selected asset, trigger flags for the three LAT strategies, a pivot and moving-average chart, an Active Alerts list. It never places trades.

**Unit 3 Execution Plan (`unit3_execution_plan.R`)**: day-by-day operating guide for 12 Oct to 6 Nov, position-size and combined-risk utilities, a DST-aware EIA release timetable, Dropbox folder checklist. Contains no trades or assignment text.

**Individual Trade Sheet (`modules/trade_sheet.R`)**: the older stand-alone fillable form with a base-R PDF export. Superseded in practice by the Trading Records exports (real template fill). It is not wired to BigQuery.

**Trading Records (BigQuery) (`modules/trading_records.R`, `R/utils_trading_records.R`)**: the main record keeper. Six sub-tabs:

1. **Connection and Setup**: create/verify tables, sync pending records, reload, session backup (.rds). Settings saved to `trading_settings`: trader name, student ID, opening balance, period dates, ADX thresholds, risk %, combined cap, minimum RRR, **Dropbox folder (local synced path)** and **Dropbox API path**.
2. **Morning Sheet**: see section 4.
3. **Trades**: A. open a trade (asset, strategy, direction, chart period, expected duration, pip size, stake, entry, up to 4 stops, target, mood, plan checks, and the student's own set-up / trigger / execution / stop reason / target reason text; computes risk and reward in pips and £, LAT RRR, regime label from ADX, correlated risk warnings). B. Manage: move stop, partial exit, close (exit code S1/S2+/ME/T, exit price, net P/L, reason for exit, lessons, mood, plan followed, deviation type and note), and **Edit entry details** (new version of the row). Every save appends a new row (version); the `_current` views return the latest per key. "All trades" table below.
4. **Statistics**: summary, equity, breakdowns, deviations.
5. **Exports (LAT files)**: Blotter (.xlsx), statistics (.xlsx), Individual Trade Sheet and Morning Sheet (.docx **and PDF**, filled into the real LAT templates), plus **Save Word + PDF to Dropbox**.
6. **Schema and SQL**: the DDL, downloadable.

**Order Evidence (Claude + BigQuery) (`modules/trading_evidence.R`)**: screenshot reader, section 3.

---

## 3. Screenshots → fields → BigQuery (what exists)

### 3.1 Order Evidence flow

1. The student picks the source (mobile app or desktop website) and uploads **one or several** screenshots (PNG/JPEG/WebP/GIF). Screen type defaults to **Auto-detect**.
2. For each image `call_claude_vision()` is called with a prompt from `tr_vision_prompt()`. The prompt includes today's date on the London clock and the rule "read every value". The reply is JSON.
3. `tr_normalise_extraction()` cleans numbers, direction, times and dates. A date or time embedded in a string ("19/10/2026 18:06") is split out. If no date is shown, the London date is used (and an info note says so). `tr_check_extraction()` runs sanity checks (stop on the wrong side, risk figures, and so on).
4. The student sees an item selector and an editable form (instrument, direction, size, entry, stop, limit, exit price, P/L, **current price and unrealised P/L**, deal ref, date, time, platform, plus ticket extras: contract type, account type, size unit, spread, margin, notional, costs).
5. **Send to Trades (right form for this screen)** routes by `screen_type` using `tr_screen_to_kind()`:
   - deal ticket / position detail / positions table → **open-trade form** (ticket details merge into the same trade; both evidence ids go along),
   - History "Closed in the last 24 hours" (`closed_trades`) → **close form** with exit price, P/L, closing date and time,
   - market/chart → evidence only.
6. Every screenshot gets a row in `trading_evidence` with status EXTRACTED / CONFIRMED / LINKED / FAILED / DISCARDED, the raw and confirmed JSON, checks, model, token counts, file name, MD5, and (for linked ones) the trade id. The image itself is **not** stored.

### 3.2 Morning tab readers (new)

A switch **"I will upload screenshots" / "Let Claude find it online (web search)"**:

| Need | Screenshot mode | Web mode |
|---|---|---|
| Market levels | `ms_shots` → `tr_morning_vision_prompt()` → `tr_morning_assign()` → boxes (Dow and Nikkei to the overnight table; FX, WTI, gold and any extra to instrument rows; mid of sell/buy; a candle-only high/low is flagged) | "Find market levels + headlines" → `text_fn` (= `ApiManager$call_claude` with web search) with `tr_morning_web_prompt()` → same assign → boxes; headlines go to the news box with a "found online, approximate" note |
| Economic calendar | two upload slots (yesterday, today) → `tr_calendar_vision_prompt()` → `tr_calendar_df()` | "Find yesterday + today calendar" → `tr_calendar_web_prompt()` for each day |

Calendar events become a table in the tab and are saved **as text lines** in the existing columns `overnight_calendar` and `todays_releases`: `time | country | importance | event | Actual x | Forecast y | Previous z` (`tr_calendar_text()` / `tr_calendar_parse_text()` round-trip). No schema change.

### 3.3 BigQuery tables (dataset `atera-2.business_strategy`, all append-only, each with a `_current` view)

| Table | Key | Holds |
|---|---|---|
| `trading_settings` | setting_key | Student details, period, plan numbers, Dropbox settings (never the token) |
| `trading_morning_sheets` | sheet_id (+version) | Date, Dow/Nikkei price, % and points, overnight news, calendar text (yesterday and today), releases in window, regime summary, planned set-ups, exposure, combined open risk, stand-aside |
| `trading_morning_levels` | level_id | Per instrument: overnight low/high, current price, time now, ADX, regime, prior H/L/C, pivots PP/R1-3/S1-3 |
| `trading_trades` | trade_id (+record_version) | The full trade lifecycle (about 70 columns): entry, up to 4 stops, target, risk and reward, outcome, texts, ticket details (spread, margin, notional, costs), evidence ids, trade purpose (ASSESSED / PRACTICE) |
| `trading_trade_events` | event_id | Stop moves and partial exits with reason |
| `trading_evidence` | evidence_id (+version) | The screenshot log described above |

Unused by design: `dropbox_path` (evidence) and `charts_dropbox_path` (trades).

### 3.4 Exports (what the app does now)

`R/utils_trading_templates.R` fills the real LAT Word templates in `www/templates/` (`Trade_Sheet_Template.docx`, `Morning_Sheet_Template.docx`) by unzipping, editing XML with xml2 and re-zipping (`zip` package). It adds the student name and ID, inline pictures (entry/in-trade/exit charts, calendar images), extra exit rows for partial exits, and event lines for in-trade management. It falls back to a plain `officer` layout if the template or packages are missing. `R/utils_trading_calendar.R` has PDF conversion (LibreOffice `soffice --headless`, run with `LD_LIBRARY_PATH` cleared on Linux), the dated file names (`Morning_Sheet_20-10-2026`, `Individual_Trade_Sheet_Brent_19-10-2026`) and Dropbox saving (local synced folder, and/or Dropbox API upload using env var `DROPBOX_ACCESS_TOKEN`).

---

## 4. What was actually done in the chat (outside the app)

The app was **not** yet filling the sheets end to end, so in the chat the sheets were produced by scripts that call the app's own export functions (`tr_trade_sheet_docx`, `tr_morning_docx`) with values the assistant read from screenshots the student pasted into the chat, then converted to PDF with LibreOffice:

| File | How it was made | Caveats |
|---|---|---|
| Individual Trade Sheet, Brent, 19/10/2026 (+PDF) | Entry 10532.3 at 07:58, stop 10397.3, target 10797.3, 0.37 per point, closed at the target 18:06 for +£98.05 (the IG History row), values typed into the script | Entry time came from the chat; the app's first record of this trade has the wrong time (21:18, should be about 06:13 UK) and purpose; fix with **Edit entry details**. Set-up, trigger and lesson fields were left blank for the student |
| Morning Sheet 19/10/2026 (+PDF) | Dow, Nikkei, four FX pairs, WTI, gold from web reports at about 07:00, plus the two calendar pictures added afterwards | Values approximate (the student insisted on approximate); low/high mostly "n/a"; the first version lacked the calendar images, which the student pointed out |
| Morning Sheet 20/10/2026 (+PDF) | Levels at about 07:30 from Newsquawk and Report.az (sources disagreed on WTI and the Dow); calendar pictures for yesterday and today embedded | Low, High and AUD-USD blank; a note on the sheet says the values are approximate and not from IG |
| Individual Trade Sheet, Brent, 20/10/2026 (+PDF) | Buy 10793.9, stop 10674.9, limit 11034.9, 0.37, stopped out 14:51 for −£44.03 (−119 pips), exit code S1 | **Entry time 08:55 is an assumption** (no clock on the Positions screen); chart period "1 Hour" assumed; expected duration blank; text fields blank; pictures: ticket, Positions row, 10-minute chart, History row |

Trading analysis given in chat (the strategy, the 2:1 reward-to-risk levels, Brent buy on 20 Oct) was advice for the student's decision, not app output. The student made and placed the trades.

---

## 5. Gaps: what stops the app (with the Claude API) from filling the sheets by itself

Everything below was **not verified live**. The sandbox had no BigQuery client, so only the logic is tested, with fake Claude replies.

### 5.1 Reliability and verification
1. **No live test of the Claude calls** (vision, web search with `web_search_20250305`, Dropbox API). First real run may need prompt and parsing fixes. Ask the student to paste the Debug Console output when it fails.
2. Vision accuracy has no benchmark. Build a small folder of real IG screenshots (mobile and desktop) with expected values and a regression test, and add checks that numbers are plausible for the instrument.
3. Web-sourced values conflict between sources (WTI, Dow). The web prompt should require two sources agreeing, return the source per value, and mark each field as `web, unverified`. Today it just says "approximate" in a note.
4. Tests used for this work live only in the previous session (`test_cal.R`, `test_tpl.R`, `test_edit.R`, `test_ev_server.R`, `test_tr_server.R`, `test_tr_logic.R` and others). A copy is delivered as `app_tests.zip` next to this file. They `setwd("app")` and source the R files; the server tests use `testServer` with fake `store`, `vision_fn` and `text_fn`.

### 5.2 Missing or weak fields: Morning Sheet (template fields vs. what is filled)
| Field | Status | Fix |
|---|---|---|
| Overnight Low / High per instrument | Mostly blank. Screenshots give one candle or a day range; web search rarely finds them | Add a screenshot type "chart with H/L header"; or compute from the app's own IG data feed (`utils_ig.R`, `data_manager`) for the window 21:00 to 07:00 UK; or let the student type |
| AUD-USD price | Blank on 20 Oct (no source found) | Include it explicitly in the web prompt and the screenshot instructions |
| Time Now | Fixed text "~07:30" | Use the screenshot clock or the time of the read |
| Dow / Nikkei change | Percent and points exist, only filled when a source gives them | As above |
| Overnight news | Web headlines or student notes | Keep the student's own notes primary; web headlines labelled |
| Calendar | Picture or text lines; **yesterday and today fetched only by web or screenshot** | Reuse the existing Economic Calendar modules (Trading Economics, FMP, BigQuery export) as the data source instead of web search, filtered to High/Medium and the instruments the student trades |
| Calendar pictures | Not stored anywhere; re-upload at export | Store the images in Cloud Storage or Dropbox and save the path (the unused `dropbox_path` columns could hold it, or add one column to morning sheets: requires table recreation) |
| Pivot points, ADX, prior H/L/C | Stored in `trading_morning_levels`, not printed on the LAT template | Decide whether the student wants them on the sheet; if so add rows or a text line |
| Regime summary, planned set-ups, exposure, releases in window | In BigQuery and the form, **not placed on the Word template** | Map to the template's free text areas if the template has them, or append as a section |

### 5.3 Missing or weak fields: Individual Trade Sheet
| Field | Status | Fix |
|---|---|---|
| Chart period, expected trade duration | Typed in the Trades tab; blank if the student does not enter them | Make them required on save (warn, not block); show a missing-fields checklist before export |
| Set-up (fundamental, technical), Trigger, Execution, Reason for stop, Reason for target, Reason for exit, Lessons | **Student-written only.** Blank in the exports when not typed | Do **not** auto-write. Add a pre-export "missing fields" panel, and optional neutral prompts and checklists that quote the saved numbers (for example "Stop is 119 pips below entry: why there?"). A "check my text for completeness" button that does not rewrite is acceptable only if the student wants it and course rules allow it |
| Entry time | The Positions screen has no clock; the app falls back to "now" | Add a screen type for IG **History / Activity → Transactions** (shows open time) and match it to the position; or read the deal confirmation. Show a red "time assumed" chip until the student confirms |
| In-trade management | Event lines come from `trading_trade_events` (stop moves, partial exits) | Each action needs an updated chart image placed under it (the "Sample Trade Sheet with In-trade Management" template). The exporter takes pictures per slot only, not per event. Add per-event images |
| Pictures per slot | Re-uploaded at every export | As for calendar images: persist them (Dropbox/GCS path per trade and per slot) |
| Duration | Computed from entry and exit | Depends on the entry time being right |
| Multiple trades with the same asset and date | File names collide (the second overwrites the first) | Add a time or a counter suffix when a file with that name already exists for another trade |

### 5.4 Flow gaps (screenshots to a finished trade)
1. **No automatic pairing.** Ticket, Positions row and History row of one trade are sent one at a time. Add matching on deal reference, market, size and price (the data is in `trading_evidence`) so that a History row closes the right open trade without the student picking it.
2. The first Brent trade of 16 to 19 Oct still has the wrong entry time/purpose in BigQuery. Fix with **Edit entry details**.
3. `trade_sheet.R` (old form) and the Unit 3 Workbench trade log are separate from the BigQuery records and may confuse; consider hiding or redirecting them.
4. BigQuery cannot connect by itself. Auto sign-in only works if `ATERA_BQ_KEY_FILE` or `GOOGLE_APPLICATION_CREDENTIALS` is set; otherwise the student signs in under API Configuration.
5. PDF needs LibreOffice on the machine that runs the app. If hosted (for example shinyapps.io) it is probably missing; either install it in the container or generate the PDF directly (for example via `officer`, or a headless-Chrome route).
6. Dropbox: the local-folder path only works when the app runs on the student's PC. The API path needs an access token in the environment variable (not in BigQuery), with the `files.content.write` scope.
7. Screenshot size: very large images slow the Claude call; add client-side downscale if needed.
8. Time zone: everything is `Europe/London`. The clocks change on 25 Oct 2026 (UK) and the US changes on 1 Nov; EIA times in the Execution Plan are DST-aware, other times are not checked.
9. Cost/safety: each screenshot costs tokens (logged in `trading_evidence`). There is no budget guard.

### 5.5 Suggested order of work for the next chat
1. Run the app once with the real Claude key and BigQuery key; capture failures from the Debug Console; fix prompts and parsing.
2. Add the pre-export **missing-fields panel** (both sheets) so nothing is silently blank.
3. Add the History/Activity screen type for entry times; automatic ticket/position/history pairing.
4. Persist images (calendar, charts) with a storage path and per-event images for in-trade management.
5. Source the calendar from the existing economic calendar modules; add overnight low/high from the IG data feed.
6. Regression tests with real screenshots; keep the six tables unless a change is unavoidable.

---

## 6. Where things are

| Path | Contents |
|---|---|
| `app.R`, `global.R` | UI/server wiring, sourcing order (`utils_trading_templates.R` after `utils_trading_exports.R`, then `utils_trading_calendar.R`), optional BigQuery auto sign-in |
| `R/utils_trading_records.R` | Table schemas and DDL, coercion, maths (pips, risk, RRR, real R), vision prompts and parsing, `tr_london_today()`, `tr_morning_assign()`, store |
| `R/utils_trading_exports.R` | Blotter, statistics, plain-layout Word fallbacks, dispatchers `tr_trade_sheet_docx` / `tr_morning_docx` |
| `R/utils_trading_templates.R` | Real-template filling (xml2 + zip) |
| `R/utils_trading_calendar.R` | Calendar prompts and parsing, file names, PDF conversion, Dropbox |
| `R/utils_api_manager.R` | BigQuery, `call_claude`, `call_claude_vision` |
| `modules/trading_records.R`, `modules/trading_evidence.R` | The two Trade Journal modules |
| `www/templates/` | The two LAT Word templates |
| `/mnt/user-data/outputs/` | Delivered Word/PDF sheets (19 and 20 Oct), zips, SQL helpers |

**When delivering:** build with `cd app && zip -qr ../trading_analysis_lat_2026_u3.zip modules R www app.R global.R`, run the tests first (`LC_ALL=C.UTF-8`), and give the student a plain table of changes. The student works in a hurry and prefers short, direct answers.
