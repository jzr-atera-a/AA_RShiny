# caldav.R -----------------------------------------------------------------
# Helpers for building iCalendar events and saving them to a CalDAV server
# (Titan Mail exposes its calendar over CalDAV at dav.titan.email).

suppressPackageStartupMessages({
  library(httr2)
  library(xml2)
})

if (!exists("%||%", baseenv())) `%||%` <- function(a, b) if (is.null(a)) b else a

# ---- iCalendar text -------------------------------------------------------

ics_escape <- function(x) {
  x <- ifelse(is.na(x), "", x)
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub(";", "\\;", x, fixed = TRUE)
  x <- gsub(",", "\\,", x, fixed = TRUE)
  x <- gsub("\r\n|\r|\n", "\\n", x)
  x
}

# Fold a content line to at most 75 octets per line (RFC 5545 3.1),
# without splitting multi-byte UTF-8 characters.
ics_fold <- function(line) {
  if (nchar(line, type = "bytes") <= 75) return(line)
  line <- enc2utf8(line)
  if (Encoding(line) == "unknown" && validUTF8(line)) Encoding(line) <- "UTF-8"
  chars <- strsplit(line, "")[[1]]
  out <- character()
  cur <- ""
  limit <- 75
  for (ch in chars) {
    if (nchar(cur, type = "bytes") + nchar(ch, type = "bytes") > limit) {
      out <- c(out, cur)
      cur <- ""
      limit <- 74 # continuation lines start with a space
    }
    cur <- paste0(cur, ch)
  }
  out <- c(out, cur)
  paste0(c(out[1], paste0(" ", out[-1])), collapse = "\r\n")
}

ics_utc <- function(t) format(t, "%Y%m%dT%H%M%SZ", tz = "UTC")

new_uid <- function() paste0(uuid::UUIDgenerate(), "@titan-events-app")

# Build a full VCALENDAR (one event) as a CRLF-terminated string.
#   start, end : POSIXct (any time zone; written as UTC)
#   alarms     : integer minutes before start, e.g. c(10, 60)
build_event_ics <- function(title, start, end, all_day = FALSE,
                            location = "", description = "",
                            alarms = integer(), uid = new_uid()) {
  lines <- c(
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Titan Events Shiny App//EN",
    "CALSCALE:GREGORIAN",
    "BEGIN:VEVENT",
    paste0("UID:", uid),
    paste0("DTSTAMP:", ics_utc(Sys.time()))
  )
  if (all_day) {
    lines <- c(lines,
      paste0("DTSTART;VALUE=DATE:", format(as.Date(start), "%Y%m%d")),
      paste0("DTEND;VALUE=DATE:", format(as.Date(end), "%Y%m%d"))
    )
  } else {
    lines <- c(lines,
      paste0("DTSTART:", ics_utc(start)),
      paste0("DTEND:", ics_utc(end))
    )
  }
  lines <- c(lines, paste0("SUMMARY:", ics_escape(title)))
  if (nzchar(location %||% "")) lines <- c(lines, paste0("LOCATION:", ics_escape(location)))
  if (nzchar(description %||% "")) lines <- c(lines, paste0("DESCRIPTION:", ics_escape(description)))
  for (m in sort(unique(as.integer(alarms)))) {
    lines <- c(lines,
      "BEGIN:VALARM",
      "ACTION:DISPLAY",
      paste0("DESCRIPTION:", ics_escape(title)),
      paste0("TRIGGER:-PT", m, "M"),
      "END:VALARM"
    )
  }
  lines <- c(lines, "END:VEVENT", "END:VCALENDAR")
  paste0(paste(vapply(lines, ics_fold, ""), collapse = "\r\n"), "\r\n")
}

