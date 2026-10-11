# R/utils_titan.R
# =============================================================================
# TITAN CALENDAR (CalDAV) ENGINE - used by the Events Scheduling group:
#   * titan_auth          - signs in from an authenticateT.R file
#   * events_to_calendar  - New events / Import .ics / Upcoming / Log
#   * every Visualisation tab with an .ics export gets two extra buttons via
#     titan_viz_hook() at the bottom of this file.
#
# Ported from the stand-alone "Titan Events" app (caldav.R). Every top-level
# name here starts with titan_ / TITAN_ so nothing can collide with the other
# suites. No password is ever printed or logged.
#
# NOTE: helper names must NOT end in _ui or _server (app.R removes every
# global object matching that pattern on restart, and the module loader treats
# <module_id>_ui / <module_id>_server as module entry points).
# =============================================================================

TITAN_SERVERS <- c(
  "Auto-detect (try all below)"                                      = "auto",
  "GoDaddy Professional Email (Titan) - dav.myprofessionalmail.com"  = "https://dav.myprofessionalmail.com",
  "Titan (global) - dav.titan.email"                                 = "https://dav.titan.email",
  "Titan (EU) - dav-eu.titan.email"                                  = "https://dav-eu.titan.email",
  "Other CalDAV server..."                                           = "custom"
)
TITAN_SERVER_URLS <- unname(TITAN_SERVERS[!TITAN_SERVERS %in% c("auto", "custom")])

TITAN_REMINDERS <- c("At start" = 0, "5 min" = 5, "10 min" = 10, "15 min" = 15,
                     "30 min" = 30, "1 hour" = 60, "2 hours" = 120, "1 day" = 1440)

# One shared list for the whole app: see R/utils_timezone.R
TITAN_DEFAULT_TZ <- BOS_DEFAULT_TZ
TITAN_TIMEZONES  <- BOS_TIMEZONES

# NULL / zero-length / NA safe default
titan_or <- function(a, b) {
  if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a
}

# ---- small formatting helpers ------------------------------------------------

titan_fmt_rem <- function(m) {
  if (!length(m)) return("none")
  paste(vapply(sort(m), function(x) {
    if (x == 0) "at start" else if (x %% 1440 == 0) paste0(x / 1440, "d")
    else if (x %% 60 == 0) paste0(x / 60, "h") else paste0(x, "m")
  }, ""), collapse = ", ")
}

titan_next_slot <- function(tz = TITAN_DEFAULT_TZ) {
  t <- as.POSIXlt(Sys.time() + 3600, tz = tz)
  sprintf("%02d:00", t$hour)
}

# ---- authenticateT.R parser ----------------------------------------------------
# The file is read as PLAIN TEXT and is never source()d / eval()ed.
#   e:name@domain.com
#   p:the-mailbox-password
titan_parse_auth_file <- function(lines) {
  lines <- as.character(lines)
  lines <- sub("^﻿", "", lines)
  lines <- sub("\r$", "", lines)
  unquote <- function(v) {
    v <- trimws(v)
    if (nchar(v) >= 2) {
      f <- substr(v, 1, 1); l <- substr(v, nchar(v), nchar(v))
      if (f %in% c("\"", "'") && f == l) v <- substr(v, 2, nchar(v) - 1)
    }
    v
  }
  grab <- function(letter) {
    i <- grep(paste0("^\\s*[", letter, toupper(letter), "]\\s*:"), lines)
    if (!length(i)) return(NA_character_)
    unquote(sub(paste0("^\\s*[", letter, toupper(letter), "]\\s*:\\s*"), "", lines[i[1]]))
  }
  email <- grab("e")
  pass  <- grab("p")
  if (is.na(email) || !nzchar(email)) {
    return(list(ok = FALSE, msg = "No email line found. The file needs one line starting with e: followed by the email address."))
  }
  if (is.na(pass) || !nzchar(pass)) {
    return(list(ok = FALSE, email = email, msg = "No password line found. The file needs a separate line starting with p: followed by the password."))
  }
  if (!grepl("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", email)) {
    return(list(ok = FALSE, email = email, msg = "The text after e: does not look like an email address."))
  }
  list(ok = TRUE, email = email, pass = pass, msg = "")
}

# ---- iCalendar text ------------------------------------------------------------

titan_ics_escape <- function(x) {
  x <- ifelse(is.na(x), "", x)
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub(";", "\\;", x, fixed = TRUE)
  x <- gsub(",", "\\,", x, fixed = TRUE)
  x <- gsub("\r\n|\r|\n", "\\n", x)
  x
}

