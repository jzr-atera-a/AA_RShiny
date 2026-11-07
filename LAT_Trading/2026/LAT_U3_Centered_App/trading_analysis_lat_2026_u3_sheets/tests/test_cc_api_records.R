# tests/test_cc_api_records.R - Capital.com client (fake network), currency, budget, scenarios, sync and the store.
# Run from the app folder:  Rscript tests/test_cc_api_records.R
suppressMessages({ library(TTR); library(zoo) })
`%||%` <- function(x, y) if (is.null(x)) y else x
source("R/utils_cc_catalog.R"); source("R/utils_cc_api.R"); source("R/utils_cc_patterns.R"); source("R/utils_cc_chart.R"); source("R/utils_cc_records.R")
pass <- 0L; fail <- 0L
ok <- function(cond, what) { if (isTRUE(cond)) { pass <<- pass + 1L; cat("  ok  ", what, "\n") } else { fail <<- fail + 1L; cat("  FAIL", what, "\n") } }
js <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null"))

# ---- a fake Capital.com: records every call, answers like the documented API -------------------------------------
fake <- local({ calls <- list(); expire_next <- FALSE; positions <- list(); orders <- list()
  fn <- function(method, url, headers, body) {
    calls[[length(calls) + 1]] <<- list(method = method, url = url, headers = headers, body = body)
    path <- sub("^https://[^/]+/api/v1", "", sub("\\?.*$", "", url))
    if (path == "/session" && method == "POST") { b <- jsonlite::fromJSON(body)
      if (!identical(headers$`X-CAP-API-KEY`, "KEY-123456789") || !identical(b$password, "pw")) return(list(status = 401, headers = list(), body = js(list(errorCode = "error.invalid.details"))))
      return(list(status = 200, headers = list(cst = "CST1", `x-security-token` = "XST1"), body = js(list(currencyIsoCode = "GBP", currentAccountId = "ACC1", accounts = list(list(accountId = "ACC1")))))) }
    if (expire_next) { expire_next <<- FALSE; return(list(status = 401, headers = list(), body = js(list(errorCode = "error.invalid.session.token")))) }
    if (is.null(headers$CST)) return(list(status = 401, headers = list(), body = "{}"))
    if (path == "/accounts") return(list(status = 200, headers = list(), body = js(list(accounts = list(list(accountId = "ACC1", accountName = "Demo", accountType = "CFD", preferred = TRUE, currency = "GBP", symbol = "£",
                                                                                                   balance = list(balance = 10000, deposit = 10000, profitLoss = 0, available = 9800)))))))
    if (path == "/markets/OIL_BRENT") return(list(status = 200, headers = list(), body = js(list(instrument = list(epic = "OIL_BRENT", name = "Brent Crude Oil", type = "COMMODITIES", currency = "USD", lotSize = 1, marginFactor = 10, marginFactorUnit = "PERCENTAGE"),
      dealingRules = list(minDealSize = list(unit = "POINTS", value = 1), minStopOrProfitDistance = list(unit = "POINTS", value = 0.05)), snapshot = list(bid = 65.00, offer = 65.04, marketStatus = "TRADEABLE")))))
    if (path == "/markets/GBPUSD") return(list(status = 200, headers = list(), body = js(list(instrument = list(epic = "GBPUSD", currency = "USD"), snapshot = list(bid = 1.2499, offer = 1.2501)))))
    if (path == "/markets") return(list(status = 200, headers = list(), body = js(list(markets = list(list(epic = "OIL_BRENT", instrumentName = "Brent Crude Oil", instrumentType = "COMMODITIES"))))))
    if (grepl("^/markets/", path)) return(list(status = 404, headers = list(), body = js(list(errorCode = "error.not-found.epic"))))
    if (path == "/prices/OIL_BRENT") { q <- sub("^[^?]*\\?", "", url); n <- 30
      t <- as.POSIXct("2026-10-20 08:00", tz = "UTC") + (0:(n - 1)) * 900; p <- 65 + cumsum(rep(c(0.02, -0.01), length.out = n))
      pr <- lapply(seq_len(n), function(i) list(snapshotTimeUTC = format(t[i], "%Y-%m-%dT%H:%M:%S"), openPrice = list(bid = p[i] - 0.02, ask = p[i] + 0.02),
                                                 highPrice = list(bid = p[i] + 0.05, ask = p[i] + 0.09), lowPrice = list(bid = p[i] - 0.06, ask = p[i] - 0.02), closePrice = list(bid = p[i], ask = p[i] + 0.04), lastTradedVolume = 100))
      return(list(status = 200, headers = list(), body = js(list(prices = pr)))) }
    if (path == "/positions" && method == "POST") { b <- jsonlite::fromJSON(body)
      positions[[1]] <<- list(position = list(dealId = "D1", dealReference = "o_ref1", size = b$size, direction = b$direction, level = 65.04, stopLevel = b$stopLevel, profitLevel = b$profitLevel,
                                              upl = 0, currency = "USD", createdDateUTC = "2026-10-20T10:00:00"), market = list(epic = b$epic, instrumentName = "Brent Crude Oil", lotSize = 1, bid = 65, offer = 65.04))
      return(list(status = 200, headers = list(), body = js(list(dealReference = "o_ref1")))) }
    if (path == "/workingorders" && method == "POST") return(list(status = 200, headers = list(), body = js(list(dealReference = "o_ref2"))))
    if (grepl("^/confirms/", path)) return(list(status = 200, headers = list(), body = js(list(dealStatus = "ACCEPTED", dealId = if (grepl("ref1", path)) "D1" else "W1", level = 65.04, date = "2026-10-20T10:00:00"))))
    if (grepl("^/positions/", path) && method == "DELETE") { positions <<- list(); return(list(status = 200, headers = list(), body = js(list(dealReference = "o_ref3")))) }
    if (path == "/positions" && method == "GET") return(list(status = 200, headers = list(), body = js(list(positions = positions))))
    if (path == "/workingorders" && method == "GET") return(list(status = 200, headers = list(), body = js(list(workingOrders = orders))))
    if (path == "/history/activity") return(list(status = 200, headers = list(), body = js(list(activities = list()))))
    if (path == "/history/transactions") return(list(status = 200, headers = list(), body = js(list(transactions = list()))))
    if (path == "/ping") return(list(status = 200, headers = list(), body = js(list(status = "OK"))))
    list(status = 404, headers = list(), body = "{}") }
  list(fn = fn, calls = function() calls, expire = function() expire_next <<- TRUE, clear = function() calls <<- list()) })

