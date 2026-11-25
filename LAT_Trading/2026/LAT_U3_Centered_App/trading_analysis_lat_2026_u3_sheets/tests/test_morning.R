# Run: Rscript tests/test_morning.R   (Morning Sheet data, 21 Nov 2026 fixes)
`%||%` <- function(x, y) if (is.null(x)) y else x
for (f in c("R/utils_trading_records.R", "R/utils_trading_exports.R", "R/utils_trading_templates.R", "R/utils_trading_calendar.R", "R/utils_trading_pipeline.R", "R/utils_calendar_sources.R")) source(f)
pass <- 0; fail <- 0; ok <- function(c, m) { if (isTRUE(c)) { pass <<- pass + 1; cat("  ok  ", m, "\n") } else { fail <<- fail + 1; cat("  FAIL", m, "\n") } }
# hourly bars around the overnight window of 16/11/2026, prices in dollars (as Yahoo gives them)
mk <- function(lo, hi, cur) { tm <- as.POSIXct("2026-11-13 00:00", tz = "UTC") + (0:(24 * 4)) * 3600; n <- length(tm); c0 <- seq(lo + 0.3 * (hi - lo), cur, length.out = n)
  list(bars = data.frame(time = tm, open = c0, high = pmin(hi, c0 + 0.1 * (hi - lo)), low = pmax(lo, c0 - 0.1 * (hi - lo)), close = c0), tz = "UTC") }
fx <- list("BZ=F" = mk(93.9, 95.4, 94.86), "CL=F" = mk(88.0, 89.47, 89.11), "NG=F" = mk(4.40, 4.60, 4.512), "EURUSD=X" = mk(1.1018, 1.1034, 1.1025), "GC=F" = mk(3835, 3904, 3856))
fetch <- function(sym, range, interval) { if (sym %in% names(fx)) fx[[sym]] else stop("no data for ", sym) }
now <- as.POSIXct("2026-11-16 07:16", tz = "Europe/London")
y <- tr_yahoo_morning(c("BRENT", "WTI", "NATGAS", "EURUSD"), as.Date("2026-11-16"), now = now, ref = c(BRENT = 94.86), fetch = fetch)
b <- y$rows[y$rows$code == "BRENT", ]
ok(b$low > 9300 && b$high < 9600 && b$low <= b$cur && b$cur <= b$high && abs(b$cur - 9486) < 1, sprintf("Brent with a typed price in dollars: low %s high %s price %s, all in IG points (was -34.1 / 140.9)", b$low, b$high, b$cur))
w <- y$rows[y$rows$code == "WTI", ]; g <- y$rows[y$rows$code == "NATGAS", ]; e <- y$rows[y$rows$code == "EURUSD", ]
ok(abs(w$cur - 8911) < 20 && w$cur == round(w$cur) && abs(g$cur - 4512) < 15 && g$cur == round(g$cur) && abs(e$cur - 1.1025) < 1e-4, "WTI x100, natural gas x1000 (IG points), EUR/USD unchanged")
y2 <- tr_yahoo_morning("BRENT", as.Date("2026-11-16"), now = now, ref = c(BRENT = 9486), fetch = fetch); ok(abs(y2$rows$cur - 9486) < 1, "a typed price already in IG points gives the same row")
y3 <- tr_yahoo_morning("BRENT", as.Date("2026-11-16"), now = now, ref = c(BRENT = 120), fetch = fetch); ok(abs(y3$rows$cur - 9486) < 15 && any(grepl("more than 3%", y3$problems)), "a wrong typed price is not used, with a note")
ok("NATGAS" %in% tr_morning_codes && tr_asset_label("NATGAS") != "NATGAS", sprintf("natural gas is a Morning Sheet row (%s)", tr_asset_label("NATGAS")))
# refresh: values already on the sheet are replaced by fresh ones
hdr <- data.frame(sheet_id = "MS_2026-11-16", dow_price = 1, dow_change_pct = 0.1, dow_change_pts = NA, nikkei_price = 2, nikkei_change_pct = -2.4, nikkei_change_pts = NA, stringsAsFactors = FALSE)
lv0 <- data.frame(level_id = "x", sheet_id = "MS_2026-11-16", sheet_date = as.Date("2026-11-16"), instrument = "BRENT", overnight_low = -34.1, overnight_high = 140.9, current_price = 94.86, time_now_uk = "01:20", stringsAsFactors = FALSE)
f1 <- tr_morning_fill(hdr, lv0, y, "MS_2026-11-16", as.Date("2026-11-16")); f2 <- tr_morning_fill(hdr, lv0, y, "MS_2026-11-16", as.Date("2026-11-16"), refresh = TRUE)
ok(f1$lv$overnight_low[f1$lv$instrument == "BRENT"] == -34.1 && f2$lv$overnight_low[f2$lv$instrument == "BRENT"] > 9300 && f2$lv$time_now_uk[f2$lv$instrument == "BRENT"] != "01:20" && "NATGAS" %in% f2$lv$instrument, "one click replaces old values and times; the old fill only filled empty cells")
# calendar: yesterday's list carried with its results; impact; units; implausible actuals
prev <- data.frame(time = c("10:00", "13:30", "13:30"), country = c("Euro Area", "United States", "Canada"), importance = c("Medium", "Medium", "High"), event = c("Industrial Production m/m", "Empire State Manufacturing Index", "CPI m/m"),
                   actual = c("", "", "0.2%"), forecast = c("0.3%", "17.6", "0.3%"), previous = c("-0.5%", "25.5", "0.1%"), stringsAsFactors = FALSE)