# Fold a content line to at most 75 octets (RFC 5545 3.1) without splitting
# multi-byte UTF-8 characters.
titan_ics_fold <- function(line) {
  if (nchar(line, type = "bytes") <= 75) return(line)
  line <- enc2utf8(line)
  chars <- strsplit(line, "")[[1]]
  out <- character()
  cur <- ""
  limit <- 75
  for (ch in chars) {
    if (nchar(cur, type = "bytes") + nchar(ch, type = "bytes") > limit) {
      out <- c(out, cur)
      cur <- ""
      limit <- 74
    }
    cur <- paste0(cur, ch)
  }
  out <- c(out, cur)
  paste0(c(out[1], paste0(" ", out[-1])), collapse = "\r\n")
}

titan_ics_utc <- function(t) format(t, "%Y%m%dT%H%M%SZ", tz = "UTC")

titan_new_uid <- function() paste0(uuid::UUIDgenerate(), "@titan-events-app")

# One-event VCALENDAR (CRLF). start/end POSIXct are written in UTC.
# alarms = integer minutes before start.
titan_build_event_ics <- function(title, start, end, all_day = FALSE,
                                  location = "", description = "",
                                  alarms = integer(), uid = titan_new_uid()) {
  lines <- c(
    "BEGIN:VCALENDAR", "VERSION:2.0",
    "PRODID:-//Business Operations Suite//Titan Events//EN",
    "CALSCALE:GREGORIAN", "BEGIN:VEVENT",
    paste0("UID:", uid),
    paste0("DTSTAMP:", titan_ics_utc(Sys.time()))
  )
  if (isTRUE(all_day)) {
    lines <- c(lines,
      paste0("DTSTART;VALUE=DATE:", format(as.Date(start), "%Y%m%d")),
      paste0("DTEND;VALUE=DATE:", format(as.Date(end), "%Y%m%d")))
  } else {
    lines <- c(lines,
      paste0("DTSTART:", titan_ics_utc(start)),
      paste0("DTEND:", titan_ics_utc(end)))
  }
  lines <- c(lines, paste0("SUMMARY:", titan_ics_escape(title)))
  if (nzchar(titan_or(location, ""))) lines <- c(lines, paste0("LOCATION:", titan_ics_escape(location)))
  if (nzchar(titan_or(description, ""))) lines <- c(lines, paste0("DESCRIPTION:", titan_ics_escape(description)))
  for (m in sort(unique(as.integer(alarms)))) {
    lines <- c(lines, "BEGIN:VALARM", "ACTION:DISPLAY",
               paste0("DESCRIPTION:", titan_ics_escape(title)),
               paste0("TRIGGER:-PT", m, "M"), "END:VALARM")
  }
  lines <- c(lines, "END:VEVENT", "END:VCALENDAR")
  paste0(paste(vapply(lines, titan_ics_fold, ""), collapse = "\r\n"), "\r\n")
}

titan_ics_unfold <- function(text) {
  text <- gsub("\r\n", "\n", text, fixed = TRUE)
  text <- gsub("\n[ \t]", "", text)
  l <- strsplit(text, "\n", fixed = TRUE)[[1]]
  l <- sub("[ \t\r]+$", "", l)
  l[nzchar(trimws(l))]
}

# Several single-event calendars -> one downloadable file.
titan_combine_ics <- function(ics_list) {
  bodies <- vapply(ics_list, function(x) {
    l <- titan_ics_unfold(x)
    i <- which(l == "BEGIN:VEVENT")[1]
    j <- tail(which(l == "END:VEVENT"), 1)
    paste(vapply(l[i:j], titan_ics_fold, ""), collapse = "\r\n")
  }, "")
  paste0(paste(c("BEGIN:VCALENDAR", "VERSION:2.0",
                 "PRODID:-//Business Operations Suite//Titan Events//EN", "CALSCALE:GREGORIAN",
                 bodies, "END:VCALENDAR"), collapse = "\r\n"), "\r\n")
}

# "Floating" local times (DTSTART:20261008T093000, no Z, no TZID) are what the
# suite's own .ics export writes. A CalDAV server cannot know their zone, so
# convert them to UTC using the chosen zone before saving. Times that already
# carry Z or TZID, and all-day dates, are left untouched.
titan_float_to_utc <- function(lines, tz = TITAN_DEFAULT_TZ) {
  if (is.null(tz) || !nzchar(tz) || !tz %in% OlsonNames()) tz <- TITAN_DEFAULT_TZ
  pat <- "^(DTSTART|DTEND|RECURRENCE-ID)(;VALUE=DATE-TIME)?:([0-9]{8}T[0-9]{6})$"
  hit <- grepl(pat, lines)
  for (k in which(hit)) {
    key <- sub(pat, "\\1", lines[k])
    val <- sub(pat, "\\3", lines[k])
    t <- as.POSIXct(val, format = "%Y%m%dT%H%M%S", tz = tz)
    if (is.na(t)) t <- as.POSIXct(val, format = "%Y%m%dT%H%M%S", tz = "UTC")  # DST gap: keep wall time
    lines[k] <- paste0(key, ":", format(t, "%Y%m%dT%H%M%SZ", tz = "UTC"))
  }
  lines
}

