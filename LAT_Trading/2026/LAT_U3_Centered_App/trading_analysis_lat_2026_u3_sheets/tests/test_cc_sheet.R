# tests/test_cc_sheet.R - the Individual Trade Sheet for a closed Capital.com trade (your trade of 2 Nov 2026)
suppressMessages({ library(TTR); library(zoo) }); `%||%` <- function(x, y) if (is.null(x)) y else x
for (f in c("R/utils_trading_records.R", "R/utils_trading_exports.R", "R/utils_trading_templates.R", "R/utils_trading_calendar.R", "R/utils_cc_catalog.R", "R/utils_cc_api.R", "R/utils_cc_patterns.R", "R/utils_cc_chart.R", "R/utils_cc_records.R", "R/utils_cc_tradelog.R", "R/utils_cc_sheet.R", "R/utils_cc_advice.R", "R/utils_cc_plan.R")) source(f)
pass <- 0L; fail <- 0L; ok <- function(c, w) { if (isTRUE(c)) { pass <<- pass + 1L; cat("  ok  ", w, "\n") } else { fail <<- fail + 1L; cat("  FAIL", w, "\n") } }
tr <- cc_coerce("trades", data.frame(trade_id = "CC_1421", record_version = 3L, source = "APP", epic = "OIL_BRENT", market_name = "Brent Oil Spot", instrument_currency = "USD", account_currency = "GBP",
  direction = "BUY", size = 11, lot_size = 1, deal_id = "POS", status = "CLOSED", entry_level = 109.756, stop_initial = 108.703, stop_level = 108.703, target_level = 110.495,
  entry_ts = as.POSIXct("2026-11-02 07:56:38", tz = "UTC"), exit_ts = as.POSIXct("2026-11-02 08:31:10", tz = "UTC"), exit_level = 108.596, exit_code = "S1", fx_rate = 0.7445,
  pnl_instrument = -12.76, pnl_account_est = -9.50, pnl_account_booked = -9.50, chart_period = "15 Min", expected_hours = 4, setup_tech = "my technical words", lessons = "my lessons"))
act <- data.frame(date_utc = c("2026-11-02T07:56:38", "2026-11-02T08:31:10"), epic = "OIL_BRENT", deal_id = "POS", source = c("USER", "SL"), type = "POSITION", status = c("ACCEPTED", "DELETED"), level = c(109.756, 108.596), stringsAsFactors = FALSE)
t <- seq(as.POSIXct("2026-11-02 06:00", tz = "UTC"), by = 60, length.out = 300); set.seed(3); p <- 109.9 - cumsum(rnorm(300, 0.004, 0.03))
bars <- data.frame(time = t, open = c(109.9, head(p, -1)), close = p); bars$high <- pmax(bars$open, bars$close) + 0.02; bars$low <- pmin(bars$open, bars$close) - 0.02
sm <- cc_trade_summary(tr, bars, act)
ok(abs(sm$duration_h - (34.53 / 60)) < 0.01, sprintf("duration from the history: %s", tr_duration_text(sm$duration_h)))
ok(abs(sm$slippage_points - (-0.107)) < 1e-9, "slippage -0.107 points against the stop")
ok(abs(sm$result_r - (-1.1016)) < 0.001 && abs(sm$result_points - (-1.16)) < 1e-9, "result -1.16 points, -1.10 R")
ok(abs(sm$planned_rrr - 0.7018) < 0.001, "planned R:R 0.70 (below the plan's 1.5)")
ok(is.finite(sm$mfe_points) && is.finite(sm$mae_points), "best and worst price while open read from the candles")
d <- tempfile("sheet"); dir.create(d); png1 <- file.path(d, "exit.png"); cc_chart_png(bars, png1, "test", 109.756, 108.703, 110.495, 108.596, sm$open_ts, sm$close_ts)
ok(file.exists(png1) && file.size(png1) > 5000, "exit chart picture drawn")
docx <- file.path(d, tr_trade_filename("Brent Oil Spot", as.Date("2026-11-02")))
r <- tryCatch({ cc_trade_sheet(tr, sm, "Jose F Zubizarreta", data.frame(slot = "exit", event_id = NA, caption = "Exit", path = png1, stringsAsFactors = FALSE), docx); "ok" }, error = function(e) conditionMessage(e))
ok(identical(r, "ok") && file.exists(docx), paste("the Word sheet is written from the LAT template:", r, basename(docx)))
if (file.exists(docx)) { x <- utils::unzip(docx, "word/document.xml", exdir = d); txt <- paste(readLines(x, warn = FALSE), collapse = "")
  ok(grepl("my technical words", txt) && grepl("my lessons", txt), "your own words are on the sheet")
  ok(grepl("108.596", txt) && grepl("S1 hit", txt) && grepl("109.756", txt), "entry 109.756, exit 108.596 and S1 are on the sheet")
  ok(grepl("-9.50", txt), "the GBP result -9.50 is on the sheet")
  ok(grepl(sprintf(">%s<", tr_ntrim(tr$size, 2)), txt), sprintf("****** Lot Size on the sheet is the deal size in units (%s), not the GBP value per point", tr$size))
  ok(grepl("Trade data \\(from Capital.com\\)", txt), "the trade data summary is on the sheet") }

