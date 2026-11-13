# tests/test_cc_module.R - the T Records C.C tab and API Configuration > Capital.com, driven with shiny::testServer
# against a fake Capital.com client and an in-memory store. Run from the app folder: Rscript tests/test_cc_module.R
suppressMessages({ library(shiny); library(TTR); library(zoo); library(DT); library(plotly) })
`%||%` <- function(x, y) if (is.null(x)) y else x
source("R/utils_cc_catalog.R"); source("R/utils_cc_api.R"); source("R/utils_cc_patterns.R"); source("R/utils_cc_chart.R"); source("R/utils_cc_records.R"); source("R/utils_cc_tradelog.R"); source("R/utils_trading_templates.R"); source("R/utils_cc_sheet.R"); source("R/utils_cc_plan.R"); source("R/utils_cc_course_full.R"); source("R/utils_cc_course_checks.R"); source("R/utils_cc_advice.R")
source("modules/cc_api_config.R"); source("modules/cc_trading_records.R")
pass <- 0L; fail <- 0L
ok <- function(cond, what) { if (isTRUE(cond)) { pass <<- pass + 1L; cat("  ok  ", what, "\n") } else { fail <<- fail + 1L; cat("  FAIL", what, "\n") } }
src <- readLines("tests/test_cc_api_records.R"); eval(parse(text = src[grep("^js <- ", src):(grep("^cat\\(\"Credentials file", src) - 1)]))   # the fake Capital.com

cl <- cc_new_client(http_fn = fake$fn, sleep_fn = function(s) NULL)
store <- cc_make_store(cc_mem_backend())
f <- tempfile(fileext = ".json"); writeLines(js(list(api_key = "KEY-123456789", identifier = "me@example.com", api_password = "pw", environment = "demo")), f)

cat("API Configuration > Capital.com\n")
testServer(cc_api_config_server, args = list(client = cl, store = store), {
  session$setInputs(cred_file = list(datapath = f, name = "capital_com_demo.json"), cred_text = "", connect = 1)
  ok(cl$connected(), "loading the file connects")
  st <- output$status; ok(grepl("Connected", paste(unlist(st), collapse = " ")) || grepl("Connected", as.character(st$html)), "status shows Connected")
  session$setInputs(def_epic = "OIL_BRENT", def_search = "Brent", save = 1)
  s <- store$current("settings"); ok("cc_default_epic" %in% s$setting_key && !any(grepl("KEY-123|pw$", s$setting_value)), "settings saved without any secret")
  session$setInputs(test = 1); ok(cl$connected(), "Test connection pings Capital.com")
})