# Combine several single-event calendars into one file for download.
combine_ics <- function(ics_list) {
  bodies <- vapply(ics_list, function(x) {
    l <- ics_unfold(x)
    i <- which(l == "BEGIN:VEVENT")[1]
    j <- tail(which(l == "END:VEVENT"), 1)
    paste(vapply(l[i:j], ics_fold, ""), collapse = "\r\n")
  }, "")
  paste0(paste(c("BEGIN:VCALENDAR", "VERSION:2.0",
                 "PRODID:-//Titan Events Shiny App//EN", "CALSCALE:GREGORIAN",
                 bodies, "END:VCALENDAR"), collapse = "\r\n"), "\r\n")
}

# ---- Reading existing .ics files -----------------------------------------

ics_unfold <- function(text) {
  text <- gsub("\r\n", "\n", text, fixed = TRUE)
  text <- gsub("\n[ \t]", "", text)
  l <- strsplit(text, "\n", fixed = TRUE)[[1]]
  l[nzchar(trimws(l))]
}

# Split an uploaded .ics into one CalDAV-ready calendar per UID.
# CalDAV stores one event (UID) per resource and forbids METHOD there,
# so METHOD is dropped and time zone definitions are copied to each piece.
split_ics <- function(text) {
  l <- ics_unfold(text)
  block <- function(name) {
    s <- which(l == paste0("BEGIN:", name))
    e <- which(l == paste0("END:", name))
    Map(function(a, b) l[a:b], s, e[seq_along(s)])
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
    uids[k] <- new_uid()
    ev <- events[[k]]
    events[[k]] <- append(ev, paste0("UID:", uids[k]), after = 1)
  }
  lapply(unique(uids), function(u) {
    evs <- unlist(events[uids == u])
    first <- events[[which(uids == u)[1]]]
    summary <- sub("^SUMMARY[^:]*:", "", grep("^SUMMARY[;:]", first, value = TRUE)[1])
    start <- sub("^DTSTART", "", grep("^DTSTART[;:]", first, value = TRUE)[1])
    lines <- c("BEGIN:VCALENDAR", "VERSION:2.0",
               "PRODID:-//Titan Events Shiny App//EN", tz, evs, "END:VCALENDAR")
    list(uid = u,
         summary = ifelse(is.na(summary), "(no title)", summary),
         start = ifelse(is.na(start), "", start),
         alarms = sum(evs == "BEGIN:VALARM"),
         ics = paste0(paste(vapply(lines, ics_fold, ""), collapse = "\r\n"), "\r\n"))
  })
}

# ---- CalDAV requests ------------------------------------------------------

dav_request <- function(url, user, pass, method, body = NULL, depth = NULL,
                        headers = list()) {
  req <- request(url) |>
    req_auth_basic(user, pass) |>
    req_method(method) |>
    req_user_agent("titan-events-shiny/1.0") |>
    req_timeout(30) |>
    req_error(is_error = function(resp) FALSE)
  if (!is.null(depth)) req <- req_headers(req, Depth = depth)
  if (length(headers)) req <- req_headers(req, !!!headers)
  if (!is.null(body)) {
    type <- if (method == "PUT") "text/calendar; charset=utf-8" else "application/xml; charset=utf-8"
    req <- req_body_raw(req, body, type = type)
  }
  req_perform(req)
}

propfind_body <- function(props) {
  paste0('<?xml version="1.0" encoding="utf-8"?>',
         '<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav" ',
         'xmlns:cs="http://calendarserver.org/ns/"><d:prop>',
         paste(props, collapse = ""), '</d:prop></d:propfind>')
}

# Parse a 207 Multi-Status response into a list of <response> nodes.
dav_responses <- function(resp) {
  if (resp_status(resp) != 207) {
    stop(sprintf("Server answered HTTP %d %s", resp_status(resp),
                 resp_status_desc(resp) %||% ""), call. = FALSE)
  }
  doc <- read_xml(resp_body_raw(resp))
  xml_find_all(doc, "//*[local-name()='response']")
}

