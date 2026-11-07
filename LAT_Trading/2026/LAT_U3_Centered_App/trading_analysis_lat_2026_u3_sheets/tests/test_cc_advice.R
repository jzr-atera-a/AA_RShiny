# tests/test_cc_advice.R - prices rounded, order checks, measured chance, Morning Sheet text, Claude's suggested trades,
# and the order sent at the price of the moment (3 Nov 2026 cases). Run from the app folder: Rscript tests/test_cc_advice.R
suppressMessages({ library(shiny); library(TTR); library(zoo); library(DT); library(plotly) })
`%||%` <- function(x, y) if (is.null(x)) y else x
for (f in c("R/utils_trading_records.R", "R/utils_cc_catalog.R", "R/utils_cc_api.R", "R/utils_cc_patterns.R", "R/utils_cc_chart.R", "R/utils_cc_records.R", "R/utils_trading_templates.R", "R/utils_cc_sheet.R", "R/utils_cc_plan.R", "R/utils_cc_course_full.R", "R/utils_cc_course_checks.R", "R/utils_cc_advice.R",
            "modules/cc_api_config.R", "modules/cc_trading_records.R")) source(f)
pass <- 0L; fail <- 0L
ok <- function(cond, what) { if (isTRUE(cond)) { pass <<- pass + 1L; cat("  ok  ", what, "\n") } else { fail <<- fail + 1L; cat("  FAIL", what, "\n") } }

cat("Prices and order checks\n")
ok(cc_px_decimals(list(decimals = 3)) == 3, "decimals from Capital.com's decimalPlacesFactor")
ok(cc_px_decimals(list(decimals = NA, bid = 105.409, offer = 105.439)) == 3, "decimals inferred from the quotes when not given")
ok(cc_round_px(105.6728, 3) == 105.673, "your rejected SELL LIMIT 105.6728 is sent as 105.673")
ok(!length(cc_order_problems("SELL", "LIMIT", 105.673, 106.331, 103.693, 105.409, 105.439, 0.01)), "SELL LIMIT above the bid with stop above and target below: fine")
ok(any(grepl("ABOVE", cc_order_problems("SELL", "LIMIT", 105.2, 106.3, 103.7, 105.409, 105.439))), "SELL LIMIT below the price is refused before sending")
ok(any(grepl("BELOW", cc_order_problems("BUY", "LIMIT", 105.6, 105.0, 107, 105.409, 105.439))), "BUY LIMIT above the price is refused before sending")
ok(any(grepl("ABOVE", cc_order_problems("BUY", "STOP", 105.3, 104.9, 107, 105.409, 105.439))), "BUY STOP below the price is refused")
ok(any(grepl("wrong side", cc_order_problems("SELL", "MARKET", NA, 105.0, 103.7, 105.409, 105.439))), "a stop on the wrong side is refused")
sh <- cc_shift_levels(105.409, 105.896, 106.068, 103.693, 3)
ok(abs(sh$shift - 0.487) < 1e-9 && sh$stop == 106.555 && sh$target == 104.18, "your 3 Nov SELL: price moved 105.409 to 105.896, stop 106.068 becomes 106.555 (distance 0.659 kept)")
ok(grepl("entry price", cc_explain_error("HTTP 400: error.validation.limit.price")), "Capital.com's error.validation.limit.price explained in plain words")
ok(cc_vs_now(106.068, 105.409, 3) == "+0.659 (+0.63%)" && cc_vs_now(103.693, 105.409, 3) == "-1.716 (-1.63%)", "levels shown as distance from the price now")

cat("Measured chance: target before stop\n")
c0 <- rep(100, 60); h0 <- c0 + 0.1; l0 <- c0 - 0.1; h0[seq(5, 60, 5)] <- 101.2   # every 5th candle spikes up 1.2
up <- cc_touch_prob(h0, l0, c0, 1, 1, 1, horizon = 10); dn <- cc_touch_prob(h0, l0, c0, -1, 1, 1, horizon = 10)
ok(up$p == 100 && dn$p == 0 && up$n > 40, sprintf("spikes up: BUY reaches 1.0 first %.0f%%, SELL %.0f%% (n=%d)", up$p, dn$p, up$n))
both <- cc_touch_prob(c0 + 2, c0 - 2, c0, 1, 1, 1, horizon = 3); ok(both$p == 0, "stop and target in the same candle count as the stop (cautious)")
ok(!is.finite(cc_touch_prob(h0, l0, c0, 1, 0, 1)$p), "no chance without a stop distance")

