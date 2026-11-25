# Run: Rscript tests/test_cc_markets.R   (every Capital.com asset class on the Trading Desk, 22 Nov 2026)
`%||%` <- function(x, y) if (is.null(x)) y else x
for (f in c("R/utils_trading_records.R", "R/utils_trading_exports.R", "R/utils_trading_templates.R", "R/utils_trading_calendar.R", "R/utils_trading_pipeline.R", "R/utils_calendar_sources.R",
            "R/utils_cc_catalog.R", "R/utils_cc_api.R", "R/utils_cc_patterns.R", "R/utils_cc_chart.R", "R/utils_cc_records.R", "R/utils_cc_markets.R", "R/utils_cc_advice.R", "R/utils_ml.R", "R/utils_cc_plan.R")) source(f)
pass <- 0; fail <- 0; ok <- function(c, m) { if (isTRUE(c)) { pass <<- pass + 1; cat("  ok  ", m, "\n") } else { fail <<- fail + 1; cat("  FAIL", m, "\n") } }

# ---- 1. every asset class, from Capital.com's instrument type, epic and name ----
mk <- list(
  list("OIL_BRENT", "Brent Crude", "COMMODITIES", "USD", "energy", "Brent crude oil", "BZ=F"), list("OIL_CRUDE", "US Crude Oil", "COMMODITIES", "USD", "energy", "WTI crude oil", "CL=F"),
  list("NATURALGAS", "Natural Gas", "COMMODITIES", "USD", "energy", "Natural gas", "NG=F"), list("GOLD", "Gold", "COMMODITIES", "USD", "metals", "Gold", "GC=F"),
  list("COPPER", "Copper", "COMMODITIES", "USD", "metals", "Industrial metals", "HG=F"), list("COFFEEARABICA", "Coffee Arabica", "COMMODITIES", "USD", "agri", "Softs", "KC=F"),
  list("WHEAT", "Wheat", "COMMODITIES", "USD", "agri", "Grains and livestock", "ZW=F"), list("EURUSD", "EUR/USD", "CURRENCIES", "USD", "forex", "FX major", "EURUSD=X"),
  list("USDJPY", "USD/JPY", "CURRENCIES", "JPY", "forex", "FX major", "JPY=X"), list("EURGBP", "EUR/GBP", "CURRENCIES", "GBP", "forex", "FX cross", "EURGBP=X"),
  list("USDTRY", "USD/TRY", "CURRENCIES", "TRY", "forex", "FX exotic", "TRY=X"), list("US500", "US 500", "INDICES", "USD", "index", "US index", "^GSPC"),
  list("UK100", "UK 100", "INDICES", "GBP", "index", "UK index", "^FTSE"), list("DE40", "Germany 40", "INDICES", "EUR", "index", "German index", "^GDAXI"),
  list("J225", "Japan 225", "INDICES", "JPY", "index", "Japanese index", "^N225"), list("HK50", "Hong Kong 50", "INDICES", "HKD", "index", "Chinese / Hong Kong index", "^HSI"),
  list("AAPL", "Apple Inc", "SHARES", "USD", "share", "Single share", "AAPL"), list("BARC", "Barclays", "SHARES", "GBP", "share", "Single share", "BARC.L"),
  list("SAP", "SAP SE", "SHARES", "EUR", "share", "Single share", NA), list("BTCUSD", "Bitcoin/USD", "CRYPTOCURRENCIES", "USD", "crypto", "Crypto", "BTC-USD"),
  list("ETHUSD", "Ethereum/USD", "CURRENCIES", "USD", "crypto", "Crypto", "ETH-USD"), list("SPY", "SPDR S&P 500 ETF Trust", "SHARES", "USD", "etf", "Exchange-traded fund", "SPY"))
bad <- character(0)
for (x in mk) { p <- cc_market_profile(x[[1]], x[[2]], x[[3]], x[[4]])
  if (!identical(p$class, x[[5]]) || !identical(p$sub, x[[6]]) || !identical(as.character(p$yahoo), as.character(x[[7]])) || length(p$drivers) < 3 || !nzchar(p$hours) || !nzchar(p$group)) bad <- c(bad, sprintf("%s (%s/%s/%s)", x[[1]], p$class, p$sub, p$yahoo)) }