cat("Journal: separate buttons (BigQuery / Dropbox / Download), sheet built on demand\n")
suppressMessages({ library(shiny); library(DT); library(plotly) }); source("R/utils_trading_pipeline.R"); source("modules/cc_trading_records.R")
drop_calls <- 0L; tr_save_sheet <- function(files, kind = "trade", ...) { drop_calls <<- drop_calls + 1L; data.frame(file = basename(files[!is.na(files)]), where = "test folder", ok = TRUE, note = "") }
st <- cc_make_store(cc_mem_backend()); tr0 <- tr; tr0$setup_tech <- NA; tr0$lessons <- NA; st$write("trades", tr0); st$write("activity", transform(act, row_id = paste(deal_id, date_utc)))
# an unfilled limit order placed from the CLAUDE 1 scenario, with the chart saved at the order
sc_tab <- data.frame(id = c("BUY MARKET", "CLAUDE 1"), source = c("Rules", "Claude"), side = "BUY", type = c("MARKET", "LIMIT"), entry = c(103.73, 102.6), stop = c(101.84, 101.9), target = c(107.509, 104.3),
                     now_px = 103.597, rrr = c(2, 2.43), meas_p = c(13, 36), meas_n = c(188L, 561L), meas_und = c(69, 9), claude_p = c(15, 38), risk_acc = 1.04, reward_acc = 2.53,
                     note = c("At the offer price now", "Claude: 102.5-102.6 held as support at 03:00-03:30"), basis = c("Bullish MACD divergence", "Main risk: EU CPI at 10:00"), stringsAsFactors = FALSE)
attr(sc_tab, "ccy") <- "GBP"; attr(sc_tab, "d") <- 3; attr(sc_tab, "at") <- as.POSIXct("2026-11-04 05:20", tz = "UTC")
lim <- cc_coerce("trades", data.frame(trade_id = "CC_LIM", record_version = 1L, source = "APP", epic = "OIL_BRENT", market_name = "Brent Oil Spot", instrument_currency = "USD", account_currency = "GBP",
  direction = "BUY", size = 1.5, lot_size = 1, status = "ORDER_WORKING", order_type = "LIMIT", order_level = 102.6, stop_initial = 101.9, stop_level = 101.9, target_level = 104.3,
  placed_ts = as.POSIXct("2026-11-04 05:23:06", tz = "UTC"), risk_account = 1.04, scan_id = "SC_LIM",
  scenario_json = cc_scenario_snapshot(sc_tab, "CLAUDE 1", TRUE, list(ok = TRUE, text = "Range day; oil heavy on talks news."), 10)))
st$write("trades", lim)
sc15 <- local({ tt <- seq(as.POSIXct("2026-11-01 00:00", tz = "UTC"), by = 900, length.out = 400); set.seed(5); pp <- 103 + cumsum(rnorm(400, 0, 0.12))
  b <- data.frame(time = tt, open = c(103, head(pp, -1)), close = pp); b$high <- pmax(b$open, b$close) + 0.05; b$low <- pmin(b$open, b$close) - 0.05; b })
s15 <- cc_scan(sc15, 15, show_from = 200L); pl_json <- cc_json(cc_scan_payload(s15, list(epic = "OIL_BRENT", res = "MINUTE_15", mins = 15), list()))
st$write("scans", data.frame(scan_id = "SC_LIM", trade_id = "CC_LIM", epic = "OIL_BRENT", resolution = "MINUTE_15", n_candles = 300L, last_candle_utc = max(bars$time), regime = "RANGE", adx = 15,
                             current_json = cc_json(data.frame(key = "double_bottom", label = "Double bottom", step = 2, bias = "bullish", status = "confirmed", candles_ago = 3, hist_n = 12, hist_win = 58)),
                             bars_json = pl_json, stringsAsFactors = FALSE))