cat("Morning Sheet from BigQuery\n")
ms <- cc_coerce_ms <- data.frame(sheet_id = c("MS_A", "MS_B"), record_version = 1L, saved_at = as.POSIXct(c("2026-11-02 06:00", "2026-11-03 06:58"), tz = "UTC"),
  sheet_date = as.Date(c("2026-11-02", "2026-11-03")), dow_price = 51983.98, dow_change_pct = 0.41, nikkei_price = 63081.86, nikkei_change_pct = -0.33,
  overnight_news = c("old news", "Oil slipped as Iran talks continued; midterms today"), overnight_calendar = "", todays_releases = "15:00 | US | Medium | JOLTS",
  releases_in_window = "15:00 | US | JOLTS", regime_summary = "", planned_setups = "", stand_aside = FALSE, stand_aside_reason = "", stringsAsFactors = FALSE)
lv <- data.frame(sheet_id = "MS_B", saved_at = as.POSIXct("2026-11-03 06:58", tz = "UTC"), instrument = "BRENT", overnight_low = 10390, overnight_high = 10595, current_price = 10579,
                 time_now_uk = "06:40", adx14 = NA, regime_label = NA, stringsAsFactors = FALSE)
m <- cc_morning_sheet(ms, lv, as.Date("2026-11-03"))
ok(!is.null(m) && m$sheet_id == "MS_B" && grepl("midterms today", m$text) && grepl("BRENT: overnight low 10,390", m$text) && grepl("IG quotes oil in cents", m$text), "today's sheet found, with its news, releases and levels")
ok(is.null(cc_morning_sheet(ms, lv, as.Date("2026-11-04"))), "no sheet for the day: NULL (the option is shown as not available)")
lv7 <- data.frame(sheet_id = "MS_B", saved_at = as.POSIXct("2026-11-03 06:58", tz = "UTC") + 1:7, instrument = c("EURUSD", "USDJPY", "GBPUSD", "AUDUSD", "WTI", "GOLD", "BRENT"),
                  overnight_low = c(1.1181, 157.766, 1.3397, 0.6975, 9576, 3925.8, 10390), overnight_high = c(1.1201, 157.969, 1.3418, 0.7006, 9760, 3974.5, 10595),
                  current_price = c(1.1197, 157.848, 1.3415, 0.6987, 9743, 3931.7, 10579), time_now_uk = "06:40", adx14 = NA, regime_label = NA, stringsAsFactors = FALSE)
m7 <- tryCatch(cc_morning_sheet(ms, lv7, as.Date("2026-11-03")), error = function(e) conditionMessage(e))
ok(is.list(m7) && length(gregexpr("overnight low", m7$text)[[1]]) == 7 && grepl("GOLD: overnight low 3,925.8", m7$text), "your 3 Nov sheet with 7 markets is read (the 'length > 1' bug)")

