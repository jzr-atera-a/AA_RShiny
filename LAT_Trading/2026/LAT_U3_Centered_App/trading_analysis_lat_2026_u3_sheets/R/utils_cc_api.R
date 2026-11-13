# R/utils_cc_api.R
# Capital.com Open API client for the "T Records C.C" tab and the API Configuration > Capital.com tab.
# Documentation: https://open-api.capital.com/  (REST, JSON, base .../api/v1/)
#
# Rules kept here:
#   * Keys never leave memory: they are not written to BigQuery, logs or files. Logs show only the masked key.
#   * Orders are refused unless the environment is DEMO (this app is for the demo account only).
#   * Session tokens (CST, X-SECURITY-TOKEN) expire after 10 minutes without a request: the client logs in again
#     on its own (before 9 minutes of silence, or once after an HTTP 401).
#   * Rate limits (Capital.com): 10 requests/s per user, 1 order per 0.1 s, 1 login per second. The client keeps
#     at least 0.12 s between requests and 1.1 s between logins.
#   * History endpoints accept at most one day per call: cc_activity_range() walks day by day.
# Every request goes through `http_fn(method, url, headers, body)` so the tests can replace the network.

cc_base_url <- function(env = "demo") if (identical(tolower(env), "live")) "https://api-capital.backend-capital.com/api/v1" else "https://demo-api-capital.backend-capital.com/api/v1"

# default transport: curl. Returns list(status, headers (named list, lower-case names), body (text))
cc_http_curl <- function(method, url, headers = list(), body = NULL, timeout = 30) {
  h <- curl::new_handle()
  curl::handle_setopt(h, customrequest = method, timeout = timeout)
  if (!is.null(body)) curl::handle_setopt(h, postfields = body)
  hd <- c(headers, list(`Content-Type` = "application/json", Accept = "application/json"))
  do.call(curl::handle_setheaders, c(list(h), hd))
  r <- curl::curl_fetch_memory(url, handle = h)
  raw_h <- curl::parse_headers_list(r$headers)
  names(raw_h) <- tolower(names(raw_h))
  txt <- rawToChar(r$content); Encoding(txt) <- "UTF-8"
  list(status = r$status_code, headers = raw_h, body = txt)
}

cc_mask <- function(k) { k <- as.character(k %||% ""); if (is.na(k) || nchar(k) < 8) "" else paste0(substr(k, 1, 4), "...", substr(k, nchar(k) - 3, nchar(k))) }

# ---- credentials file -------------------------------------------------------------------------------------
# {"api_key": "...", "identifier": "you@example.com", "api_password": "...", "environment": "demo"}
# (alternative names accepted: apiKey / key, login / email, password / customPassword, env)
cc_read_credentials <- function(path = NULL, text = NULL) {
  j <- tryCatch(if (!is.null(text) && nzchar(trimws(text))) jsonlite::fromJSON(text, simplifyVector = TRUE) else jsonlite::fromJSON(path, simplifyVector = TRUE),
                error = function(e) stop("The Capital.com file is not valid JSON: ", conditionMessage(e)))
  pick <- function(...) { for (k in c(...)) { v <- j[[k]]; if (!is.null(v) && length(v) && nzchar(as.character(v[1]))) return(trimws(as.character(v[1]))) }; NA_character_ }
  out <- list(api_key = pick("api_key", "apiKey", "key", "X-CAP-API-KEY"), identifier = pick("identifier", "login", "email", "username"),
              api_password = pick("api_password", "password", "customPassword", "apiPassword"), environment = tolower(pick("environment", "env")))
  if (is.na(out$environment)) out$environment <- "demo"
  miss <- c(api_key = "api_key", identifier = "identifier (your login email)", api_password = "api_password (the custom password set for the key)")[
    vapply(c("api_key", "identifier", "api_password"), function(k) is.na(out[[k]]), TRUE)]
  if (length(miss)) stop("Missing in the Capital.com file: ", paste(miss, collapse = ", "), ".")
  if (!out$environment %in% c("demo", "live")) stop("environment must be \"demo\" or \"live\".")
  out
}
# a Capital.com credentials file in the local key folder (C:/111_SecA/_q_api on Windows, or LAT_CRED_DIR)
cc_find_local_credentials <- function(dir = if (exists("tr_cred_dir", mode = "function")) tr_cred_dir() else "") {
  if (!nzchar(dir) || !dir.exists(dir)) return(NULL)
  fs <- list.files(dir, pattern = "\\.json$", full.names = TRUE, ignore.case = TRUE)
  fs <- fs[order(!grepl("capital", basename(fs), ignore.case = TRUE), -as.numeric(file.mtime(fs)))]
  for (f in fs) { cr <- tryCatch(cc_read_credentials(f), error = function(e) NULL); if (!is.null(cr)) return(c(cr, list(path = f))) }
  NULL
}

