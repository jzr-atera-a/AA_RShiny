# R/utils_trading_pipeline.R
# Screenshots + online sources -> BigQuery -> LAT templates -> PDF: the pieces that join the steps up.
#   A. Where the app runs (desktop or a Posit / Shiny Server) and its settings from environment variables
#   B. Claude web search: a stream reader that keeps the sources and can continue a paused search
#   C. Morning Sheet levels from Yahoo Finance (overnight low / high, current price, Dow and Nikkei)
#   D. Dropbox: access token (long-lived or refresh token), upload, download, and a picture store
#   E. Pictures saved per trade / per morning sheet (rows in the existing trading_evidence table)
#   F. Missing-field checks before an export
#   G. Matching a closed-trade (History) row to the right open trade
# Plain R, testable without Shiny. No new BigQuery columns: pictures use evidence.dropbox_path / screen_type / user_notes.

if (!exists("%||%", inherits = TRUE)) `%||%` <- function(a, b) if (is.null(a)) b else a

# =============================================================================================
# A. Runtime
# =============================================================================================
# "server" when running under Shiny Server / Posit Connect (no Dropbox folder on the machine; use the Dropbox API),
# "desktop" otherwise. TRADING_RUNTIME=server|desktop forces it.
tr_runtime <- function() {
  f <- tolower(Sys.getenv("TRADING_RUNTIME", ""))
  if (f %in% c("server", "desktop")) return(f)
  if (nzchar(Sys.getenv("SHINY_SERVER_VERSION")) || identical(Sys.getenv("RSTUDIO_PRODUCT"), "CONNECT") || nzchar(Sys.getenv("CONNECT_SERVER"))) "server" else "desktop"
}
tr_is_server <- function() identical(tr_runtime(), "server")

# =============================================================================================
# B. Claude web search (streamed): keep every block so sources survive and a paused turn can be continued
# =============================================================================================
tr_sse_state <- function() { s <- new.env(parent = emptyenv()); s$blocks <- list(); s$stop_reason <- NULL; s$usage <- list(); s$error <- NULL; s }

# Apply one parsed SSE event (a list from the JSON after "data: ") to the state.
tr_sse_apply <- function(s, ev) {
  ty <- ev$type %||% ""
  if (ty == "message_start") { u <- ev$message$usage; if (!is.null(u)) s$usage <- u }
  else if (ty == "content_block_start") {
    b <- ev$content_block; i <- as.integer(ev$index %||% length(s$blocks)) + 1L
    if (identical(b$type, "text")) { b$text <- b$text %||% "" }
    if (b$type %in% c("server_tool_use", "tool_use")) b$.json <- ""
    s$blocks[[i]] <- b
  } else if (ty == "content_block_delta") {
    i <- as.integer(ev$index) + 1L; d <- ev$delta; if (i > length(s$blocks) || is.null(s$blocks[[i]])) return(invisible(s))
    b <- s$blocks[[i]]
    if (identical(d$type, "text_delta")) b$text <- paste0(b$text %||% "", d$text %||% "")
    else if (identical(d$type, "input_json_delta")) b$.json <- paste0(b$.json %||% "", d$partial_json %||% "")
    else if (identical(d$type, "citations_delta")) b$citations <- c(b$citations %||% list(), list(d$citation))
    s$blocks[[i]] <- b
  } else if (ty == "content_block_stop") {
    i <- as.integer(ev$index) + 1L; if (i > length(s$blocks) || is.null(s$blocks[[i]])) return(invisible(s))
    b <- s$blocks[[i]]
    if (!is.null(b$.json)) { j <- b$.json; b$.json <- NULL
      b$input <- if (nzchar(trimws(j))) tryCatch(jsonlite::fromJSON(j, simplifyVector = FALSE), error = function(e) setNames(list(), character(0))) else setNames(list(), character(0)) }
    s$blocks[[i]] <- b
  } else if (ty == "message_delta") {
    if (!is.null(ev$delta$stop_reason)) s$stop_reason <- ev$delta$stop_reason
    if (!is.null(ev$usage)) for (k in names(ev$usage)) s$usage[[k]] <- ev$usage[[k]]
  } else if (ty == "error") s$error <- ev$error$message %||% "Unknown stream error"
  invisible(s)
}
# Feed a chunk of raw SSE text; returns the unprocessed remainder (an incomplete event).
tr_sse_feed <- function(s, buffer) {
  buffer <- gsub("\r\n", "\n", buffer, fixed = TRUE)
  while (grepl("\n\n", buffer, fixed = TRUE)) {
    pos <- regexpr("\n\n", buffer, fixed = TRUE); blk <- substr(buffer, 1, pos - 1); buffer <- substr(buffer, pos + 2, nchar(buffer))
    for (dl in grep("^data: ?", strsplit(blk, "\n", fixed = TRUE)[[1]], value = TRUE)) {
      js <- sub("^data: ?", "", dl); if (trimws(js) %in% c("", "[DONE]")) next
      ev <- tryCatch(jsonlite::fromJSON(js, simplifyVector = FALSE), error = function(e) NULL)
      if (!is.null(ev)) tr_sse_apply(s, ev)
    }
  }
  buffer
}
# Text of the reply (all text blocks, in order)
tr_sse_text <- function(blocks) paste(vapply(Filter(function(b) is.list(b) && identical(b$type, "text"), blocks), function(b) as.character(b$text %||% "")[1], ""), collapse = "")
# Every web source the search returned or the text cited: data.frame(url, title, kind)
tr_sse_sources <- function(blocks) {
  out <- list()
  for (b in blocks) {
    if (!is.list(b)) next
    # a search that failed comes back as ONE object {type, error_code}, not a list of results: skip it
    if (identical(b$type, "web_search_tool_result") && is.list(b$content) && is.null(names(b$content)))
      for (r in b$content) if (is.list(r) && is.character(r$url) && length(r$url) == 1) out[[length(out) + 1]] <- data.frame(url = r$url, title = if (is.character(r$title)) r$title[1] else "", kind = "search result", stringsAsFactors = FALSE)
    if (identical(b$type, "text") && is.list(b$citations))
      for (ci in b$citations) if (is.list(ci) && is.character(ci$url) && length(ci$url) == 1) out[[length(out) + 1]] <- data.frame(url = ci$url, title = if (is.character(ci$title)) ci$title[1] else "", kind = "cited", stringsAsFactors = FALSE)
  }
  if (!length(out)) return(data.frame(url = character(0), title = character(0), kind = character(0), stringsAsFactors = FALSE))
  d <- do.call(rbind, out); d <- d[order(d$kind != "cited"), , drop = FALSE]; d[!duplicated(d$url), , drop = FALSE]
}
# Blocks as they must be sent back when the API pauses a long search (stop_reason "pause_turn")
tr_sse_blocks_for_resend <- function(blocks) {
  blocks <- Filter(function(b) is.list(b) && !(identical(b$type, "text") && !nzchar(b$text %||% "")), blocks)
  lapply(blocks, function(b) { b$.json <- NULL; if (identical(b$type, "text") && !length(b$citations)) b$citations <- NULL; b })
}
# Error text from a non-200 reply body (JSON, or the body itself)
tr_api_error_text <- function(status, body) {
  p <- tryCatch(jsonlite::fromJSON(body, simplifyVector = FALSE), error = function(e) NULL)
  m <- if (!is.null(p$error$message)) p$error$message else substr(gsub("\\s+", " ", body), 1, 300)
  sprintf("Claude API error (HTTP %s): %s", status, m)
}