cat("Credentials file\n")
f <- tempfile(fileext = ".json"); writeLines(js(list(api_key = "KEY-123456789", identifier = "me@example.com", api_password = "pw", environment = "demo")), f)
cr <- cc_read_credentials(f); ok(identical(cr$environment, "demo") && identical(cr$identifier, "me@example.com"), "reads the JSON credentials file")
ok(inherits(try(cc_read_credentials(text = '{"api_key":"x"}'), silent = TRUE), "try-error"), "a file missing the login or password is refused with a message")
d <- tempfile(); dir.create(d); file.copy(f, file.path(d, "capital_com_demo.json")); writeLines('{"type":"service_account","private_key":"x"}', file.path(d, "bq.json"))
lc <- cc_find_local_credentials(d); ok(!is.null(lc) && basename(lc$path) == "capital_com_demo.json", "finds the Capital.com file in the key folder and ignores the BigQuery key")

cat("Client\n")
cl <- cc_new_client(http_fn = fake$fn, sleep_fn = function(s) NULL)
cl$set_credentials(cr); cl$login(); st <- cl$status()
ok(st$connected && identical(st$account_id, "ACC1") && identical(st$currency, "GBP"), "logs in, keeps the account and its currency")
ok(!grepl("123456789", paste(st$masked_key, cl$log(), collapse = " ")), "the full key never appears in the status or the log")
a <- cc_accounts_df(cl$accounts()); ok(a$balance == 10000 && a$available == 9800, "accounts parsed (balance, available)")
mf <- cc_market_facts(cl$market("OIL_BRENT")); ok(mf$currency == "USD" && mf$min_size == 1 && mf$margin_factor == 10, "market facts: currency, minimum size, margin")
fake$expire(); a2 <- cc_accounts_df(cl$accounts()); ok(nrow(a2) == 1, "an expired session (401) logs in again by itself")
b <- cc_prices_to_bars(cl$prices("OIL_BRENT", "MINUTE_15", 1000))
ok(nrow(b) == 30 && abs(b$close[1] - 65.04) < 1e-9, "prices become mid-price candles (between bid and ask)")
fake$clear(); invisible(cc_fetch_bars(cl, "OIL_BRENT", "MINUTE_15", as.POSIXct("2026-10-01", tz = "UTC"), as.POSIXct("2026-10-30", tz = "UTC")))
ok(length(fake$calls()) >= 3, "long ranges are fetched in pages of at most 1000 candles")
ref <- list(fn = function(method, url, headers, body) { if (grepl("/prices/", url) && grepl("from=2026-09", url)) return(list(status = 400, headers = list(), body = js(list(errorCode = "error.invalid.daterange")))); fake$fn(method, url, headers, body) })
cl_r <- cc_new_client(http_fn = ref$fn, sleep_fn = function(s) NULL); cl_r$set_credentials(cr); msgs <- character(0)
br <- cc_fetch_bars(cl_r, "OIL_BRENT", "MINUTE_15", as.POSIXct("2026-09-20", tz = "UTC"), as.POSIXct("2026-10-20", tz = "UTC"), log = function(...) msgs <<- c(msgs, paste(...)))
ok(nrow(br) > 0 && length(attr(br, "refused")) >= 1 && any(grepl("refused", msgs)), "a refused date range is skipped and logged, the rest is still read")
all_bad <- list(fn = function(method, url, headers, body) { if (grepl("/prices/", url) && grepl("from=", url)) return(list(status = 400, headers = list(), body = js(list(errorCode = "error.invalid.daterange")))); fake$fn(method, url, headers, body) })
cl_b <- cc_new_client(http_fn = all_bad$fn, sleep_fn = function(s) NULL); cl_b$set_credentials(cr)
bb2 <- cc_fetch_bars(cl_b, "OIL_BRENT", "MINUTE_15", as.POSIXct("2026-10-01", tz = "UTC"), as.POSIXct("2026-10-20", tz = "UTC"), log = function(...) NULL)
ok(nrow(bb2) > 0, "if every dated range is refused, the latest candles are read without dates")
fake$clear(); invisible(cc_activity_range(cl, as.POSIXct("2026-10-20", tz = "UTC"), as.POSIXct("2026-10-23", tz = "UTC")))
ok(length(Filter(function(z) grepl("history/activity", z$url), fake$calls())) == 3, "activity is read one day per request (3 days = 3 requests)")
live <- cc_new_client(http_fn = fake$fn, sleep_fn = function(s) NULL); cr2 <- cr; cr2$environment <- "live"; live$set_credentials(cr2)
ok(inherits(try(live$open_position("OIL_BRENT", "BUY", 1), silent = TRUE), "try-error"), "orders are refused when the environment is not demo")
r <- cl$open_position("OIL_BRENT", "BUY", 2, stop_level = 64.5, profit_level = 66)
ok(identical(r$dealStatus, "ACCEPTED") && r$dealId == "D1", "a market order is sent and its confirmation read")
body <- jsonlite::fromJSON(Filter(function(z) z$method == "POST" && grepl("/positions", z$url), fake$calls())[[1]]$body)
ok(body$direction == "BUY" && body$size == 2 && body$stopLevel == 64.5 && body$profitLevel == 66, "the order body carries direction, size, stop and target")
w <- cl$open_working_order("OIL_BRENT", "SELL", 1, 66, "LIMIT", 66.5, 65, good_till = as.POSIXct("2026-10-21 10:00", tz = "UTC"))
wb <- jsonlite::fromJSON(Filter(function(z) grepl("workingorders", z$url) && z$method == "POST", fake$calls())[[1]]$body)
ok(wb$type == "LIMIT" && wb$level == 66 && wb$goodTillDate == "2026-10-21T10:00:00", "a limit order carries its level, type and expiry (UTC)")