# ---- the client ------------------------------------------------------------------------------------------
# A closure-based object; one per R session (cc_client, created in global.R).
cc_new_client <- function(http_fn = cc_http_curl, sleep_fn = Sys.sleep, now_fn = Sys.time) {
  st <- new.env(parent = emptyenv())
  st$creds <- NULL; st$cst <- NULL; st$xst <- NULL; st$last_call <- as.POSIXct(0, origin = "1970-01-01"); st$last_login <- st$last_call
  st$session <- NULL; st$account_id <- NULL; st$connected <- FALSE; st$last_error <- NULL; st$calls <- 0L; st$log <- character(0)
  logl <- function(...) { s <- paste0(format(now_fn(), "%H:%M:%S"), " ", paste0(...)); st$log <- utils::tail(c(st$log, s), 200); cat("[Capital.com]", paste0(...), "\n") }
  pace <- function(gap) { dt <- as.numeric(difftime(now_fn(), st$last_call, units = "secs")); if (dt < gap) sleep_fn(gap - dt) }
  base <- function() cc_base_url(st$creds$environment)
  body_json <- function(x) if (is.null(x)) NULL else as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", digits = NA))
  parse <- function(r) { if (!nzchar(r$body %||% "")) return(list()); tryCatch(jsonlite::fromJSON(r$body, simplifyVector = FALSE), error = function(e) list(raw = r$body)) }
  err_text <- function(r) { p <- parse(r); paste0("HTTP ", r$status, ": ", p$errorCode %||% p$error %||% substr(r$body %||% "", 1, 200)) }

  login <- function() {
    if (is.null(st$creds)) stop("Capital.com is not set up: load the credentials file in API Configuration > Capital.com.")
    gap <- as.numeric(difftime(now_fn(), st$last_login, units = "secs")); if (gap < 1.1) sleep_fn(1.1 - gap)
    r <- http_fn("POST", paste0(base(), "/session"), list(`X-CAP-API-KEY` = st$creds$api_key),
                 body_json(list(identifier = st$creds$identifier, password = st$creds$api_password, encryptedPassword = FALSE)))
    st$last_login <- now_fn(); st$last_call <- st$last_login; st$calls <- st$calls + 1L
    if (r$status >= 400) { st$connected <- FALSE; st$last_error <- err_text(r); logl("login failed: ", st$last_error); stop("Capital.com login failed (", st$last_error, ").") }
    st$cst <- r$headers[["cst"]] %||% NULL; st$xst <- r$headers[["x-security-token"]] %||% NULL
    if (is.null(st$cst) || is.null(st$xst)) { st$connected <- FALSE; stop("Capital.com login returned no session tokens (CST / X-SECURITY-TOKEN).") }
    st$session <- parse(r); st$account_id <- st$account_id %||% st$session$currentAccountId
    st$connected <- TRUE; st$last_error <- NULL
    logl("logged in (", toupper(st$creds$environment), ", key ", cc_mask(st$creds$api_key), ", account ", st$account_id %||% "-", ")")
    invisible(st$session)
  }
  request <- function(method, path, query = NULL, body = NULL, retry = TRUE, gap = 0.12) {
    if (is.null(st$cst) || as.numeric(difftime(now_fn(), st$last_call, units = "secs")) > 540) login()
    q <- if (length(query)) { query <- query[!vapply(query, function(v) is.null(v) || (length(v) == 1 && is.na(v)), TRUE)]
      paste0("?", paste(sprintf("%s=%s", names(query), vapply(query, function(v) utils::URLencode(as.character(v), reserved = TRUE), "")), collapse = "&")) } else ""
    pace(gap)
    r <- http_fn(method, paste0(base(), path, q), list(`X-CAP-API-KEY` = st$creds$api_key, CST = st$cst, `X-SECURITY-TOKEN` = st$xst), body_json(body))
    st$last_call <- now_fn(); st$calls <- st$calls + 1L
    if (r$status == 401 && retry) { logl("session expired: logging in again"); st$cst <- NULL; login(); return(request(method, path, query, body, retry = FALSE, gap = gap)) }
    if (r$status >= 400) { st$last_error <- err_text(r); logl(method, " ", path, " failed: ", st$last_error); stop("Capital.com ", method, " ", path, " failed (", st$last_error, ").") }
    parse(r)
  }

  obj <- list()
  obj$set_credentials <- function(creds) { st$creds <- creds; st$cst <- NULL; st$connected <- FALSE; st$account_id <- NULL; invisible(TRUE) }
  obj$has_credentials <- function() !is.null(st$creds)
  obj$environment <- function() st$creds$environment %||% NA_character_
  obj$is_demo <- function() identical(st$creds$environment, "demo")
  obj$connected <- function() isTRUE(st$connected)
  obj$status <- function() list(has_credentials = !is.null(st$creds), connected = isTRUE(st$connected), environment = st$creds$environment %||% NA,
                                masked_key = cc_mask(st$creds$api_key), identifier = st$creds$identifier %||% NA, account_id = st$account_id %||% NA,
                                currency = st$session$currencyIsoCode %||% NA, last_error = st$last_error, calls = st$calls, last_call = st$last_call)
  obj$log <- function() st$log
  obj$login <- function() login()
  obj$disconnect <- function() { if (!is.null(st$cst)) tryCatch(request("DELETE", "/session", retry = FALSE), error = function(e) NULL); st$cst <- NULL; st$connected <- FALSE; invisible(TRUE) }
  obj$request <- request
  obj$ping <- function() request("GET", "/ping")
  obj$session_info <- function() request("GET", "/session")
  obj$accounts <- function() request("GET", "/accounts")$accounts %||% list()
  obj$switch_account <- function(account_id) { if (identical(account_id, st$account_id)) return(invisible(TRUE))
    request("PUT", "/session", body = list(accountId = account_id)); st$account_id <- account_id; invisible(TRUE) }
  obj$account_id <- function() st$account_id
  obj$search_markets <- function(term) request("GET", "/markets", query = list(searchTerm = term))$markets %||% list()
  obj$market <- function(epic) request("GET", paste0("/markets/", utils::URLencode(epic, reserved = TRUE)))
  obj$markets <- function(epics) request("GET", "/markets", query = list(epics = paste(epics, collapse = ",")))
  obj$prices <- function(epic, resolution = "MINUTE_15", max = 1000, from = NULL, to = NULL)
    request("GET", paste0("/prices/", utils::URLencode(epic, reserved = TRUE)), query = list(resolution = resolution, max = max, from = from, to = to))
  obj$positions <- function() request("GET", "/positions")$positions %||% list()
  obj$working_orders <- function() request("GET", "/workingorders")$workingOrders %||% list()
  obj$confirm <- function(deal_reference) request("GET", paste0("/confirms/", deal_reference))
  obj$activity <- function(from, to, detailed = TRUE) request("GET", "/history/activity", query = list(from = from, to = to, detailed = if (detailed) "true" else "false"))$activities %||% list()
  obj$transactions <- function(from, to) request("GET", "/history/transactions", query = list(from = from, to = to))$transactions %||% list()

  # ---- dealing (DEMO ONLY) -----------------------------------------------------------------------------
  demo_only <- function() if (!identical(st$creds$environment, "demo")) stop("Orders are only sent to the Capital.com DEMO account from this app (environment is '", st$creds$environment %||% "-", "').")
  wait_confirm <- function(ref) {   # the deal is confirmed asynchronously: ask a few times
    for (k in 1:6) { cf <- tryCatch(obj$confirm(ref), error = function(e) NULL)
      if (!is.null(cf) && !is.null(cf$dealStatus)) { cf$position_deal_id <- cc_opened_deal_id(cf); return(cf) }; sleep_fn(0.5) }
    list(dealStatus = "UNKNOWN", dealReference = ref)
  }
  obj$open_position <- function(epic, direction, size, stop_level = NULL, profit_level = NULL, guaranteed_stop = FALSE) {
    demo_only(); direction <- toupper(direction); stopifnot(direction %in% c("BUY", "SELL"), is.finite(size), size > 0)
    b <- list(epic = epic, direction = direction, size = size, guaranteedStop = isTRUE(guaranteed_stop))
    if (length(stop_level) && is.finite(stop_level)) b$stopLevel <- stop_level
    if (length(profit_level) && is.finite(profit_level)) b$profitLevel <- profit_level
    r <- request("POST", "/positions", body = b, gap = 0.15); logl("position requested ", direction, " ", size, " ", epic, " ref ", r$dealReference %||% "-")
    c(list(request = b), wait_confirm(r$dealReference))
  }
  obj$open_working_order <- function(epic, direction, size, level, type = c("LIMIT", "STOP"), stop_level = NULL, profit_level = NULL, good_till = NULL) {
    demo_only(); type <- match.arg(type); direction <- toupper(direction); stopifnot(direction %in% c("BUY", "SELL"), is.finite(size), size > 0, is.finite(level))
    b <- list(epic = epic, direction = direction, size = size, level = level, type = type)
    if (length(stop_level) && is.finite(stop_level)) b$stopLevel <- stop_level
    if (length(profit_level) && is.finite(profit_level)) b$profitLevel <- profit_level
    if (!is.null(good_till)) b$goodTillDate <- format(as.POSIXct(good_till), "%Y-%m-%dT%H:%M:%S", tz = "UTC")
    r <- request("POST", "/workingorders", body = b, gap = 0.15); logl("working order requested ", type, " ", direction, " ", size, " ", epic, " @ ", level)
    c(list(request = b), wait_confirm(r$dealReference))
  }
  obj$update_position <- function(deal_id, stop_level = NULL, profit_level = NULL) {
    demo_only(); b <- list(); if (length(stop_level) && is.finite(stop_level)) b$stopLevel <- stop_level; if (length(profit_level) && is.finite(profit_level)) b$profitLevel <- profit_level
    if (!length(b)) stop("Nothing to change."); r <- request("PUT", paste0("/positions/", deal_id), body = b); c(list(request = b), wait_confirm(r$dealReference)) }
  obj$close_position <- function(deal_id) { demo_only(); r <- request("DELETE", paste0("/positions/", deal_id)); wait_confirm(r$dealReference) }
  obj$cancel_working_order <- function(deal_id) { demo_only(); r <- request("DELETE", paste0("/workingorders/", deal_id)); wait_confirm(r$dealReference) }
  obj$top_up <- function(amount) { demo_only(); request("POST", "/accounts/topUp", body = list(amount = amount)) }
  obj
}