ok(!length(bad), sprintf("%d markets in 10 asset classes: class, type, Yahoo symbol, drivers, sessions and group right%s", length(mk), if (length(bad)) paste(":", paste(bad, collapse = "; ")) else ""))
ok(cc_class_of(NA, "EURUSD") == "forex" && cc_class_of(NA, "BTCUSD") == "crypto" && cc_class_of(NA, "US100", "US Tech 100") == "index" && cc_class_of("RATES", "BUND") == "bond", "class found without Capital.com's type too")
p <- cc_market_profile("EURJPY", "EUR/JPY", "CURRENCIES", "JPY")
ok(all(c("EUR", "JPY", "Euro Area", "Japan") %in% p$cal_countries) && any(grepl("European Central Bank", p$drivers)) && any(grepl("Bank of Japan", p$drivers)), "a forex pair: both currencies, their central banks and calendar countries")
s <- cc_market_profile("AAPL", "Apple Inc", "SHARES", "USD"); ok(any(grepl("earnings", s$drivers)) && all(c("US500", "US100") %in% s$related) && grepl("14:30", s$hours), "a share: earnings, its index, US cash hours")
cr <- cc_market_profile("BTCUSD", "Bitcoin/USD", "CRYPTOCURRENCIES", "USD"); ok(grepl("7 days", cr$hours) && any(grepl("ETF", cr$drivers)), "crypto: 24/7 and its own drivers")

# ---- 2. news and the economic calendar per market ----
ct <- c("United States", "Japan", "Euro Area", "United Kingdom", "")
ev <- c("CPI y/y", "BoJ Policy Rate", "ECB Main Refinancing Rate", "CPI y/y", "EIA Crude Oil Inventories")
ok(identical(cc_news_relevant(ct, ev, cc_market_profile("OIL_BRENT", "Brent", "COMMODITIES", "USD")), c(TRUE, FALSE, FALSE, FALSE, TRUE)), "Brent: US data and EIA matter, Japanese / euro / UK data do not")
ok(identical(cc_news_relevant(ct, ev, p), c(FALSE, TRUE, TRUE, FALSE, FALSE)), "EUR/JPY: the BoJ and the ECB matter, US and UK data do not")
ok(identical(cc_news_relevant(ct, ev, cc_market_profile("UK100", "UK 100", "INDICES", "GBP")), c(FALSE, FALSE, FALSE, TRUE, FALSE)), "UK 100: UK data matter")
em <- cc_event_markets(ct, ev, list(cc_market_profile("OIL_BRENT", "Brent", "COMMODITIES", "USD"), p)); ok(em[1] == "Brent" && em[2] == "EUR/JPY" && em[5] == "Brent", "each release names the markets of mine it moves")
np <- tr_news_prompt(as.Date("2026-11-23"), "markets", "Brent (OPEC+...); Apple Inc (earnings)"); ok(grepl("5 most important", np) && grepl("at least one story per market", np) && grepl("Apple Inc", np), "news: one prompt for all my markets, 5 stories")
ok(length(tr_news_items(replicate(7, list(headline = "h", url = "https://x.com/a"), simplify = FALSE))) == 5, "up to 5 stories kept")
ex <- cc_exposure_note(cc_watch_profiles(c("OIL_BRENT", "OIL_CRUDE", "GOLD", "EURUSD")))
ok(grepl("OIL_BRENT, OIL_CRUDE \\(Energy", ex) && grepl("Groups on the watchlist", ex), "exposure note: markets of the same group counted together")
pp <- cc_profile_prompt(s, list(text = "OPEN now")); ok(grepl("MARKET PROFILE \\(Share", pp) && grepl("earnings", pp) && grepl("OPEN now", pp) && grepl("do not borrow facts", pp), "the Claude API gets the market's profile")