# Split an .ics into one CalDAV-ready calendar per UID. METHOD is dropped (not
# allowed in stored CalDAV objects); VTIMEZONEs are copied to each piece.
titan_split_ics <- function(text, float_tz = TITAN_DEFAULT_TZ) {
  l <- titan_ics_unfold(text)
  l <- titan_float_to_utc(l, float_tz)
  block <- function(name) {
    s <- which(l == paste0("BEGIN:", name))
    e <- which(l == paste0("END:", name))
    n <- min(length(s), length(e))
    if (!n) return(list())
    Map(function(a, b) l[a:b], s[seq_len(n)], e[seq_len(n)])
  }
  tz <- unlist(block("VTIMEZONE"))
  events <- block("VEVENT")
  if (!length(events)) stop("No events (VEVENT) found in the file.")

  uid_of <- function(ev) {
    u <- grep("^UID[;:]", ev, value = TRUE)[1]
    if (is.na(u)) NA_character_ else sub("^UID[^:]*:", "", u)
  }
  uids <- vapply(events, uid_of, "")
  for (k in which(is.na(uids))) {
    uids[k] <- titan_new_uid()
    events[[k]] <- append(events[[k]], paste0("UID:", uids[k]), after = 1)
  }
  lapply(unique(uids), function(u) {
    evs <- unlist(events[uids == u])
    first <- events[[which(uids == u)[1]]]
    summary <- sub("^SUMMARY[^:]*:", "", grep("^SUMMARY[;:]", first, value = TRUE)[1])
    start <- sub("^DTSTART", "", grep("^DTSTART[;:]", first, value = TRUE)[1])
    lines <- c("BEGIN:VCALENDAR", "VERSION:2.0",
               "PRODID:-//Business Operations Suite//Titan Events//EN", tz, evs, "END:VCALENDAR")
    list(uid = u,
         summary = ifelse(is.na(summary), "(no title)", summary),
         start = ifelse(is.na(start), "", start),
         alarms = sum(evs == "BEGIN:VALARM"),
         ics = paste0(paste(vapply(lines, titan_ics_fold, ""), collapse = "\r\n"), "\r\n"))
  })
}

# ---- CalDAV requests -----------------------------------------------------------

titan_dav_request <- function(url, user, pass, method, body = NULL, depth = NULL,
                              headers = list(), timeout = 30) {
  req <- httr2::request(url)
  req <- httr2::req_auth_basic(req, user, pass)
  req <- httr2::req_method(req, method)
  req <- httr2::req_user_agent(req, "titan-events-shiny/1.0")
  req <- httr2::req_timeout(req, timeout)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  if (!is.null(depth)) req <- httr2::req_headers(req, Depth = depth)
  if (length(headers)) req <- do.call(httr2::req_headers, c(list(req), headers))
  if (!is.null(body)) {
    type <- if (method == "PUT") "text/calendar; charset=utf-8" else "application/xml; charset=utf-8"
    req <- httr2::req_body_raw(req, body, type = type)
  }
  httr2::req_perform(req)
}

titan_propfind_body <- function(props) {
  paste0('<?xml version="1.0" encoding="utf-8"?>',
         '<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav" ',
         'xmlns:cs="http://calendarserver.org/ns/"><d:prop>',
         paste(props, collapse = ""), '</d:prop></d:propfind>')
}

titan_dav_responses <- function(resp) {
  if (httr2::resp_status(resp) != 207) {
    stop(sprintf("Server answered HTTP %d %s", httr2::resp_status(resp),
                 titan_or(httr2::resp_status_desc(resp), "")), call. = FALSE)
  }
  doc <- xml2::read_xml(httr2::resp_body_raw(resp))
  xml2::xml_find_all(doc, "//*[local-name()='response']")
}

titan_lx <- function(node, path) {
  xml2::xml_find_first(node, paste0(".//", paste0("*[local-name()='", strsplit(path, "/")[[1]], "']", collapse = "/")))
}


titan_xml_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

titan_abs_url <- function(href, base) xml2::url_absolute(trimws(href), base)

titan_ensure_slash <- function(u) if (grepl("/$", u)) u else paste0(u, "/")