# The confirmation's own dealId is not always the id the positions list uses: the position opened is listed under
# affectedDeals (status OPENED). Returns that id, else the confirmation's dealId.
cc_opened_deal_id <- function(cf) {
  ad <- cf$affectedDeals %||% list()
  ids <- vapply(ad, function(z) if (toupper(cc_chr(z$status) %||% "") %in% c("OPENED", "OPEN", "AMENDED")) cc_chr(z$dealId) else NA_character_, "")
  ids <- ids[!is.na(ids)]; if (length(ids)) ids[1] else cc_chr(cf$dealId)
}

# ---- response helpers -------------------------------------------------------------------------------------
cc_num <- function(x) { v <- suppressWarnings(as.numeric(if (is.null(x) || !length(x)) NA else x[[1]])); if (length(v)) v else NA_real_ }
cc_chr <- function(x) if (is.null(x) || !length(x) || is.na(x[[1]])) NA_character_ else as.character(x[[1]])
cc_ts <- function(x) {   # vectorised: one time per element (it used to read only the first one)
  if (length(x) > 1) return(as.POSIXct(vapply(seq_along(x), function(i) as.numeric(cc_ts(x[[i]])), 0), origin = "1970-01-01", tz = "UTC"))
  s <- cc_chr(x); if (is.na(s)) return(as.POSIXct(NA, tz = "UTC"))
  s <- sub("Z$", "", sub("\\.[0-9]+", "", gsub("T", " ", s)))
  as.POSIXct(s, tz = "UTC", tryFormats = c("%Y-%m-%d %H:%M:%S", "%Y/%m/%d %H:%M:%S", "%Y-%m-%d %H:%M")) }