# =============================================================================================
# C. Morning Sheet levels from Yahoo Finance (hourly bars for the overnight range; daily bars for Dow / Nikkei)
# =============================================================================================
tr_yahoo_symbols <- c(EURUSD = "EURUSD=X", USDJPY = "JPY=X", GBPUSD = "GBPUSD=X", AUDUSD = "AUDUSD=X", WTI = "CL=F", BRENT = "BZ=F",
                      GOLD = "GC=F", SILVER = "SI=F", NATGAS = "NG=F", COPPER = "HG=F", USDCAD = "CAD=X", USDCHF = "CHF=X", NZDUSD = "NZDUSD=X",
                      EURGBP = "EURGBP=X", EURJPY = "EURJPY=X", GBPJPY = "GBPJPY=X", DOW = "^DJI", SP500 = "^GSPC", NASDAQ = "^NDX", FTSE100 = "^FTSE",
                      GER40 = "^GDAXI", JP225 = "^N225")

tr_yahoo_url <- function(symbol, range = "5d", interval = "60m")
  paste0("https://query1.finance.yahoo.com/v8/finance/chart/", utils::URLencode(symbol, reserved = TRUE), "?range=", range, "&interval=", interval, "&includePrePost=true")

# Parse a Yahoo chart reply -> list(bars = data.frame(time (UTC), open, high, low, close), tz = exchange time zone, meta)
tr_yahoo_parse <- function(txt) {
  p <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = FALSE), error = function(e) NULL)
  r <- p$chart$result; if (is.null(r) || !length(r)) stop("Yahoo returned no data", if (!is.null(p$chart$error$description)) paste0(": ", p$chart$error$description) else "")
  r <- r[[1]]; ts <- unlist(r$timestamp); q <- r$indicators$quote[[1]]
  num <- function(x) as.numeric(unlist(lapply(x, function(v) if (is.null(v)) NA_real_ else v)))
  if (!length(ts)) return(list(bars = data.frame(time = as.POSIXct(character(0), tz = "UTC"), open = numeric(0), high = numeric(0), low = numeric(0), close = numeric(0)), tz = "UTC", meta = r$meta))
  b <- data.frame(time = as.POSIXct(ts, origin = "1970-01-01", tz = "UTC"), open = num(q$open), high = num(q$high), low = num(q$low), close = num(q$close))
  b <- b[is.finite(b$close), , drop = FALSE]
  list(bars = b, tz = r$meta$exchangeTimezoneName %||% "UTC", meta = r$meta)
}
tr_yahoo_fetch <- function(symbol, range = "5d", interval = "60m") {
  h <- curl::new_handle(); curl::handle_setopt(h, timeout = 30, followlocation = TRUE)
  curl::handle_setheaders(h, `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
  r <- curl::curl_fetch_memory(tr_yahoo_url(symbol, range, interval), handle = h)
  if (r$status_code != 200) stop("Yahoo HTTP ", r$status_code, " for ", symbol)
  tr_yahoo_parse(rawToChar(r$content))
}

# The overnight window used on the sheet: from 21:00 UK the evening before the sheet date to `now`
# (for a past date: to 07:30 UK on that date). Returns POSIXct in UTC.
tr_overnight_window <- function(day, now = Sys.time()) {
  day <- as.Date(day)
  from <- as.POSIXct(paste(format(day - 1), "21:00:00"), tz = "Europe/London")
  cap <- as.POSIXct(paste(format(day), "07:30:00"), tz = "Europe/London")
  to <- if (identical(day, as.Date(format(now, tz = "Europe/London")))) now else cap
  attr(from, "tzone") <- "UTC"; to <- as.POSIXct(to); attr(to, "tzone") <- "UTC"
  list(from = from, to = to)
}
# Overnight low / high / last price from hourly bars inside the window. Bars are stamped with their START time.
tr_overnight_from_bars <- function(bars, from, to, bar_minutes = 60) {
  if (is.null(bars) || !nrow(bars)) return(NULL)
  end <- bars$time + bar_minutes * 60
  w <- bars[end > from & bars$time < to, , drop = FALSE]
  if (!nrow(w)) return(NULL)
  last_end <- min(max(w$time) + bar_minutes * 60, to)
  list(low = min(w$low, na.rm = TRUE), high = max(w$high, na.rm = TRUE), cur = utils::tail(w$close, 1),
       time = format(last_end, "%H:%M", tz = "Europe/London"), bars = nrow(w))
}
# Index level for the sheet: the last daily close (and change on the session before). Dow: the US session BEFORE the
# sheet date; Nikkei: the Tokyo session OF the sheet date (it closes before London opens).
tr_index_from_daily <- function(parsed, day, same_day = FALSE) {
  b <- parsed$bars; if (is.null(b) || nrow(b) < 2) return(NULL)
  d <- as.Date(format(b$time, tz = parsed$tz %||% "UTC")); day <- as.Date(day)
  keep <- if (same_day) d <= day else d < day
  b <- b[keep, , drop = FALSE]; if (nrow(b) < 2) return(NULL)
  n <- nrow(b); pts <- b$close[n] - b$close[n - 1]
  list(price = b$close[n], chg_pts = pts, chg_pct = 100 * pts / b$close[n - 1], session = format(d[keep][n]))
}
# IG quotes some markets in points (Brent 10793.9 = $107.939; EUR/USD 11643.0 = 1.1643). Scale Yahoo values to the
# price already in the row so a sheet never mixes the two. Returns the factor (1 when no reference price).
tr_scale_to <- function(ref, yahoo) {
  if (!is.finite(ref) || !is.finite(yahoo) || yahoo <= 0 || ref <= 0) return(1)
  k <- round(log10(ref / yahoo)); if (abs(log10(ref / yahoo) - k) < 0.3 && k != 0) 10^k else 1
}
# Fill Morning Sheet levels for `codes` (app instrument codes). fetch(symbol, range, interval) is injectable for tests.
# ref = named numeric vector of current prices already on the sheet (IG screenshots), used only for scaling.
# Returns list(rows = data.frame(code, low, high, cur, time, scale, source), dow, nikkei, problems)
# decimals shown for a price: FX 4 (JPY pairs 3), everything else (oil and index points, gold) 1
tr_price_digits <- function(code) { cd <- toupper(if (is.null(code) || is.na(code[1])) "" else code[1]); if (grepl("JPY", cd)) 3 else if (grepl("^[A-Z]{6}$", cd)) 4 else 1 }
tr_yahoo_morning <- function(codes, day, now = Sys.time(), ref = numeric(0), fetch = tr_yahoo_fetch) {
  win <- tr_overnight_window(day, now); rows <- list(); problems <- character(0)
  rng <- if (as.numeric(difftime(now, win$to, units = "days")) > 4) "1mo" else "5d"
  for (cd in unique(toupper(codes[!is.na(codes) & nzchar(codes)]))) {
    sym <- tr_yahoo_symbols[cd]; if (is.na(sym)) { problems <- c(problems, paste0(cd, ": no Yahoo symbol known")); next }
    p <- tryCatch(fetch(sym, rng, "60m"), error = function(e) { problems <<- c(problems, paste0(cd, ": ", conditionMessage(e))); NULL }); if (is.null(p)) next
    o <- tr_overnight_from_bars(p$bars, win$from, win$to); if (is.null(o)) { problems <- c(problems, paste0(cd, ": no bars in the overnight window")); next }
    k <- tr_scale_to(unname(ref[cd]), o$cur)
    if (k == 1 && cd %in% c("WTI", "BRENT") && o$cur < 1000) k <- 100        # IG quotes oil in points (x100) even when no IG price is typed
    dg <- tr_price_digits(cd); rd <- function(v) round(v, dg)
    # shift onto the IG price when you have typed / read it (IG and Yahoo differ by a few points to ~2%)
    rf <- unname(ref[cd]); off <- if (length(rf) == 1 && is.finite(rf)) rf - o$cur * k else 0
    # previous session high / low / close from the SAME hourly series (the daily series can be on another futures contract)
    hb_all <- p$bars; ud <- as.Date(format(hb_all$time, "%Y-%m-%d", tz = "Europe/London"))
    prev_d <- suppressWarnings(max(ud[ud < as.Date(day) & !(format(ud, "%u") %in% c("6", "7"))]))
    ph <- pl <- pc <- NA_real_
    if (is.finite(prev_d)) { ps <- hb_all[ud == prev_d, , drop = FALSE]; if (nrow(ps)) { ph <- max(ps$high) * k + off; pl <- min(ps$low) * k + off; pc <- utils::tail(ps$close, 1) * k + off } }
    hb <- p$bars[p$bars$time < win$to, , drop = FALSE]   # ADX(14) on the hourly bars up to the end of the window
    adx <- if (nrow(hb) >= 30) tryCatch({ a <- stats::na.omit(as.data.frame(TTR::ADX(cbind(hb$high, hb$low, hb$close), n = 14))); round(utils::tail(a$ADX, 1), 1) }, error = function(e) NA_real_) else NA_real_
    rows[[length(rows) + 1]] <- data.frame(code = cd, low = rd(o$low * k + off), high = rd(o$high * k + off), cur = rd(o$cur * k + off), time = o$time, scale = k, offset = round(off, dg),
                                           prior_high = rd(ph), prior_low = rd(pl), prior_close = rd(pc), adx = adx,
                                           prior_day = if (is.finite(prev_d)) format(prev_d, "%a %d/%m") else NA_character_,
                                           source = paste0("Yahoo ", sym, " hourly"), stringsAsFactors = FALSE)
  }
  idx <- function(sym, same) { p <- tryCatch(fetch(sym, "1mo", "1d"), error = function(e) { problems <<- c(problems, paste0(sym, ": ", conditionMessage(e))); NULL })
    if (is.null(p)) NULL else tr_index_from_daily(p, day, same) }
  list(rows = if (length(rows)) do.call(rbind, rows) else NULL, dow = idx("^DJI", FALSE), nikkei = idx("^N225", TRUE),
       window = sprintf("%s to %s UK", format(win$from, "%d/%m %H:%M", tz = "Europe/London"), format(win$to, "%d/%m %H:%M", tz = "Europe/London")), problems = problems)
}

# =============================================================================================
# D. Dropbox: token, upload, download, picture store
# =============================================================================================
# Dropbox access tokens from the App Console expire after about 4 hours. For a server (or to stop re-pasting tokens)
# set DROPBOX_APP_KEY, DROPBOX_APP_SECRET and DROPBOX_REFRESH_TOKEN: a fresh access token is fetched when needed.
.tr_dbx_cache <- new.env(parent = emptyenv())
tr_dropbox_token <- function(post = NULL) {
  rt <- Sys.getenv("DROPBOX_REFRESH_TOKEN"); ak <- Sys.getenv("DROPBOX_APP_KEY"); as_ <- Sys.getenv("DROPBOX_APP_SECRET")
  if (nzchar(rt) && nzchar(ak) && nzchar(as_)) {
    if (!is.null(.tr_dbx_cache$token) && isTRUE(.tr_dbx_cache$expires > Sys.time() + 120)) return(.tr_dbx_cache$token)
    post <- post %||% function(fields) {
      h <- curl::new_handle(); curl::handle_setform(h, .list = fields); curl::handle_setopt(h, timeout = 30)
      r <- curl::curl_fetch_memory("https://api.dropbox.com/oauth2/token", handle = h)
      if (r$status_code >= 400) stop("Dropbox token refresh HTTP ", r$status_code, ": ", substr(rawToChar(r$content), 1, 200))
      jsonlite::fromJSON(rawToChar(r$content))
    }
    j <- tryCatch(post(list(grant_type = "refresh_token", refresh_token = rt, client_id = ak, client_secret = as_)),
                  error = function(e) { cat("[Dropbox]", conditionMessage(e), "\n"); NULL })
    if (!is.null(j$access_token)) { .tr_dbx_cache$token <- j$access_token; .tr_dbx_cache$expires <- Sys.time() + as.numeric(j$expires_in %||% 14400); return(j$access_token) }
  }
  Sys.getenv("DROPBOX_ACCESS_TOKEN")
}
tr_dropbox_join <- function(...) { p <- paste(c(...)[nzchar(c(...))], collapse = "/"); p <- gsub("//+", "/", paste0("/", gsub("^/+", "", p))); sub("/$", "", p) }
tr_dropbox_upload_to <- function(file, path, token) {
  h <- curl::new_handle(); body <- readBin(file, "raw", file.size(file))
  curl::handle_setopt(h, post = TRUE, postfieldsize = length(body), postfields = body, timeout = 120)
  curl::handle_setheaders(h, Authorization = paste("Bearer", token), `Content-Type` = "application/octet-stream",
                          `Dropbox-API-Arg` = as.character(jsonlite::toJSON(list(path = path, mode = "overwrite", autorename = FALSE, mute = TRUE), auto_unbox = TRUE)))
  r <- curl::curl_fetch_memory("https://content.dropboxapi.com/2/files/upload", handle = h)
  if (r$status_code >= 400) stop("Dropbox API HTTP ", r$status_code, ": ", substr(rawToChar(r$content), 1, 200))
  path
}
tr_dropbox_download <- function(path, dest, token) {
  h <- curl::new_handle(); curl::handle_setopt(h, post = TRUE, postfieldsize = 0, postfields = raw(0), timeout = 120)
  curl::handle_setheaders(h, Authorization = paste("Bearer", token), `Dropbox-API-Arg` = as.character(jsonlite::toJSON(list(path = path), auto_unbox = TRUE)))
  r <- curl::curl_fetch_disk("https://content.dropboxapi.com/2/files/download", dest, handle = h)
  if (r$status_code >= 400) { msg <- tryCatch(readChar(dest, 300), error = function(e) ""); unlink(dest); stop("Dropbox download HTTP ", r$status_code, ": ", msg) }
  dest
}

# Picture store. Every picture gets a RELATIVE path such as "Screenshots/2026-10-20/EV_..._chart.png". It is written
# to the local Dropbox folder (desktop) and/or uploaded under the API path (server or both), and always kept in a
# session cache so this session works even without Dropbox. The saved path is prefixed "session:" when it only
# exists in the cache (it will not survive a restart).
tr_image_store <- function(local_dir = "", api_dir = "", token_fn = tr_dropbox_token,
                           upload = tr_dropbox_upload_to, download = tr_dropbox_download, cache = file.path(tempdir(), "lat_pictures")) {
  force(local_dir); force(api_dir); force(token_fn); force(upload); force(download)   # evaluate now: a reactive that builds the store must depend on the settings
  dir.create(cache, recursive = TRUE, showWarnings = FALSE)
  st <- list()
  st$local <- function() { d <- trimws(as.character(local_dir)); if (length(d) && nzchar(d) && !tr_is_server() && tr_local_path_ok(d)) d else "" }
  st$api <- function() { d <- trimws(as.character(api_dir)); if (length(d) && nzchar(d)) d else "" }
  st$durable <- function() nzchar(st$local()) || (nzchar(st$api()) && nzchar(token_fn()))
  st$put <- function(file, rel) {
    rel <- gsub("^/+", "", gsub("\\\\", "/", rel)); where <- character(0)
    cp <- file.path(cache, rel); dir.create(dirname(cp), recursive = TRUE, showWarnings = FALSE); file.copy(file, cp, overwrite = TRUE)
    if (nzchar(st$local())) { dst <- file.path(st$local(), rel)
      ok <- tryCatch({ dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE); file.copy(file, dst, overwrite = TRUE) }, error = function(e) FALSE)
      if (isTRUE(ok)) where <- c(where, "folder") }
    tok <- if (nzchar(st$api())) token_fn() else ""
    if (nzchar(st$api()) && nzchar(tok)) { r <- tryCatch(upload(file, tr_dropbox_join(st$api(), rel), tok), error = function(e) { cat("[Pictures]", conditionMessage(e), "\n"); NULL })
      if (!is.null(r)) where <- c(where, "api") }
    list(path = if (length(where)) rel else paste0("session:", rel), where = where)
  }
  # local file for a stored relative path, or NA
  st$get <- function(path) {
    if (is.na(path) || !nzchar(path)) return(NA_character_)
    rel <- sub("^session:", "", path)
    cp <- file.path(cache, rel); if (file.exists(cp)) return(cp)
    if (nzchar(st$local()) && file.exists(file.path(st$local(), rel))) return(file.path(st$local(), rel))
    tok <- if (nzchar(st$api())) token_fn() else ""
    if (nzchar(st$api()) && nzchar(tok)) { dir.create(dirname(cp), recursive = TRUE, showWarnings = FALSE)
      r <- tryCatch(download(tr_dropbox_join(st$api(), rel), cp, tok), error = function(e) { cat("[Pictures]", conditionMessage(e), "\n"); NULL })
      if (!is.null(r) && file.exists(cp)) return(cp) }
    NA_character_
  }
  st
}
tr_picture_rel <- function(evidence_id, name, day = Sys.Date()) {
  nm <- gsub("[^A-Za-z0-9._-]+", "_", basename(name)); paste0("Screenshots/", format(as.Date(day)), "/", evidence_id, "_", nm)
}

# Shrink a picture before it is sent to Claude (needs the magick package; skipped silently without it).
# Claude reads images up to about 1568 px on the long side at full detail; bigger images only cost time.
tr_downscale_image <- function(path, max_px = 1568) {
  if (!requireNamespace("magick", quietly = TRUE)) return(path)
  out <- tryCatch({
    im <- magick::image_read(path); inf <- magick::image_info(im)
    if (max(inf$width, inf$height) <= max_px) return(path)
    f <- tempfile(fileext = paste0(".", tolower(tools::file_ext(path))))
    magick::image_write(magick::image_resize(im, sprintf("%dx%d>", max_px, max_px)), f); f
  }, error = function(e) path)
  out
}

# =============================================================================================
# E. Pictures for the sheets (rows in trading_evidence; no new columns)
# =============================================================================================
#   kind = "picture", status = "ATTACHED" (or "DISCARDED"), trade_id = the trade (or the morning sheet id "MS_yyyy-mm-dd"),
#   screen_type = the slot: "entry", "intrade" or "intrade:<event_id>", "exit", "post_exit", "calendar_o", "calendar_t", "market",
#   user_notes = the caption printed above the picture (for example "4 Hour"), dropbox_path = the stored path.
# Platform screenshots read in Order Evidence (ticket, positions, history) that are LINKED to the trade are used too:
# ticket / open -> after the entry charts; close / history -> exit.
tr_picture_slots <- c("Entry chart (with stop and target)" = "entry", "In-trade management (stop move / partial exit)" = "intrade",
                      "Exit chart" = "exit", "Outcome of Trade (IG history / result row)" = "outcome", "Post-exit chart" = "post_exit",
                      "Other (evidence only, not printed)" = "other")
tr_picture_captions <- c("Daily", "4 Hour", "1 Hour", "30 Min", "15 Min", "10 Min", "5 Min", "IG deal ticket", "IG positions", "IG history (closed)")

tr_picture_row <- function(evidence_id, owner_id, slot, caption, path, name, md5 = NA_character_, size = NA_integer_, mime = NA_character_) {
  data.frame(evidence_id = evidence_id, record_version = 1L, kind = "picture", status = "ATTACHED", trade_id = owner_id, file_name = name,
             file_md5 = md5, mime = mime, size_bytes = as.integer(size), dropbox_path = path, screen_type = slot,
             user_notes = if (is.null(caption) || is.na(caption)) NA_character_ else caption, stringsAsFactors = FALSE)
}
# Pictures to place on a sheet, in print order: data.frame(slot, event_id, caption, dropbox_path, file_name, evidence_id)
tr_pictures_for <- function(evidence, owner_id) {
  empty <- data.frame(slot = character(0), event_id = character(0), caption = character(0), dropbox_path = character(0), file_name = character(0), evidence_id = character(0), stringsAsFactors = FALSE)
  if (is.null(evidence) || !nrow(evidence)) return(empty)
  e <- evidence[!is.na(evidence$trade_id) & evidence$trade_id == owner_id & !is.na(evidence$dropbox_path) & nzchar(evidence$dropbox_path), , drop = FALSE]
  e <- e[!(e$status %in% c("DISCARDED", "FAILED")), , drop = FALSE]
  if (!nrow(e)) return(empty)
  pic <- e$kind == "picture"
  st <- ifelse(pic, e$screen_type, ifelse(e$kind %in% c("open", "ticket"), "entry_platform", ifelse(e$kind %in% c("close", "history"), "exit", "other")))
  st[is.na(st)] <- "other"
  slot <- sub(":.*$", "", st); ev <- ifelse(grepl(":", st), sub("^[^:]*:", "", st), NA_character_)
  cap <- ifelse(pic, e$user_notes, ifelse(e$kind == "ticket", "IG deal ticket", ifelse(e$kind == "open", "IG position", ifelse(e$kind %in% c("close", "history"), "IG history (closed)", NA_character_))))
  d <- data.frame(slot = slot, event_id = ev, caption = cap, dropbox_path = e$dropbox_path, file_name = e$file_name, evidence_id = e$evidence_id,
                  saved_at = e$saved_at, stringsAsFactors = FALSE)
  ord <- c(entry = 1, entry_platform = 2, intrade = 3, exit = 4, outcome = 4.5, post_exit = 5, calendar_o = 6, calendar_t = 7, market = 8, other = 9)
  d <- d[order(ord[d$slot], d$saved_at), , drop = FALSE]; d$saved_at <- NULL; rownames(d) <- NULL; d
}

# =============================================================================================
# F. Missing-field checks (shown before an export; the export still works)
# =============================================================================================
# Returns data.frame(field, level ("missing" | "assumed" | "yours"), note). "yours" = a box only the student writes.
tr_trade_gaps <- function(trade, legs = NULL, pictures = NULL) {
  out <- list(); add <- function(f, l, n) out[[length(out) + 1]] <<- data.frame(field = f, level = l, note = n, stringsAsFactors = FALSE)
  v <- function(k) { x <- trade[[k]]; if (is.null(x) || !length(x)) NA else x[1] }
  blank <- function(x) is.null(x) || !length(x) || is.na(x[1]) || !nzchar(trimws(as.character(x[1])))
  if (blank(v("chart_period"))) add("Chart Period", "missing", "Type the chart timeframe you entered on.")
  if (!is.finite(suppressWarnings(as.numeric(v("expected_duration_hours"))))) add("Expected Trade Duration", "missing", "Your planned holding time.")
  if (is.na(v("entry_ts"))) add("Entry date/time", "missing", "") else if (isTRUE(grepl("TIME_ASSUMED", v("notes") %||% ""))) add("Entry time", "assumed", "The screenshot showed no clock. Confirm it from IG History > Activity, then Edit the trade.")
  for (p in list(c("setup_fundamental", "Set-up (fundamental)"), c("setup_technical", "Set-up (technical)"), c("trigger_text", "Trigger"), c("execution_text", "Execution"),
                 c("stop_reason", "Reason for Stop Loss placement"), c("target_reason", "Reason for Target Limit placement")))
    if (blank(v(p[1]))) add(p[2], "yours", "Write it in your own words (Trades > Edit trade).")
  if (identical(v("status"), "CLOSED") || (!is.null(legs) && nrow(legs))) {
    last <- if (!is.null(legs) && nrow(legs)) legs[which.max(legs$exit_ts), ] else trade
    if (blank(last$reason_for_exit)) add("Reason for Exit", "yours", "Only the exit code is filled in.")
    if (blank(last$lessons_learned)) add("Lessons learned", "yours", "")
  } else add("Trade Exit", "missing", "The trade is still open: the exit table will be empty.")
  if (is.null(pictures) || !any(pictures$slot == "entry")) add("Entry chart picture", "missing", "Add the chart with your stop and target (several timeframes if you used them).")
  if (identical(v("status"), "CLOSED") && (is.null(pictures) || !any(pictures$slot %in% c("exit", "post_exit")))) add("Exit / post-exit chart", "missing", "")
  if (!length(out)) return(data.frame(field = character(0), level = character(0), note = character(0), stringsAsFactors = FALSE))
  do.call(rbind, out)
}
tr_morning_gaps <- function(sheet, levels = NULL, cal_pics = 0L) {
  out <- list(); add <- function(f, l, n) out[[length(out) + 1]] <<- data.frame(field = f, level = l, note = n, stringsAsFactors = FALSE)
  if (!is.finite(sheet$dow_price)) add("Dow Jones price", "missing", "")
  if (!is.finite(sheet$nikkei_price)) add("Nikkei price", "missing", "")
  for (cd in c("EURUSD", "USDJPY", "GBPUSD", "AUDUSD", "WTI", "GOLD")) {
    r <- if (!is.null(levels) && nrow(levels)) levels[levels$instrument == cd, , drop = FALSE] else NULL
    lab <- tr_asset_label(cd)
    if (is.null(r) || !nrow(r)) { add(lab, "missing", "No row saved."); next }
    miss <- c(Low = !is.finite(r$overnight_low[1]), High = !is.finite(r$overnight_high[1]), `Current price` = !is.finite(r$current_price[1]), `Time now` = is.na(r$time_now_uk[1]) || !nzchar(r$time_now_uk[1]))
    if (any(miss)) add(lab, "missing", paste(names(miss)[miss], collapse = ", "))
  }
  if (is.na(sheet$overnight_news) || !nzchar(sheet$overnight_news)) add("Overnight news", "yours", "")
  if ((is.na(sheet$overnight_calendar) || !nzchar(sheet$overnight_calendar)) && cal_pics == 0) add("Economic calendar (overnight)", "missing", "Read the IG calendar screenshot or attach it.")
  if ((is.na(sheet$todays_releases) || !nzchar(sheet$todays_releases)) && cal_pics == 0) add("Today's data releases", "missing", "")
  if (!length(out)) return(data.frame(field = character(0), level = character(0), note = character(0), stringsAsFactors = FALSE))
  do.call(rbind, out)
}

# =============================================================================================
# G. Which open trade does a closed-trade (History) row belong to?
# =============================================================================================
# Match on asset, then direction, then opening price (within 0.5 point) and size; a deal reference wins outright.
# Returns the trade_id, or NA when nothing fits (the student then picks the trade).
tr_match_open_trade <- function(open, v) {
  if (is.null(open) || !nrow(open)) return(NA_character_)
  ref <- v$deal_ref %||% NA
  if (!is.na(ref) && nzchar(ref) && "deal_reference" %in% names(open)) { h <- open[!is.na(open$deal_reference) & open$deal_reference == ref, , drop = FALSE]; if (nrow(h)) return(h$trade_id[1]) }
  c1 <- open[open$asset == (v$asset %||% ""), , drop = FALSE]; if (!nrow(c1)) return(NA_character_)
  dir <- v$direction %||% NA; if (!is.na(dir)) { c2 <- c1[c1$direction == dir, , drop = FALSE]; if (nrow(c2)) c1 <- c2 }
  en <- suppressWarnings(as.numeric(v$entry %||% NA)); sz <- suppressWarnings(as.numeric(v$size %||% NA))
  score <- rep(0, nrow(c1))
  if (is.finite(en)) score <- score + ifelse(abs(c1$entry_price - en) <= 0.5 + 1e-9, 2, ifelse(abs(c1$entry_price - en) <= 5, 1, -2))
  if (is.finite(sz)) score <- score + ifelse(abs(c1$stake_per_pip_gbp - sz) < 1e-9, 1, -1)
  best <- which(score == max(score)); if (max(score) < 0) return(NA_character_)
  cand <- c1[best, , drop = FALSE]; cand$trade_id[which.max(cand$entry_ts)]
}

# =============================================================================================
# H. Facts from the records, shown beside the student's own text boxes (no AI, no wording of the answer)
# =============================================================================================
# Returns a character vector of factual lines worked out from the saved numbers only.
tr_trade_facts <- function(trade, legs = NULL, events = NULL, levels = NULL, sheet = NULL) {
  out <- character(0); add <- function(...) out <<- c(out, paste0(...))
  f <- function(x, d = 1) if (is.finite(x)) formatC(x, format = "f", digits = d, big.mark = ",") else "?"
  num <- function(x) suppressWarnings(as.numeric(x))
  dir <- if (identical(trade$direction, "B")) "Buy" else "Sell"; sgn <- tr_dir(trade$direction); pip <- num(trade$pip_size); if (!is.finite(pip) || pip <= 0) pip <- 1
  add(sprintf("Entry: %s %s at %s on %s %s UK, %s per point.", dir, tr_asset_label(trade$asset), tr_ntrim(trade$entry_price), tr_ddmmyyyy(trade$entry_ts), sub("(\\d\\d)(\\d\\d)", "\\1:\\2", tr_hhmm(trade$entry_ts)), tr_ntrim(trade$stake_per_pip_gbp, 2)))
  add(sprintf("Stop %s (%s pips %s the entry, risk GBP %s%s); target %s (%s pips); planned RRR %s.", tr_ntrim(trade$stop1), f(num(trade$initial_risk_pips)), if (sgn > 0) "below" else "above",
              f(num(trade$initial_risk_gbp), 2), if (is.finite(num(trade$risk_pct_equity))) sprintf(", %s%% of equity", f(num(trade$risk_pct_equity), 2)) else "", tr_ntrim(trade$target), f(num(trade$initial_reward_pips)), f(num(trade$initial_rrr), 2)))
  if (!is.na(trade$regime_label) && nzchar(trade$regime_label)) add(sprintf("Regime recorded at entry: %s (ADX %s).", trade$regime_label, f(num(trade$regime_adx))))
  if (!is.null(levels) && nrow(levels)) {
    lv <- levels[levels$instrument == trade$asset, , drop = FALSE]
    if (nrow(lv)) { lv <- lv[1, ]; e <- num(trade$entry_price)
      if (is.finite(num(lv$overnight_low)) && is.finite(num(lv$overnight_high)))
        add(sprintf("Morning Sheet overnight range %s to %s: entry was %s pips %s.", tr_ntrim(lv$overnight_low), tr_ntrim(lv$overnight_high),
                    f(if (e > lv$overnight_high) (e - lv$overnight_high) / pip else if (e < lv$overnight_low) (lv$overnight_low - e) / pip else min(e - lv$overnight_low, lv$overnight_high - e) / pip),
                    if (e > lv$overnight_high) "above the overnight high" else if (e < lv$overnight_low) "below the overnight low" else "inside the range (distance to the nearer edge)"))
      piv <- c(S3 = lv$pivot_s3, S2 = lv$pivot_s2, S1 = lv$pivot_s1, PP = lv$pivot_pp, R1 = lv$pivot_r1, R2 = lv$pivot_r2, R3 = lv$pivot_r3); piv <- piv[is.finite(piv)]
      if (length(piv)) { near <- names(piv)[which.min(abs(piv - e))]
        add(sprintf("Pivot levels that day: %s. Nearest to the entry: %s (%s pips away); nearest to the stop: %s; to the target: %s.", paste(sprintf("%s %s", names(piv), tr_ntrim(piv, 1)), collapse = ", "),
                    near, f(abs(piv[[near]] - e) / pip), names(piv)[which.min(abs(piv - num(trade$stop1)))], names(piv)[which.min(abs(piv - num(trade$target)))])) } }
  }
  if (!is.null(sheet) && nrow(sheet)) {
    cal <- tr_calendar_parse_text(sheet$todays_releases[1])
    if (nrow(cal)) {
      en <- format(trade$entry_ts, "%H:%M", tz = "Europe/London"); ex <- if (!is.null(legs) && nrow(legs) && any(!is.na(legs$exit_ts))) format(max(legs$exit_ts, na.rm = TRUE), "%H:%M", tz = "Europe/London") else "23:59"
      w <- cal[cal$importance %in% c("High", "Medium") & nzchar(cal$time) & cal$time >= en & cal$time <= ex, , drop = FALSE]
      add(if (nrow(w)) paste0("High/Medium releases while the trade was open: ", paste(sprintf("%s %s %s (%s)", w$time, w$country, w$event, w$importance), collapse = "; "), ".")
          else "No High/Medium releases on that day's calendar while the trade was open.")
    }
  }
  if (!is.null(events) && nrow(events)) for (i in seq_len(nrow(events))) { ev <- events[i, ]
    add(if (identical(ev$event_type, "STOP_MOVE")) sprintf("%s: stop moved %s -> %s.", format(ev$event_ts, "%d/%m %H:%M", tz = "Europe/London"), tr_ntrim(ev$old_stop), tr_ntrim(ev$new_stop))
        else sprintf("%s: part closed (%s per point) at %s.", format(ev$event_ts, "%d/%m %H:%M", tz = "Europe/London"), tr_ntrim(ev$size_closed_per_pip, 2), tr_ntrim(ev$price))) }
  if (!is.null(legs) && nrow(legs)) for (i in seq_len(nrow(legs))) { l <- legs[i, ]
    add(sprintf("Exit: %s at %s on %s %s UK (%s), %s pips, GBP %s, %s R, after %s.", if (is.na(l$exit_code)) "closed" else l$exit_code, tr_ntrim(l$exit_price), tr_ddmmyyyy(l$exit_ts),
                sub("(\\d\\d)(\\d\\d)", "\\1:\\2", tr_hhmm(l$exit_ts)), tr_exit_code_text(l$exit_code), f(num(l$pips_result)), f(num(l$net_pnl_gbp), 2), f(num(l$real_r), 2), tr_duration_text(num(l$duration_hours)))) }
  out
}

# =============================================================================================
# I. Fixed Dropbox folders for the LAT sheets (hard-coded, as asked on 21 Oct)
# =============================================================================================
# Desktop: C:/Users/jfz00/Dropbox/London Academy of Trading/Jose-F_Zubizarreta/{Morning Sheets | Individual Trade Sheets}
# Server (Dropbox API, "Full Dropbox" app): /London Academy of Trading/Jose-F_Zubizarreta/{...}
# LAT_DROPBOX_ROOT overrides the Dropbox root (tests, or another computer).
tr_lat_student_rel <- "London Academy of Trading/Jose-F_Zubizarreta"
tr_lat_sheet_dirs <- c(morning = "Morning Sheets", trade = "Individual Trade Sheets", other = "")
tr_lat_root_local <- function() Sys.getenv("LAT_DROPBOX_ROOT", "C:/Users/jfz00/Dropbox")
# a Windows drive path (C:/...) means nothing on Linux / macOS: it would become a folder named "C:" inside the app
tr_local_path_ok <- function(p) length(p) == 1 && !is.na(p) && nzchar(p) && (.Platform$OS.type == "windows" || !grepl("^[A-Za-z]:[/\\]", p))
tr_lat_base_local <- function() file.path(tr_lat_root_local(), tr_lat_student_rel)
tr_lat_base_api <- function() paste0("/", tr_lat_student_rel)
# where a sheet of this kind goes: list(local = folder or "" when this computer has no such Dropbox, api = Dropbox path)
tr_sheet_targets <- function(kind = c("morning", "trade", "other")) {
  kind <- match.arg(kind); sub <- tr_lat_sheet_dirs[[kind]]
  root_ok <- !tr_is_server() && tr_local_path_ok(tr_lat_root_local()) && dir.exists(tr_lat_root_local())
  list(local = if (root_ok) sub("/$", "", file.path(tr_lat_base_local(), sub)) else "", api = sub("/$", "", paste0(tr_lat_base_api(), if (nzchar(sub)) paste0("/", sub) else "")))
}
# Save sheet files to their fixed folder. A file that would be replaced with different content is first copied to
# "<folder>/_previous versions/<name>_<yyyymmdd-HHMMSS>.<ext>". keep_existing = TRUE never replaces an existing file (back-fill).
tr_save_sheet <- function(files, kind = "morning", token = tr_dropbox_token(), upload = tr_dropbox_upload, keep_existing = FALSE) {
  files <- files[!is.na(files) & file.exists(files)]; tg <- tr_sheet_targets(kind); notes <- list()
  if (nzchar(tg$local)) {
    dir.create(tg$local, recursive = TRUE, showWarnings = FALSE)
    for (f in files) { dst <- file.path(tg$local, basename(f))
      if (!file.exists(dst)) next
      if (keep_existing) { notes[[length(notes) + 1]] <- data.frame(file = basename(f), where = tg$local, ok = TRUE, note = "kept the file already there (back-fill never replaces a sheet)", stringsAsFactors = FALSE); files <- setdiff(files, f); next }
      if (!identical(unname(tools::md5sum(dst)), unname(tools::md5sum(f)))) {
        bk <- file.path(tg$local, "_previous versions"); dir.create(bk, showWarnings = FALSE)
        file.copy(dst, file.path(bk, paste0(tools::file_path_sans_ext(basename(f)), "_", format(file.mtime(dst), "%Y%m%d-%H%M%S"), ".", tools::file_ext(f))), overwrite = TRUE) } }
  }
  res <- if (length(files)) tr_save_to_dropbox(files, tg$local, if (nzchar(token)) tg$api else "", token = token, upload = upload) else NULL
  if (!nzchar(tg$local) && !nzchar(token))
    res <- data.frame(file = if (length(files)) basename(files) else "", where = "", ok = FALSE,
                      note = sprintf("not saved: no Dropbox at %s on this computer and no Dropbox token for the API", tr_lat_root_local()), stringsAsFactors = FALSE)
  out <- do.call(rbind, c(notes, list(res))); if (is.null(out)) data.frame(file = character(0), where = character(0), ok = logical(0), note = character(0)) else out
}

# =============================================================================================
# J. Expected trade duration from the student's own plan (Setup: "15 Min = 4; 1 Hour = 8; Daily = 48", hours)
# =============================================================================================
tr_norm_period <- function(x) { x <- tolower(gsub("[^A-Za-z0-9]", "", as.character(x)))
  x <- sub("minutes?$|mins?$|m$", "min", x); x <- sub("hours?$|hrs?$|h$", "hour", x); x <- sub("^(day|d1|1d|1day)$", "daily", x); x }
tr_parse_plan_durations <- function(txt) {
  if (is.null(txt) || is.na(txt) || !nzchar(trimws(txt))) return(numeric(0))
  p <- trimws(unlist(strsplit(txt, "[;,\n]"))); p <- p[grepl("=", p)]
  v <- suppressWarnings(as.numeric(trimws(sub("^[^=]*=", "", p)))); k <- tr_norm_period(sub("=.*$", "", p))
  setNames(v[is.finite(v)], k[is.finite(v)])
}
tr_plan_duration <- function(chart_period, txt) {
  n <- if (is.null(txt) || !length(txt) || is.na(txt[1])) NA_real_ else suppressWarnings(as.numeric(trimws(txt[1])))   # one plain number (hours) = the same duration for every chart period
  if (length(n) == 1 && is.finite(n)) return(n)
  m <- tr_parse_plan_durations(txt); k <- tr_norm_period(chart_period)
  if (length(k) != 1 || is.na(k) || !nzchar(k) || !(k %in% names(m))) NA_real_ else unname(m[[k]]) }

# =============================================================================================
# K. A chart drawn from Yahoo prices for an empty chart slot (labelled as such; aligned to the IG entry price)
# =============================================================================================
tr_yahoo_range_for <- function(from) { d <- as.numeric(difftime(Sys.time(), from, units = "days"))
  if (d <= 4) "5d" else if (d <= 28) "1mo" else if (d <= 85) "3mo" else if (d <= 180) "6mo" else if (d <= 360) "1y" else "2y" }
# kind "entry": the run-up to the entry; "post_exit": entry to 12 h after the exit. Returns list(file, caption) or NULL.
tr_trade_chart_png <- function(trade, legs = NULL, events = NULL, kind = c("entry", "post_exit"), file = tempfile(fileext = ".png"), fetch = tr_yahoo_fetch, now = Sys.time()) {
  kind <- match.arg(kind); sym <- unname(tr_yahoo_symbols[toupper(trade$asset)]); if (is.na(sym) || is.na(trade$entry_ts)) return(NULL)
  utc <- function(x) { x <- as.POSIXct(x); attr(x, "tzone") <- "UTC"; x }
  trade$entry_ts <- utc(trade$entry_ts); if (!is.null(legs) && nrow(legs)) legs$exit_ts <- utc(legs$exit_ts); if (!is.null(events) && nrow(events)) events$event_ts <- utc(events$event_ts)
  ex <- if (!is.null(legs) && nrow(legs) && any(!is.na(legs$exit_ts))) max(legs$exit_ts, na.rm = TRUE) else as.POSIXct(NA)
  intraday <- grepl("min", tolower(tr_or(trade$chart_period, ""))) && as.numeric(difftime(now, trade$entry_ts, units = "days")) < 55
  iv <- if (intraday) "15m" else "60m"; step <- if (intraday) 15 * 60 else 3600
  from <- if (kind == "entry") trade$entry_ts - (if (intraday) 16 else 48) * 3600 else trade$entry_ts - (if (intraday) 6 else 24) * 3600
  to <- if (kind == "entry") trade$entry_ts + 2 * step else min(now, (if (is.na(ex)) now else ex) + 12 * 3600)
  p <- tryCatch(fetch(sym, if (intraday) "60d" else tr_yahoo_range_for(from), iv), error = function(e) NULL); if (is.null(p)) return(NULL)
  b <- p$bars; b <- b[b$time >= from & b$time <= to & is.finite(b$high) & is.finite(b$low), , drop = FALSE]; if (nrow(b) < 5) return(NULL)
  at <- b[b$time <= trade$entry_ts, , drop = FALSE]; p0 <- if (nrow(at)) utils::tail(at$close, 1) else b$open[1]
  k <- tr_scale_to(trade$entry_price, p0); off <- trade$entry_price - p0 * k
  for (cn in c("open", "high", "low", "close")) b[[cn]] <- b[[cn]] * k + off
  lv <- c(trade$stop1, trade$target, trade$entry_price, if (!is.null(events) && nrow(events)) events$new_stop, if (!is.na(ex)) legs$exit_price)
  # honesty check: do the drawn prices reach the IG exit level while the trade was open? (Yahoo futures and the IG price can differ)
  gap_note <- ""
  if (!is.na(ex) && kind == "post_exit") { live <- b[b$time >= trade$entry_ts - step & b$time <= ex + step, , drop = FALSE]
    tol <- 0.15 * abs(trade$entry_price - trade$stop1)
    if (nrow(live) && any(vapply(legs$exit_price, function(xp) xp < min(live$low) - tol || xp > max(live$high) + tol, TRUE)))
      gap_note <- "; NOTE: these Yahoo prices do not reach the IG exit level, so IG's price differed from Yahoo's here" }
  yl <- range(c(b$low, b$high, lv), na.rm = TRUE); yl <- yl + c(-1, 1) * diff(yl) * 0.04
  grDevices::png(file, width = 1600, height = 900, res = 170); on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(4, 4.8, 4.2, 1), las = 1, cex = 0.8)
  x <- as.numeric(b$time); w <- step * 0.35
  graphics::plot(range(x), yl, type = "n", xaxt = "n", xlab = "UK time", ylab = "Price (IG points)")
  graphics::title(sprintf("%s, %s bars (Yahoo %s, aligned to the IG entry price)", tr_asset_label(trade$asset), if (intraday) "15 minute" else "1 hour", sym), line = 2.6)
  tk <- pretty(b$time, n = 8); graphics::axis(1, at = as.numeric(tk), labels = format(tk, "%d/%m %H:%M", tz = "Europe/London"))
  up <- b$close >= b$open
  graphics::segments(x, b$low, x, b$high, col = "grey35")
  graphics::rect(x - w, pmin(b$open, b$close), x + w, pmax(b$open, b$close), col = ifelse(up, "#15803d", "#b91c1c"), border = NA)
  graphics::abline(h = trade$entry_price, col = "#1d4ed8", lwd = 2); graphics::abline(h = trade$stop1, col = "#b91c1c", lwd = 2, lty = 2); graphics::abline(h = trade$target, col = "#15803d", lwd = 2, lty = 2)
  graphics::abline(v = as.numeric(trade$entry_ts), col = "#1d4ed8", lty = 3)
  if (!is.null(events) && nrow(events)) for (i in seq_len(nrow(events))) if (is.finite(events$new_stop[i])) graphics::segments(as.numeric(events$event_ts[i]), events$new_stop[i], max(x), events$new_stop[i], col = "#f59e0b", lwd = 2, lty = 2)
  if (!is.na(ex) && kind == "post_exit") { graphics::points(as.numeric(legs$exit_ts), legs$exit_price, pch = 23, bg = "#111827", cex = 1.6); graphics::abline(v = as.numeric(ex), col = "#111827", lty = 3) }
  graphics::legend("top", inset = c(0, -0.085), xpd = TRUE, horiz = TRUE, bty = "n", cex = 0.85, lwd = 2, lty = c(1, 2, 2, if (kind == "post_exit" && !is.na(ex)) NA),
                   pch = c(NA, NA, NA, if (kind == "post_exit" && !is.na(ex)) 23), pt.bg = "#111827", col = c("#1d4ed8", "#b91c1c", "#15803d", if (kind == "post_exit" && !is.na(ex)) "#111827"),
                   legend = c(sprintf("Entry %s", tr_ntrim(trade$entry_price)), sprintf("Stop %s", tr_ntrim(trade$stop1)), sprintf("Target %s", tr_ntrim(trade$target)), if (kind == "post_exit" && !is.na(ex)) "Exit"))
  list(file = file, gap = nzchar(gap_note), caption = paste0(sprintf("%s %s chart, %s (own work from Yahoo Finance %s data, aligned to the IG entry price; IG's own chart may differ slightly)",
                                       tr_asset_label(trade$asset), if (intraday) "15 Min" else "1 Hour", if (kind == "entry") "entry with stop and target" else "after the exit", sym), gap_note))
}

# =============================================================================================
# L. Report checks for instructions 2 and 4, and web addresses in the student's text
# =============================================================================================
u3_numbering_ok <- function(txt, task_no) { t <- trimws(tr_or(txt, "")); if (!nzchar(t)) return(NA)
  grepl(sprintf("^(Task\\s*)?%d([.):]|\\s)", task_no), t, ignore.case = TRUE) || grepl(sprintf("(^|\\n)\\s*%d\\.\\d", task_no), t) }
u3_long_quotes <- function(txt, max_words = 30) { t <- tr_or(txt, ""); if (!nzchar(t)) return(character(0))
  q <- unlist(regmatches(t, gregexpr("[\"\u201c][^\"\u201d]{20,}[\"\u201d]", t))); q[vapply(q, u3_word_count, 0L) > max_words] }
u3_urls <- function(txt) { u <- unlist(regmatches(tr_or(txt, ""), gregexpr("https?://[^[:space:])>\"]+", tr_or(txt, "")))); unique(sub("[.,;]+$", "", u)) }

# =============================================================================================
# M. Fill the empty cells of a Morning Sheet from Yahoo (values already there are kept)
# =============================================================================================
tr_morning_codes <- c("EURUSD", "USDJPY", "GBPUSD", "AUDUSD", "WTI", "GOLD", "BRENT")
# hdr: one-row morning_sheets frame; lv: its morning_levels rows (may be empty); y: tr_yahoo_morning() result.
# Returns list(hdr, lv, filled = character vector of what was filled).
tr_morning_fill <- function(hdr, lv, y, sid, day) {
  filled <- character(0)
  lv <- tr_coerce("morning_levels", if (is.null(lv) || !nrow(lv)) NULL else lv)
  for (cd in unique(c(tr_morning_codes, lv$instrument))) {
    r <- if (!is.null(y$rows)) y$rows[y$rows$code == cd, , drop = FALSE] else NULL; if (is.null(r) || !nrow(r)) next
    i <- which(lv$instrument == cd)[1]
    if (is.na(i)) { lv <- rbind(lv, tr_coerce("morning_levels", data.frame(level_id = paste0(sid, "_", cd), sheet_id = sid, sheet_date = as.Date(day), instrument = cd, stringsAsFactors = FALSE))); i <- nrow(lv) }
    set <- function(col, val, lab) if (!is.finite(suppressWarnings(as.numeric(lv[[col]][i]))) && is.finite(val)) { lv[[col]][i] <<- val; filled <<- c(filled, paste(tr_asset_label(cd), lab)) }
    set("overnight_low", r$low, "low"); set("overnight_high", r$high, "high"); set("current_price", r$cur, "price")
    if (is.na(lv$time_now_uk[i]) || !nzchar(lv$time_now_uk[i]) || grepl("~", lv$time_now_uk[i])) { lv$time_now_uk[i] <- r$time; filled <- c(filled, paste(tr_asset_label(cd), "time")) }
  }
  idx <- function(x, p, pc, pp, lab) if (!is.null(x) && !is.finite(suppressWarnings(as.numeric(hdr[[p]])))) {
    hdr[[p]] <<- x$price; hdr[[pc]] <<- round(x$chg_pct, 2); hdr[[pp]] <<- round(x$chg_pts, 2); filled <<- c(filled, lab) }
  idx(y$dow, "dow_price", "dow_change_pct", "dow_change_pts", "Dow"); idx(y$nikkei, "nikkei_price", "nikkei_change_pct", "nikkei_change_pts", "Nikkei")
  list(hdr = hdr, lv = lv, filled = filled)
}
# memoised fetch for a back-fill run (each symbol fetched once per interval)
tr_fetch_cached <- function(fetch = tr_yahoo_fetch) { cache <- new.env(); function(sym, range, interval) { k <- paste(sym, interval)
  if (is.null(cache[[k]])) cache[[k]] <- tryCatch(fetch(sym, if (interval == "1d") "3mo" else "3mo", interval), error = function(e) e)
  if (inherits(cache[[k]], "error")) stop(conditionMessage(cache[[k]])); cache[[k]] } }
