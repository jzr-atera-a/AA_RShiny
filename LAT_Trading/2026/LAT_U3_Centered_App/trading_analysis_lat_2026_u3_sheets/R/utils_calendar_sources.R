# R/utils_calendar_sources.R
# Economic calendar without screenshots. Four sources, chosen on the Morning Sheet tab:
#   ff    Forex Factory weekly feed (JSON, free, no key, no Claude)             <- default
#   shots IG calendar screenshots read by Claude (vision)                       (in trading_records.R)
#   web   Claude web search                                                     (backup; also used for actuals)
#   fred  official US: FRED release dates (FRED_API_KEY) + EIA oil reports (EIA_API_KEY)
# Output is always the app's calendar table: time (HH:MM UK), country, importance, event, actual, forecast, previous,
# saved as text lines in the existing overnight_calendar / todays_releases / releases_in_window columns.

tr_ff_urls <- c(this = "https://nfs.faireconomy.media/ff_calendar_thisweek.json", last = "https://nfs.faireconomy.media/ff_calendar_lastweek.json")
tr_cal_keep_ccy <- c("USD", "GBP", "EUR", "CNY", "JPY", "AUD", "CAD", "ALL")   # majors + China + Canada (oil producer); "ALL" = OPEC / global
tr_cal_ccy_country <- c(USD = "United States", GBP = "United Kingdom", EUR = "Euro Area", JPY = "Japan", CNY = "China", AUD = "Australia",
                        CAD = "Canada", NZD = "New Zealand", CHF = "Switzerland", ALL = "Global")
tr_cal_oil_pattern <- "(?i)crude|\\boil\\b|natural gas|gasoline|distillate|heating oil|API Weekly|OPEC|Baker Hughes|rig count|\\bEIA\\b|petroleum|refinery"