cc_api_time <- function(t) format(as.POSIXct(t), "%Y-%m-%dT%H:%M:%S", tz = "UTC")

# Capital.com price list -> bars (time UTC, open/high/low/close = mid of bid and ask, spread, volume)
cc_prices_to_bars <- function(p) {
  pr <- p$prices %||% list(); if (!length(pr)) return(data.frame(time = as.POSIXct(character(0), tz = "UTC"), open = numeric(0), high = numeric(0), low = numeric(0), close = numeric(0), spread = numeric(0), volume = numeric(0)))
  mid <- function(z) { b <- cc_num(z$bid); a <- cc_num(z$ask %||% z$offer); if (is.finite(b) && is.finite(a)) (a + b) / 2 else if (is.finite(b)) b else a }
  sp <- function(z) { b <- cc_num(z$bid); a <- cc_num(z$ask %||% z$offer); if (is.finite(b) && is.finite(a)) a - b else NA_real_ }
  d <- data.frame(time = do.call(c, lapply(pr, function(z) cc_ts(z$snapshotTimeUTC %||% z$snapshotTime))),
                  open = vapply(pr, function(z) mid(z$openPrice), 0), high = vapply(pr, function(z) mid(z$highPrice), 0),
                  low = vapply(pr, function(z) mid(z$lowPrice), 0), close = vapply(pr, function(z) mid(z$closePrice), 0),
                  spread = vapply(pr, function(z) sp(z$closePrice), 0), volume = vapply(pr, function(z) cc_num(z$lastTradedVolume), 0))
  d <- d[is.finite(d$open) & is.finite(d$close) & !is.na(d$time), , drop = FALSE]
  d <- d[order(d$time), , drop = FALSE]; d <- d[!duplicated(d$time), , drop = FALSE]; rownames(d) <- NULL; d
}

