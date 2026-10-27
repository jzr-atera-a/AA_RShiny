# Economic calendar + market levels (screenshots or Claude web search), PDF conversion and Dropbox saving.
# Everything here is plain R so it can be tested without Shiny. No new BigQuery columns are needed: the calendar goes
# into the existing text columns overnight_calendar / todays_releases as one line per event ("time | country | importance | event | Actual | Forecast | Previous").

tr_cal_cols <- c("time", "country", "importance", "event", "actual", "forecast", "previous")

tr_calendar_vision_prompt <- function() paste(
  "You are transcribing a screenshot of an economic calendar table (columns: TIME, COUNTRY, IMPORTANCE, EVENT, ACTUAL, FORECAST, PREVIOUS).",
  "Return ONE JSON object: {\"day_label\": string|null (the date heading shown, for example 'Oct 20, 2026 (Today)'), \"events\": [ ... ], \"notes\": string|null (only about legibility)}.",
  "One entry per row, in the order shown: {\"time\": \"HH:MM\"|null, \"country\": string, \"importance\": \"High\"|\"Medium\"|\"Low\"|null, \"event\": string, \"actual\": string|null, \"forecast\": string|null, \"previous\": string|null}.",
  "Rules: copy every value exactly as shown, including units and symbols (%, K, M, B, CHF). A dash or an empty cell is null. Do not calculate, correct or add rows. Ignore the small grey text under a time such as 'in 2:29 hours'.")

tr_calendar_web_prompt <- function(day, label = c("today", "yesterday")) {
  label <- match.arg(label)
  paste0("Use web search to find the economic calendar for ", format(day, "%A %d %B %Y"), " (", label, ", UK / London time) from a reputable calendar source (for example Trading Economics, Investing.com, FXStreet, Forex Factory or the IG economic calendar). ",
         "List the High and Medium importance releases and speeches for the UK, US, Euro Area, Germany, China, Japan, Australia and Canada, plus EVERY oil-related release whatever its rating ",
         "(EIA crude inventories and natural gas storage, API weekly crude stocks, OPEC / OPEC+ meetings and reports, Baker Hughes rig count, and events in major oil producers such as Saudi Arabia, Russia, Norway and the UAE). ",
         "If the day is a weekend or a holiday with no releases, return an empty events list. ",
         if (label == "yesterday") "Include the Actual, Forecast and Previous values. " else "Include the Actual value only if it has already been released. ",
         "Convert all times to UK time (HH:MM, 24 hour). Do NOT invent anything: if you cannot find a value use null; if you cannot find the calendar at all return an empty events list.\n",
         "Reply with ONE JSON object and nothing else: {\"events\": [{\"time\": \"HH:MM\"|null, \"country\": string, \"importance\": \"High\"|\"Medium\"|\"Low\", \"event\": string, \"actual\": string|null, \"forecast\": string|null, \"previous\": string|null}], \"source\": string, \"notes\": string|null}.")
}

tr_morning_web_prompt <- function(day) paste0(
  "Use web search to find the market levels as of about 07:00 UK time on ", format(day, "%A %d %B %Y"), " for: Dow Jones (previous US close), Nikkei 225, EUR/USD, USD/JPY, GBP/USD, AUD/USD, WTI crude, Brent crude and gold. ",
  "For each give the current price, the overnight (since the previous US close) low and high if you can find them, and the change on the previous close in points and in percent. Use reputable sources (Reuters, Bloomberg, Investing.com, FXStreet, MarketPulse, Newsquawk). ",
  "Do NOT invent values: use null for anything you cannot find. Prices must be plain numbers. Also give 2 to 4 short factual overnight headlines that move oil or the dollar, each with the URL it came from. Give the source URL of every price; if two sources disagree on a price by more than 0.3%, give null for that price and say so in notes.\n",
  "Reply with ONE JSON object and nothing else: {\"markets\": [{\"name\": string, \"last_price\": number|null, \"day_low\": number|null, \"day_high\": number|null, \"range_basis\": \"day\"|null, \"change_pts\": number|null, \"change_pct\": number|null, \"time_text\": \"HH:MM\"|null, \"source\": string|null}], \"headlines\": [{\"text\": string, \"url\": string|null}], \"sources\": [string], \"notes\": string|null}.")
# headlines may come back as plain strings or as {text, url}
tr_web_headlines <- function(h) {
  if (is.null(h) || !length(h)) return(character(0))
  vapply(h, function(x) { if (is.list(x)) { t <- as.character(x$text %||% ""); u <- as.character(x$url %||% ""); if (length(u) && nzchar(u)) paste0(t, " (", u, ")") else t } else as.character(x) }, "")
}