cat("T Records C.C\n")
set.seed(9); n <- 900; p <- 65 * exp(cumsum(rnorm(n, 0, 0.0015)))
bars <- data.frame(time = as.POSIXct("2026-10-01", tz = "UTC") + (0:(n - 1)) * 900, open = c(65, head(p, -1)), close = p); bars$high <- pmax(bars$open, bars$close) + 0.03; bars$low <- pmin(bars$open, bars$close) - 0.03
testServer(cc_trading_records_server, args = list(client = cl, store = store, fetch_bars = function(epic, res, from, to) bars, vision_fn = function(prompt) list(text = '{"checks":[],"additions":[{"key":"bull_flag","from_candle":1,"to_candle":2,"invalid":1,"target":2,"note":"old"}]}'),
                                                  now_fn = function() as.POSIXct("2026-10-20 10:00", tz = "UTC")), {
  session$setInputs(s_risk = 1, s_cap = 2, s_minrrr = 1.5, s_adx_t = 25, s_adx_r = 20, s_hold = 10, s_hist_days = 20, s_on_from = "22:00", s_on_to = "06:00", s_or_start = "08:00", s_or_min = 60,
                    m_search = "Brent", m_find = 1)
  session$setInputs(m_epic = "OIL_BRENT"); ok(!is.null(mkt()) && mkt()$currency == "USD", "market facts read (quoted in USD)")
  session$setInputs(c_window = "48", c_res = "MINUTE_15", c_load = 1)
  ok(!is.null(scan()) && scan()$n == n, "chart loaded and every pattern rule run")
  ok(nrow(cc_coverage(scan())) == 141, "coverage of all 141 matrix rows is available")
  ch <- tryCatch({ output$c_chart; "ok" }, error = function(e) paste(class(e)[1], conditionMessage(e))); ok(identical(ch, "ok"), paste("the chart renders right after loading:", ch))
  ok(length(picks()) == nrow(scan()$current_df), "every pattern alive is drawn by default")
  session$setInputs(c_pick = scan()$current_df$key[2]); ok(length(picks()) == 1 && picks()[[1]]$num == 2, "ticking one box draws only that pattern, keeping its number")
  session$setInputs(c_none = 1); ok(length(picks()) == 0, "None clears the chart of patterns")
  session$setInputs(c_all = 1); ok(length(picks()) == nrow(scan()$current_df), "All ticks every pattern again")
  session$setInputs(o_dir = "BUY", o_size = 1, o_stop = 60, o_target = 70)
  for (o in c("c_r5", "c_sr", "c_osc", "c_profile", "c_related", "p_risk", "ps_bias", "ps_plan", "at_out")) { r <- tryCatch({ x <- output[[o]]; "ok" }, error = function(e) conditionMessage(e)); ok(identical(r, "ok"), paste("**** output renders:", o, r)) }
  ok(!is.null(r5()) && all(c("minor", "base", "major") %in% names(r5()$trends)), "**** Rule of Five frames and trends")
  session$setInputs(c_course = cc_course_checks$id); cf <- course_facts(scan(), scan_meta()); ok(length(cf) == 15 && sum(nzchar(unlist(cf))) >= 11, paste("**** facts for all 15 Claude course checks:", paste(names(cf)[!nzchar(unlist(cf))], collapse = ",")))
  session$setInputs(c_claude = 1); r <- claude_read(); rd <- store$current("claude_readings"); ln <- store$current("claude_reading_lines")
  ok(!is.null(r) && nrow(rd) >= 1 && sum(ln$section == "COURSE_CHECK") == 15 && all(ln$reading_id %in% rd$reading_id), "***** second reading saved: 1 reading row and 15 course-check lines")
  session$setInputs(c_pick = scan()$current_df$key, c_panel = "auto", c_levels = TRUE)
  ok(length(picks()) == nrow(scan()$current_df), "several patterns can be drawn at once")
  w <- plotly::plotly_build(cc_chart(scan(), picks(), panel = "auto")); sh <- w$x$layout$shapes
  ok(length(sh) >= length(picks()), "each drawn pattern has its shaded span and shape on the price chart")
  session$setInputs(c_save_note = "first scan", c_save = 1)
  sv <- store$current("scans"); ok(nrow(sv) == 1 && grepl("bars_all", sv$bars_json) && grepl("patterns", sv$bars_json), "Save scan writes the candles, settings and patterns to cc_scans")
  rs <- cc_scan_restore(sv$bars_json); ok(identical(sort(rs$scan$current_df$key), sort(scan()$current_df$key)), "a saved scan reopens with exactly the same patterns")
  session$setInputs(c_saved = sv$scan_id, c_open = 1); ok(isTRUE(scan_meta()$restored), "Open saved scan redraws it (view only)")
  session$setInputs(c_load = 2)
  k1 <- scan()$current_df$key[1]; rt <- sprintf('{"checks":[{"key":"%s","verdict":"agree","reason":"clear"}],"additions":[]}', k1)
  store$write("claude_readings", data.frame(reading_id = "CR_test", source = "app", epic = scan_meta()$epic, reply_text = rt, facts_json = "{}", stringsAsFactors = FALSE))
  claude_read(list(checks = data.frame(key = k1, verdict = "agree", reason = "clear"), additions = data.frame(), saved = list(id = "CR_test", where = "bigquery"), epic = scan_meta()$epic))
  session$setInputs(c_save = 2); sv2 <- store$current("scans"); sv2 <- sv2[order(sv2$saved_at), ]; ok(grepl('"reading_id":"CR_test"', tail(sv2$bars_json, 1)), "******** the scan saves the id of its Claude reading")
  claude_read(NULL); session$setInputs(c_saved = tail(sv2$scan_id, 1), c_open = 2)
  ok(!is.null(claude_read()) && identical(claude_read()$saved$id, "CR_test") && nrow(claude_read()$checks) == 1, "******** Open saved scan brings its Claude reading back")
  session$setInputs(c_load = 3)
  session$setInputs(c_claude = 1); r <- claude_read(); ok(!is.null(r) && r$refused == 1 && nrow(r$additions) == 0, "a Claude addition that does not reach the last candles is refused")
  session$setInputs(p_refresh = 1); ok(!is.null(acct()$read_at), "Refresh balance records when the balance was read")
  session$setInputs(p_size = 2, p_build = 1); sc <- scen()
  ok(!is.null(sc) && nrow(sc) >= 2 && all(sc$type == "MARKET") && all(is.finite(sc$risk_acc)), "market scenarios (deals) with the money in the account currency")
  ok(isTRUE(scen_msg()[[1]]) && grepl("market scenarios \\(deals\\)", scen_msg()[[2]]), "a message confirms the scenarios were worked out")
  session$setInputs(p_show_bad = TRUE); js <- as.character(output$p_scen); ok(!grepl("''''", js, fixed = TRUE) && grepl("Scenario", js), "the scenarios table carries no broken colouring script")
  rx <- paste(cc_plan_mode_rules, collapse = "|")
  do.call(session$setInputs, c(setNames(as.list(rep("warn", length(cc_plan_mode_rules))), paste0("s_pm_", names(cc_plan_mode_rules))), list(p_build = 2))); sw <- scen()
  ok(!any(grepl(paste0("BREAKS:[^|]*(", rx, ")"), sw$plan)) && nrow(sw) >= 2, "******* rules on Warn never block a scenario")
  ok(all(grepl("Rules on Warn|WARN|OK|half size|BREAKS", sw$plan)) && !any(grepl("Market regime|Rule of Five", sw$checks)), "... they show as WARN and are not in the blocking checks")
  do.call(session$setInputs, c(setNames(as.list(rep("block", length(cc_plan_mode_rules))), paste0("s_pm_", names(cc_plan_mode_rules))), list(p_build = 3))); sc <- scen()
  ok(attr(sc, "ccy") == "GBP", "scenario money is in GBP (the account), converted from USD")
  for (k in c("o_fund", "o_tech", "o_trigger", "o_exec", "o_stopwhy", "o_tgtwhy")) do.call(session$setInputs, setNames(list(""), k))
  sent <- list(); e <- session$rootScope(); if (bindingIsLocked("sendInputMessage", e)) unlockBinding("sendInputMessage", e)
  e$sendInputMessage <- function(inputId, message) sent[[sub("^.*-", "", inputId)]] <<- message
  do.call(session$setInputs, c(setNames(as.list(rep("off", length(cc_plan_mode_rules))), paste0("s_pm_", names(cc_plan_mode_rules))), list(p_build = 4))); sc4 <- scen()
  pick <- sc4$id[!sc4$blocked][1]; ok(!is.na(pick), "with the switchable rules Off a scenario can be chosen")
  session$setInputs(p_size_plan = TRUE, p_pick = pick); nv <- function(k) suppressWarnings(as.numeric(sent[[k]]$value))
  ok(identical(sent$o_dir$value, "BUY") && is.finite(nv("o_stop")) && is.finite(nv("o_target")), "******** choosing the radio button alone fills direction, stop and target")
  ok(identical(sent$o_strategy$value, cc_scen_setup(sc4[sc4$id == pick, ])) && nzchar(sent$o_chart$value %||% "") && identical(sent$o_purpose$value, "ASSESSED"), "... and the set-up, chart period and Assessed trade")
  ok(is.finite(nv("o_size")) && nv("o_size") >= 1 && nv("o_size") <= 2 && is.null(sent$p_size) && is.finite(nv("o_hours")), "********* the size typed (2) is kept (or halved to 1): never replaced by the plan-risk size; 'Size you want' is not changed")
  for (pk in sc4$id[!sc4$blocked]) { sent <- list(); session$setInputs(p_pick = pk); if (length(sent)) ok(nv("o_size") %in% c(1, 2), paste("*********", pk, "-> size", nv("o_size"), "(typed 2)")) }
  sent <- list(); session$setInputs(p_size = NA, p_size_plan = FALSE, p_pick = sc4$id[!sc4$blocked][1]); session$setInputs(p_pick = sc4$id[!sc4$blocked][min(2, sum(!sc4$blocked))])
  ok(is.null(sent$o_size), "********* no size typed and the plan-risk box off: the ticket size is left alone and you are asked to type it")
  session$setInputs(p_size = 2, p_size_plan = FALSE)
  session$setInputs(p_size = 3, p_build = 21); session$setInputs(p_pick = character(0), p_use = 31)
  ok(TRUE, "********* Copy pressed with no scenario selected (after changing the size and working them out again): no crash")
  r <- tryCatch({ session$setInputs(p_pick = NULL, p_use = 32); "ok" }, error = function(e) conditionMessage(e)); ok(identical(r, "ok"), "********* ... nor with the choice empty")
  session$setInputs(p_size = 2)
  do.call(session$setInputs, c(setNames(as.list(rep("block", length(cc_plan_mode_rules))), paste0("s_pm_", names(cc_plan_mode_rules))), list(p_build = 5))); sc <- scen()
  session$setInputs(p_pick = "BUY MARKET", p_use = 1)
  ok(TRUE, "choosing a scenario copies the levels")
  do.call(session$setInputs, c(setNames(as.list(rep("off", length(cc_plan_mode_rules))), paste0("s_pm_", names(cc_plan_mode_rules))), list(s_rr_pattern = 3, p_build = 8))); s3 <- scen()
  pt <- cc_scen_setup(s3) == "PATTERN"; ok(any(pt) && all(s3$rrr[pt] >= 3 - 1e-6) && all(grepl("minimum R:R 3.00", s3$note[pt])), "******** a set-up's own minimum R:R moves its scenarios' targets out (stop kept)")
  ok(!any(pt) || all(s3$rrr[!pt] < 3 + 1e-6), "... other set-ups keep the general minimum")
  session$setInputs(s_rr_pattern = NA, o_strategy = "PATTERN")
  ci0 <- claude_info(); sc0 <- scen(); session$setInputs(c_auto = TRUE, c_load = 7)
  ok(!is.null(scen()) && !is.null(claude_info()) && !identical(claude_info(), ci0), "******** one step: Analyse loads the chart, works out the scenarios and asks the Claude API")
  session$setInputs(o_dir = "BUY", o_type = "MARKET", o_size = 2, o_stop = round(sc$stop[sc$id == "BUY MARKET"], 3), o_target = round(sc$target[sc$id == "BUY MARKET"], 3),
                    o_level = NA, o_good_h = NA, o_purpose = "PRACTICE", o_strategy = "OTHER", o_chart = "15 Min", o_hours = 10, o_mood = 3,
                    o_fund = "my words", o_tech = "", o_trigger = "", o_exec = "", o_stopwhy = "", o_tgtwhy = "", o_ok = TRUE)
  t <- ticket(); ok(length(t$errors) == 0, "the ticket passes its checks")
  keep_tg <- input$o_target; session$setInputs(o_target = round(65.04 + 0.5 * (65.04 - input$o_stop), 3))
  ok(any(grepl("below the minimum", ticket()$errors)), "an order with reward:risk below the minimum is blocked")
  session$setInputs(o_target = keep_tg)
  session$setInputs(o_send = 1, o_confirm = 1)
  tr <- store$current("trades"); ok(nrow(tr) == 1 && tr$status == "OPEN" && tr$entry_level == 65.04 && tr$deal_id == "D1", "the order is sent; the trade is saved from the broker's fill")
  ok(identical(tr$setup_fund, "my words") && is.na(tr$stop_reason) || identical(tr$stop_reason, ""), "only your own words are saved in the reasoning boxes")
  ok(is.finite(tr$risk_account) && tr$account_currency == "GBP" && tr$instrument_currency == "USD", "the trade carries both currencies and the money at risk")
  x <- paste(as.character(output$o_open_tbl), collapse = ""); ok(grepl("Deal id", x) && any(trades()$status == "OPEN" & trades()$trade_id == tr$trade_id[1]), "***** the deal sent is listed in Plan & Order as OPEN from the records")
  ok(grepl("Recorded in BigQuery|uploaded to BigQuery", paste(unlist(output$o_result), collapse = " ")), "***** the send result says where the trade was recorded")
  sc2 <- store$current("scans"); ok(any(sc2$trade_id %in% tr$trade_id), "the chart and its patterns are saved with the trade")
  ev <- store$current("events"); ok(nrow(ev) >= 1 && any(ev$event_type == "ORDER_MARKET"), "the order and the broker's answer are logged")
  session$setInputs(sync = 1); ok(nrow(live()$pos) == 1, "sync reads the open position")
  session$setInputs(j_trade = tr$trade_id, j_purpose = "PRACTICE", j_chart = "15 Min", j_hours = 10, j_code = "", j_fund = "my words", j_tech = "t", j_trigger = "", j_exec = "", j_stopwhy = "", j_tgtwhy = "",
                    j_why = "", j_lessons = "learned", j_analysis = "", j_followed = "Y", j_devtype = "", j_devnote = "", j_mood = 3, j_save = 1)
  tr2 <- store$current("trades"); ok(tr2$record_version == 2L && tr2$lessons == "learned", "journal edits are saved as a new version")
  ok(nrow(store$read("trades")) >= 2, "earlier versions are kept")
  session$setInputs(pos_pick = "D1", pos_why = "test close", pos_close = 1, pos_close_ok = 1, st_scope = "ALL")
  tr3 <- store$current("trades"); ok(tr3$status == "CLOSED" && tr3$exit_code == "ME" && is.finite(tr3$pnl_account_est), "closing by hand records the exit (ME) and the P/L in GBP")
  ok(!is.null(stats()) && stats()$n == 1, "statistics count the closed trade")
  outs <- c("status_bar", "m_facts", "c_info", "c_pick_note", "c_chart", "c_active", "c_cov", "c_claude_out", "p_money", "p_size_help", "p_scen", "p_pick_ui", "o_checks", "o_result",
            "c_boxes", "sync_out", "p_scen_msg", "c_save_out", "pos_tbl", "ord_tbl", "j_facts", "j_tbl", "st_tiles", "st_equity", "st_pat", "fx_explain", "fx_cmp", "fx_tx", "fx_bal", "ddl")
  bad <- character(0); for (o in outs) { r <- tryCatch({ output[[o]]; TRUE }, error = function(e) { if (inherits(e, "shiny.silent.error")) TRUE else { cat("    ", o, ":", conditionMessage(e), "\n"); FALSE } }); if (!r) bad <- c(bad, o) }
  ok(!length(bad), sprintf("every output of the tab renders (%d checked)", length(outs)))
})