txr <- list(fn = function(method, url, headers, body) { if (grepl("/history/transactions", url) && grepl("from=", url)) return(list(status = 400, headers = list(), body = js(list(errorCode = "error.invalid.daterange"))))
  if (grepl("/history/transactions", url) && grepl("lastPeriod=86400", url)) return(list(status = 200, headers = list(), body = js(list(transactions = list(list(dateUtc = "2026-11-02T10:00:00", instrumentName = "Brent Oil Spot", transactionType = "TRADE", size = -0.81, currency = "GBP"))))))
  fake$fn(method, url, headers, body) })
cl_t <- cc_new_client(http_fn = txr$fn, sleep_fn = function(s) NULL); cl_t$set_credentials(cr); lg <- character(0)
tx2 <- cc_transactions_range(cl_t, as.POSIXct("2026-11-01", tz = "UTC"), as.POSIXct("2026-11-02 12:00", tz = "UTC"), log = function(...) lg <<- c(lg, paste(...)))
ok(length(tx2) == 1, "transactions: the last 24 hours are read first (dated ranges are refused by Capital.com)")
fake$clear(); invisible(cc_fetch_bars(cl, "OIL_BRENT", "MINUTE_30", as.POSIXct("2026-10-13", tz = "UTC"), as.POSIXct("2026-11-02", tz = "UTC")))
spans <- vapply(Filter(function(z) grepl("/prices/", z$url), fake$calls()), function(z) { f <- sub(".*from=([^&]+).*", "\\1", z$url); t <- sub(".*to=([^&]+).*", "\\1", z$url)
  as.numeric(difftime(as.POSIXct(utils::URLdecode(t), format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"), as.POSIXct(utils::URLdecode(f), format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"), units = "days")) }, 0)
ok(length(spans) >= 3 && all(spans <= 7.0001), sprintf("price history asked in spans of at most 7 days (%d requests for 20 days of 30-minute candles)", length(spans)))

cat("Currency and budget\n")
fx <- cc_fx_rate(cl, "USD", "GBP"); ok(abs(fx$rate - 1 / 1.25) < 1e-9 && fx$epic == "GBPUSD", "USD -> GBP from Capital.com's GBPUSD mid (divided)")
ok(cc_fx_rate(cl, "GBP", "GBP")$rate == 1, "same currency: rate 1")
bg <- cc_budget("BUY", 65.04, 64.54, 66.04, 2, 1, fx$rate, 10000, 9800, 10, "PERCENTAGE", 0.04, 0, 1, 2, 1.5, 1, 0.05)
ok(abs(bg$risk_account - 0.5 * 2 * 0.8) < 1e-9 && abs(bg$balance_if_stop - (10000 - 0.8)) < 1e-9, "risk in GBP = 0.5 points x size 2 x 0.8")
ok(abs(bg$balance_if_target - (10000 + 1.6)) < 1e-9 && abs(bg$rrr - 2) < 1e-9, "balance if target and reward:risk")
ok(abs(bg$margin_account - 65.04 * 2 * 0.10 * 0.8) < 1e-9, "margin = notional x 10% converted to GBP")
ok(abs(bg$size_for_plan - 10000 * 0.01 / (0.5 * 0.8)) < 1e-6, "size that risks the plan's 1%")
ok(length(cc_budget("BUY", 65, 65.5, 66, 1, 1, 0.8, 10000, 9800)$errors) > 0, "a stop above a buy is an error")
ok(any(grepl("minimum", cc_budget("BUY", 65, 64, 66, 0.5, 1, 0.8, 10000, 9800, min_size = 1)$errors)), "a size below Capital.com's minimum is an error")
ok(any(grepl("plan", cc_budget("BUY", 65, 60, 75, 100, 1, 0.8, 10000, 9800, risk_pct_plan = 1)$warnings)), "risk above the plan's % is a warning")