cc_resolutions <- c("1 min" = "MINUTE", "5 min" = "MINUTE_5", "15 min" = "MINUTE_15", "30 min" = "MINUTE_30", "1 hour" = "HOUR", "4 hours" = "HOUR_4", "1 day" = "DAY")
cc_res_minutes <- c(MINUTE = 1, MINUTE_5 = 5, MINUTE_15 = 15, MINUTE_30 = 30, HOUR = 60, HOUR_4 = 240, DAY = 1440, WEEK = 10080)

# bars for [from, to]: the API returns at most 1000 values per call, so long ranges are fetched in pages
# Capital.com refuses some date ranges with "error.invalid.daterange" (for example a start further back than it keeps
# minute data, or a range with no trading in it). Each page that is refused is logged with its dates and skipped; if
# every dated page is refused, the latest 1000 candles are fetched without dates (always accepted).
cc_fetch_bars <- function(client, epic, resolution, from, to = Sys.time(), max_calls = 20, log = function(...) cat("[Capital.com]", ..., "\n")) {
  if (identical(resolution, "MINUTE")) return(tryCatch(cc_fetch_bars(client, epic, "MINUTE_1X", from, to, max_calls, log), error = function(e) {   # ********
    if (!grepl("not-found|not found", conditionMessage(e))) stop(e); log(sprintf("%s has no 1-minute candles on Capital.com: 5-minute used", epic)); cc_fetch_bars(client, epic, "MINUTE_5", from, to, max_calls, log) }))
  if (identical(resolution, "MINUTE_1X")) resolution <- "MINUTE"
  # at most ~7 days per request (a 20-day span was refused for 30-minute candles) and never more than 990 candles
  mins <- cc_res_minutes[[resolution]]; step <- min(mins * 60 * 990, 7 * 86400)
  out <- list(); t0 <- as.POSIXct(from); k <- 0; refused <- character(0)
  while (t0 < to && k < max_calls) {
    t1 <- min(to, t0 + step); k <- k + 1
    if (as.numeric(difftime(t1, t0, units = "mins")) < mins) break          # less than one candle left
    p <- tryCatch(client$prices(epic, resolution, max = 1000, from = cc_api_time(t0), to = cc_api_time(t1)),
                  error = function(e) { if (grepl("daterange", conditionMessage(e))) NULL else stop(e) })
    if (is.null(p)) refused <- c(refused, sprintf("%s to %s", cc_api_time(t0), cc_api_time(t1))) else out[[length(out) + 1]] <- cc_prices_to_bars(p)
    t0 <- t1
  }
  if (length(refused)) log(sprintf("prices %s %s: Capital.com refused %d date range(s) (%s)", epic, resolution, length(refused), paste(refused, collapse = "; ")))
  b <- do.call(rbind, out)
  if (is.null(b) || !nrow(b)) { log(sprintf("prices %s %s: no dated page accepted, reading the latest 1000 candles instead", epic, resolution))
    b <- cc_prices_to_bars(client$prices(epic, resolution, max = 1000)) }
  b <- b[order(b$time), , drop = FALSE]; b <- b[!duplicated(b$time), , drop = FALSE]; rownames(b) <- NULL
  attr(b, "refused") <- refused; b
}