over <- data.frame(time = c("13:30", "17:00"), country = c("Canada", "United States"), importance = c("High", "High"), event = c("CPI m/m", "Fed Chairman Warsh Speaks"), actual = c("", ""), forecast = c("0.3%", ""), previous = c("0.1%", ""), stringsAsFactors = FALSE)
cr <- tr_cal_carry(prev, over); ok(nrow(cr) == 4 && all(c("Industrial Production m/m", "Empire State Manufacturing Index") %in% cr$event) && cr$actual[cr$event == "CPI m/m"] == "0.2%" && identical(cr$time, c("10:00", "13:30", "13:30", "17:00")),
  "overnight list keeps every event of yesterday's list, with the result already known, in time order (17/11 lost two events)")
cal <- data.frame(time = c("07:00", "07:00", "07:00", "15:30", "15:30", "21:30", "13:30"), country = "x", importance = c("High", "Medium", "Medium", "Low", "Low", "Low", "Medium"),
  event = c("CPI y/y", "PPI Output m/m", "Unemployment Rate", "Crude Oil Inventories", "Natural Gas Storage (oil)", "API Weekly Statistical Bulletin (oil)", "Unemployment Claims"),
  actual = c("0.5", "10.8", "4.6", "", "", "", "201K"), forecast = c("3.6%", "0.6%", "4.7%", "0.4M", "25B", "", "198K"), previous = c("3.5%", "0.8%", "4.7%", "4.7M", "61B", "", "200K"), stringsAsFactors = FALSE)
cf <- tr_cal_fix(cal)
ok(cf$actual[1] == "0.5% (check)" && cf$actual[2] == "10.8% (check)" && cf$actual[3] == "4.6%" && cf$actual[7] == "201K", "actuals get their % unit; ones far from the forecast are marked '(check)' (18/11: UK CPI 0.5 against 3.6%)")
ok(all(cf$importance[4:5] == "High") && cf$importance[6] == "Medium" && cf$event[5] == "Natural Gas Storage (energy)", "EIA crude and gas reports rated High, API Medium; gas no longer tagged '(oil)'")
# news: short, reputable, no repeats; own words kept
it <- list(list(headline = "Fed minutes show more hikes likely", context = paste(rep("long context", 30), collapse = " "), source = "CNBC", url = "https://cnbc.com/a"),
           list(headline = "Fed minutes show more hikes likely", context = "repeat", source = "Reuters", url = "https://reuters.com/b"),
           list(headline = "EIA: crude stocks up 3.4m", context = "to 417.8m barrels", source = "EIA", url = "https://eia.gov"))