cat("Scenarios\n")
set.seed(5); n <- 600; cl_ <- 65 * exp(cumsum(rnorm(n, 0, 0.0015))); bars <- data.frame(time = as.POSIXct("2026-10-01", tz = "UTC") + (0:(n - 1)) * 900, open = c(65, head(cl_, -1)), close = cl_)
bars$high <- pmax(bars$open, bars$close) + 0.03; bars$low <- pmin(bars$open, bars$close) - 0.03
sc <- cc_scan(bars, 15, list(horizon = 30)); scn <- cc_scenarios(sc, tail(bars$close, 1) - 0.02, tail(bars$close, 1) + 0.02)
ok(nrow(scn) >= 2 && all(scn$type == "MARKET") && setequal(scn$side, c("BUY", "SELL")), sprintf("%d scenarios, all DEALS at the market (no limit / stop orders), both sides", nrow(scn)))
rr <- abs(scn$target - scn$entry) / abs(scn$entry - scn$stop); ok(all(rr >= 1.5 - 1e-9), sprintf("every scenario meets the minimum Reward:Risk 1.5 (lowest %.3f)", min(rr)))
scn2 <- cc_scenarios(sc, tail(bars$close, 1) - 0.02, tail(bars$close, 1) + 0.02, 0.01, 2.5, 2); rr2 <- abs(scn2$target - scn2$entry) / abs(scn2$entry - scn2$stop)
ok(all(rr2 >= 2.5 - 1e-9) && all(abs(scn2$stop * 100 - round(scn2$stop * 100)) < 1e-6), sprintf("a minimum of 2.5 is met too, after rounding to 2 decimals (lowest %.3f)", min(rr2)))
ok(all(abs(scn$entry - scn$stop) >= 0.5 * sc$ctx$a[sc$ctx$n] - 1e-9), "no stop closer than 0.5 ATR (the tiny-stop SELL of 4 Nov cannot happen again)")
ok(all(ifelse(scn$side == "BUY", scn$stop < scn$entry & scn$target > scn$entry, scn$stop > scn$entry & scn$target < scn$entry)), "every scenario has its stop and target on the correct sides")
ok(!any(grepl("success|probab", tolower(paste(names(scn), scn$note, scn$basis)))), "scenarios carry no success probability")
lastp <- tail(bars$close, 1)
ok(all(scn$entry[scn$side == "BUY"] > lastp) && all(scn$entry[scn$side == "SELL"] < lastp), "buys at the offer, sells at the bid (the price now)")

cat("Exit codes\n")
ok(cc_exit_code("BUY", 66, 64.5, 64.5, 66) == "T", "exit at the target = T"); ok(cc_exit_code("BUY", 64.5, 64.5, 64.5, 66) == "S1", "exit at the initial stop = S1")
ok(cc_exit_code("BUY", 65.2, 64.5, 65.2, 66) == "S2+", "exit at a moved stop = S2+"); ok(cc_exit_code("SELL", 64.9, 65.5, 65.5, 64) == "ME", "exit between = ME (manual)")

cat("Sync (reconcile)\n")
tr <- cc_coerce("trades", data.frame(trade_id = c("T1", "T2"), record_version = 1L, epic = "OIL_BRENT", market_name = "Brent Crude Oil", instrument_currency = "USD", account_currency = "GBP",
  direction = c("BUY", "SELL"), size = c(2, 1), lot_size = 1, order_type = c("MARKET", "LIMIT"), order_deal_id = c(NA, "W1"), deal_id = c("D9", NA), status = c("OPEN", "ORDER_WORKING"),
  entry_level = c(65, NA), stop_initial = c(64.5, 66.5), stop_level = c(64.5, 66.5), target_level = c(66, 65)))
act <- data.frame(date_utc = "2026-10-20T12:00:00", epic = "OIL_BRENT", deal_id = "D9", source = "SL", type = "POSITION", status = "DELETED", level = 64.5, size = 2, direction = "BUY", stringsAsFactors = FALSE)
tx <- data.frame(date_utc = "2026-10-20T12:00:30", instrument = "Brent Crude Oil", type = "TRADE", amount = -0.81, currency = "GBP", reference = "x", stringsAsFactors = FALSE)
pos <- data.frame(deal_id = "D10", deal_reference = "r", epic = "OIL_BRENT", name = "Brent Crude Oil", direction = "SELL", size = 1, level = 65.9, stop_level = 66.5, profit_level = 65,
                  upl = 0, currency = "USD", created_utc = "2026-10-20T13:00:00", bid = 65.8, offer = 65.84, contract_size = 1, lot_size = 1, guaranteed = FALSE, working_order_id = "W1", stringsAsFactors = FALSE)
rc <- cc_reconcile(tr, pos, data.frame(), act, tx, "GBP", function(ccy) 0.8)
u <- rc$updated
ok(u$status[u$trade_id == "T1"] == "CLOSED" && u$exit_level[u$trade_id == "T1"] == 64.5 && u$exit_code[u$trade_id == "T1"] == "S1", "a position gone from the platform is closed with its exit level and code")
ok(abs(u$pnl_account_est[u$trade_id == "T1"] - (-0.5 * 2 * 0.8)) < 1e-9 && u$pnl_account_booked[u$trade_id == "T1"] == -0.81, "P/L: the estimate in GBP and the amount Capital.com booked, side by side")
ok(u$status[u$trade_id == "T2"] == "OPEN" && u$entry_level[u$trade_id == "T2"] == 65.9, "a working order that filled becomes OPEN at the fill level")
ok(is.null(rc$new), "the filled order's position is not added again as a new trade")
ok(all(u$record_version == 2L), "changes are new versions (append-only)")
rc2 <- cc_reconcile(cc_coerce("trades", NULL), pos, data.frame(), data.frame(), data.frame(), "GBP")
ok(!is.null(rc2$new) && rc2$new$source == "PLATFORM", "a position opened on the platform is added (source PLATFORM)")