lx <- function(node, path) {
  xml_find_first(node, paste0(".//", paste0("*[local-name()='", strsplit(path, "/")[[1]], "']", collapse = "/")))
}

abs_url <- function(href, base) url_absolute(trimws(href), base)

auth_fail <- function(resp) {
  if (resp_status(resp) == 401) {
    stop("Sign-in rejected (HTTP 401). Check the email and password; if the ",
         "account uses two-factor sign-in, use an app password.", call. = FALSE)
  }
}

# ---- Calendar discovery ----------------------------------------------------
# Tries every common CalDAV layout (Titan, GoDaddy Professional Email powered
# by Titan, generic servers) and records each request so failures can be
# diagnosed. Returns list(calendars = data.frame(name, url), trace = data.frame).

calendars_in <- function(resp) {
  res <- dav_responses(resp)
  out <- lapply(res, function(n) {
    rt <- lx(n, "resourcetype")
    if (inherits(rt, "xml_missing")) return(NULL)
    kinds <- xml_name(xml_children(rt))
    url <- abs_url(xml_text(lx(n, "href")), resp_url(resp))
    name <- xml_text(lx(n, "displayname"))
    if (is.na(name) || !nzchar(name)) name <- utils::URLdecode(basename(sub("/$", "", url)))
    comps <- xml_attr(xml_find_all(n, ".//*[local-name()='comp']"), "name")
    data.frame(name = name, url = url,
               is_calendar = "calendar" %in% kinds && (!length(comps) || "VEVENT" %in% comps),
               is_collection = "collection" %in% kinds)
  })
  do.call(rbind, out)
}