testServer(cc_trading_records_server, args = list(client = cc_new_client(http_fn = function(...) list(status = 500, headers = list(), body = "{}"), sleep_fn = function(s) NULL), store = st,
                                                  fetch_bars = function(...) bars, vision_fn = function(p) list(text = paste("C says: the limit at 102.600 was not reached.", if (grepl("CLAUDE 1", p)) "Prompt had the scenario." else ""))), {
  session$setInputs(j_trade = "CC_1421"); session$flushReact()
  session$setInputs(j_chart = "30 Min", j_stopwhy = "Reduce risk give previous outcomes of trades.", j_tgtwhy = "Just giving it a go", j_why = "Reached stop limit.",
                    j_purpose = "ASSESSED", j_followed = "Y", j_devtype = "", j_devnote = "", j_mood = 3, j_fund = "", j_tech = "", j_trigger = "", j_exec = "", j_lessons = "", j_analysis = "", j_hours = NA, j_code = "S1",
                    j_c = "", j_c_incl = TRUE)
  # Download Word: builds from what is on screen, saves nothing
  f <- output$j_dl_docx; ok(is.character(f) && file.exists(f) && grepl("\\.docx$", f) || (file.exists(f) && identical(readBin(f, "raw", 2), charToRaw("PK"))), "Download Word gives a real .docx (zip), not an HTML page, without any earlier save")
  if (file.exists(f)) { dx <- tempfile(); xx <- utils::unzip(f, "word/document.xml", exdir = dx); tt <- paste(readLines(xx, warn = FALSE), collapse = "")
    ok(grepl("Reduce risk give previous outcomes", tt) && grepl("Just giving it a go", tt) && grepl("30 Min", tt), "the downloaded sheet has what is on screen (not saved yet)") }
  t <- st$current("trades"); ok(t$record_version[t$trade_id == "CC_1421"] == 3L, "Download saved nothing to BigQuery (still version 3)")
  session$setInputs(j_drop = 1); session$flushReact()
  t <- st$current("trades"); ok(drop_calls == 1L && t$record_version[t$trade_id == "CC_1421"] == 3L, "Save to Dropbox writes the files only (BigQuery still version 3)")
  ok(grepl("Saved to Dropbox", paste(as.character(output$j_sheet_out), collapse = "")), "Dropbox result shown")
  session$setInputs(j_save = 1); t <- st$current("trades"); k <- t[t$trade_id == "CC_1421", ]
  ok(k$stop_reason == "Reduce risk give previous outcomes of trades." && k$record_version == 4L && drop_calls == 1L, "Save to BigQuery saves your entries (version 4) and writes no file")
  session$setInputs(j_save = 2); ok(grepl("Nothing changed", paste(as.character(output$j_msg), collapse = "")), "Save again with no change: says nothing changed")
  ok(grepl("Download Word", paste(as.character(output$j_where_sheet), collapse = "")), "the panel says what each button does")
  # the unfilled limit order: recommendation, C analysis, context at the bottom
  session$setInputs(j_trade = "CC_LIM"); session$flushReact()
  ok(grepl("PLATFORM 1", paste(as.character(output$j_rec), collapse = "")) && grepl("not been filled", paste(as.character(output$j_rec), collapse = "")), "the Journal shows the recommended trade saved with the order and that it is not filled")
  session$setInputs(j_c_write = 1); session$flushReact()
  cm <- paste(as.character(output$j_c_msg), collapse = ""); ok(grepl("Written", cm), "C analysis written (prose call)")
  session$setInputs(j_c = "C says: the limit at 102.600 was not reached. Prompt had the scenario.", j_c_incl = TRUE)
  session$setInputs(j_save = 3); e <- st$current("events"); ce <- e[e$event_type %in% "C_ANALYSIS" & e$trade_id %in% "CC_LIM", ]
  ok(nrow(ce) == 1 && grepl("102.600", ce$note), "C analysis saved to BigQuery (cc_events, C_ANALYSIS)")
  f2 <- output$j_dl_docx; dx <- tempfile(); xx <- utils::unzip(f2, "word/document.xml", exdir = dx); tt <- paste(readLines(xx, warn = FALSE), collapse = "")
  ok(grepl("Context \\(from the app", tt) && grepl("PLATFORM 1", tt) && grepl("36%", tt) && grepl("38%", tt) && grepl("Double bottom", tt), "unfilled order sheet: context with the scenario, both chances and the patterns table")
  ok(grepl("Analysis", tt) && grepl("was not reached", tt), "the analysis is at the bottom when ticked")
  ok(!grepl("Claude|CLAUDE|C estimate|C analysis", tt), "****** the worksheet never names Claude: only the platform")
  ok(grepl("has not been filled", tt), "the sheet says the order was not filled")
  ok(grepl("Chart and patterns at the order", tt) && length(grep("^word/media/", utils::unzip(f2, list = TRUE)$Name)) >= 1, "the chart saved at the order is in the context block")
  ok(regexpr("Context \\(from the app", tt) > regexpr("Lessons", tt), "the context block is at the bottom, after the LAT fields")
  session$setInputs(j_c_incl = FALSE); f3 <- output$j_dl_docx; dx <- tempfile(); xx <- utils::unzip(f3, "word/document.xml", exdir = dx); tt <- paste(readLines(xx, warn = FALSE), collapse = "")
  ok(!grepl("C analysis \\(C = Claude\\)", tt) && grepl("PLATFORM 1", tt), "unticked: no C analysis, the recommendation stays")
  if (!is.na(tr_find_soffice())) { fp <- output$j_dl_pdf; ok(file.exists(fp) && identical(readBin(fp, "raw", 4), charToRaw("%PDF")), "Download PDF gives a real PDF") }
})
cat("Your 5 Nov trade: a stop order that filled and closed between syncs, repaired, then its sheet with the C analysis\n")
st5 <- cc_make_store(cc_mem_backend())
sc5 <- data.frame(id = "BUY STOP", source = "Rules", side = "BUY", type = "STOP", entry = 93.593, stop = 92.895, target = 94.987, now_px = 93.40, rrr = 2.0, meas_p = 31, meas_n = 402L, meas_und = 22, claude_p = 34,
                  note = "Enters only if price breaks the high of the last 5 candles", basis = "Bullish engulfing (measured 44% target-first, n=18)", stringsAsFactors = FALSE); attr(sc5, "d") <- 3