cat("Your case of 5 Nov: a stop order filled AND closed between two syncs (was marked expired)\n")
wo <- cc_coerce("trades", data.frame(trade_id = "CC_83be", record_version = 1L, source = "APP", epic = "OIL_BRENT", market_name = "Brent Oil Spot", instrument_currency = "USD", account_currency = "GBP",
  direction = "BUY", size = 3, lot_size = 1, order_type = "STOP", order_level = 93.593, order_deal_id = "00000000-WO-83be", status = "ORDER_WORKING",
  stop_initial = 92.895, stop_level = 92.895, target_level = 94.987, placed_ts = as.POSIXct("2026-11-05 04:15:32", tz = "UTC")))
# as Capital.com wrote them on 5 Nov
act5 <- data.frame(date_utc = c("2026-11-05T04:10:51.699", "2026-11-05T04:15:31.448", "2026-11-05T05:30:01.840", "2026-11-05T05:30:01.840", "2026-11-05T09:23:32.236", "2026-11-05T09:23:32.236"), epic = "OIL_BRENT",
  deal_id = c("WO-21ea", "00000000-WO-83be", "00000000-WO-83be", "POS-5NOV", "POS-5NOV", "WO-9b0f"), source = c("USER", "USER", "USER", "USER", "TP", "TP"),
  type = c("WORKING_ORDER", "WORKING_ORDER", "WORKING_ORDER", "POSITION", "POSITION", "WORKING_ORDER"), status = c("CREATED", "CREATED", "EXECUTED", "ACCEPTED", "ACCEPTED", "EXECUTED"),
  level = c(92.824, 93.593, 93.593, 93.598, 95.003, 94.987), size = 3, direction = c("SELL", "BUY", "BUY", "BUY", "SELL", "SELL"),
  json = c("{}", "{}", "{}", '{"details":{"workingOrderId":"00000000-WO-83be","level":93.598}}', '{"details":{"workingOrderId":"WO-9b0f","openPrice":93.598}}', "{}"), stringsAsFactors = FALSE)
tx5 <- data.frame(date_utc = "2026-11-05T09:23:33.100", instrument = "Brent Oil Spot", type = "TRADE", amount = 3.13, currency = "GBP", reference = "143577948857444", stringsAsFactors = FALSE)
r5 <- cc_reconcile(wo, data.frame(), data.frame(), act5, tx5, "GBP", function(ccy) 0.74228)
u5 <- r5$updated
ok(!is.null(u5) && u5$status == "CLOSED" && u5$entry_level == 93.598 && u5$deal_id == "POS-5NOV", "the vanished order is found filled at 93.598 (position POS-5NOV), not 'expired'")
ok(u5$exit_level == 95.003 && u5$exit_code == "T" && format(u5$exit_ts, "%H:%M", tz = "UTC") == "09:23" && u5$pnl_account_booked == 3.13, "and closed by the target (filled 95.003) at 09:23 with Capital.com's +3.13 booked")
ok(identical(format(cc_ts(act5$date_utc[c(1, 4)]), "%H:%M"), c("04:10", "05:30")), "times are read for every row (the bug: only the first row's time was read)")
ok(any(grepl("filled at 93.598", r5$messages)) && any(r5$events$event_type == "ORDER_FILLED") && any(r5$events$event_type == "POSITION_CLOSED"), "the sync says so and records the fill and the close")
wx <- wo; wx$status <- "EXPIRED"; wx$record_version <- 2L
r6 <- cc_reconcile(wx, data.frame(), data.frame(), act5, tx5, "GBP", function(ccy) 0.74228); u6 <- r6$updated
ok(!is.null(u6) && u6$status == "CLOSED" && u6$exit_level == 95.003 && u6$record_version == 3L && any(grepl("repaired", r6$messages)), "your record already marked EXPIRED is repaired to CLOSED (new version)")
a_noid <- act5; a_noid$json <- "{}"
u7 <- cc_reconcile(wo, data.frame(), data.frame(), a_noid, tx5, "GBP", function(ccy) 0.74228)$updated
ok(!is.null(u7) && u7$status == "CLOSED" && u7$entry_level == 93.598, "found also without ids: same market, side, size, after the order, near its level")
a_none <- act5[3, ]; a_none$type <- "POSITION"; a_none$size <- 5; u8 <- cc_reconcile(wo, data.frame(), data.frame(), a_none, data.frame(), "GBP")$updated
ok(is.null(u8) || u8$status != "CLOSED", "a different position (size 5) is not taken as the fill")
a_exp <- data.frame(date_utc = "2026-11-05T10:00:00", epic = "OIL_BRENT", deal_id = "00000000-WO-83be", source = "SYSTEM", type = "WORKING_ORDER", status = "EXPIRED", level = 93.593, size = 3, direction = "BUY", json = "{}", stringsAsFactors = FALSE)
u9 <- cc_reconcile(wo, data.frame(), data.frame(), a_exp, data.frame(), "GBP")$updated
ok(!is.null(u9) && u9$status == "EXPIRED", "an order that really expired is still marked expired")