# market details -> the facts the tab needs (defensive: field names follow the documented IG-style layout; anything
# missing stays NA and is shown as "not given by Capital.com")
cc_market_facts <- function(m) {
  ins <- m$instrument %||% list(); dr <- m$dealingRules %||% list(); sn <- m$snapshot %||% list()
  rule <- function(x) cc_num(if (is.list(x)) x$value else x)
  list(epic = cc_chr(ins$epic %||% m$epic), name = cc_chr(ins$name %||% m$instrumentName), type = cc_chr(ins$type %||% m$instrumentType),
       currency = cc_chr(ins$currency %||% (if (length(ins$currencies)) ins$currencies[[1]]$code else NULL)),
       lot_size = cc_num(ins$lotSize), unit = cc_chr(ins$unit), margin_factor = cc_num(ins$marginFactor), margin_unit = cc_chr(ins$marginFactorUnit),
       min_size = rule(dr$minDealSize), max_size = rule(dr$maxDealSize), min_stop_distance = rule(dr$minStopOrProfitDistance %||% dr$minNormalStopOrLimitDistance),
       min_step = rule(dr$minSizeIncrement %||% dr$minStepDistance),
       bid = cc_num(sn$bid), offer = cc_num(sn$offer), status = cc_chr(sn$marketStatus), update = cc_chr(sn$updateTimeUTC %||% sn$updateTime),
       scaling = cc_num(sn$scalingFactor %||% ins$scalingFactor), decimals = cc_num(sn$decimalPlacesFactor))
}