w5 <- cc_coerce("trades", data.frame(trade_id = "CC_83be", record_version = 2L, source = "APP", epic = "OIL_BRENT", market_name = "Brent Oil Spot", instrument_currency = "USD", account_currency = "GBP",
  direction = "BUY", size = 3, lot_size = 1, order_type = "STOP", order_level = 93.593, order_deal_id = "00000000-WO-83be", status = "EXPIRED", stop_initial = 92.895, stop_level = 92.895, target_level = 94.987,
  placed_ts = as.POSIXct("2026-11-05 04:15:32", tz = "UTC"), risk_account = 1.55, scenario_json = cc_scenario_snapshot(sc5, "BUY STOP", TRUE, list(ok = TRUE, text = "Oil firm after inventories."), 10)))
st5$write("trades", w5)
a5 <- data.frame(row_id = c("a", "b"), date_utc = c("2026-11-05T05:30:01", "2026-11-05T09:23:10"), epic = "OIL_BRENT", deal_id = c("00000000-WO-83be", "POS-5NOV"), source = c("SYSTEM", "TP"), type = "POSITION",
                 status = "ACCEPTED", level = c(93.598, 94.987), size = 3, direction = "BUY",
                 json = c('{"details":{"actions":[{"actionType":"POSITION_OPENED","affectedDealId":"POS-5NOV"}]}}', '{"details":{"actions":[{"actionType":"POSITION_CLOSED","affectedDealId":"POS-5NOV"}]}}'), stringsAsFactors = FALSE)