cat("Your case of 2 Nov: order wrongly closed + PLATFORM copy, position still open\n")
mine <- cc_coerce("trades", data.frame(trade_id = c("CC_1421", "CC_4bac"), record_version = c(2L, 1L), source = c("APP", "PLATFORM"), epic = "OIL_BRENT", market_name = "Brent Oil Spot",
  instrument_currency = "USD", account_currency = "GBP", direction = "BUY", size = 11, lot_size = 1, order_type = "MARKET",
  order_deal_id = c("00000000-701d-5710-049c-2b98001c241e", NA), deal_id = c("00000000-701d-5710-049c-2b98001c241e", "POS-REAL-ID"),
  status = c("CLOSED", "OPEN"), entry_level = 109.756, stop_initial = 108.703, stop_level = 108.703, target_level = 110.495,
  entry_ts = as.POSIXct("2026-11-02 07:56:38", tz = "UTC"), setup_fund = c("my words", NA)))
posr <- data.frame(deal_id = "POS-REAL-ID", deal_reference = "o_33c7", epic = "OIL_BRENT", name = "Brent Oil Spot", direction = "BUY", size = 11, level = 109.756, stop_level = 108.703, profit_level = 110.495,
                   upl = -6.49, currency = "USD", created_utc = "2026-11-02T07:56:38", bid = 109.15, offer = 109.18, contract_size = 1, lot_size = 1, guaranteed = FALSE, working_order_id = NA, stringsAsFactors = FALSE)
actr <- data.frame(date_utc = "2026-11-02T07:56:38", epic = "OIL_BRENT", deal_id = "POS-REAL-ID", source = "USER", type = "POSITION", status = "ACCEPTED", level = 109.756, size = 11, direction = "BUY", stringsAsFactors = FALSE)
rr <- cc_reconcile(mine, posr, data.frame(), actr, data.frame(), "GBP", function(ccy) 0.744)
uu <- rr$updated
ok(uu$status[uu$trade_id == "CC_1421"] == "OPEN" && uu$deal_id[uu$trade_id == "CC_1421"] == "POS-REAL-ID" && is.na(uu$exit_level[uu$trade_id == "CC_1421"]), "your order is reopened on the position's real id, false exit cleared")
ok(uu$setup_fund[uu$trade_id == "CC_1421"] == "my words", "your own words stay with it")
ok(uu$status[uu$trade_id == "CC_4bac"] == "DUPLICATE", "the copy added by the earlier sync is marked DUPLICATE")
ok(is.null(rr$new), "no new trade is added")
st <- cc_make_store(cc_mem_backend()); st$write("trades", mine); st$write("trades", uu); cur <- st$current("trades")
rr2 <- cc_reconcile(cur, posr, data.frame(), actr, data.frame(), "GBP", function(ccy) 0.744)
ok(is.null(rr2$new) && (is.null(rr2$updated) || !any(rr2$updated$status %in% c("CLOSED", "OPEN") & rr2$updated$trade_id == "CC_4bac")), "a second sync changes nothing (no new copy, nothing closed)")
o1 <- cc_coerce("trades", data.frame(trade_id = "T9", record_version = 1L, source = "APP", epic = "OIL_BRENT", direction = "BUY", size = 1, lot_size = 1, deal_id = "CONF-ID", order_deal_id = "CONF-ID", status = "OPEN", entry_level = 109, stop_initial = 108, target_level = 110, entry_ts = as.POSIXct("2026-11-02 09:00", tz = "UTC")))
p9 <- posr; p9$deal_id <- "OTHER-ID"; p9$size <- 1; p9$level <- 109.0; p9$created_utc <- "2026-11-02T09:00:05"
r9 <- cc_reconcile(o1, p9, data.frame(), data.frame(), data.frame(), "GBP")
ok(r9$updated$deal_id == "OTHER-ID" && r9$updated$status == "OPEN" && is.null(r9$new), "a position listed under another id is matched (market, side, size, entry, time) and linked, not duplicated")
r10 <- cc_reconcile(o1, data.frame(), data.frame(), data.frame(), data.frame(), "GBP")
ok(is.null(r10$updated) && any(grepl("left OPEN", r10$messages)), "a trade missing from the positions with no close in the history stays OPEN")
a11 <- data.frame(date_utc = "2026-11-02T10:00:00", epic = "OIL_BRENT", deal_id = "CONF-ID", source = "SL", type = "POSITION", status = "DELETED", level = 108, size = 1, direction = "BUY", stringsAsFactors = FALSE)
r11 <- cc_reconcile(o1, data.frame(), data.frame(), a11, data.frame(), "GBP", function(c) 0.744)
ok(r11$updated$status == "CLOSED" && r11$updated$exit_level == 108 && r11$updated$exit_code == "S1", "a close in the history closes it, with exit level and code")
ok(cc_opened_deal_id(list(dealId = "CONF", affectedDeals = list(list(dealId = "POS", status = "OPENED")))) == "POS", "the position id is taken from the confirmation's affected deals")