# ---- 3. opening hours, market closed, deal sizes ----
oh <- list(mon = list("00:00 - 21:59", "23:05 - 00:00"), tue = list("00:00 - 21:59"), wed = list("00:00 - 21:59"), thu = list("00:00 - 21:59"), fri = list("00:00 - 21:00"), sat = list(), sun = list("23:05 - 00:00"), zone = "UTC")
h <- cc_hours_parse(oh)
ok(isTRUE(cc_hours_open(h, as.POSIXct("2026-11-23 10:00", tz = "UTC"))) && isFALSE(cc_hours_open(h, as.POSIXct("2026-11-21 12:00", tz = "UTC"))) && isTRUE(cc_hours_open(h, as.POSIXct("2026-11-22 23:30", tz = "UTC"))) &&
   isFALSE(cc_hours_open(h, as.POSIXct("2026-11-23 22:30", tz = "UTC"))), "opening hours: open on Monday, closed on Saturday, open Sunday 23:30, closed in the daily break")
f <- list(name = "Brent", status = NA, hours = h)
ok(length(cc_market_closed(f, as.POSIXct("2026-11-21 12:00", tz = "UTC"))) == 1 && !length(cc_market_closed(modifyList(f, list(status = "TRADEABLE")), as.POSIXct("2026-11-21 12:00", tz = "UTC"))) &&
   grepl("not tradeable", cc_market_closed(list(name = "AAPL", status = "CLOSED"))), "a deal on a closed market is stopped before sending")
h24 <- cc_hours_parse(list(mon = list("00:00 - 00:00"), tue = list("00:00 - 00:00"), wed = list("00:00 - 00:00"), thu = list("00:00 - 00:00"), fri = list("00:00 - 00:00"), sat = list("00:00 - 00:00"), sun = list("00:00 - 00:00"), zone = "UTC"))
ok(isTRUE(cc_hours_open(h24, as.POSIXct("2026-11-21 12:00", tz = "UTC"))) && grepl("every day", cc_hours_text(h24)$text), "crypto: open every day")
ok(identical(cc_size_problems(0.5, 1, 100, 1)[1], "Size 0.5 is below this market's minimum 1.") && grepl("multiple of 0.01", cc_size_problems(0.015, 0.01, NA, 0.01)) && !length(cc_size_problems(2, 1, 100, 1)) &&
   grepl("maximum", cc_size_problems(500, 1, 100, 1)) && cc_size_fix(0.157, 0.1, 0.1) == 0.1 && cc_size_fix(0.05, 0.1, 0.01) == 0.1, "deal size: minimum, step and maximum of the market")
mf <- cc_market_facts(list(instrument = list(epic = "AAPL", name = "Apple Inc", type = "SHARES", currency = "USD", lotSize = 1, openingHours = oh, guaranteedStopAllowed = TRUE),
  dealingRules = list(minDealSize = list(value = 1), maxDealSize = list(value = 1000), minSizeIncrement = list(value = 1), minStopOrProfitDistance = list(value = 0.1)),
  snapshot = list(bid = 190.1, offer = 190.3, marketStatus = "TRADEABLE", decimalPlacesFactor = 2)))
ok(mf$size_step == 1 && mf$max_size == 1000 && nrow(mf$hours$slots) == 7 && isTRUE(mf$guaranteed_stop), "market details: size step, maximum, opening hours read from Capital.com")

# ---- 4. Capital.com's market tree and the watchlist ----
top <- list(nodes = list(list(id = "hierarchy_v1.commodities", name = "Commodities"), list(id = "hierarchy_v1.shares", name = "Shares"), list(id = "hierarchy_v1.crypto", name = "Cryptocurrencies")))
leaf <- list(markets = list(list(epic = "AAPL", instrumentName = "Apple Inc", instrumentType = "SHARES", bid = 190.1, offer = 190.3, marketStatus = "TRADEABLE"),
                            list(epic = "TSLA", instrumentName = "Tesla Inc", instrumentType = "SHARES", bid = 250, offer = 250.4, marketStatus = "CLOSED")))