tr_calendar_df <- function(parsed) {
  e <- parsed$events; empty <- as.data.frame(setNames(replicate(length(tr_cal_cols), character(0), simplify = FALSE), tr_cal_cols), stringsAsFactors = FALSE)
  if (is.null(e) || !length(e)) return(empty)
  if (!is.null(names(e))) e <- list(e)
  s <- function(x, k) { v <- x[[k]]; if (is.null(v) || !length(v) || is.na(v) || !nzchar(trimws(as.character(v)))) "" else trimws(as.character(v)) }
  d <- do.call(rbind, lapply(e, function(x) data.frame(time = s(x, "time"), country = s(x, "country"), importance = s(x, "importance"), event = s(x, "event"),
                                                       actual = s(x, "actual"), forecast = s(x, "forecast"), previous = s(x, "previous"), stringsAsFactors = FALSE)))
  d <- d[nzchar(d$event), , drop = FALSE]; rownames(d) <- NULL; d
}

# one line per event, used for the saved text and the Word sheet when no picture is attached
tr_calendar_text <- function(df) {
  if (is.null(df) || !nrow(df)) return("")
  dash <- function(v) ifelse(nzchar(v), v, "-")
  paste(paste(dash(df$time), dash(df$country), dash(df$importance), df$event, paste("Actual", dash(df$actual)), paste("Forecast", dash(df$forecast)), paste("Previous", dash(df$previous)), sep = " | "), collapse = "\n")
}
tr_calendar_parse_text <- function(txt) {
  empty <- as.data.frame(setNames(replicate(length(tr_cal_cols), character(0), simplify = FALSE), tr_cal_cols), stringsAsFactors = FALSE)
  if (is.null(txt) || is.na(txt) || !nzchar(txt)) return(empty)
  ln <- trimws(unlist(strsplit(txt, "\r?\n"))); ln <- ln[grepl(" \\| .* \\| .* \\| .* \\| Actual ", ln)]
  if (!length(ln)) return(empty)
  p <- strsplit(ln, " | ", fixed = TRUE); un <- function(v) ifelse(v == "-", "", v); cut <- function(v, w) un(sub(paste0("^", w, " "), "", v))
  data.frame(time = un(vapply(p, `[`, "", 1)), country = un(vapply(p, `[`, "", 2)), importance = un(vapply(p, `[`, "", 3)), event = vapply(p, `[`, "", 4),
             actual = cut(vapply(p, `[`, "", 5), "Actual"), forecast = cut(vapply(p, `[`, "", 6), "Forecast"), previous = cut(vapply(p, `[`, "", 7), "Previous"), stringsAsFactors = FALSE)
}
tr_calendar_is_table <- function(txt) nrow(tr_calendar_parse_text(txt)) > 0

# ----------------------------------------------------------------------------- file names
tr_morning_filename <- function(day, ext = "docx") paste0("Morning_Sheet_", format(as.Date(day), "%d-%m-%Y"), ".", ext)
tr_trade_filename <- function(asset, day, ext = "docx") {
  a <- as.character(asset); a <- if (grepl("^[A-Z]{6}$", a)) a else tools::toTitleCase(tolower(gsub("[^A-Za-z0-9]+", " ", a)))
  paste0("Individual_Trade_Sheet_", gsub(" +", "_", trimws(a)), "_", format(as.Date(day), "%d-%m-%Y"), ".", ext)
}

# ----------------------------------------------------------------------------- PDF (needs LibreOffice on the machine running the app)
tr_find_soffice <- function() {
  w <- Sys.which(c("soffice", "libreoffice")); w <- w[nzchar(w)]
  if (length(w)) return(unname(w[1]))
  cand <- c("C:/Program Files/LibreOffice/program/soffice.exe", "C:/Program Files (x86)/LibreOffice/program/soffice.exe", "/Applications/LibreOffice.app/Contents/MacOS/soffice")
  cand <- cand[file.exists(cand)]; if (length(cand)) cand[1] else NA_character_
}
tr_docx_to_pdf <- function(docx, outdir = dirname(docx)) {
  so <- tr_find_soffice(); if (is.na(so)) return(NA_character_)
  prof <- tempfile("lo_profile_"); dir.create(prof)
  url <- paste0("file:///", sub("^/+", "", normalizePath(prof, winslash = "/", mustWork = FALSE)))   # Windows needs file:///C:/... (forward slashes)
  system2(so, c(paste0("-env:UserInstallation=", url), "--headless", "--convert-to", "pdf", "--outdir", shQuote(outdir), shQuote(docx)), stdout = FALSE, stderr = FALSE, timeout = 120,
          env = if (.Platform$OS.type == "unix") "LD_LIBRARY_PATH=" else character(0))   # R's own library path can break LibreOffice on Linux
  pdf <- file.path(outdir, sub("\\.docx$", ".pdf", basename(docx))); if (file.exists(pdf)) pdf else NA_character_
}