discover_calendars <- function(server, user, pass) {
  server <- sub("/+$", "", trimws(server))
  if (!grepl("^https?://", server)) server <- paste0("https://", server)
  enc <- utils::URLencode(user, reserved = TRUE)

  trace <- data.frame(step = character(), url = character(), status = character(), note = character())
  call <- function(step, url, body, depth) {
    r <- tryCatch(dav_request(url, user, pass, "PROPFIND", body, depth = depth),
                  error = function(e) e)
    if (inherits(r, "error")) {
      trace[nrow(trace) + 1, ] <<- list(step, url, "no response", conditionMessage(r))
      return(NULL)
    }
    note <- if (resp_status(r) == 207) "" else
      substr(gsub("\\s+", " ", tryCatch(resp_body_string(r), error = function(e) "")), 1, 160)
    if (resp_url(r) != url) note <- paste("redirected to", resp_url(r), note)
    trace[nrow(trace) + 1, ] <<- list(step, url, as.character(resp_status(r)), note)
    r
  }
  ok <- function(r) !is.null(r) && resp_status(r) == 207
  href_of <- function(r, path) {
    h <- tryCatch(xml_text(lx(dav_responses(r)[[1]], path)), error = function(e) NA)
    if (is.na(h) || !nzchar(trimws(h))) NULL else abs_url(h, resp_url(r))
  }

  # 1. Find the principal (who the user is on this server)
  candidates <- unique(c(
    paste0(server, "/principals/", user),        # GoDaddy Titan documented URL
    paste0(server, "/principals/", user, "/"),
    paste0(server, "/principals/", enc, "/"),
    paste0(server, "/.well-known/caldav"),
    paste0(server, "/")
  ))
  principal <- NULL
  for (u in candidates) {
    r <- call("find principal", u, propfind_body("<d:current-user-principal/>"), "0")
    if (!ok(r)) next
    principal <- href_of(r, "current-user-principal/href") %||% resp_url(r)
    break
  }

  # 2. Find the calendar home and list calendars in it
  homes <- character()
  if (!is.null(principal)) {
    r <- call("calendar home", principal, propfind_body("<c:calendar-home-set/>"), "0")
    if (ok(r)) homes <- c(homes, href_of(r, "calendar-home-set/href"))
    homes <- c(homes, principal)
  }
  homes <- unique(c(homes, paste0(server, "/principals/", user, "/calendar/"),
                    paste0(server, "/principals/", user, "/")))

  list_body <- propfind_body(c("<d:displayname/>", "<d:resourcetype/>",
                               "<c:supported-calendar-component-set/>"))
  found <- NULL
  for (h in homes) {
    r <- call("list calendars", ensure_slash(h), list_body, "1")
    if (!ok(r)) next
    items <- tryCatch(calendars_in(r), error = function(e) NULL)
    if (is.null(items)) next
    found <- rbind(found, items[items$is_calendar, c("name", "url")])
    if (!is.null(found) && nrow(found)) break
    # Titan nests calendars one level deeper (.../principals/<email>/calendar/<id>/)
    subs <- items$url[items$is_collection & !items$is_calendar &
                      sub("/$", "", items$url) != sub("/$", "", resp_url(r))]
    for (sub_url in head(subs, 10)) {
      r2 <- call("list calendars", ensure_slash(sub_url), list_body, "1")
      if (!ok(r2)) next
      it2 <- tryCatch(calendars_in(r2), error = function(e) NULL)
      if (!is.null(it2)) found <- rbind(found, it2[it2$is_calendar, c("name", "url")])
    }
    if (!is.null(found) && nrow(found)) break
  }

  if (!is.null(found) && nrow(found)) {
    found <- found[!duplicated(found$url), ]
    return(list(calendars = found, trace = trace))
  }

  codes <- trace$status
  msg <- if (all(codes == "no response")) {
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

ensure_slash <- function(u) if (grepl("/$", u)) u else paste0(u, "/")

# Save one calendar object. Returns list(ok, status, message, url).
put_event <- function(calendar_url, user, pass, ics, uid, overwrite = FALSE) {
  file <- paste0(gsub("[^A-Za-z0-9._-]", "_", uid), ".ics")
  url <- paste0(ensure_slash(calendar_url), file)
  hdr <- if (overwrite) list() else list(`If-None-Match` = "*")
  r <- tryCatch(dav_request(url, user, pass, "PUT", body = ics, headers = hdr),
                error = function(e) e)
  if (inherits(r, "error")) return(list(ok = FALSE, status = NA, message = conditionMessage(r), url = url))
  s <- resp_status(r)
  msg <- switch(as.character(s),
    "201" = "Created", "204" = "Updated",
    "412" = "Already exists (same UID) - not overwritten",
    "401" = "Sign-in rejected", "403" = "Not allowed by the server",
    paste("HTTP", s, tryCatch(substr(resp_body_string(r), 1, 200), error = function(e) ""))
  )
  list(ok = s %in% c(200, 201, 204), status = s, message = msg, url = url)
}

# Summarise the first VEVENT of a calendar text. Returns NULL if there is none.
parse_vevent <- function(data) {
  if (is.na(data) || !nzchar(trimws(data))) return(NULL)
  l <- trimws(ics_unfold(data), which = "right")
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
  start <- parse_ics_time(get("DTSTART"))
  end <- parse_ics_time(get("DTEND"))
  if (is.na(end) && !is.na(start)) end <- start
  title <- sub("^SUMMARY[^:]*:", "", get("SUMMARY"), ignore.case = TRUE)
  list(start = start, end = end,
       title = if (nzchar(title)) gsub("\\\\([,;\\\\])", "\\1", title) else "(no title)",
       alarms = sum(toupper(ev) == "BEGIN:VALARM"))
}

empty_events <- function() {
  data.frame(start = as.POSIXct(character(), tz = "UTC"), end = as.POSIXct(character(), tz = "UTC"),
             title = character(), alarms = integer(), href = character())
}

# List events between two times. Returns data.frame(start, end, title, alarms, href).
# Uses a CalDAV calendar-query; if the server's answer is incomplete it falls back
# to downloading each event, and it never fails because of one odd event.
list_events <- function(calendar_url, user, pass, from, to) {
  cal <- ensure_slash(calendar_url)
  attr(from, "tzone") <- "UTC"; attr(to, "tzone") <- "UTC"
  body <- paste0(
    '<?xml version="1.0" encoding="utf-8"?>',
    '<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">',
    '<d:prop><d:getetag/><c:calendar-data/></d:prop>',
    '<c:filter><c:comp-filter name="VCALENDAR"><c:comp-filter name="VEVENT">',
    '<c:time-range start="', ics_utc(from), '" end="', ics_utc(to), '"/>',
    '</c:comp-filter></c:comp-filter></c:filter></c:calendar-query>')
  r <- dav_request(cal, user, pass, "REPORT", body, depth = "1")
  auth_fail(r)

  items <- NULL
  if (resp_status(r) == 207) {
    res <- dav_responses(r)
    items <- lapply(res, function(n) {
      list(href = abs_url(xml_text(lx(n, "href")), resp_url(r)),
           data = xml_text(lx(n, "calendar-data")))
    })
  } else {
    # Fallback: list every resource in the calendar, filter by date below
    r2 <- dav_request(cal, user, pass, "PROPFIND", propfind_body("<d:getetag/>"), depth = "1")
    auth_fail(r2)
    res <- dav_responses(r2)
    items <- lapply(res, function(n) list(href = abs_url(xml_text(lx(n, "href")), resp_url(r2)), data = NA))
  }
  # drop the calendar collection itself
  items <- Filter(function(x) sub("/$", "", x$href) != sub("/$", "", cal), items)

  rows <- lapply(items, function(x) {
    ev <- parse_vevent(x$data)
    if (is.null(ev)) {
      raw <- tryCatch(get_event_raw(x$href, user, pass), error = function(e) NA)
      ev <- parse_vevent(raw)
    }
    if (is.null(ev)) return(NULL) # not an event (e.g. a task) or unreadable
    data.frame(start = ev$start, end = ev$end, title = ev$title, alarms = ev$alarms, href = x$href)
  })
  out <- do.call(rbind, rows)
  if (is.null(out) || !nrow(out)) return(empty_events())
  keep <- is.na(out$start) | (out$end >= from & out$start < to) | (out$start >= from & out$start < to)
  keep[is.na(keep)] <- TRUE
  out <- out[keep, ]
  out[order(out$start, na.last = TRUE), ]
}

# DTSTART/DTEND line -> POSIXct (UTC, TZID or date-only). NA if it can't be read.
parse_ics_time <- function(line) {
  na <- as.POSIXct(NA_character_, tz = "UTC")
  if (is.na(line) || !nzchar(line)) return(na)
  value <- trimws(sub("^[^:]*:", "", line))
  params <- sub(":.*$", "", line)
  tz <- if (grepl("TZID=", params, ignore.case = TRUE))
    gsub('"', "", sub(".*TZID=([^;]+).*", "\\1", params, ignore.case = TRUE)) else "UTC"
  if (!tz %in% OlsonNames()) tz <- "UTC"
  t <- tryCatch({
    if (grepl("^\\d{8}$", value)) as.POSIXct(value, format = "%Y%m%d", tz = tz)
    else if (grepl("Z$", value)) as.POSIXct(value, format = "%Y%m%dT%H%M%SZ", tz = "UTC")
    else as.POSIXct(value, format = "%Y%m%dT%H%M%S", tz = tz)
  }, error = function(e) na)
  if (length(t) != 1) return(na)
  attr(t, "tzone") <- "UTC"
  t
}

get_event_raw <- function(href, user, pass) {
  r <- dav_request(href, user, pass, "GET")
  if (resp_status(r) != 200) stop("HTTP ", resp_status(r))
  resp_body_string(r, encoding = "UTF-8")
}

delete_event <- function(href, user, pass) {
  r <- dav_request(href, user, pass, "DELETE")
  resp_status(r) %in% c(200, 204)
}