# positions -> data.frame
cc_positions_df <- function(pos) {
  if (!length(pos)) return(data.frame())
  do.call(rbind, lapply(pos, function(z) { p <- z$position %||% list(); m <- z$market %||% list()
    data.frame(deal_id = cc_chr(p$dealId), deal_reference = cc_chr(p$dealReference), epic = cc_chr(m$epic), name = cc_chr(m$instrumentName),
               direction = cc_chr(p$direction), size = cc_num(p$size), level = cc_num(p$level), stop_level = cc_num(p$stopLevel),
               profit_level = cc_num(p$profitLevel), upl = cc_num(p$upl), currency = cc_chr(p$currency), created_utc = cc_chr(p$createdDateUTC %||% p$createdDate),
               bid = cc_num(m$bid), offer = cc_num(m$offer), contract_size = cc_num(p$contractSize), lot_size = cc_num(m$lotSize),
               guaranteed = isTRUE(p$guaranteedStop), working_order_id = cc_chr(p$workingOrderId), stringsAsFactors = FALSE) }))
}
cc_orders_df <- function(wo) {
  if (!length(wo)) return(data.frame())
  do.call(rbind, lapply(wo, function(z) { w <- z$workingOrderData %||% list(); m <- z$marketData %||% list()
    data.frame(deal_id = cc_chr(w$dealId), epic = cc_chr(w$epic %||% m$epic), name = cc_chr(m$instrumentName), direction = cc_chr(w$direction),
               type = cc_chr(w$orderType), size = cc_num(w$orderSize), level = cc_num(w$orderLevel), stop_distance = cc_num(w$stopDistance),
               profit_distance = cc_num(w$profitDistance), good_till = cc_chr(w$goodTillDateUTC %||% w$goodTillDate), currency = cc_chr(w$currencyCode),
               created_utc = cc_chr(w$createdDateUTC %||% w$createdDate), bid = cc_num(m$bid), offer = cc_num(m$offer), stringsAsFactors = FALSE) }))
}
cc_accounts_df <- function(acc) {
  if (!length(acc)) return(data.frame())
  do.call(rbind, lapply(acc, function(a) { b <- a$balance %||% list()
    data.frame(account_id = cc_chr(a$accountId), name = cc_chr(a$accountName), type = cc_chr(a$accountType), preferred = isTRUE(a$preferred),
               currency = cc_chr(a$currency), symbol = cc_chr(a$symbol), balance = cc_num(b$balance), deposit = cc_num(b$deposit),
               profit_loss = cc_num(b$profitLoss), available = cc_num(b$available), stringsAsFactors = FALSE) }))
}
# activity and transactions over any range: the API takes at most one day per call
cc_activity_range <- function(client, from, to = Sys.time()) {
  out <- list(); t0 <- as.POSIXct(from)
  while (t0 < to) { t1 <- min(to, t0 + 86400 - 1)
    a <- client$activity(cc_api_time(t0), cc_api_time(t1)); if (length(a)) out <- c(out, a); t0 <- t1 + 1 }
  out
}
# transactions: Capital.com refuses dated ranges for this endpoint (seen 2 Nov 2026), so only the last 24 hours are read
# (lastPeriod in seconds, its maximum). Older transactions come from the cc_transactions rows saved by earlier syncs.
cc_transactions_range <- function(client, from = NULL, to = NULL, log = function(...) cat("[Capital.com]", ..., "\n")) {
  tryCatch(client$request("GET", "/history/transactions", query = list(lastPeriod = 86400))$transactions %||% list(),
           error = function(e) { log("transactions (last 24 h) failed:", conditionMessage(e)); list() })
}
cc_activity_df <- function(a) {
  if (!length(a)) return(data.frame())
  do.call(rbind, lapply(a, function(z) { d <- z$details %||% list()
    data.frame(date_utc = cc_chr(z$dateUTC %||% z$date), epic = cc_chr(z$epic), deal_id = cc_chr(z$dealId), source = cc_chr(z$source), type = cc_chr(z$type),
               status = cc_chr(z$status), level = cc_num(d$level), size = cc_num(d$size), direction = cc_chr(d$direction),
               stop_level = cc_num(d$stopLevel), profit_level = cc_num(d$profitLevel), currency = cc_chr(d$currency),
               json = as.character(jsonlite::toJSON(z, auto_unbox = TRUE, null = "null")), stringsAsFactors = FALSE) }))
}
cc_transactions_df <- function(a) {
  if (!length(a)) return(data.frame())
  do.call(rbind, lapply(a, function(z) data.frame(date_utc = cc_chr(z$dateUtc %||% z$dateUTC %||% z$date), instrument = cc_chr(z$instrumentName),
    type = cc_chr(z$transactionType), note = cc_chr(z$note), reference = cc_chr(z$reference), amount = cc_num(z$size), currency = cc_chr(z$currency),
    status = cc_chr(z$status), json = as.character(jsonlite::toJSON(z, auto_unbox = TRUE, null = "null")), stringsAsFactors = FALSE)))
}