titan_auth_fail <- function(resp) {
  if (httr2::resp_status(resp) == 401) {
    stop("Sign-in rejected (HTTP 401). Check the email and password in authenticateT.R; if the ",
         "account uses two-factor sign-in, use an app password.", call. = FALSE)
  }
}

# ---- Calendar discovery ----------------------------------------------------------
# Tries every common CalDAV layout and records each request so failures can be
# diagnosed. Returns list(calendars = data.frame(name, url), trace = data.frame).

titan_calendars_in <- function(resp) {
  res <- titan_dav_responses(resp)
  out <- lapply(res, function(n) {
    rt <- titan_lx(n, "resourcetype")
    if (inherits(rt, "xml_missing")) return(NULL)
    kinds <- xml2::xml_name(xml2::xml_children(rt))
    url <- titan_abs_url(xml2::xml_text(titan_lx(n, "href")), httr2::resp_url(resp))
    name <- xml2::xml_text(titan_lx(n, "displayname"))
    if (is.na(name) || !nzchar(name)) name <- utils::URLdecode(basename(sub("/$", "", url)))
    comps <- xml2::xml_attr(xml2::xml_find_all(n, ".//*[local-name()='comp']"), "name")
    data.frame(name = name, url = url,
               is_calendar = "calendar" %in% kinds && (!length(comps) || "VEVENT" %in% comps),
               is_collection = "collection" %in% kinds, stringsAsFactors = FALSE)
  })
  do.call(rbind, out)
}

titan_discover_calendars <- function(server, user, pass) {
  server <- sub("/+$", "", trimws(server))
  if (!grepl("^https?://", server)) server <- paste0("https://", server)
  enc <- utils::URLencode(user, reserved = TRUE)

  trace <- data.frame(step = character(), url = character(), status = character(),
                      note = character(), stringsAsFactors = FALSE)
  call <- function(step, url, body, depth) {
    r <- tryCatch(titan_dav_request(url, user, pass, "PROPFIND", body, depth = depth),
                  error = function(e) e)
    if (inherits(r, "error")) {
      trace[nrow(trace) + 1, ] <<- list(step, url, "no response", conditionMessage(r))
      return(NULL)
    }
    note <- if (httr2::resp_status(r) == 207) "" else
      substr(gsub("\\s+", " ", tryCatch(httr2::resp_body_string(r), error = function(e) "")), 1, 160)
    if (httr2::resp_url(r) != url) note <- paste("redirected to", httr2::resp_url(r), note)
    trace[nrow(trace) + 1, ] <<- list(step, url, as.character(httr2::resp_status(r)), note)
    r
  }
  ok <- function(r) !is.null(r) && httr2::resp_status(r) == 207
  href_of <- function(r, path) {
    h <- tryCatch(xml2::xml_text(titan_lx(titan_dav_responses(r)[[1]], path)), error = function(e) NA)
    if (is.na(h) || !nzchar(trimws(h))) NULL else titan_abs_url(h, httr2::resp_url(r))
  }

  candidates <- unique(c(
    paste0(server, "/principals/", user),
    paste0(server, "/principals/", user, "/"),
    paste0(server, "/principals/", enc, "/"),
    paste0(server, "/.well-known/caldav"),
    paste0(server, "/")
  ))
  principal <- NULL
  for (u in candidates) {
    r <- call("find principal", u, titan_propfind_body("<d:current-user-principal/>"), "0")
    if (!ok(r)) next
    principal <- titan_or(href_of(r, "current-user-principal/href"), httr2::resp_url(r))
    break
  }

  homes <- character()
  if (!is.null(principal)) {
    r <- call("calendar home", principal, titan_propfind_body("<c:calendar-home-set/>"), "0")
    if (ok(r)) homes <- c(homes, href_of(r, "calendar-home-set/href"))
    homes <- c(homes, principal)
  }
  homes <- unique(c(homes, paste0(server, "/principals/", user, "/calendar/"),
                    paste0(server, "/principals/", user, "/")))

  list_body <- titan_propfind_body(c("<d:displayname/>", "<d:resourcetype/>",
                                     "<c:supported-calendar-component-set/>"))
  found <- NULL
  for (h in homes) {
    r <- call("list calendars", titan_ensure_slash(h), list_body, "1")
    if (!ok(r)) next
    items <- tryCatch(titan_calendars_in(r), error = function(e) NULL)
    if (is.null(items)) next
    found <- rbind(found, items[items$is_calendar, c("name", "url")])
    if (!is.null(found) && nrow(found)) break
    subs <- items$url[items$is_collection & !items$is_calendar &
                      sub("/$", "", items$url) != sub("/$", "", httr2::resp_url(r))]
    for (sub_url in head(subs, 10)) {
      r2 <- call("list calendars", titan_ensure_slash(sub_url), list_body, "1")
      if (!ok(r2)) next
      it2 <- tryCatch(titan_calendars_in(r2), error = function(e) NULL)
      if (!is.null(it2)) found <- rbind(found, it2[it2$is_calendar, c("name", "url")])
    }
    if (!is.null(found) && nrow(found)) break
  }

  if (!is.null(found) && nrow(found)) {
    found <- found[!duplicated(found$url), ]
    rownames(found) <- NULL
    return(list(calendars = found, trace = trace))
  }

  codes <- trace$status
  msg <- if (!length(codes) || all(codes == "no response")) {
    paste0("Couldn't reach ", server, ". Check the internet connection, VPN or firewall.")
  } else if (any(codes == "401") && !any(codes == "207")) {
    paste0("The server rejected the email/password (HTTP 401) on every address tried. ",
           "Use the full email address and the mailbox password (the one used for webmail ",
           "and the Titan app, not the GoDaddy account password).")
  } else if (any(codes == "207")) {
    "Signed in, but no calendars were found. See the Log tab for what the server returned."
  } else {
    paste0("The server didn't accept the calendar requests (", paste(unique(codes), collapse = ", "),
           "). Try another server option; details are in the Log tab.")
  }
  err <- simpleError(msg)
  err$trace <- trace
  stop(err)
}