# ----------------------------------------------------------------------------- Dropbox
# local_dir: the Dropbox folder synced to this computer. api_dir + token (env DROPBOX_ACCESS_TOKEN): upload through the Dropbox API (works when the app runs on a server).
tr_dropbox_upload <- function(file, api_dir, token) {
  path <- paste0("/", gsub("^/+|/+$", "", api_dir), "/", basename(file)); path <- gsub("//+", "/", path)
  h <- curl::new_handle(); body <- readBin(file, "raw", file.size(file))
  curl::handle_setopt(h, post = TRUE, postfieldsize = length(body), postfields = body, timeout = 120)
  curl::handle_setheaders(h, Authorization = paste("Bearer", token), `Content-Type` = "application/octet-stream",
                          `Dropbox-API-Arg` = jsonlite::toJSON(list(path = path, mode = "overwrite", autorename = FALSE), auto_unbox = TRUE))
  r <- curl::curl_fetch_memory("https://content.dropboxapi.com/2/files/upload", handle = h)
  if (r$status_code >= 400) stop("Dropbox API HTTP ", r$status_code, ": ", substr(rawToChar(r$content), 1, 200))
  path
}
tr_save_to_dropbox <- function(files, local_dir = "", api_dir = "", token = Sys.getenv("DROPBOX_ACCESS_TOKEN"), upload = tr_dropbox_upload) {
  files <- files[!is.na(files) & file.exists(files)]; out <- list()
  add <- function(f, where, ok, note) out[[length(out) + 1]] <<- data.frame(file = basename(f), where = where, ok = ok, note = note, stringsAsFactors = FALSE)
  local_dir <- trimws(as.character(local_dir)); api_dir <- trimws(as.character(api_dir))
  for (f in files) {
    if (nzchar(local_dir)) {
      ok <- tryCatch({ dir.create(local_dir, recursive = TRUE, showWarnings = FALSE); file.copy(f, file.path(local_dir, basename(f)), overwrite = TRUE) }, error = function(e) FALSE)
      add(f, local_dir, isTRUE(ok), if (isTRUE(ok)) "saved to the Dropbox folder on this computer" else "could not write to that folder")
    }
    if (nzchar(api_dir) && nzchar(token)) {
      r <- tryCatch(upload(f, api_dir, token), error = function(e) conditionMessage(e)); ok <- is.character(r) && startsWith(r, "/")
      add(f, paste0("Dropbox:", api_dir), ok, if (ok) paste("uploaded to", r) else r)
    }
  }
  if (!nzchar(local_dir) && !(nzchar(api_dir) && nzchar(token))) add(if (length(files)) files[1] else "", "", FALSE, "no Dropbox folder set (Setup tab) and no DROPBOX_ACCESS_TOKEN: nothing was saved")
  do.call(rbind, out)
}

# Top 3 news for the Morning Sheet: general markets, Brent oil, or another asset the user names
tr_news_prompt <- function(day, topic = c("general", "brent", "other"), asset = "") {
  topic <- match.arg(topic)
  what <- switch(topic, general = "the global financial markets (equities, bonds, currencies, commodities, central banks)",
                 brent = "Brent crude oil (supply, OPEC+, inventories, demand, geopolitics, prices)",
                 other = sprintf("%s (what moves its price)", if (nzchar(asset)) asset else "the markets"))
  paste0("Use web search to find the 3 most important news stories about ", what, " published overnight before ", format(as.Date(day), "%A %d %B %Y"),
         " 07:00 UK time (from about 18:00 UK the previous evening; on a Monday include the weekend). Use reputable news sources (Reuters, Bloomberg, Financial Times, ",
         "CNBC, MarketWatch, Wall Street Journal, AP, the official source for policy decisions).\n",
         "For each story write for a reader who has not followed it:\n",
         "- headline: one short sentence saying what happened, with the key number (price move, rate, amount) where the source gives it;\n",
         "- context: 2 to 3 further FACTUAL sentences taken from the source: the background (what was expected or decided before, the previous level, who is involved), ",
         "the figures reported, and what the source says happens next (a meeting, a deadline, a release). Name the market or asset concerned.\n",
         "No opinions of your own, no trading advice, no predictions beyond what the source reports. Give the source name, the publication time if shown, and the exact article URL. ",
         "Do NOT invent: if you find fewer than 3 stories with a source, return fewer.\n",
         "Reply with ONE JSON object and nothing else: {\"news\": [{\"headline\": string, \"context\": string, \"source\": string, \"time\": string|null, \"url\": string}]}")
}
# items -> list of valid items (headline + https URL), at most 3
tr_news_items <- function(items) {
  if (is.null(items) || !length(items)) return(list())
  if (is.data.frame(items)) items <- lapply(seq_len(nrow(items)), function(i) as.list(items[i, ]))
  g <- function(x, k) { v <- x[[k]]; if (is.null(v) || !length(v) || is.na(v[1])) "" else trimws(as.character(v[1])) }
  ok <- Filter(function(x) is.list(x) && nzchar(g(x, "headline")) && grepl("^https?://", g(x, "url")), items)
  utils::head(lapply(ok, function(x) list(headline = sub("[.]?$", ".", g(x, "headline")), context = g(x, "context"), source = g(x, "source"), time = g(x, "time"), url = g(x, "url"))), 3)
}
# one paragraph per story: headline, context, (source, time) and the link (made clickable on the Word sheet)
tr_news_lines <- function(items) {
  it <- tr_news_items(items); if (!length(it)) return(character(0))
  vapply(it, function(x) trimws(sprintf("- %s %s (%s%s) %s", x$headline, x$context, if (nzchar(x$source)) x$source else "source",
                                        if (nzchar(x$time)) paste0(", ", x$time) else "", x$url)), "")
}