cat("Claude's suggested trades\n")
f <- list(epic = "OIL_BRENT", name = "Brent", currency = "USD", bid = 105.409, offer = 105.439, decimals = 3, min_stop_distance = 0.01)
rep_txt <- 'Here: {"summary":"Bearish after the spike; midterms risk.","morning_sheet_used":true,"suggestions":[{"side":"SELL","type":"LIMIT","entry":105.6728,"stop":106.4512,"target":103.9,"probability_pct":42,"horizon_hours":6,"why":"Rising wedge top.","main_risk":"US midterms"},{"side":"BUY","type":"MARKET","entry":105.44,"stop":104.6,"target":107,"probability_pct":35,"horizon_hours":4,"why":"x","main_risk":"y"},{"side":"HOLD","type":"X","entry":1,"stop":1,"target":1}],"scenario_estimates":[{"id":"SELL MARKET","probability_pct":40}]}'
pr <- cc_suggest_parse(rep_txt, f)
ok(pr$ok && nrow(pr$rows) == 2 && all(pr$rows$type == "MARKET") && pr$rows$entry[1] == 105.409 && pr$rows$stop[1] == 106.451, "Claude's LIMIT idea becomes a deal at the bid now; levels rounded to 3 decimals; a row that is not BUY/SELL is dropped")
ok(pr$rows$entry[2] == 105.439 && pr$rows$claude_p[1] == 42 && pr$used_sheet && pr$estimates$claude_p == 40, "a BUY uses the offer now; Claude's estimates kept")
pr2 <- cc_suggest_parse(rep_txt, f, 2); rr <- abs(pr2$rows$target - pr2$rows$entry) / abs(pr2$rows$entry - pr2$rows$stop)
ok(all(rr >= 2 - 1e-9) && any(grepl("minimum Reward:Risk 2.00", pr2$rows$note)), sprintf("with a minimum of 2, Claude's targets are moved out to meet it and it says so (lowest %.3f)", min(rr)))
ok(grepl("MUST be at least 2", cc_suggest_prompt(cc_scan(data.frame(time = as.POSIXct("2026-10-01", tz = "UTC") + (0:299) * 900, open = 100, high = 100.2 + sin(1:300) / 5, low = 99.8 + sin(1:300) / 5, close = 100 + sin(1:300) / 5), 15),
                                                   f, NULL, list(min_rrr = 2)) ) , "Claude is told the minimum Reward:Risk as a hard rule and that every trade is a deal now")
ok(!cc_suggest_parse("sorry", f)$ok, "an unreadable reply is reported, not guessed")
ok(cc_yahoo_symbol("OIL_BRENT") == "BZ=F" && cc_yahoo_symbol("X", "US Crude Oil") == "CL=F" && is.na(cc_yahoo_symbol("ZZZ", "Unknown")), "Yahoo symbols matched to Capital.com markets")
cat("Trading Desk parts\n")
tp <- desk_tabbox(TRUE, width = 12, id = "x", tabPanel("A", "a"), tabPanel("B", "b")); ok(inherits(tp, "desk_parts") && length(tp) == 2, "a module's tabs can be handed to the Trading Desk")
ok(length(desk_parts(cc_trading_records_ui("cc_records", parts = TRUE))) == 9, "the Capital.com screen gives its 9 tabs (new: 9. Backtest & Blotter *)")

cat("The tab: scenarios, Claude with the Morning Sheet, order sent at the price of the moment\n")
src <- readLines("tests/test_cc_api_records.R"); eval(parse(text = src[grep("^js <- ", src):(grep("^cat\\(\"Credentials file", src) - 1)]))
cl <- cc_new_client(http_fn = fake$fn, sleep_fn = function(s) NULL)
cf <- tempfile(fileext = ".json"); writeLines('{"api_key":"KEY-123456789","identifier":"me@example.com","api_password":"pw","environment":"demo"}', cf)
cl$set_credentials(cc_read_credentials(cf)); invisible(cl$login())
store <- cc_make_store(cc_mem_backend()); prompts <- character(0)
set.seed(9); n <- 900; p <- 65 * exp(cumsum(rnorm(n, 0, 0.0015)))
bars <- data.frame(time = as.POSIXct("2026-10-01", tz = "UTC") + (0:(n - 1)) * 900, open = c(65, head(p, -1)), close = p); bars$high <- pmax(bars$open, bars$close) + 0.03; bars$low <- pmin(bars$open, bars$close) - 0.03
claude <- function(prompt) { prompts <<- c(prompts, prompt)
  list(text = '{"summary":"test","morning_sheet_used":true,"suggestions":[{"side":"SELL","type":"LIMIT","entry":65.4567,"stop":66.1234,"target":63.9876,"probability_pct":41,"horizon_hours":5,"why":"w","main_risk":"r"}],"scenario_estimates":[{"id":"BUY MARKET","probability_pct":52}]}') }