it[[2]]$source <- "x.com"; it[[2]]$url <- "https://x.com/c"; it[[2]]$headline <- "Oil falls"; it <- c(it, list(list(headline = "Fed minutes show more hikes likely", context = "again", source = "Reuters", url = "https://reuters.com/b")))
nl <- tr_news_lines_short(it); ok(length(nl) == 2 && all(nchar(nl) < 200) && !any(grepl("x.com", nl)) && grepl("\\(CNBC\\)$", nl[1]), "news: short lines, repeats and weak sources (x.com, substack...) removed")
ok(tr_news_own_part("My view: oil weak.\nFound online (unverified), 18/11/2026:\n- a\nFound online (unverified), top news on markets:\n- b") == "My view: oil weak." && tr_news_own_part("Note: levels and headlines found online, not read from IG.") == "", "the app's earlier news blocks are replaced, the student's own lines kept")
# regime from ADX
lv <- data.frame(instrument = c("BRENT", "WTI", "NATGAS", "EURUSD", "GOLD"), adx14 = c(25.4, 33.1, 18, NA, 40), stringsAsFactors = FALSE)
ra <- tr_ms_regime_auto(lv, c(30, 20)); ok(grepl("Brent.*25.4: unclear", ra$regime) && grepl("Holy Grail", ra$setups) && grepl("Pivot Point Bounce", ra$setups) && !ra$stand && !grepl("Gold", ra$regime), "regime and planned set-ups from the ADX of the plan's markets")
ok(tr_ms_regime_auto(data.frame(instrument = "BRENT", adx14 = 25, stringsAsFactors = FALSE))$stand, "every market unclear = stand aside, with the reason")
# the template's Name label is wide enough
x <- paste(readLines(utils::unzip("www/templates/Morning_Sheet_Template.docx", "word/document.xml", exdir = tempfile()), warn = FALSE), collapse = ""); t1 <- regmatches(x, regexpr("<w:tbl>.*?</w:tbl>", x, perl = TRUE))
ok(grepl('<w:gridCol w:w="1300"/>', t1) && !grepl('w:w="846"', t1), "Name label column widened so 'Name:' stays on one line")
# ******************** one click, inside the module: prices, calendar, news, regime, BigQuery first, then the PDF in Dropbox
suppressMessages({ library(shiny); for (f in c("R/utils_data.R", "R/utils_trading_decision.R", "R/utils_local_creds.R", "R/utils_trade_scenarios.R", "R/utils_patterns.R")) try(source(f), silent = TRUE); source("modules/trading_records.R") })
fx[["^DJI"]] <- { b <- mk(52000, 52400, 52347.55); b$bars <- b$bars[1:25, ]; b$bars$time <- as.POSIXct("2026-10-20 21:00", tz = "UTC") + (0:24) * 86400; b }; fx[["^N225"]] <- fx[["^DJI"]]
fx[["JPY=X"]] <- mk(159.5, 160.1, 159.667); fx[["GBPUSD=X"]] <- mk(1.32, 1.3226, 1.3214); fx[["AUDUSD=X"]] <- mk(0.6766, 0.6795, 0.6778)
dbx <- tempfile("dbx"); dir.create(dbx); Sys.setenv(LAT_DROPBOX_ROOT = dbx, TR_RUNTIME = "local")
web <- function(p) { if (grepl("ACTUAL released values", p)) return(list(text = '{"events":[{"time":"13:30","event":"CPI m/m","actual":"0.2%"}]}'))
  if (grepl("news", p, ignore.case = TRUE) && !grepl("calendar", p, ignore.case = TRUE)) return(list(text = '{"news":[{"headline":"Brent falls 1% on supply surplus","context":"recovering Hormuz shipments","source":"Reuters","time":"06:10","url":"https://reuters.com/x"},{"headline":"Dollar firm","context":"hawkish Fed","source":"x.com","url":"https://x.com/y"}]}'))
  list(text = '{"events":[{"time":"13:30","country":"Canada","importance":"High","event":"CPI m/m","actual":"","forecast":"0.3%","previous":"0.1%"},{"time":"15:30","country":"United States","importance":"Low","event":"Crude Oil Inventories","actual":"","forecast":"0.4M","previous":"4.7M"}]}') }