tr_http_text <- function(url, timeout = 30) {
  h <- curl::new_handle(); curl::handle_setopt(h, timeout = timeout, followlocation = TRUE)
  curl::handle_setheaders(h, `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36", Accept = "application/json,text/plain,*/*")
  r <- curl::curl_fetch_memory(url, handle = h); if (r$status_code != 200) stop("HTTP ", r$status_code, " for ", sub("\\?.*$", "", url))
  rawToChar(r$content)
}
tr_cal_empty <- function() as.data.frame(setNames(replicate(length(tr_cal_cols), character(0), simplify = FALSE), tr_cal_cols), stringsAsFactors = FALSE)

# The dates "yesterday / overnight" covers for a sheet date: the previous trading day and any weekend days after it.
tr_cal_overnight_days <- function(day) { day <- as.Date(day); p <- day - 1; while (format(p, "%u") %in% c("6", "7")) p <- p - 1; seq(p, day - 1, by = "day") }

# Forex Factory JSON -> data.frame(ts (UTC), date_uk, time, country, importance, event, actual, forecast, previous, oil)
tr_ff_parse <- function(txt) {
  x <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = TRUE), error = function(e) NULL)
  if (is.null(x) || !NROW(x)) return(NULL)
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  d <- sub("([+-]\\d\\d):(\\d\\d)$", "\\1\\2", x$date)                 # 2026-10-26T05:00:00-04:00 -> -0400 for strptime
  ts <- as.POSIXct(strptime(d, "%Y-%m-%dT%H:%M:%S%z", tz = "UTC"))
  title <- as.character(x$title); ccy <- toupper(as.character(x$country))
  country <- unname(tr_cal_ccy_country[ccy]); country[is.na(country)] <- ccy[is.na(country)]
  for (p in list(c("^German ", "Germany"), c("^French ", "France"), c("^Italian ", "Italy"), c("^Spanish ", "Spain")))
    country[ccy == "EUR" & grepl(p[1], title)] <- p[2]
  data.frame(ts = ts, date_uk = as.Date(format(ts, "%Y-%m-%d", tz = "Europe/London")), time = format(ts, "%H:%M", tz = "Europe/London"),
             ccy = ccy, country = country, importance = as.character(x$impact), event = title,
             actual = if ("actual" %in% names(x)) as.character(x$actual) else "", forecast = as.character(x$forecast), previous = as.character(x$previous),
             oil = grepl(tr_cal_oil_pattern, title, perl = TRUE), stringsAsFactors = FALSE)
}
# Keep High and Medium events of the markets that matter, plus every oil event whatever its rating; one day or several.
tr_ff_select <- function(ff, days) {
  if (is.null(ff) || !nrow(ff)) return(tr_cal_empty())
  base <- ff[ff$date_uk %in% as.Date(days) & !(ff$importance %in% "Holiday") & (ff$ccy %in% tr_cal_keep_ccy | ff$oil), , drop = FALSE]
  k <- base[base$importance %in% c("High", "Medium") | base$oil, , drop = FALSE]
  # a quiet day (fewer than 4 such events): also show that day's Low-rated releases, so the sheet is never empty when events exist
  for (d in as.list(unique(base$date_uk))) if (sum(k$date_uk == d) < 4) k <- rbind(k, base[base$date_uk == d & !(base$importance %in% c("High", "Medium")) & !base$oil, , drop = FALSE])
  k <- k[order(k$ts), , drop = FALSE]
  if (!nrow(k)) return(tr_cal_empty())
  multi <- length(unique(as.Date(days))) > 1
  data.frame(time = if (multi) paste(format(k$date_uk, "%a"), k$time) else k$time, country = k$country, importance = k$importance,
             event = ifelse(k$oil & !grepl("(?i)oil|crude", k$event, perl = TRUE), paste0(k$event, " (oil)"), k$event),
             actual = ifelse(is.na(k$actual), "", k$actual), forecast = ifelse(is.na(k$forecast), "", k$forecast), previous = ifelse(is.na(k$previous), "", k$previous),
             stringsAsFactors = FALSE)
}
# Fetch this week's and last week's feeds; returns list(ff = parsed rows, covered = dates covered, problems)
tr_ff_load <- function(fetch_text = tr_http_text) {
  out <- list(); cov <- as.Date(character(0)); probs <- character(0)
  for (nm in names(tr_ff_urls)) {
    t <- tryCatch(fetch_text(tr_ff_urls[[nm]]), error = function(e) { probs <<- c(probs, paste0("Forex Factory ", nm, " week: ", conditionMessage(e))); NULL })
    p <- if (is.null(t)) NULL else tr_ff_parse(t)
    if (!is.null(p) && nrow(p)) { out[[nm]] <- p
      wk0 <- min(p$date_uk); wk0 <- wk0 - as.integer(format(wk0, "%w"))   # the feed's week runs Sunday to Saturday
      cov <- c(cov, seq(wk0, wk0 + 6, by = "day")) }
  }
  list(ff = if (length(out)) do.call(rbind, out) else NULL, covered = unique(cov), problems = probs)
}

# Releases inside the trading window: today's events from `from` (HH:MM UK) for `hours` hours
tr_cal_in_window <- function(df, from = "08:00", hours = 10) {
  if (is.null(df) || !nrow(df)) return(tr_cal_empty())
  hm <- function(x) { m <- regmatches(x, regexpr("\\d{1,2}:\\d{2}", x)); v <- rep(NA_real_, length(x)); ok <- nchar(m) > 0
    v[regexpr("\\d{1,2}:\\d{2}", x) > 0] <- vapply(strsplit(m, ":"), function(z) as.numeric(z[1]) * 60 + as.numeric(z[2]), 0); v }
  t <- hm(df$time); f <- hm(from); keep <- is.finite(t) & t >= f & t <= f + 60 * hours
  df[keep, , drop = FALSE]
}

# Claude: actual values for releases already out (only the rows given; never invents)
tr_calendar_actuals_prompt <- function(df, days) paste0(
  "Use web search to find the ACTUAL released values of these economic releases (UK times, ", paste(format(as.Date(days), "%a %d %b %Y"), collapse = ", "), "). ",
  "Use reputable sources (Forex Factory, Investing.com, Trading Economics, FXStreet, the official statistics office or central bank, EIA for oil). ",
  "Do NOT invent values: if you cannot find an actual, use null. Keep units as published (%, K, M, B).\n",
  paste(sprintf("- %s | %s | %s", df$time, df$country, df$event), collapse = "\n"),
  "\nReply with ONE JSON object and nothing else: {\"events\": [{\"time\": string, \"event\": string, \"actual\": string|null, \"url\": string|null}]}")
tr_cal_merge_actuals <- function(df, parsed) {
  e <- parsed$events; if (is.null(df) || !nrow(df) || is.null(e) || !length(e)) return(df)
  if (is.data.frame(e)) e <- lapply(seq_len(nrow(e)), function(i) as.list(e[i, ]))
  key <- function(x) gsub("[^a-z0-9]", "", tolower(x))
  for (x in e) { a <- x$actual; if (is.null(a) || !length(a) || is.na(a) || !nzchar(trimws(as.character(a)))) next
    i <- which(key(df$event) == key(as.character(x$event)) & !nzchar(df$actual))
    if (length(i) > 1 && !is.null(x$time)) i <- i[endsWith(df$time[i], as.character(x$time))]
    if (length(i)) df$actual[i[1]] <- trimws(as.character(a)) }
  df
}

# ---- official US: FRED release dates + EIA oil reports ----------------------------------------------------
# FRED has dates but no times or importance: the main US releases with their usual time (US Eastern) and importance
tr_fred_watch <- data.frame(
  name = c("Employment Situation", "Consumer Price Index", "Gross Domestic Product", "Personal Income and Outlays", "Advance Monthly Sales for Retail and Food Services",
           "Producer Price Index", "Unemployment Insurance Weekly Claims Report", "Advance Report on Durable Manufacturers' Shipments, Inventories and Orders", "Industrial Production and Capacity Utilization",
           "New Residential Construction", "New Residential Sales", "Existing Home Sales", "Job Openings and Labor Turnover Survey", "Employment Cost Index", "ADP National Employment Report",
           "University of Michigan: Consumer Sentiment", "FOMC Press Release", "Conference Board Consumer Confidence"),
  event = c("Non-Farm Payrolls / Employment Situation", "CPI", "GDP", "Personal Income, Spending and PCE prices", "Retail Sales", "PPI", "Unemployment Claims", "Durable Goods Orders",
            "Industrial Production", "Housing Starts", "New Home Sales", "Existing Home Sales", "JOLTS Job Openings", "Employment Cost Index", "ADP Non-Farm Employment",
            "UoM Consumer Sentiment", "FOMC Statement", "CB Consumer Confidence"),
  et = c("08:30", "08:30", "08:30", "08:30", "08:30", "08:30", "08:30", "08:30", "09:15", "08:30", "10:00", "10:00", "10:00", "08:30", "08:15", "10:00", "14:00", "10:00"),
  importance = c("High", "High", "High", "High", "High", "Medium", "Medium", "Medium", "Medium", "Medium", "Medium", "Medium", "Medium", "Medium", "Medium", "Medium", "High", "Medium"),
  stringsAsFactors = FALSE)
tr_et_to_uk <- function(day, hhmm) format(as.POSIXct(paste(day, hhmm), tz = "America/New_York"), "%H:%M", tz = "Europe/London")
tr_fred_calendar <- function(days, key = Sys.getenv("FRED_API_KEY"), fetch_text = tr_http_text) {
  if (!nzchar(key)) stop("FRED_API_KEY is not set (free key: fred.stlouisfed.org > My Account > API Keys)")
  days <- as.Date(days)
  url <- sprintf("https://api.stlouisfed.org/fred/releases/dates?api_key=%s&file_type=json&realtime_start=%s&realtime_end=%s&include_release_dates_with_no_data=true&limit=1000&sort_order=asc",
                 key, format(min(days)), format(max(days)))
  x <- jsonlite::fromJSON(fetch_text(url))$release_dates; if (is.null(x) || !NROW(x)) return(tr_cal_empty())
  x <- as.data.frame(x, stringsAsFactors = FALSE); x <- x[as.Date(x$date) %in% days, , drop = FALSE]
  m <- match(x$release_name, tr_fred_watch$name); x <- x[!is.na(m), , drop = FALSE]; m <- m[!is.na(m)]
  if (!nrow(x)) return(tr_cal_empty())
  w <- tr_fred_watch[m, ]; multi <- length(days) > 1
  uk <- mapply(tr_et_to_uk, x$date, w$et)
  d <- data.frame(time = if (multi) paste(format(as.Date(x$date), "%a"), uk) else uk, country = "United States", importance = w$importance,
                  event = w$event, actual = "", forecast = "", previous = "", stringsAsFactors = FALSE)
  d[order(x$date, uk), , drop = FALSE]
}
# EIA weekly reports: crude stocks (Wednesday 10:30 US Eastern) and natural gas storage (Thursday 10:30 ET); actual / previous
# change from the EIA API when EIA_API_KEY is set and the report is out. Holiday weeks can shift a day: check EIA's schedule.
tr_eia_series <- list(crude = list(route = "petroleum/stoc/wstk", series = "WCESTUS1", wday = "3", event = "EIA Crude Oil Inventories", unit = "M", div = 1000),
                      gas = list(route = "natural-gas/stor/wkly", series = "NW2_EPG0_SWO_R48_BCF", wday = "4", event = "EIA Natural Gas Storage", unit = "B", div = 1))
tr_eia_calendar <- function(days, key = Sys.getenv("EIA_API_KEY"), fetch_text = tr_http_text, now = Sys.time()) {
  days <- as.Date(days); rows <- list(); multi <- length(days) > 1
  for (s in tr_eia_series) for (d in as.list(days)) { if (format(d, "%u") != s$wday) next
    uk <- tr_et_to_uk(format(d), "10:30"); act <- ""; prev <- ""
    if (nzchar(key)) {
      url <- sprintf("https://api.eia.gov/v2/%s/data/?api_key=%s&frequency=weekly&data[0]=value&facets[series][]=%s&sort[0][column]=period&sort[0][direction]=desc&length=3", s$route, key, s$series)
      v <- tryCatch(jsonlite::fromJSON(fetch_text(url))$response$data, error = function(e) NULL)
      if (!is.null(v) && NROW(v) >= 3) { v <- v[order(v$period, decreasing = TRUE), ]; val <- as.numeric(v$value) / s$div
        released <- as.POSIXct(paste(d, uk), tz = "Europe/London") <= now
        latest_for_d <- as.Date(v$period[1]) >= d - 7
        f <- function(x) sprintf("%+.1f%s", x, s$unit)
        if (released && latest_for_d) { act <- f(val[1] - val[2]); prev <- f(val[2] - val[3]) } else prev <- f(val[1] - val[2]) } }
    rows[[length(rows) + 1]] <- data.frame(time = if (multi) paste(format(d, "%a"), uk) else uk, country = "United States", importance = "High", event = s$event,
                                           actual = act, forecast = "", previous = prev, stringsAsFactors = FALSE) }
  if (!length(rows)) tr_cal_empty() else do.call(rbind, rows)
}

# ==== Combined source: Forex Factory -> Yahoo Finance economic calendar -> Claude ====================================
# Rows used internally keep their date: data.frame(date, time (HH:MM UK), country, importance, event, actual, forecast, previous, oil, src)
tr_cal_rows_empty <- function() data.frame(date = as.Date(character(0)), time = character(0), country = character(0), importance = character(0), event = character(0),
                                           actual = character(0), forecast = character(0), previous = character(0), oil = logical(0), src = character(0), stringsAsFactors = FALSE)
tr_ff_rows <- function(ff, days) {
  if (is.null(ff) || !nrow(ff)) return(tr_cal_rows_empty())
  k <- ff[ff$date_uk %in% as.Date(days) & !(ff$importance %in% "Holiday") & (ff$ccy %in% tr_cal_keep_ccy | ff$oil), , drop = FALSE]
  if (!nrow(k)) return(tr_cal_rows_empty())
  data.frame(date = k$date_uk, time = k$time, country = k$country, importance = k$importance, event = k$event, actual = ifelse(is.na(k$actual), "", k$actual),
             forecast = ifelse(is.na(k$forecast), "", k$forecast), previous = ifelse(is.na(k$previous), "", k$previous), oil = k$oil, src = "Forex Factory", stringsAsFactors = FALSE)
}
# Yahoo Finance economic calendar page for one day (HTML table: Event, Country, Event Time, For, Actual, Market Expectation, Prior to This, Revised from)
tr_yahoo_cal_url <- function(day) { d <- format(as.Date(day)); sprintf("https://finance.yahoo.com/calendar/economic?from=%s&to=%s&day=%s&offset=0&size=100", d, d, d) }
tr_yahoo_cal_ccy <- c(US = "United States", GB = "United Kingdom", UK = "United Kingdom", DE = "Germany", FR = "France", IT = "Italy", ES = "Spain", EU = "Euro Area", EMU = "Euro Area",
                      JP = "Japan", CN = "China", AU = "Australia", CA = "Canada", SA = "Saudi Arabia", NO = "Norway", RU = "Russia", AE = "United Arab Emirates")
tr_cal_major_pattern <- "(?i)\\bCPI\\b|inflation|\\bGDP\\b|\\bPMI\\b|payroll|unemployment|jobless|claims|retail sales|interest rate|rate decision|cash rate|policy rate|consumer confidence|sentiment|\\bifo\\b|\\bZEW\\b|\\bPPI\\b|trade balance|industrial production|durable goods|housing starts|home sales|\\bPCE\\b|\\bISM\\b|employment|budget|\\bFOMC\\b|\\bECB\\b|\\bBOE\\b|\\bBOJ\\b|\\bRBA\\b|\\bBOC\\b|\\bPBOC\\b|Fed\\b"
tr_yahoo_cal_parse <- function(html, day) {
  doc <- tryCatch(xml2::read_html(html), error = function(e) NULL); if (is.null(doc)) return(tr_cal_rows_empty())
  tab <- xml2::xml_find_first(doc, "//table"); if (inherits(tab, "xml_missing")) return(tr_cal_rows_empty())
  hdr <- tolower(trimws(xml2::xml_text(xml2::xml_find_all(tab, ".//thead//th"))))
  rows <- xml2::xml_find_all(tab, ".//tbody/tr"); if (!length(rows) || !length(hdr)) return(tr_cal_rows_empty())
  cell <- function(r) trimws(xml2::xml_text(xml2::xml_find_all(r, "./td")))
  m <- do.call(rbind, lapply(rows, function(r) { v <- cell(r); length(v) <- length(hdr); v })); colnames(m) <- hdr
  col <- function(p) { i <- grep(p, hdr); if (length(i)) m[, i[1]] else rep("", nrow(m)) }
  tt <- col("time"); ev <- col("^event"); cc <- toupper(col("country")); act <- col("^actual"); fc <- col("expectation|forecast|consensus"); pr <- col("prior|previous")
  # "8:30 AM EDT" -> UK time; a time without zone is taken as US Eastern (Yahoo's default)
  uk <- vapply(tt, function(x) {
    mm <- regmatches(x, regexec("(\\d{1,2}):(\\d{2})\\s*([AP]M)?\\s*([A-Z]{2,4})?", x))[[1]]; if (length(mm) < 3) return("")
    h <- as.integer(mm[2]) %% 12 + if (identical(toupper(mm[4]), "PM")) 12 else 0; if (!nzchar(mm[4])) h <- as.integer(mm[2])
    tz <- switch(toupper(tr_or(mm[5], "")), EDT = , EST = , ET = "America/New_York", GMT = , BST = "Europe/London", UTC = "UTC", "America/New_York")
    format(as.POSIXct(sprintf("%s %02d:%s", format(as.Date(day)), h, mm[3]), tz = tz), "%H:%M", tz = "Europe/London") }, "")
  country <- unname(tr_yahoo_cal_ccy[cc]); country[is.na(country)] <- cc[is.na(country)]
  blank <- function(x) { x[is.na(x) | x %in% c("-", "--", "N/A")] <- ""; x }
  ev <- trimws(gsub("\\s*\\*+\\s*$", "", ev))   # Yahoo marks some names with a trailing "*"
  oil <- grepl(tr_cal_oil_pattern, ev, perl = TRUE)
  d <- data.frame(date = as.Date(day), time = uk, country = country, importance = ifelse(grepl(tr_cal_major_pattern, ev, perl = TRUE) | oil, "Medium", "Low"),
                  event = ev, actual = blank(act), forecast = blank(fc), previous = blank(pr), oil = oil, src = "Yahoo", stringsAsFactors = FALSE)
  d <- d[nzchar(d$event) & (cc %in% names(tr_yahoo_cal_ccy) | oil), , drop = FALSE]; rownames(d) <- NULL; d
}
# Same release in both sources: same day, within 30 minutes, and most words of the shorter name shared
tr_cal_same <- function(a, b) {
  w <- function(x) setdiff(unique(strsplit(gsub("[^a-z0-9 ]", " ", tolower(x)), " +")[[1]]), c("", "m", "y", "q", "s", "index", "the", "of", "german", "us", "uk"))
  wa <- w(a); wb <- w(b); if (!length(wa) || !length(wb)) return(FALSE); length(intersect(wa, wb)) / min(length(wa), length(wb)) >= 0.5
}
tr_cal_mins <- function(t) { m <- regmatches(t, regexpr("\\d{1,2}:\\d{2}", t)); if (!length(m)) return(NA_real_); p <- as.numeric(strsplit(m, ":")[[1]]); p[1] * 60 + p[2] }
# Forex Factory rows complemented by Yahoo: actuals / forecasts / previous filled in, Yahoo releases FF does not list added
tr_cal_combine <- function(ffr, yr) {
  if (is.null(yr) || !nrow(yr)) return(ffr)
  if (is.null(ffr) || !nrow(ffr)) return(yr[yr$country == "United States" | yr$oil | yr$importance %in% c("High", "Medium"), , drop = FALSE])   # a day Forex Factory does not cover
  used <- rep(FALSE, nrow(yr))
  for (i in seq_len(nrow(ffr))) {
    c0 <- which(!used & yr$date == ffr$date[i] & abs(vapply(yr$time, tr_cal_mins, 0) - tr_cal_mins(ffr$time[i])) <= 30)
    same_nums <- function(j) any(c(ffr$forecast[i], ffr$previous[i]) != "" & c(ffr$forecast[i], ffr$previous[i]) == c(yr$forecast[j], yr$previous[j]))
    c0 <- c0[vapply(c0, function(j) tr_cal_same(ffr$event[i], yr$event[j]) || (ffr$country[i] == yr$country[j] && same_nums(j)), TRUE)]; if (!length(c0)) next
    j <- c0[1]; used[j] <- TRUE
    for (k in c("actual", "forecast", "previous")) if (!nzchar(ffr[[k]][i]) && nzchar(yr[[k]][j])) ffr[[k]][i] <- yr[[k]][j]
    rank <- c(Low = 1, Medium = 2, High = 3); if (tr_or(rank[yr$importance[j]], 0) > tr_or(rank[ffr$importance[i]], 0)) ffr$importance[i] <- yr$importance[j]
    if (nzchar(yr$actual[j]) && ffr$src[i] == "Forex Factory") ffr$src[i] <- "Forex Factory + Yahoo"
  }
  # Yahoo-only releases are added only when they matter: US releases (their times are reliable) rated Medium by name, or oil releases
  add <- yr[!used & ((yr$country == "United States" & yr$importance %in% c("High", "Medium")) | yr$oil), , drop = FALSE]
  out <- rbind(ffr, add); rownames(out) <- NULL; out
}
# Keep High / Medium / oil per day; a day with fewer than 4 such events also shows its Low releases. Sorted by date and time.
tr_cal_keep <- function(r) {
  if (is.null(r) || !nrow(r)) return(tr_cal_rows_empty())
  k <- r[r$importance %in% c("High", "Medium") | r$oil, , drop = FALSE]
  for (d in as.list(unique(r$date))) if (sum(k$date == d) < 4) k <- rbind(k, r[r$date == d & !(r$importance %in% c("High", "Medium")) & !r$oil & grepl("^Forex", r$src), , drop = FALSE])
  k[order(k$date, vapply(k$time, tr_cal_mins, 0)), , drop = FALSE]
}
tr_cal_format <- function(r, multi = length(unique(r$date)) > 1) {
  if (is.null(r) || !nrow(r)) return(tr_cal_empty())
  data.frame(time = if (multi) paste(format(r$date, "%a"), r$time) else r$time, country = r$country, importance = r$importance,
             event = ifelse(r$oil & !grepl("(?i)oil|crude", r$event, perl = TRUE), paste0(r$event, " (oil)"), r$event),
             actual = r$actual, forecast = r$forecast, previous = r$previous, stringsAsFactors = FALSE)
}
# Claude's table (time, country, importance, event, ...) for one day -> rows
tr_cal_rows_from_df <- function(df, day, src = "Claude") {
  if (is.null(df) || !nrow(df)) return(tr_cal_rows_empty())
  data.frame(date = as.Date(day), time = sub("^\\w{3} ", "", df$time), country = df$country, importance = df$importance, event = df$event, actual = df$actual,
             forecast = df$forecast, previous = df$previous, oil = grepl(tr_cal_oil_pattern, df$event, perl = TRUE), src = src, stringsAsFactors = FALSE)
}

# Did Yahoo really serve the day asked for? Compare its releases with Forex Factory's: the page is kept only if it shares at
# least one release with FF on that day, or (a day FF does not cover) it is not the same page as another day's.
tr_yahoo_page_ok <- function(yr, day, ff_rows_all, other_pages = list()) {
  if (is.null(yr) || !nrow(yr)) return(FALSE)
  sig <- tr_yahoo_page_sig(yr)
  if (any(vapply(other_pages, function(o) identical(o, sig), TRUE))) return(FALSE)
  if (is.null(ff_rows_all) || !nrow(ff_rows_all)) return(TRUE)
  hits <- function(dd) { f <- ff_rows_all[ff_rows_all$date == dd, , drop = FALSE]; if (!nrow(f)) return(NA)
    sum(vapply(seq_len(nrow(yr)), function(j) any(vapply(seq_len(nrow(f)), function(i) tr_cal_same(f$event[i], yr$event[j]), TRUE)), TRUE)) }
  h0 <- hits(as.Date(day)); if (is.na(h0)) {   # FF does not cover this day: reject if the page matches another day FF covers
    oth <- setdiff(unique(ff_rows_all$date), as.Date(day)); return(!any(vapply(as.list(oth), function(dd) isTRUE(hits(dd) >= 2), TRUE))) }
  h0 > 0
}
tr_yahoo_page_sig <- function(yr) if (is.null(yr) || !nrow(yr)) "" else paste(sort(yr$event), collapse = "|")   # event names only (UK times shift with the clock change)
# Pages fetched for several days: a page that comes back identical for different days belongs to at most ONE of them (the day
# Forex Factory agrees with); every page must also pass tr_yahoo_page_ok. pages: named list (names = dates) of parsed rows.
tr_yahoo_pages_filter <- function(pages, ff_rows_all) {
  if (!length(pages)) return(pages)
  sig <- vapply(pages, tr_yahoo_page_sig, ""); keep <- rep(TRUE, length(pages))
  hits <- function(i) { f <- ff_rows_all[ff_rows_all$date == as.Date(names(pages)[i]), , drop = FALSE]; y <- pages[[i]]; if (is.null(f) || !nrow(f) || !nrow(y)) return(0)
    sum(vapply(seq_len(nrow(y)), function(j) any(vapply(seq_len(nrow(f)), function(k) tr_cal_same(f$event[k], y$event[j]), TRUE)), TRUE)) }
  for (g in unique(sig[nzchar(sig)])) { ix <- which(sig == g); if (length(ix) < 2) next
    h <- vapply(ix, hits, 0); keep[ix] <- FALSE; if (max(h) > 0) keep[ix[which.max(h)]] <- TRUE }
  for (i in which(keep)) keep[i] <- tr_yahoo_page_ok(pages[[i]], as.Date(names(pages)[i]), ff_rows_all, list())
  pages[keep]
}