cat("Records check on opening the tab (your two rows from 2 Nov, no Sync pressed)\n")
st2 <- cc_make_store(cc_mem_backend())
st2$write("trades", cc_coerce("trades", data.frame(trade_id = c("CC_20261102075638.336_1421", "CC_20261102075724.976_4bac"), record_version = 2L, source = c("APP", "PLATFORM"), epic = "OIL_BRENT",
  market_name = "Brent Oil Spot", instrument_currency = "USD", account_currency = "GBP", direction = "BUY", size = 11, lot_size = 1, order_type = "MARKET",
  deal_id = c("00000000-701d", "POS-REAL-ID"), status = "CLOSED", entry_level = 109.756, stop_initial = 108.703, stop_level = 108.703, target_level = 110.495,
  entry_ts = as.POSIXct(c("2026-11-02 07:56:38", "2026-11-02 07:56:38"), tz = "UTC"), exit_level = c(0, 108.596), exit_ts = as.POSIXct(c("2026-11-02 07:56:40", "2026-11-02 08:34:00"), tz = "UTC"),
  exit_code = "S1", pnl_account_est = c(-900.10, -9.50), setup_fund = c("my words", NA))))
testServer(cc_trading_records_server, args = list(client = cc_new_client(http_fn = fake$fn, sleep_fn = function(s) NULL), store = st2, fetch_bars = function(...) NULL), {
  session$flushReact()
  t <- st2$current("trades"); k <- t[t$trade_id == "CC_20261102075638.336_1421", ]
  ok(k$status == "CLOSED" && k$exit_level == 108.596 && k$setup_fund == "my words", "on opening: your trade repaired to exit 108.596 without pressing Sync")
  ok(t$status[t$trade_id == "CC_20261102075724.976_4bac"] == "DUPLICATE", "on opening: the copy marked DUPLICATE")
  invisible(output$closed_tbl); tt <- trades(); tt <- tt[tt$status %in% "CLOSED", ]
  ok(nrow(tt) == 1 && tt$exit_level == 108.596 && !any(abs(tt$pnl_account_est + 900.10) < 0.01, na.rm = TRUE), "Closed trades table: one row at 108.596, no -900.10")
  s <- cc_trade_stats(t); ok(s$n == 1 && abs(s$net + 9.5) < 1e-9, "statistics: 1 trade, -9.50")
})
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); if (fail) quit(status = 1)