st <- tr_make_store(tr_bq_backend(NULL))
st$write("morning_sheets", data.frame(sheet_id = "MS_2026-11-13", record_version = 1L, sheet_date = as.Date("2026-11-13"), todays_releases = tr_calendar_text(prev), stringsAsFactors = FALSE))
testServer(trading_records_server, args = list(store = st, quiet = TRUE, text_fn = web, yahoo_fn = fetch, http_fn = function(u) stop("offline")), {
  session$setInputs(ms_date = as.Date("2026-11-16"), s_name = "Jose F Zubizarreta (D1005749)", ms_news = "My view: oil heavy.\nFound online (unverified), 15/11/2026:\n- old line", ms_cal_src = "all", ml7_inst = "BRENT", ml7_cur = 94.86)
  session$setInputs(ms_oneclick = 1); session$flushReact()
  h <- tr_read_current(st, "morning_sheets"); h <- h[h$sheet_id == "MS_2026-11-16", ]; l <- tr_read_current(st, "morning_levels"); l <- l[l$sheet_id == "MS_2026-11-16", ]
  ok(nrow(h) == 1 && nrow(l) >= 7, sprintf("saved to BigQuery: the sheet and %d level rows", nrow(l)))
  ok(all(is.finite(l$overnight_low) & is.finite(l$overnight_high) & is.finite(l$current_price) & nzchar(l$time_now_uk)) && all(c("BRENT", "NATGAS", "WTI") %in% l$instrument) && l$current_price[l$instrument == "BRENT"] > 9000,
     "every price row filled, oil and gas in IG points")
  ok(is.finite(h$dow_change_pts) && is.finite(h$nikkei_change_pts), "Dow and Nikkei with points and %")
  flds <- c("trader_name", "overnight_news", "overnight_calendar", "todays_releases", "releases_in_window", "regime_summary", "planned_setups", "exposure_note")
  ok(all(vapply(flds, function(k) !is.na(h[[k]]) && nzchar(h[[k]]), TRUE)), paste("every text field filled:", paste(flds[!vapply(flds, function(k) !is.na(h[[k]]) && nzchar(h[[k]]), TRUE)], collapse = ", ")))
  ok(grepl("^My view: oil heavy.", h$overnight_news) && !grepl("old line", h$overnight_news) && grepl("Brent falls", h$overnight_news) && !grepl("x.com", h$overnight_news), "news: your words kept, the old app block replaced, weak source dropped")
  oc <- tr_calendar_parse_text(h$overnight_calendar); ok(any(grepl("Industrial Production", oc$event)) && any(grepl("Empire State", oc$event)), "yesterday's events carried into the overnight list")
  tc <- tr_calendar_parse_text(h$todays_releases); ok(tc$importance[grepl("Crude Oil Inventories", tc$event)] == "High", "Crude Oil Inventories rated High")
  out <- paste(as.character(output$ms_oneclick_out), collapse = ""); fs <- list.files(dbx, recursive = TRUE, pattern = "Morning_Sheet_16-11-2026")
  ok(any(grepl("\\.pdf$", fs)) && grepl("BigQuery", out) && regexpr("BigQuery", out) < regexpr("Dropbox: Morning_Sheet", out), sprintf("BigQuery first, then the PDF in Dropbox (%s)", paste(basename(fs), collapse = ", ")))
})
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); if (fail) quit(status = 1)