day_ms <- list(ok = TRUE, sheet_id = "MS_X", saved_at = as.POSIXct("2026-10-20 06:50", tz = "UTC"), text = "MORNING SHEET 20/10/2026 ... Overnight news: OPEC unchanged")
have_sheet <- TRUE
ybars <- bars; ybars[c("open", "high", "low", "close")] <- ybars[c("open", "high", "low", "close")] + 3   # Yahoo futures 3 above
yasked <- character(0)
testServer(cc_trading_records_server, args = list(client = cl, store = store, fetch_bars = function(epic, res, from, to) bars, vision_fn = claude,
                                                  yahoo_fn = function(symbol, range, interval) { yasked <<- c(yasked, paste(symbol, range, interval)); list(bars = ybars) },
                                                  morning_fn = function(day) if (have_sheet) day_ms else list(ok = FALSE, why = "No Morning Sheet for 20/10/2026 in BigQuery.", missing = TRUE),
                                                  now_fn = function() as.POSIXct("2026-10-20 10:00", tz = "UTC")), {
  session$setInputs(s_risk = 1, s_cap = 2, s_minrrr = 1.5, s_adx_t = 25, s_adx_r = 20, s_hold = 10, s_hist_days = 20, s_on_from = "22:00", s_on_to = "06:00", s_or_start = "08:00", s_or_min = 60,
                    m_search = "Brent", m_find = 1)
  session$setInputs(m_epic = "OIL_BRENT"); session$setInputs(c_window = "48", c_res = "MINUTE_15", c_load = 1)
  session$setInputs(c_src = "YAHOO", c_ysym = "", c_load = 2)
  ok(identical(yasked, "BZ=F 60d 15m") && grepl("Yahoo BZ=F", scan_meta()$source), "Yahoo chosen: BZ=F 15-minute candles are read for Brent")
  ok(abs(utils::tail(scan()$ctx$c, 1) - mean(c(65.00, 65.04))) < 1e-9, "Yahoo candles shifted so the last close equals Capital.com's price now")
  session$setInputs(c_src = "CC", c_load = 3); ok(identical(scan_meta()$source, "Capital.com"), "back to Capital.com candles")
  session$setInputs(p_size = 2, p_build = 1); sc <- scen()
  ok(nrow(sc) >= 2 && all(sc$type == "MARKET") && all(sc$entry == round(sc$entry, 2)) && all(sc$stop == round(sc$stop, 2)), "deal scenarios, levels rounded to the market's 2 decimals")
  ok(all(sc$rrr >= 1.5 - 1e-6) && !any(sc$blocked & grepl("R:R", sc$checks)), sprintf("no scenario is below the minimum Reward:Risk (lowest %.2f)", min(sc$rrr)))
  session$setInputs(p_rrr = 2.5, p_build = 2); sc <- scen(); ok(all(sc$rrr >= 2.5 - 1e-6) && grepl("Reward:Risk of 2.50", scen_msg()[[2]]), "box 2's minimum (changed to 2.5) is used for the scenarios")
  session$setInputs(p_rrr = 1.5, p_build = 3); sc <- scen()
  ok(all(is.finite(sc$meas_p) | sc$meas_n == 0) && any(sc$meas_n > 50), "each scenario has a measured chance with its n")
  session$setInputs(p_show_bad = TRUE); x <- as.character(output$p_scen); ok(grepl("Stop vs now", x) && grepl("Chance target first: measured", x) && grepl("Claude", x), "table shows levels vs now and both chances")
  ui <- paste(as.character(output$p_ms_ui), collapse = ""); ok(grepl("found in BigQuery", ui) && grepl("p_ms_use", ui), "today's Morning Sheet found: the option is on")
  session$setInputs(p_ms_use = "yes", p_claude = 1); sc2 <- scen()
  ok(any(grepl("OPEC unchanged", prompts)) && grepl("AND the Morning Sheet", tail(prompts, 1)), "Claude received today's Morning Sheet")
  cr <- sc2[sc2$source == "Claude", ]
  ok(nrow(cr) == 1 && cr$type == "MARKET" && cr$entry == mkt()$bid && cr$stop == 66.12 && cr$claude_p == 41 && is.finite(cr$meas_p) && cr$rrr >= 1.5 - 1e-6, "Claude's trade added as a deal at the bid, meeting the minimum R:R, with Claude's and the measured chance")
  ok(sc2$claude_p[sc2$id == "BUY MARKET"] == 52, "Claude's estimate added to the rule scenario")
  session$setInputs(p_ms_use = "no", p_claude = 2); ok(grepl("No Morning Sheet is included", tail(prompts, 1)), "with No, the sheet is not sent")
  # ****** the previous 4 working days' trades from BigQuery go to Claude for a review
  store$write("trades", data.frame(trade_id = c("CC_OLD1", "CC_OLD2", "CC_OLDX"), status = "CLOSED", epic = "OIL_BRENT", market_name = "Brent Oil Spot", direction = "BUY", size = 1,
    entry_level = 65, stop_initial = 64.8, target_level = 65.5, exit_level = 64.79, exit_code = "S1", pnl_account_est = -0.2, lessons = c("stop too tight", "again tight", "too old"),
    entry_ts = as.POSIXct(c("2026-10-19 08:00", "2026-10-14 09:00", "2026-10-13 09:00"), tz = "UTC"), exit_ts = as.POSIXct(c("2026-10-19 08:20", "2026-10-14 09:30", "2026-10-13 09:30"), tz = "UTC"), stringsAsFactors = FALSE))
  ok(identical(format(cc_prev_workdays(as.POSIXct("2026-10-20 10:00", tz = "UTC"), 4)), c("2026-10-19", "2026-10-16", "2026-10-15", "2026-10-14")), "previous 4 working days skip the weekend")
  session$setInputs(p_hist_use = TRUE, p_claude = 3); pr <- tail(prompts, 1)
  ok(grepl("PREVIOUS 4 WORKING DAYS", pr) && grepl("stop too tight", pr) && grepl("again tight", pr) && !grepl("too old", pr) && grepl("past_trades_review", pr), "with the option ticked, the trades of the previous 4 working days (not older) are sent with the review task")
  cs <- store$current("claude_suggestions"); cs <- cs[order(cs$saved_at), ]; ok(isTRUE(tail(cs$history_asked, 1)) && tail(cs$history_n, 1) == 2L, "the call is saved with how many past trades were sent")
  ok(grepl("2 trade\\(s\\) found", paste(as.character(output$p_hist_info), collapse = "")), "the option says how many trades it found")
  session$setInputs(p_hist_use = FALSE, p_claude = 4); ok(!grepl("PREVIOUS 4 WORKING DAYS", tail(prompts, 1)), "unticked: no past trades sent")
  have_sheet <<- FALSE; session$setInputs(p_ms_reload = 1); ui2 <- paste(as.character(output$p_ms_ui), collapse = "")
  ok(grepl("not available", ui2) && grepl("No Morning Sheet", ui2), "no sheet today: the option says it is not available")
  # market order: the ticket was worked out at an older price; it is sent at the price of the moment, distances kept
  for (k in c("o_fund", "o_tech", "o_trigger", "o_exec", "o_stopwhy", "o_tgtwhy")) do.call(session$setInputs, setNames(list(""), k))
  m0 <- mkt(); m0$offer <- 64.50; m0$bid <- 64.46; mkt(m0)
  session$setInputs(o_dir = "BUY", o_type = "MARKET", o_size = 2, o_stop = 63.70, o_target = 65.70, o_level = NA, o_good_h = NA, o_purpose = "PRACTICE", o_strategy = "OTHER",
                    o_chart = "15 Min", o_hours = 10, o_mood = 3, o_ok = TRUE)
  ok(grepl("Price now 64.50", paste(as.character(output$o_checks), collapse = "")) && grepl("-0.80", paste(as.character(output$o_checks), collapse = "")), "the ticket shows the price now and each level's distance from it")
  session$setInputs(o_size = 104.3); ok(any(grepl("bigger than the size you set", ticket()$errors)), "****** a size above the size you set (box 1) is refused: 104.3 vs 2")
  session$setInputs(o_size = 2)
  fake$clear(); session$setInputs(o_send = 1, o_confirm = 1)
  pb <- jsonlite::fromJSON(Filter(function(z) z$method == "POST" && grepl("/positions$", z$url), fake$calls())[[1]]$body)
  ok(abs(pb$stopLevel - 64.24) < 1e-9 && abs(pb$profitLevel - 66.24) < 1e-9, sprintf("price moved 64.50 -> 65.04: stop sent %s, target %s (distances 0.80 / 1.20 kept)", pb$stopLevel, pb$profitLevel))
  ok(grepl("moved with it", paste(as.character(output$o_result), collapse = "")), "the result says the levels moved with the price")
  # extra decimals are rounded; nothing is ever sent as a working order
  session$setInputs(o_dir = "SELL", o_stop = 66.1234, o_target = 61.9876, o_ok = TRUE)
  ok(any(grepl("more than 2 decimals", ticket()$warnings)), "the ticket warns that extra decimals will be rounded")
  fake$clear(); session$setInputs(o_send = 2, o_confirm = 2); calls <- fake$calls()
  ok(!any(vapply(calls, function(z) grepl("workingorders", z$url), TRUE)) && any(vapply(calls, function(z) z$method == "POST" && grepl("/positions$", z$url), TRUE)), "the SELL goes as a deal (POST /positions), never a working order")
  session$setInputs(o_dir = "BUY", o_stop = 63.70, o_target = 64.90, o_ok = TRUE)
  ok(any(grepl("below your minimum", ticket()$errors)), "a deal below the minimum Reward:Risk is blocked in the ticket")
  ui <- paste(as.character(output$o_result), collapse = ""); ok(grepl("Deal opened", ui) && grepl("Trades", ui), "the result says the deal is open and in Trades")
  # course study plan: plan rules on the ticket, Rule of Five tick boxes, reason to break, PLAN_CHECK saved
  session$setInputs(s_pl_markets = "GOLD", s_pl_r1 = "Trade with the trend", o_dir = "SELL", o_stop = 66.1234, o_target = 61.9876, o_ok = TRUE, o_break = "")
  pc <- plan_chk(); ok(!pc$ok[1] && any(grepl("Plan point 1", pc$rule)), "plan check: market not in the plan and the unticked Rule of Five fail")
  ok(grepl("Plan point 1: Trade with the trend", paste(as.character(output$o_plan), collapse = "")), "the ticket shows the Rule of Five tick box with the student's own text")
  fake$clear(); session$setInputs(o_send = 3); ok(!length(Filter(function(z) z$method == "POST", fake$calls())), "a deal that breaks the plan is NOT sent without a reason")
  session$setInputs(o_break = "Testing gold rule exception", o_send = 4, o_confirm = 4)
  ok(any(vapply(fake$calls(), function(z) z$method == "POST" && grepl("/positions$", z$url), TRUE)), "with a written reason it is sent")
  e <- store$current("events"); pe <- e[e$event_type %in% "PLAN_CHECK", ]; ok(nrow(pe) >= 1 && grepl("Testing gold rule exception", tail(pe$note, 1)) && grepl("BROKEN", tail(pe$note, 1)), "the plan check and the reason are saved with the trade (cc_events PLAN_CHECK)")
  # ***** plan-consistent scenarios, saved Claude output
  sc <- scen(); ok(all(c("plan", "blocked") %in% names(sc)) && all(sc$blocked[startsWith(sc$plan, "BREAKS")]), "***** every scenario carries its plan check; one that breaks the plan is blocked")
  session$setInputs(p_show_bad = FALSE); x <- paste(as.character(output$p_scen), collapse = ""); ok(!any(vapply(sc$id[sc$blocked], function(i) grepl(paste0(">", i, "<"), x, fixed = TRUE), TRUE)), "***** scenarios that break the plan are hidden by default")
  ok(nrow(store$current("scenarios")) > 0 && nrow(store$current("claude_suggestions")) > 0, "***** scenarios and Claude suggestions are saved")
  cs <- store$current("claude_suggestions"); ok(any(cs$morning_sheet_used %in% TRUE) && all(nzchar(cs$reply_text)), "***** the call with the Morning Sheet is saved with Claude's reply")
  session$setInputs(p_show_bad = TRUE)
  session$setInputs(p_build = 9); sc <- scen(); ok(all(c("htf_d", "htf_h4", "fit") %in% names(sc)) && grepl("Trend daily / 4h", paste(as.character(output$p_scen), collapse = "")), "every scenario shows the daily / 4-hour trend and whether it is with or against it")
})
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); if (fail) quit(status = 1)