# Save one calendar object. Returns list(ok, status, message, url).
titan_put_event <- function(calendar_url, user, pass, ics, uid, overwrite = FALSE) {
  file <- paste0(gsub("[^A-Za-z0-9._-]", "_", uid), ".ics")
  url <- paste0(titan_ensure_slash(calendar_url), file)
  hdr <- if (overwrite) list() else list(`If-None-Match` = "*")
  r <- tryCatch(titan_dav_request(url, user, pass, "PUT", body = ics, headers = hdr),
                error = function(e) e)
  if (inherits(r, "error")) return(list(ok = FALSE, status = NA, message = conditionMessage(r), url = url))
  s <- httr2::resp_status(r)
  msg <- switch(as.character(s),
    "201" = "Created", "204" = "Updated",
    "412" = "Already exists (same UID) - not overwritten",
    "401" = "Sign-in rejected", "403" = "Not allowed by the server",
    paste("HTTP", s, tryCatch(substr(httr2::resp_body_string(r), 1, 200), error = function(e) ""))
  )
  list(ok = s %in% c(200, 201, 204), status = s, message = msg, url = url)
}

# DTSTART/DTEND line -> POSIXct (UTC, TZID or date-only). NA if unreadable.
titan_parse_ics_time <- function(line) {
  na <- as.POSIXct(NA_character_, tz = "UTC")
  if (length(line) != 1 || is.na(line) || !nzchar(line)) return(na)
  value <- trimws(sub("^[^:]*:", "", line))
  params <- sub(":.*$", "", line)
  tz <- if (grepl("TZID=", params, ignore.case = TRUE))
    gsub('"', "", sub(".*TZID=([^;]+).*", "\\1", params, ignore.case = TRUE)) else "UTC"
  if (!tz %in% OlsonNames()) tz <- "UTC"
  t <- tryCatch({
    if (grepl("^[0-9]{8}$", value)) as.POSIXct(value, format = "%Y%m%d", tz = tz)
    else if (grepl("Z$", value)) as.POSIXct(value, format = "%Y%m%dT%H%M%SZ", tz = "UTC")
    else as.POSIXct(value, format = "%Y%m%dT%H%M%S", tz = tz)
  }, error = function(e) na)
  if (length(t) != 1) return(na)
  attr(t, "tzone") <- "UTC"
  t
}

# Summarise the first VEVENT of a calendar text. NULL if there is none.
titan_parse_vevent <- function(data) {
  if (length(data) != 1 || is.na(data) || !nzchar(trimws(data))) return(NULL)
  l <- trimws(titan_ics_unfold(data), which = "right")
  up <- toupper(l)
  i <- which(up == "BEGIN:VEVENT")[1]
  if (is.na(i)) return(NULL)
  j <- which(up == "END:VEVENT" & seq_along(up) > i)[1]
  if (is.na(j)) j <- length(l)
  ev <- l[i:j]
  get <- function(p) {
    v <- grep(paste0("^", p, "[;:]"), ev, value = TRUE, ignore.case = TRUE)[1]
    if (is.na(v)) "" else v
  }
  start <- titan_parse_ics_time(get("DTSTART"))
  end <- titan_parse_ics_time(get("DTEND"))
  if (is.na(end) && !is.na(start)) end <- start
  title <- sub("^SUMMARY[^:]*:", "", get("SUMMARY"), ignore.case = TRUE)
  list(start = start, end = end,
       title = if (nzchar(title)) gsub("\\\\([,;\\\\])", "\\1", title) else "(no title)",
       alarms = sum(toupper(ev) == "BEGIN:VALARM"))
}