nd <- cc_nav_nodes(top); m <- cc_nav_markets(leaf); ch <- cc_market_choices(m)
ok(nrow(nd) == 3 && nd$name[3] == "Cryptocurrencies" && nrow(m) == 2 && unname(ch[1]) == "AAPL" && grepl("Apple Inc  \\[AAPL, SHARES\\]", names(ch)[1]), "market tree: asset classes, groups and markets read")
calls <- character(0); http <- function(method, url, headers = list(), body = NULL, timeout = 30) { calls <<- c(calls, url)
  b <- if (grepl("/session$", url)) "{}" else if (grepl("marketnavigation/", url)) jsonlite::toJSON(leaf, auto_unbox = TRUE) else if (grepl("marketnavigation", url)) jsonlite::toJSON(top, auto_unbox = TRUE) else "{}"
  list(status = 200, body = as.character(b), headers = list(cst = "c", `x-security-token` = "x")) }
cl <- cc_new_client(http_fn = http, sleep_fn = function(s) NULL); cl$set_credentials(list(api_key = "k", identifier = "i", api_password = "p", environment = "demo"))
r1 <- tryCatch(cc_nav_nodes(cl$navigation()), error = function(e) NULL); r2 <- tryCatch(cc_nav_markets(cl$navigation_node("hierarchy_v1.shares")), error = function(e) NULL)
ok(!is.null(r1) && nrow(r1) == 3 && !is.null(r2) && nrow(r2) == 2 && any(grepl("/marketnavigation/hierarchy_v1.shares\\?limit=500", calls)), "client: GET /marketnavigation and /marketnavigation/{node}?limit=500")
cc_watch_set("aapl, btcusd; OIL_BRENT", info = list(AAPL = list(epic = "AAPL", name = "Apple Inc", type = "SHARES", currency = "USD"), BTCUSD = list(epic = "BTCUSD", name = "Bitcoin/USD", type = "CRYPTOCURRENCIES", currency = "USD")))
ok(identical(cc_watch_get(), c("AAPL", "BTCUSD", "OIL_BRENT")) && cc_watch$v > 0, "watchlist: typed epics cleaned, any asset class")
codes <- cc_register_watch()
ok(identical(unname(codes), c("AAPL", "BTCUSD", "BRENT")) && tr_asset_label("AAPL") == "Apple Inc" && tr_asset_class("BTCUSD") == "Crypto" && tr_yahoo_sym("BTCUSD") == "BTC-USD" && tr_yahoo_sym("AAPL") == "AAPL" &&
   tr_asset_label("BRENT") == "Brent Crude", "watchlist markets become Morning Sheet markets (label, class, Yahoo symbol); Brent keeps its own row")
ok(cc_code_epic("AAPL") == "AAPL" && cc_code_epic("BRENT") == "OIL_BRENT" && cc_code_epic("WTI") == "OIL_CRUDE" && cc_epic_code("US500") == "SP500", "app codes and Capital.com epics both ways")
ch2 <- tr_asset_choices(); ok("Your Capital.com markets" %in% names(ch2) && "AAPL" %in% ch2[["Your Capital.com markets"]], "asset pickers list my markets first")

# ---- 5. Morning Sheet levels for any market ----
mkbars <- function(lo, hi, from = as.POSIXct("2026-11-17 00:00", tz = "UTC")) { tm <- from + (0:(24 * 7)) * 3600; n <- length(tm); c0 <- seq(lo, hi, length.out = n)
  data.frame(time = tm, open = c0, high = c0 + 0.002 * hi, low = c0 - 0.002 * hi, close = c0) }
d <- as.Date("2026-11-23"); now <- as.POSIXct("2026-11-23 07:10", tz = "Europe/London")
cy <- cc_morning_levels(NULL, c("SAP", "OIL_BRENT"), d, now = now, codes = c("SAP", "BRENT"), fetch = function(e) if (e == "SAP") mkbars(180, 190, as.POSIXct("2026-11-17", tz = "UTC")) else mkbars(60, 62, as.POSIXct("2026-11-17", tz = "UTC")))
ok(!is.null(cy$rows) && nrow(cy$rows) == 2 && cy$rows$cur[1] > 180 && cy$rows$cur[1] < 195 && cy$rows$cur[2] > 6000 && is.finite(cy$rows$adx[1]) && is.finite(cy$rows$prior_high[1]) && grepl("Capital.com SAP", cy$rows$source[1]),
   "Capital.com candles: overnight low / high / price, previous session and ADX for a share; Brent in IG points")