cat("Your case after the stop was hit: real trade falsely closed at 0, copy closed at 108.596\n")
m2 <- cc_coerce("trades", data.frame(trade_id = c("CC_1421", "CC_4bac"), record_version = c(2L, 2L), source = c("APP", "PLATFORM"), epic = "OIL_BRENT", market_name = "Brent Oil Spot",
  instrument_currency = "USD", account_currency = "GBP", direction = "BUY", size = 11, lot_size = 1, order_type = "MARKET", strategy = c("PIVOT_BOUNCE", NA),
  order_deal_id = c("00000000-701d", NA), deal_id = c("00000000-701d", "POS-REAL-ID"), status = "CLOSED", entry_level = 109.756, stop_initial = 108.703, stop_level = 108.703, target_level = 110.495,
  entry_ts = as.POSIXct("2026-11-02 07:56:38", tz = "UTC"), exit_level = c(0, 108.596), exit_code = "S1", pnl_instrument = c(-1207.32, -12.76), pnl_account_est = c(-900.10, -9.51),
  pnl_account_booked = c(NA, -9.50), setup_fund = c("my words", NA)))
r12 <- cc_reconcile(m2, data.frame(), data.frame(), data.frame(), data.frame(), "GBP", function(c) 0.744); u12 <- r12$updated
ok(u12$exit_level[u12$trade_id == "CC_1421"] == 108.596 && u12$pnl_account_booked[u12$trade_id == "CC_1421"] == -9.50 && u12$status[u12$trade_id == "CC_1421"] == "CLOSED", "your real trade takes the real exit 108.596 and the booked -9.50")
ok(u12$setup_fund[u12$trade_id == "CC_1421"] == "my words" && u12$status[u12$trade_id == "CC_4bac"] == "DUPLICATE", "your words stay; the copy becomes DUPLICATE")
st12 <- cc_make_store(cc_mem_backend()); st12$write("trades", m2); st12$write("trades", u12); s12 <- cc_trade_stats(st12$current("trades"))
ok(s12$n == 1 && abs(s12$net - (-9.50)) < 1e-9 && abs(s12$avg_r - (-1.1016)) < 0.01, sprintf("statistics: 1 trade, net %.2f GBP, %.2f R (not -909.60)", s12$net, s12$avg_r))
a0 <- data.frame(date_utc = "2026-11-02T08:00:00", epic = "OIL_BRENT", deal_id = "X1", source = "USER", type = "POSITION", status = "DELETED", level = 0, size = 1, direction = "BUY", stringsAsFactors = FALSE)
o0 <- cc_coerce("trades", data.frame(trade_id = "T0", record_version = 1L, source = "APP", epic = "OIL_BRENT", direction = "BUY", size = 1, lot_size = 1, deal_id = "X1", status = "OPEN", entry_level = 109, stop_initial = 108, target_level = 110))
r0 <- cc_reconcile(o0, data.frame(), data.frame(), a0, data.frame(), "GBP", function(c) 0.744)
ok(is.na(r0$updated$exit_level) && !isTRUE(r0$updated$pnl_account_est < -50), "a price of 0 in the history is never taken as the exit")

cat("Store and tables\n")
s <- cc_make_store(cc_mem_backend()); s$write("trades", tr); s$write("trades", u)
cur <- s$current("trades"); ok(nrow(cur) == 2 && all(cur$record_version == 2L), "latest version per trade is current")
ok(length(cc_ddl("p", "d")) == 2 * length(cc_tables) + sum(vapply(cc_tables, function(t) length(t$added) > 0, TRUE)) && any(grepl("ADD COLUMN IF NOT EXISTS history_asked", cc_ddl("p", "d"))) && all(grepl("cc_", names(unlist(lapply(cc_tables, `[[`, "table"))) ) | TRUE), "DDL: a table and a _current view for each cc_ table, plus ALTER for columns added later ******")
ok(all(grepl("^cc_", vapply(cc_tables, `[[`, "", "table"))), "every table is prefixed cc_ (the IG tables are separate)")
off <- cc_make_store(list(connected = function() FALSE, ensure = function() NULL, write = function(...) stop("x"), read = function(...) stop("x")))
off$write("events", data.frame(event_id = "E1", event_type = "X")); ok(off$pending_count() == 1 && nrow(off$read("events")) == 1, "without BigQuery a record is kept in the session and queued")

cat(sprintf("\n%d passed, %d failed\n", pass, fail)); if (fail) quit(status = 1)

# ---- 2 Nov round 4: closes by hand (actions in details), saved history, exit repair, state line ----
js_close <- '{"dealId":"POS9","epic":"OIL_BRENT","type":"POSITION","status":"ACCEPTED","source":"USER","details":{"level":108.2,"actions":[{"actionType":"POSITION_CLOSED","affectedDealId":"POS9"}]}}'
act9 <- data.frame(date_utc = c("2026-11-02T10:00:05", "2026-11-02T14:40:00"), epic = "OIL_BRENT", deal_id = c("POS9", "POS9"), source = c("USER", "USER"),
                   type = c("POSITION", "POSITION"), status = c("ACCEPTED", "ACCEPTED"), level = c(109.0, 108.2), size = 1, direction = c("SELL", "SELL"),
                   stop_level = NA_real_, profit_level = NA_real_, currency = "USD",
                   json = c('{"details":{"actions":[{"actionType":"POSITION_OPENED","affectedDealId":"POS9"}]}}', js_close), stringsAsFactors = FALSE)