titan_empty_events <- function() {
  data.frame(start = as.POSIXct(character(), tz = "UTC"), end = as.POSIXct(character(), tz = "UTC"),
             title = character(), alarms = integer(), href = character(), stringsAsFactors = FALSE)
}

titan_get_event_raw <- function(href, user, pass) {
  r <- titan_dav_request(href, user, pass, "GET")
  if (httr2::resp_status(r) != 200) stop("HTTP ", httr2::resp_status(r))
  httr2::resp_body_string(r, encoding = "UTF-8")
}

titan_delete_event <- function(href, user, pass) {
  r <- titan_dav_request(href, user, pass, "DELETE")
  httr2::resp_status(r) %in% c(200, 204)
}

# Events between two times. Returns data.frame(start, end, title, alarms, href)
# with attributes `skipped` (items not read within the time budget) and
# `sample` (start of the server's answer, for the Log when something is skipped).
# Per the HANDOVER notes: a calendar-query REPORT first; items the server
# returns WITHOUT calendar-data are fetched with calendar-multiget in batches
# of 50 inside a total time budget, never one GET per event (that froze the app).
titan_list_events <- function(calendar_url, user, pass, from, to, budget = 25) {
  t0 <- Sys.time()
  cal <- titan_ensure_slash(calendar_url)
  attr(from, "tzone") <- "UTC"; attr(to, "tzone") <- "UTC"
  body <- paste0(
    '<?xml version="1.0" encoding="utf-8"?>',
    '<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">',
    '<d:prop><d:getetag/><c:calendar-data/></d:prop>',
    '<c:filter><c:comp-filter name="VCALENDAR"><c:comp-filter name="VEVENT">',
    '<c:time-range start="', titan_ics_utc(from), '" end="', titan_ics_utc(to), '"/>',
    '</c:comp-filter></c:comp-filter></c:filter></c:calendar-query>')
  r <- titan_dav_request(cal, user, pass, "REPORT", body, depth = "1")
  titan_auth_fail(r)

  sample_txt <- ""
  if (httr2::resp_status(r) == 207) {
    sample_txt <- substr(tryCatch(httr2::resp_body_string(r), error = function(e) ""), 1, 400)
    res <- titan_dav_responses(r)
    items <- lapply(res, function(n) {
      list(href = titan_abs_url(xml2::xml_text(titan_lx(n, "href")), httr2::resp_url(r)),
           data = xml2::xml_text(titan_lx(n, "calendar-data")))
    })
  } else {
    r2 <- titan_dav_request(cal, user, pass, "PROPFIND", titan_propfind_body("<d:getetag/>"), depth = "1")
    titan_auth_fail(r2)
    sample_txt <- substr(tryCatch(httr2::resp_body_string(r2), error = function(e) ""), 1, 400)
    res <- titan_dav_responses(r2)
    items <- lapply(res, function(n) list(href = titan_abs_url(xml2::xml_text(titan_lx(n, "href")), httr2::resp_url(r2)),
                                          data = NA_character_))
  }
  items <- Filter(function(x) sub("/$", "", x$href) != sub("/$", "", cal), items)

  parsed <- lapply(items, function(x) titan_parse_vevent(x$data))
  need <- which(vapply(seq_along(items), function(i) {
    is.null(parsed[[i]]) && (is.na(items[[i]]$data) || !nzchar(trimws(items[[i]]$data)))
  }, logical(1)))

  skipped <- 0L
  if (length(need)) {
    batches <- split(need, ceiling(seq_along(need) / 50))
    for (b in batches) {
      if (as.numeric(difftime(Sys.time(), t0, units = "secs")) > budget) { skipped <- skipped + length(b); next }
      hrefs <- vapply(items[b], function(x) httr2::url_parse(x$href)$path, "")
      mg <- paste0(
        '<?xml version="1.0" encoding="utf-8"?>',
        '<c:calendar-multiget xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">',
        '<d:prop><d:getetag/><c:calendar-data/></d:prop>',
        paste0("<d:href>", titan_xml_escape(hrefs), "</d:href>", collapse = ""),
        '</c:calendar-multiget>')
      mr <- tryCatch(titan_dav_request(cal, user, pass, "REPORT", mg, depth = "1"), error = function(e) NULL)
      if (is.null(mr) || httr2::resp_status(mr) != 207) { skipped <- skipped + length(b); next }
      got <- tryCatch(titan_dav_responses(mr), error = function(e) NULL)
      if (is.null(got)) { skipped <- skipped + length(b); next }
      for (n in got) {
        h <- titan_abs_url(xml2::xml_text(titan_lx(n, "href")), httr2::resp_url(mr))
        k <- b[which(vapply(items[b], function(x) sub("/$", "", x$href) == sub("/$", "", h), logical(1)))[1]]
        if (is.na(k)) next
        parsed[[k]] <- titan_parse_vevent(xml2::xml_text(titan_lx(n, "calendar-data")))
      }
    }
  }

  rows <- lapply(seq_along(items), function(i) {
    ev <- parsed[[i]]
    if (is.null(ev)) return(NULL)
    data.frame(start = ev$start, end = ev$end, title = ev$title, alarms = ev$alarms,
               href = items[[i]]$href, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  if (is.null(out) || !nrow(out)) out <- titan_empty_events()
  else {
    keep <- is.na(out$start) | (out$end >= from & out$start < to) | (out$start >= from & out$start < to)
    keep[is.na(keep)] <- TRUE
    out <- out[keep, , drop = FALSE]
    out <- out[order(out$start, na.last = TRUE), , drop = FALSE]
    rownames(out) <- NULL
  }
  attr(out, "skipped") <- skipped
  attr(out, "sample") <- sample_txt
  out
}

# ---- Suite events (ics_event objects) -> Titan "Events to save" items -----------

# "-PT15M" / "-PT1H" / "-P1D" / "-P7D" -> minutes before the start
titan_alarm_minutes <- function(alarms) {
  if (length(alarms) == 0) return(integer())
  pat <- "^-?P(?:([0-9]+)D)?(?:T(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9]+)S)?)?$"
  out <- vapply(as.character(alarms), function(a) {
    if (is.na(a) || !grepl(pat, a, perl = TRUE)) return(NA_real_)
    g <- function(k) { v <- sub(pat, paste0("\\", k), a, perl = TRUE); if (nzchar(v)) as.numeric(v) else 0 }
    g(1) * 1440 + g(2) * 60 + g(3) + g(4) / 60
  }, 0)
  as.integer(sort(unique(round(out[!is.na(out)]))))
}

# Local wall-clock (date + minutes after midnight) in zone tz -> POSIXct
titan_local_posix <- function(date, minutes, tz = TITAN_DEFAULT_TZ) bos_tz_local_posix(date, minutes, tz)

# events: list of ics_event() objects (R/utils_ics.R). Returns the same item
# structure the "Events to save" table uses: uid, title, when, start, reminders, ics.
# UIDs are kept (they are deterministic), so re-sending the same plan can
# replace instead of duplicating.
titan_events_to_queue <- function(events, tz = TITAN_DEFAULT_TZ) {
  if (is.null(tz) || !nzchar(tz) || !tz %in% OlsonNames()) tz <- TITAN_DEFAULT_TZ
  out <- list()
  for (ev in events) {
    d <- tryCatch(as.Date(ev$date), error = function(e) NA)
    if (length(d) != 1 || is.na(d)) next
    desc <- if (is.character(ev$description) && length(ev$description) == 1 && !is.na(ev$description)) ev$description else ""
    u <- if (is.character(ev$url) && length(ev$url) == 1 && !is.na(ev$url) && grepl("^https?://", ev$url)) ev$url else ""
    if (nzchar(u)) desc <- trimws(paste0(desc, if (nzchar(desc)) "\n" else "", u))
    loc <- if (is.character(ev$location) && length(ev$location) == 1 && !is.na(ev$location)) ev$location else ""
    ev_tz <- if (!is.null(ev$tz) && length(ev$tz) == 1 && !is.na(ev$tz) && ev$tz %in% OlsonNames()) ev$tz else tz   # saved zone wins
    title <- as.character(titan_or(ev$summary, "(no title)"))[1]
    rem <- titan_alarm_minutes(ev$alarms)
    uid <- as.character(titan_or(ev$uid, titan_new_uid()))[1]
    if (isTRUE(ev$all_day) || is.na(ev$start)) {
      start <- as.POSIXct(format(d), tz = ev_tz)
      end   <- as.POSIXct(format(d + 1), tz = ev_tz)
      when  <- paste(format(d, "%a %d %b %Y"), "(all day)")
      all_day <- TRUE
    } else {
      start <- titan_local_posix(d, ev$start, ev_tz)
      end   <- if (is.na(ev$end)) start + 3600 else titan_local_posix(d, ev$end, ev_tz)
      if (end <= start) end <- start + 3600
      when  <- format(start, "%a %d %b %Y %H:%M %Z")
      all_day <- FALSE
    }
    out[[length(out) + 1]] <- list(
      uid = uid, title = title, when = when, start = start, reminders = rem, ev = ev, tz = ev_tz,
      ics = titan_build_event_ics(title, start, end, all_day, loc, desc, rem, uid))
  }
  out
}

# Re-renders a queued item (start, "when", reminders, .ics text) in zone tz from
# its stored local wall-clock time, so changing the Events-to-save time zone
# changes what is shown, downloaded and sent. Items without a stored event are
# returned unchanged.
titan_item_in_tz <- function(item, tz) {
  if (is.null(item$ev)) return(item)
  r <- titan_events_to_queue(list(item$ev), tz)
  if (length(r)) r[[1]] else item
}

# ---- Two buttons on every Visualisation tab's calendar-export box ----------------
# Called from inside a visualisation module's server (moduleServer scope), once,
# after its own ics_result() reactive exists. Defines output$titan_buttons and the
# two click handlers. Buttons appear only once the user has authenticated.
titan_viz_hook <- function(input, output, session, api_manager, ics_result, cal_name) {
  ns <- session$ns

  output$titan_buttons <- renderUI({
    st <- api_manager$titan_state()
    if (!isTRUE(st$ok)) {
      return(div(class = "status-info", style = "margin-top: 10px;",
        icon("calendar-check"), " Titan calendar: not signed in. Load your authenticateT.R file under ",
        tags$strong("Events Scheduling > Titan Authentication"), " to enable the calendar-load buttons here."))
    }
    tagList(
      hr(),
      h4(icon("calendar-plus"), " Titan Calendar"),
      p("Signed in to Titan as ", tags$strong(st$email), ". ",
        tags$strong(".ics load to calendar"), " sends this view's .ics to the Import tab; ",
        tags$strong("Load events into calendar"), " puts its events straight into the Events to save list."),
      fluidRow(
        column(4, actionButton(ns("titan_load_ics"), ".ics load to calendar",
                               icon = icon("file-import"), class = "btn-primary", style = "width: 100%;")),
        column(4, actionButton(ns("titan_load_events"), "Load events into calendar",
                               icon = icon("calendar-plus"), class = "btn-success", style = "width: 100%;"))
      )
    )
  })

  get_events <- function() {
    res <- tryCatch(ics_result(), error = function(e) NULL)
    ev <- if (is.null(res)) list() else res$events
    if (length(ev) == 0) {
      showNotification("Nothing to send: load data in this tab first (see the note above the calendar download).",
                       type = "warning", duration = 7)
      return(NULL)
    }
    ev
  }

  go_to <- function(subtab) {
    api_manager$titan_goto(subtab)
    tryCatch(updateTabItems(session$rootScope(), "sidebar_menu", selected = "events_to_calendar"),
             error = function(e) cat("[Titan] could not switch tab:", conditionMessage(e), "\n"))
  }

  observeEvent(input$titan_load_ics, {
    if (!isTRUE(api_manager$titan_state()$ok)) return()
    ev <- get_events(); if (is.null(ev)) return()
    txt <- tryCatch(ics_calendar_text(ev, cal_name), error = function(e) NULL)
    if (is.null(txt)) { showNotification("Could not build the .ics.", type = "error"); return() }
    api_manager$titan_set_pending_ics(txt, label = paste0(cal_name, " (", length(ev), " events)"))
    api_manager$titan_log_add(sprintf("Received .ics from %s: %d event(s) -> Import .ics file tab", cal_name, length(ev)))
    showNotification(sprintf("%d event(s) sent to the Import .ics file tab.", length(ev)), type = "message")
    go_to("import")
  })

  observeEvent(input$titan_load_events, {
    if (!isTRUE(api_manager$titan_state()$ok)) return()
    ev <- get_events(); if (is.null(ev)) return()
    items <- tryCatch(titan_events_to_queue(ev, api_manager$titan_tz), error = function(e) {
      cat("❌ [Titan] could not convert events:", conditionMessage(e), "\n"); NULL })
    if (is.null(items) || length(items) == 0) {
      showNotification("Could not convert these events for the calendar.", type = "error"); return()
    }
    n_new <- api_manager$titan_queue_add(items)
    api_manager$titan_log_add(sprintf("Received %d event(s) from %s into Events to save (%d new)", length(items), cal_name, n_new))
    showNotification(sprintf("%d event(s) added to Events to save (%d already in the list).", n_new, length(items) - n_new),
                     type = "message")
    go_to("new")
  })
}