yf <- function(sym, range, interval) { if (sym == "AAPL") list(bars = mkbars(185, 190, as.POSIXct("2026-11-17", tz = "UTC")), tz = "UTC") else if (interval == "1d") list(bars = data.frame(time = as.POSIXct("2026-11-20", tz = "UTC") + 0:2 * 86400, open = 1, high = 1, low = 1, close = 1)) else stop("no data") }
cc_watch$info$SAP <- list(epic = "SAP", name = "SAP SE", type = "SHARES", currency = "EUR"); cc_register_watch(c("SAP"))
ys <- cc_ms_levels(c("AAPL", "SAP"), d, yahoo_fetch = yf, now = now, cc_fetch = function(e) mkbars(180, 190, as.POSIXct("2026-11-17", tz = "UTC")))
ok(!is.null(ys$rows) && setequal(ys$rows$code, c("AAPL", "SAP")) && grepl("Yahoo", ys$rows$source[ys$rows$code == "AAPL"]) && grepl("Capital.com", ys$rows$source[ys$rows$code == "SAP"]) && any(grepl("Capital.com candles used for SAP", ys$problems)),
   "Yahoo where it has the market, Capital.com candles for the rest (SAP has no Yahoo symbol)")
y0 <- cc_ms_levels(c("SAP"), d, yahoo_fetch = yf, now = now, client = NULL); ok(is.null(y0$rows) && any(grepl("connect Capital.com", y0$problems)), "without Capital.com the sheet says which markets have no price source")
hdr <- data.frame(sheet_id = "MS_2026-11-23", dow_price = NA, dow_change_pct = NA, dow_change_pts = NA, nikkei_price = NA, nikkei_change_pct = NA, nikkei_change_pts = NA, stringsAsFactors = FALSE)
fl <- tr_morning_fill(hdr, NULL, ys, "MS_2026-11-23", d)
ok(all(c("AAPL", "SAP") %in% fl$lv$instrument) && is.finite(fl$lv$overnight_low[fl$lv$instrument == "SAP"]) && any(grepl("SAP SE low", fl$filled)), "the Morning Sheet gets a row for every market read (watchlist markets too)")
rw <- tr_morning_rows(fl$lv); ok(any(rw$cm$Overnight == "SAP SE") && any(rw$cm$Overnight == "Apple Inc"), "the Word sheet lists them by name")
ra <- tr_ms_regime_auto(transform(fl$lv, adx14 = c(35, 15)[seq_len(nrow(fl$lv))]), c(30, 20), markets = c("AAPL", "SAP")); ok(grepl("Apple Inc", ra$regime) && grepl("SAP SE", ra$regime), "regime read for my markets")

# ---- 6. weekly review by asset class ----
tr <- data.frame(trade_id = c("a", "b", "c"), status = "CLOSED", direction = c("BUY", "SELL", "BUY"), epic = c("OIL_BRENT", "AAPL", "BTCUSD"), market_name = c("Brent Crude", "Apple Inc", "Bitcoin/USD"),
                 entry_ts = as.POSIXct("2026-11-23 10:00", tz = "UTC") + 0:2 * 3600, entry_level = c(60, 190, 90000), stop_initial = c(59, 192, 89000), exit_level = c(62, 186, 89000), target_level = c(62, 186, 92000),
                 strategy = "PATTERN", stringsAsFactors = FALSE)
w <- cc_week_review(tr, as.Date("2026-11-23"), as.Date("2026-11-27"))
ok(!is.null(w$by_class) && setequal(w$by_class$`Asset class`, c("Commodity: energy", "Share", "Crypto")) && w$by_class$`Total R`[w$by_class$`Asset class` == "Crypto"] == -1, "weekly review: results by asset class")
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); if (fail) quit(status = 1)