ok(identical(cc_is_close(act9), c(FALSE, TRUE)), "a close by hand (USER, action POSITION_CLOSED) is seen as a close; the opening row is not")
tr9 <- cc_coerce("trades", data.frame(trade_id = "CC_9", record_version = 1L, source = "APP", epic = "OIL_BRENT", market_name = "Brent", instrument_currency = "USD", account_currency = "GBP",
                 direction = "SELL", size = 1, lot_size = 1, deal_id = "CONF9", order_deal_id = "CONF9", status = "OPEN", entry_level = 109.0, stop_initial = 110, stop_level = 110, target_level = 107,
                 entry_ts = as.POSIXct("2026-11-02 10:00:00", tz = "UTC"), placed_ts = as.POSIXct("2026-11-02 10:00:00", tz = "UTC"), stringsAsFactors = FALSE))
tx9 <- data.frame(date_utc = "2026-11-02T14:40:01", instrument = "Brent", type = "TRADE", note = "", reference = "R9", amount = 0.61, currency = "GBP", status = "PROCESSED", stringsAsFactors = FALSE)
rc9 <- cc_reconcile(tr9, data.frame(), data.frame(), act9, tx9, "GBP", fx_fun = function(c) 0.76, now = as.POSIXct("2026-11-02 15:30:00", tz = "UTC"))
ok(nrow(rc9$updated) == 1 && rc9$updated$status == "CLOSED" && rc9$updated$exit_level == 108.2, "trade saved with the confirmation id is closed through the opening row's position id, closed by hand")
ok(isTRUE(all.equal(rc9$updated$pnl_account_booked, 0.61)), "booked amount found")
tr9b <- tr9; tr9b$status <- "CLOSED"; tr9b$exit_level <- 0; tr9b$pnl_account_booked <- NA
rc9b <- cc_reconcile(tr9b, data.frame(), data.frame(), act9, tx9, "GBP", fx_fun = function(c) 0.76)
ok(nrow(rc9b$updated) == 1 && rc9b$updated$exit_level == 108.2 && any(grepl("Repaired CC_9: closed at 108.2", rc9b$messages)), "a CLOSED trade with exit 0 is repaired from the history")
tr9c <- tr9b; tr9c$exit_level <- 108.2; tr9c$exit_ts <- as.POSIXct("2026-11-02 14:40:00", tz = "UTC")
rc9c <- cc_reconcile(tr9c, data.frame(), data.frame(), act9, tx9, "GBP")
ok(nrow(rc9c$updated) == 1 && isTRUE(all.equal(rc9c$updated$pnl_account_booked, 0.61)), "a closed trade without its booked amount gets it")
tr9c$pnl_account_booked <- 0.61; rc9d <- cc_reconcile(tr9c, data.frame(), data.frame(), act9, tx9, "GBP")
ok(is.null(rc9d$updated) && !length(rc9d$messages), "a complete closed trade: no change (no repeat writes)")
ok(grepl("0 open, 0 working order\\(s\\), 1 closed. Last closed: CC_9 SELL 1 Brent, exit 108.2, 0.61 GBP", cc_trades_state(tr9c)), "state line after sync")

cat("Your screen on 2 Nov: both copies CLOSED, the copy has no PLATFORM tag and different saved times\n")
m3 <- cc_coerce("trades", data.frame(trade_id = c("CC_20261102075638.336_1421", "CC_20261102075724.976_4bac"), record_version = c(2L, 2L), source = c("APP", NA), epic = "OIL_BRENT",
  market_name = "Brent Oil Spot", instrument_currency = "USD", account_currency = "GBP", direction = "BUY", size = 11, lot_size = 1, order_type = "MARKET",
  deal_id = c("00000000-701d", "POS-REAL-ID"), status = "CLOSED", entry_level = 109.756, stop_initial = 108.703, stop_level = 108.703, target_level = 110.495,
  entry_ts = as.POSIXct(c("2026-11-02 07:56:38", NA), tz = "UTC"), exit_level = c(0, 108.596), exit_ts = as.POSIXct(c("2026-11-02 07:56:40", "2026-11-02 08:34:00"), tz = "UTC"),
  exit_code = "S1", pnl_instrument = c(-1207.32, -12.76), pnl_account_est = c(-900.10, -9.50), pnl_account_booked = NA, setup_fund = c("my words", NA)))
r13 <- cc_reconcile(m3, data.frame(), data.frame(), data.frame(), data.frame(), "GBP", function(c) 0.744); u13 <- r13$updated
k13 <- u13[u13$trade_id == "CC_20261102075638.336_1421", ]
ok(nrow(k13) == 1 && k13$exit_level == 108.596 && k13$status == "CLOSED" && k13$setup_fund == "my words", "your order keeps your words and takes the real exit 108.596")
ok(u13$status[u13$trade_id == "CC_20261102075724.976_4bac"] == "DUPLICATE", "the copy becomes DUPLICATE")
st13 <- cc_make_store(cc_mem_backend()); st13$write("trades", m3); st13$write("trades", u13); s13 <- cc_trade_stats(st13$current("trades"))
ok(s13$n == 1 && abs(s13$net - (-9.50)) < 1e-9, sprintf("statistics: 1 trade, %.2f GBP", s13$net))
r14 <- cc_reconcile(st13$current("trades"), data.frame(), data.frame(), data.frame(), data.frame(), "GBP", function(c) 0.744)
ok(is.null(r14$updated) && !length(r14$messages), "the next sync changes nothing")
ok(identical(format(cc_id_time("CC_20261102075638.336_1421"), "%H:%M:%S"), "07:56:38"), "time read from the trade id")