t5 <- data.frame(row_id = "t", date_utc = "2026-11-05T09:23:12", instrument = "Brent Oil Spot", type = "TRADE", amount = 3.13, currency = "GBP", reference = "143577948857444", note = "", stringsAsFactors = FALSE)
st5$write("activity", a5); st5$write("transactions", t5)
rp <- cc_reconcile(st5$current("trades"), data.frame(), data.frame(), st5$current("activity"), st5$current("transactions"), "GBP", function(ccy) 0.74228)
st5$write("trades", rp$updated); st5$write("events", rp$events); k5 <- st5$current("trades")
ok(k5$status == "CLOSED" && k5$entry_level == 93.598 && k5$exit_code == "T" && k5$pnl_account_booked == 3.13, "repaired in the records: CLOSED, entry 93.598, exit at the target, +3.13 booked")
b5 <- local({ tt <- seq(as.POSIXct("2026-11-05 02:00", tz = "UTC"), by = 300, length.out = 160); pp <- seq(93.2, 95.2, length.out = 160); data.frame(time = tt, open = pp, high = pp + 0.05, low = pp - 0.05, close = pp, volume = 0) })
testServer(cc_trading_records_server, args = list(client = cc_new_client(http_fn = function(...) list(status = 500, headers = list(), body = "{}"), sleep_fn = function(s) NULL), store = st5,
    fetch_bars = function(...) b5, morning_fn = function(day) list(ok = TRUE, text = paste("MORNING SHEET", format(day, "%d/%m/%Y"), "bias: Brent bearish; BoE 12:00"), saved_at = as.POSIXct("2026-11-05 06:40", tz = "UTC")),
    vision_fn = function(p) { c_prompt5 <<- p; list(text = paste(if (grepl("MORNING SHEET 05/11/2026", p)) "[with the Morning Sheet]" else "[no sheet]","C: the BUY STOP recommendation (31% measured, 34% estimated, R:R 2.0) worked: the stop order filled at 93.598 and the target 94.987 was hit.",
                                                                            if (grepl("BUY STOP", p) && grepl("94.987", p)) "[prompt had the scenario and the exit]" else "[prompt incomplete]")) }), {
  session$setInputs(j_trade = "CC_83be"); session$flushReact()
  session$setInputs(j_chart = "15 Min", j_stopwhy = "", j_tgtwhy = "", j_why = "Target reached.", j_purpose = "PRACTICE", j_followed = "Y", j_devtype = "", j_devnote = "", j_mood = 3, j_fund = "", j_tech = "",
                    j_trigger = "", j_exec = "", j_lessons = "", j_analysis = "", j_hours = NA, j_code = "", j_c = "", j_c_incl = TRUE)
  ok(grepl("BUY STOP", paste(as.character(output$j_rec), collapse = "")), "the Journal shows the recommended trade saved with the order")
  ok(grepl("Morning Sheet of 05/11/2026: LOADED from BigQuery", paste(as.character(output$j_c_ms_ui), collapse = "")), "the tick box itself says the Morning Sheet of the trade's day is LOADED from BigQuery")
  session$setInputs(j_c_ms = TRUE, j_c_write = 1); session$flushReact(); ok(grepl("Written with the Morning Sheet", paste(as.character(output$j_c_msg), collapse = "")), "C analysis written with the Morning Sheet")
  ok(grepl("MORNING SHEET 05/11/2026", c_prompt5), "C's prompt contained that day's Morning Sheet")
  session$setInputs(j_c_ms = FALSE, j_c_write = 2); session$flushReact(); ok(grepl("without the Morning Sheet", paste(as.character(output$j_c_msg), collapse = "")), "unticked: written without it")
  session$setInputs(j_c = "C: the BUY STOP recommendation (31% measured, 34% estimated, R:R 2.0) worked: the stop order filled at 93.598 and the target 94.987 was hit. [prompt had the scenario and the exit]")
  f5 <- output$j_dl_docx; ok(file.exists(f5) && identical(readBin(f5, "raw", 2), charToRaw("PK")), "Download Word gives the sheet for the repaired trade")
  dx <- tempfile(); xx <- utils::unzip(f5, "word/document.xml", exdir = dx); tt <- paste(readLines(xx, warn = FALSE), collapse = "")
  ok(grepl("93.598", tt) && grepl("94.987", tt), "the sheet has the real entry 93.598 and exit 94.987")
  ok(grepl("BUY STOP", tt) && grepl("31%", tt) && grepl("34%", tt) && grepl("Analysis", tt) && !grepl("Claude", tt) && grepl("prompt had the scenario and the exit", tt), "the context: the recommended trade, both chances, and the C analysis (written from the scenario and the real exit)")
  if (!is.na(tr_find_soffice())) { fp <- output$j_dl_pdf; ok(identical(readBin(fp, "raw", 4), charToRaw("%PDF")), "Download PDF gives the PDF") ; file.copy(fp, "/tmp/sheet_5nov.pdf", overwrite = TRUE) }
})
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); if (fail) quit(status = 1)
