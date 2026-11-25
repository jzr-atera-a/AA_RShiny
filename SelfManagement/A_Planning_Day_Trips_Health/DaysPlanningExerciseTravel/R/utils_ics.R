# R/utils_ics.R
# iCalendar (.ics) export for the Visualisation tabs of Day Planner, Diet
# Planner, Exercise Tracker, Events Scheduling and Funding Programmes.
#
# Why this is a separate engine from R/utils_calendar_export.R (used by the
# Browse tabs): that writer stamps every time with a trailing "Z" (UTC), so
# a 9:00 AM stop shows up shifted in the user's calendar; it can only read a
# single clock time, so a Day Planner range like "9:00 AM - 11:00 AM (2h 00m)"
# turns into NANA; it never folds long lines; and it generates a random UID
# on every export, so re-importing duplicates events instead of updating them.
#
# Design decisions (all deliberate):
#  * Clock times are written as FLOATING local times (no Z, no TZID). A 9:00
#    stop in Paris shows as 9:00 on the calendar of someone standing in Paris,
#    which is what a schedule means. UTC would silently shift it.
#  * UIDs are deterministic (suite + date + sequence + name), so importing the
#    same plan twice updates the existing events rather than duplicating them.
#  * Text is escaped and long lines folded at 75 octets per RFC 5545, with
#    CRLF line endings, so strict parsers (Outlook, Apple Calendar) accept it.
#  * Anything that has no usable date is reported back (never silently
#    dropped, never guessed): each builder returns list(events, notes).

# ---------------------------------------------------------------- low level

ics_real <- function(x) {
  if (is.null(x) || length(x) == 0) return(FALSE)
  x <- x[1]
  if (is.na(x)) return(FALSE)
  s <- tolower(trimws(as.character(x)))
  nzchar(s) && !(s %in% c("n/a", "na", "none", "tbd", "not specified", "null"))
}

ics_chr <- function(x, default = "") {
  if (is.null(x) || length(x) == 0 || is.na(x[1])) return(default)
  trimws(as.character(x[1]))
}

# The model writes totals as "Total: 480 kcal"; prefixing our own label would
# read "Total calories: Total: 480 kcal".
ics_strip_total <- function(x) trimws(sub("^\\s*total\\s*:?\\s*", "", as.character(x), ignore.case = TRUE))

ics_escape_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- gsub("\\\\", "\\\\\\\\", x)     # backslash  -> \\
  x <- gsub(";", "\\\\;", x)           # semicolon  -> \;
  x <- gsub(",", "\\\\,", x)           # comma      -> \,
  x <- gsub("\r\n|\r|\n", "\\\\n", x)  # newline    -> \n
  x
}

# Fold one content line at 75 octets (RFC 5545 3.1) without splitting a
# multi-byte UTF-8 character (emoji, accents).
ics_fold_line <- function(line, limit = 75L) {
  line <- enc2utf8(line)
  if (nchar(line, type = "bytes") <= limit) return(line)
  cps <- utf8ToInt(line)
  chars <- vapply(cps, intToUtf8, character(1))
  bytes <- vapply(chars, function(ch) nchar(ch, type = "bytes"), integer(1))
  out <- character(0); cur <- character(0); cur_bytes <- 0L; first <- TRUE
  for (k in seq_along(chars)) {
    allowed <- if (first) limit else limit - 1L   # continuation lines start with 1 space
    if (cur_bytes + bytes[k] > allowed) {
      out <- c(out, paste0(if (first) "" else " ", paste(cur, collapse = "")))
      first <- FALSE; cur <- character(0); cur_bytes <- 0L
    }
    cur <- c(cur, chars[k]); cur_bytes <- cur_bytes + bytes[k]
  }
  out <- c(out, paste0(if (first) "" else " ", paste(cur, collapse = "")))
  out
}

ics_prop <- function(name, value) ics_fold_line(paste0(name, ":", value))

ics_fmt_date <- function(d) format(d, "%Y%m%d")

# date + minutes-from-midnight -> "YYYYMMDDTHHMMSS" (floating local time).
# Minutes beyond 24h roll over to the following day (stops that run past
# midnight).
ics_fmt_local <- function(d, minutes) {
  d2 <- d + (minutes %/% 1440)
  mm <- minutes %% 1440
  sprintf("%sT%02d%02d00", ics_fmt_date(d2), mm %/% 60, mm %% 60)
}

ics_make_uid <- function(suite, key, idx) {
  k <- gsub("[^A-Za-z0-9]+", "-", enc2utf8(paste(key, collapse = "-")))
  k <- substr(k, 1, 80)
  paste0(suite, "-", k, "-", idx, "@business-ops-suite")
}

# --------------------------------------------------------------- parsing

# "2026-07-10", "10 July 2026", "July 10, 2026", Date objects. NA otherwise
# ("Rolling basis", "Not confirmed", "TBD" ...).
ics_parse_date <- function(x) {
  na_date <- as.Date(NA)
  if (inherits(x, "Date")) return(x[1])
  if (inherits(x, "POSIXt")) return(as.Date(x[1]))
  if (is.null(x) || length(x) == 0 || is.na(x[1])) return(na_date)
  s <- trimws(as.character(x[1]))
  if (!nzchar(s)) return(na_date)
  for (f in c("%Y-%m-%d", "%Y/%m/%d", "%d %B %Y", "%d %b %Y", "%B %d, %Y", "%b %d, %Y", "%B %d %Y")) {
    d <- suppressWarnings(as.Date(s, format = f))
    if (!is.na(d)) {
      yr <- as.integer(format(d, "%Y"))
      if (yr >= 1990 && yr <= 2100) return(d)
    }
  }
  na_date
}

# Durations in minutes, only from unambiguous units: "45 min", "2h 00m",
# "1.5 hours", "7h 20m". "400 m" (metres) and "4 sets x 8 reps" are NOT
# durations and return NA - guessing here would put a 400-minute swim in
# someone's calendar.
ics_parse_minutes <- function(text) {
  if (is.null(text) || length(text) == 0 || is.na(text[1])) return(NA_real_)
  t <- tolower(as.character(text[1]))
  hm <- regmatches(t, regexec("([0-9]+(?:\\.[0-9]+)?)\\s*h(?:rs?|ours?)?\\s*([0-9]{1,2})\\s*m(?:ins?|inutes?)?\\b", t, perl = TRUE))[[1]]
  if (length(hm) == 3) return(as.numeric(hm[2]) * 60 + as.numeric(hm[3]))
  h <- regmatches(t, regexec("([0-9]+(?:\\.[0-9]+)?)\\s*(?:hrs?|hours?)\\b", t, perl = TRUE))[[1]]
  m <- regmatches(t, regexec("([0-9]+)\\s*(?:mins?|minutes?)\\b", t, perl = TRUE))[[1]]
  hours <- if (length(h) == 2) as.numeric(h[2]) else NA_real_
  mins  <- if (length(m) == 2) as.numeric(m[2]) else NA_real_
  if (is.na(hours) && is.na(mins)) return(NA_real_)
  sum(c(hours * 60, mins), na.rm = TRUE)
}

ics_parse_clock_tokens <- function(text) {
  t <- gsub("\\([^)]*\\)", " ", as.character(text))          # drop "(2h 00m)"
  t <- gsub("[\u2013\u2014\u2212]", "-", t)                  # en/em dash, minus
  rx <- "\\b(\\d{1,2}):(\\d{2})\\s*[AaPp]\\.?[Mm]\\.?|\\b(\\d{1,2})\\s*[AaPp]\\.?[Mm]\\.?|\\b(\\d{1,2}):(\\d{2})\\b"
  m <- gregexpr(rx, t, perl = TRUE)[[1]]
  if (m[1] == -1) return(list())
  toks <- regmatches(t, list(m))[[1]]
  res <- lapply(toks, function(s) {
    p <- regmatches(s, regexec("^(\\d{1,2})(?::(\\d{2}))?\\s*([AaPp])?", s, perl = TRUE))[[1]]
    list(h = as.integer(p[2]),
         m = if (length(p) >= 3 && nzchar(p[3])) as.integer(p[3]) else 0L,
         mer = if (length(p) >= 4 && nzchar(p[4])) toupper(p[4]) else NA_character_)
  })
  Filter(function(k) !is.na(k$h) && !is.na(k$m) && k$m < 60 &&
           (if (is.na(k$mer)) k$h <= 24 else (k$h >= 1 && k$h <= 12)), res)
}

ics_tok_minutes <- function(tok) {
  if (is.na(tok$mer)) return(tok$h * 60L + tok$m)             # 24-hour clock
  (tok$h %% 12L) * 60L + tok$m + (if (tok$mer == "P") 720L else 0L)
}

# "9:00 AM - 11:00 AM (2h 00m)", "09:00-11:30", "7:30 AM", "11:00 - 2:00 PM".
# Returns list(ok, start, end) in minutes from midnight; end may be > 1440 for
# stops that run past midnight, and is NA when only a start is known and no
# duration is stated.
ics_parse_time_range <- function(text, default_duration = NULL) {
  out <- list(ok = FALSE, start = NA_real_, end = NA_real_)
  if (is.null(text) || length(text) == 0 || is.na(text[1])) return(out)
  toks <- ics_parse_clock_tokens(text[1])
  if (length(toks) == 0) return(out)
  t1 <- toks[[1]]
  if (length(toks) >= 2) {
    t2 <- toks[[2]]
    if (is.na(t1$mer) && !is.na(t2$mer)) {      # "11:00 - 2:00 PM"
      cand <- t1; cand$mer <- t2$mer
      t1 <- if (ics_tok_minutes(cand) <= ics_tok_minutes(t2)) cand else { cand$mer <- "A"; cand }
    }
    s <- ics_tok_minutes(t1); e <- ics_tok_minutes(t2)
    if (e == s) e <- NA_real_ else if (e < s) e <- e + 1440      # runs past midnight
    return(list(ok = TRUE, start = s, end = e))
  }
  s <- ics_tok_minutes(t1)
  dur <- ics_parse_minutes(text[1])
  if (is.na(dur)) dur <- if (is.null(default_duration)) NA_real_ else default_duration
  list(ok = TRUE, start = s, end = if (is.na(dur)) NA_real_ else s + dur)
}

# ---------------------------------------------------------- event + writer

# One calendar entry. Timed events carry start/end minutes-from-midnight;
# all-day events (deadlines, day summaries, anything without a readable time)
# carry only the date. alarms: ISO-8601 offsets such as "-PT15M" or "-P7D".
ics_event <- function(uid, summary, date, start = NA_real_, end = NA_real_,
                      description = "", location = "", url = "", categories = NULL,
                      geo = NULL, transparent = FALSE, alarms = NULL, tz = NULL) {
  list(uid = uid, summary = summary, date = date, start = start, end = end,
       all_day = is.na(start), description = description, location = location,
       url = url, categories = categories, geo = geo,
       transparent = transparent, alarms = alarms,
       tz = if (is.null(tz)) NULL else bos_tz_value(tz))
}

# The time zone saved with a row (time_zone column); rows saved before the
# column existed, or with an unusable value, are read as BOS_DEFAULT_TZ.
ics_row_tz <- function(r) {
  if (is.null(r) || !"time_zone" %in% names(r)) return(BOS_DEFAULT_TZ)
  bos_tz_value(r$time_zone[1])
}

ics_event_lines <- function(ev, dtstamp) {
  lines <- c("BEGIN:VEVENT", ics_prop("UID", ev$uid), paste0("DTSTAMP:", dtstamp))
  if (isTRUE(ev$all_day)) {
    lines <- c(lines, paste0("DTSTART;VALUE=DATE:", ics_fmt_date(ev$date)),
                      paste0("DTEND;VALUE=DATE:", ics_fmt_date(ev$date + 1)))   # DTEND is exclusive
  } else {
    end <- if (is.na(ev$end)) ev$start + 60 else ev$end
    if (!is.null(ev$tz)) {
      # a zone was chosen and saved with the data: write real instants (UTC), so
      # every calendar shows the correct local time in the viewer's own zone
      lines <- c(lines, paste0("DTSTART:", bos_tz_utc_stamp(ev$date, ev$start, ev$tz)),
                        paste0("DTEND:", bos_tz_utc_stamp(ev$date, end, ev$tz)))
    } else {
      lines <- c(lines, paste0("DTSTART:", ics_fmt_local(ev$date, ev$start)),
                        paste0("DTEND:", ics_fmt_local(ev$date, end)))
    }
  }
  lines <- c(lines, ics_prop("SUMMARY", ics_escape_text(ev$summary)))
  if (ics_real(ev$description)) lines <- c(lines, ics_prop("DESCRIPTION", ics_escape_text(ev$description)))
  if (ics_real(ev$location))    lines <- c(lines, ics_prop("LOCATION", ics_escape_text(ev$location)))
  if (ics_real(ev$url) && grepl("^https?://", trimws(ev$url), ignore.case = TRUE)) {
    lines <- c(lines, ics_prop("URL", gsub("[[:space:]]", "", ev$url)))
  }
  if (length(ev$categories) > 0) {
    cats <- ev$categories[vapply(ev$categories, ics_real, logical(1))]
    if (length(cats) > 0) lines <- c(lines, ics_prop("CATEGORIES", paste(ics_escape_text(cats), collapse = ",")))
  }
  if (!is.null(ev$geo) && length(ev$geo) == 2 && all(is.finite(ev$geo)) &&
      abs(ev$geo[1]) <= 90 && abs(ev$geo[2]) <= 180) {
    lines <- c(lines, sprintf("GEO:%.6f;%.6f", ev$geo[1], ev$geo[2]))
  }
  lines <- c(lines, "STATUS:CONFIRMED", if (isTRUE(ev$transparent)) "TRANSP:TRANSPARENT" else "TRANSP:OPAQUE", "SEQUENCE:0")
  for (a in ev$alarms) {
    lines <- c(lines, "BEGIN:VALARM", "ACTION:DISPLAY", ics_prop("DESCRIPTION", ics_escape_text(ev$summary)),
               paste0("TRIGGER:", a), "END:VALARM")
  }
  c(lines, "END:VEVENT")
}

ics_calendar_text <- function(events, cal_name = "Business Operations Suite") {
  stamp <- format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")
  lines <- c("BEGIN:VCALENDAR", "VERSION:2.0",
             "PRODID:-//Business Operations Suite//Visualisation Export//EN",
             "CALSCALE:GREGORIAN", "METHOD:PUBLISH",
             ics_prop("X-WR-CALNAME", ics_escape_text(cal_name)))
  for (ev in events) lines <- c(lines, ics_event_lines(ev, stamp))
  lines <- c(lines, "END:VCALENDAR")
  paste0(paste(lines, collapse = "\r\n"), "\r\n")                  # RFC 5545: CRLF
}

# Written as raw UTF-8 bytes so Windows/Android never re-encode or add a BOM.
ics_write_file <- function(events, cal_name, file) {
  writeBin(charToRaw(enc2utf8(ics_calendar_text(events, cal_name))), file)
  invisible(file)
}

# ------------------------------------------------------------ preview line

# Status shown above the download button, built from the same result object
# the download uses, so what the user reads is exactly what they get.
ics_status_html <- function(result, loaded = TRUE) {
  if (!isTRUE(loaded)) {
    return(tags$div(class = "status-info", tags$i(class = "fa fa-info-circle"),
                    " Load a view above first, then download its calendar."))
  }
  ev <- result$events
  n <- length(ev)
  n_all <- sum(vapply(ev, function(e) isTRUE(e$all_day), logical(1)))
  notes <- result$notes
  shown <- head(notes, 6)
  more <- length(notes) - length(shown)
  tags$div(
    class = if (n == 0) "status-warning" else if (length(notes) > 0) "status-info" else "status-success",
    tags$i(class = if (n == 0) "fa fa-exclamation-triangle" else "fa fa-calendar-check"),
    sprintf(" %d calendar event%s ready (%d timed, %d all-day).", n, if (n == 1) "" else "s", n - n_all, n_all),
    if (n > n_all) {
      zs <- unique(unlist(lapply(ev, function(e) if (isTRUE(e$all_day)) NULL else e$tz)))
      if (length(zs) > 0) tags$div(style = "margin-top: 4px;", tags$i(class = "fa fa-globe"),
        paste0(" Times are in ", paste(vapply(zs, function(z) paste0(bos_tz_label(z), " (", z, ")"), ""), collapse = " and "),
               " - the zone saved with this data."))
    },
    if (length(shown) > 0) tags$ul(style = "margin: 6px 0 0 18px; font-size: 0.9em;",
                                    lapply(shown, tags$li),
                                    if (more > 0) tags$li(sprintf("...and %d more.", more)) else NULL) else NULL
  )
}

# ===================================================================
#                      PER-SUITE EVENT BUILDERS
# ===================================================================
# Each takes the data frame the Visualisation tab currently has loaded and
# returns list(events = <list of ics_event>, notes = <character>).

# Keep the stored order (row_sequence) when present; never fail just because
# a column is missing.
ics_sort <- function(d) {
  if ("row_sequence" %in% names(d)) d[order(suppressWarnings(as.numeric(d$row_sequence))), , drop = FALSE] else d
}

ics_empty <- function(msg) list(events = list(), notes = msg)

# ---- Day Planner -----------------------------------------------------
# Location rows carry a real time window ("9:00 AM - 11:00 AM (2h 00m)").
# Transport rows only carry a duration ("15 min"), so they are anchored to
# the end of the previous stop. The Summary row (weather forecast + day
# insights) becomes a non-blocking all-day entry.
ics_events_day_planner <- function(d, include_transport = TRUE, alarms = TRUE) {
  if (is.null(d) || nrow(d) == 0) return(ics_empty("Nothing loaded yet."))
  d <- ics_sort(d)
  events <- list(); notes <- character(0)
  prev_end <- NA_real_; prev_date <- as.Date(NA)

  for (i in seq_len(nrow(d))) {
    r <- d[i, , drop = FALSE]
    dt <- ics_parse_date(r$schedule_date)
    rt <- tolower(ics_chr(r$row_type))
    nm <- ics_chr(r$location_name, "Stop")
    if (is.na(dt)) { notes <- c(notes, sprintf("Skipped '%s': no valid date.", nm)); next }
    uid <- ics_make_uid("dayplanner", c(format(dt), r$row_sequence, nm), i)

    if (rt == "location") {
      place <- paste(c(nm, if (ics_real(r$city)) ics_chr(r$city), if (ics_real(r$country)) ics_chr(r$country)), collapse = ", ")
      desc <- paste(c(
        if (ics_real(r$location_details)) ics_chr(r$location_details),
        if (ics_real(r$opening_hours)) paste0("Opening hours: ", ics_chr(r$opening_hours)),
        if (ics_real(r$recommended_time)) paste0("Planned: ", ics_chr(r$recommended_time)),
        if (ics_real(r$observations)) paste0("\n", ics_chr(r$observations))), collapse = "\n")
      tr <- ics_parse_time_range(r$recommended_time)
      if (!tr$ok) {
        notes <- c(notes, sprintf("'%s' has no readable time (\"%s\") - added as an all-day entry.", nm, ics_chr(r$recommended_time)))
        events[[length(events) + 1]] <- ics_event(tz = ics_row_tz(r), uid, paste0("\U0001F4CD ", nm), dt, description = desc, location = place,
                                                  categories = c("Day Planner", ics_chr(r$day_type)))
      } else {
        end <- if (is.na(tr$end)) tr$start + 60 else tr$end
        if (is.na(tr$end)) notes <- c(notes, sprintf("'%s' has no end time - assumed 1 hour.", nm))
        events[[length(events) + 1]] <- ics_event(tz = ics_row_tz(r), uid, paste0("\U0001F4CD ", nm), dt, tr$start, end, desc, place,
                                                  categories = c("Day Planner", ics_chr(r$day_type)),
                                                  alarms = if (alarms) "-PT15M" else NULL)
        prev_end <- end; prev_date <- dt
      }

    } else if (rt == "transport") {
      if (!include_transport) next
      tr <- ics_parse_time_range(r$recommended_time)
      if (tr$ok && !is.na(tr$end)) { s <- tr$start; e <- tr$end
      } else if (!is.na(prev_end) && !is.na(prev_date) && prev_date == dt) {
        dur <- ics_parse_minutes(r$recommended_time); if (is.na(dur)) dur <- 15
        s <- prev_end; e <- prev_end + dur
      } else {
        notes <- c(notes, sprintf("Transport '%s' skipped: no preceding stop to anchor its time.", nm)); next
      }
      desc <- paste(c(if (ics_real(r$location_details)) ics_chr(r$location_details),
                      if (ics_real(r$recommended_time)) paste0("Expected: ", ics_chr(r$recommended_time)),
                      if (ics_real(r$observations)) paste0("\n", ics_chr(r$observations))), collapse = "\n")
      events[[length(events) + 1]] <- ics_event(tz = ics_row_tz(r), uid, paste0("\U0001F686 ", nm), dt, s, e, desc,
                                                categories = c("Day Planner", "Transport"))

    } else if (rt == "summary") {
      desc <- paste(c(if (ics_real(r$location_details)) ics_chr(r$location_details),
                      if (ics_real(r$recommended_time)) paste0("Day total: ", ics_strip_total(ics_chr(r$recommended_time))),
                      if (ics_real(r$observations)) paste0("\n", ics_chr(r$observations))), collapse = "\n")
      title <- if (ics_real(r$location_details)) ics_chr(r$location_details) else paste(ics_chr(r$day_type, "Day"), "plan")
      events[[length(events) + 1]] <- ics_event(tz = ics_row_tz(r), uid, paste0("\U0001F5D3\uFE0F ", title), dt, description = desc,
                                                categories = c("Day Planner", ics_chr(r$day_type)), transparent = TRUE)
    }
  }
  list(events = events, notes = notes)
}

# ---- Diet Planner ----------------------------------------------------
ics_meal_defaults <- function(name) {
  n <- tolower(name)
  if (grepl("brunch", n)) return(list(start = 630, dur = 45))
  if (grepl("breakfast", n)) return(list(start = 480, dur = 30))
  if (grepl("lunch", n)) return(list(start = 750, dur = 45))
  if (grepl("dinner|supper", n)) return(list(start = 1140, dur = 60))
  if (grepl("morning.*snack|snack.*morning", n)) return(list(start = 630, dur = 15))
  if (grepl("evening.*snack|snack.*evening", n)) return(list(start = 1230, dur = 15))
  if (grepl("snack", n)) return(list(start = 960, dur = 15))
  NULL
}

ics_events_diet <- function(d, alarms = TRUE) {
  if (is.null(d) || nrow(d) == 0) return(ics_empty("Nothing loaded yet."))
  d <- ics_sort(d)
  events <- list(); notes <- character(0)
  for (i in seq_len(nrow(d))) {
    r <- d[i, , drop = FALSE]
    dt <- ics_parse_date(r$log_date); rt <- tolower(ics_chr(r$row_type)); nm <- ics_chr(r$meal_name, "Meal")
    if (is.na(dt)) { notes <- c(notes, sprintf("Skipped '%s': no valid date.", nm)); next }
    uid <- ics_make_uid("diet", c(format(dt), r$row_sequence, nm), i)
    macros <- if (ics_real(r$calories_macros)) diet_parse_calories_macros(r$calories_macros) else list(calories = NA)

    if (rt == "meal") {
      desc <- paste(c(if (ics_real(r$meal_details)) ics_chr(r$meal_details),
                      if (ics_real(r$calories_macros)) paste0("Calories / macros: ", ics_chr(r$calories_macros)),
                      if (ics_real(r$observations)) paste0("\n", ics_chr(r$observations))), collapse = "\n")
      title <- paste0("\U0001F37D\uFE0F ", nm, if (!is.na(macros$calories)) sprintf(" (%d kcal)", as.integer(macros$calories)) else "")
      tr <- ics_parse_time_range(r$meal_time)
      def <- ics_meal_defaults(nm)
      if (tr$ok) {
        end <- if (is.na(tr$end)) tr$start + (if (is.null(def)) 30 else def$dur) else tr$end
        events[[length(events) + 1]] <- ics_event(tz = ics_row_tz(r), uid, title, dt, tr$start, end, desc,
                                                  categories = c("Diet", ics_chr(r$diet_type)),
                                                  alarms = if (alarms) "-PT10M" else NULL)
      } else if (!is.null(def)) {
        notes <- c(notes, sprintf("'%s' had no time - placed at %02d:%02d (typical for this meal).", nm, def$start %/% 60, def$start %% 60))
        events[[length(events) + 1]] <- ics_event(tz = ics_row_tz(r), uid, title, dt, def$start, def$start + def$dur,
                                                  paste0(desc, "\n(Time suggested - none was specified.)"),
                                                  categories = c("Diet", ics_chr(r$diet_type)),
                                                  alarms = if (alarms) "-PT10M" else NULL)
      } else {
        notes <- c(notes, sprintf("'%s' has no readable time (\"%s\") - added as an all-day entry.", nm, ics_chr(r$meal_time)))
        events[[length(events) + 1]] <- ics_event(tz = ics_row_tz(r), uid, title, dt, description = desc, categories = c("Diet", ics_chr(r$diet_type)))
      }
    } else if (rt == "summary") {
      desc <- paste(c(if (ics_real(r$meal_details)) ics_chr(r$meal_details),
                      if (ics_real(r$calories_macros)) paste0("Day total: ", ics_strip_total(ics_chr(r$calories_macros))),
                      if (ics_real(r$dietary_restrictions)) paste0("Restrictions: ", ics_chr(r$dietary_restrictions)),
                      if (ics_real(r$observations)) paste0("\n", ics_chr(r$observations))), collapse = "\n")
      events[[length(events) + 1]] <- ics_event(tz = ics_row_tz(r), uid, paste0("\U0001F957 ", ics_chr(r$diet_type, "Diet"), " day",
                                                            if (!is.na(macros$calories)) sprintf(" - %d kcal", as.integer(macros$calories)) else ""),
                                                dt, description = desc, categories = c("Diet", ics_chr(r$diet_type)), transparent = TRUE)
    }
  }
  list(events = events, notes = notes)
}

# ---- Exercise Tracker ------------------------------------------------
# Exercise rows carry NO clock time (sets/reps/distance only). A workout is
# one calendar block, not eight 5-minute ones, so the whole session becomes a
# single event starting at a time the user chooses, listing every exercise.
ics_events_exercise <- function(d, start_time = "18:00", alarms = TRUE) {
  if (is.null(d) || nrow(d) == 0) return(ics_empty("Nothing loaded yet."))
  d <- ics_sort(d)
  notes <- character(0)
  dt <- ics_parse_date(d$workout_date[1])
  if (is.na(dt)) return(ics_empty("The loaded session has no valid date."))

  st <- suppressWarnings(as.integer(strsplit(start_time, ":")[[1]]))
  start_min <- if (length(st) == 2 && !anyNA(st)) st[1] * 60 + st[2] else 1080

  rt <- tolower(vapply(d$row_type, ics_chr, character(1)))
  ex <- d[rt == "exercise", , drop = FALSE]
  sm <- d[rt == "summary", , drop = FALSE]

  total <- if (nrow(sm) > 0) ics_parse_minutes(sm$metric_primary[1]) else NA_real_
  if (is.na(total) && nrow(ex) > 0) {
    parts <- vapply(seq_len(nrow(ex)), function(k) {
      v <- ics_parse_minutes(ex$metric_primary[k]); if (is.na(v)) v <- ics_parse_minutes(ex$exercise_details[k])
      if (is.na(v)) 6 else v                       # ~6 min for a strength set block with no stated duration
    }, numeric(1))
    total <- sum(parts)
    notes <- c(notes, "Session length estimated from the listed exercises (no total was recorded).")
  }
  if (is.na(total)) { total <- 60; notes <- c(notes, "No durations recorded - assumed 60 minutes.") }
  total <- min(240, max(15, ceiling(total / 5) * 5))

  st_type <- ics_chr(d$session_type[1], "Workout")
  lines <- character(0)
  for (k in seq_len(nrow(ex))) {
    e <- ex[k, ]
    bits <- c(if (ics_real(e$exercise_details)) ics_chr(e$exercise_details),
              if (ics_real(e$metric_primary)) ics_chr(e$metric_primary),
              if (ics_real(e$metric_secondary)) ics_chr(e$metric_secondary),
              if (ics_real(e$calories_burned)) ics_chr(e$calories_burned))
    lines <- c(lines, sprintf("%d. %s%s%s%s", k, ics_chr(e$exercise_name, "Exercise"),
                              if (ics_real(e$exercise_category)) paste0(" [", ics_chr(e$exercise_category), "]") else "",
                              if (length(bits) > 0) paste0(" - ", paste(unique(bits), collapse=" | ")) else "",
                              if (ics_real(e$observations)) paste0("\n   Tip: ", ics_chr(e$observations)) else ""))
  }
  extra <- c(if (nrow(sm) > 0 && ics_real(sm$calories_burned[1])) paste0("Total calories: ", ics_strip_total(ics_chr(sm$calories_burned[1]))),
             if (nrow(sm) > 0 && ics_real(sm$observations[1])) paste0("Notes: ", ics_chr(sm$observations[1])),
             if (ics_real(d$session_notes[1])) paste0("Session goals: ", ics_chr(d$session_notes[1])))
  desc <- paste(c(lines, if (length(extra) > 0) c("", extra)), collapse = "\n")

  title <- sprintf("\U0001F3CB\uFE0F %s workout%s", st_type, if (nrow(ex) > 0) sprintf(" (%d exercise%s)", nrow(ex), if (nrow(ex) == 1) "" else "s") else "")
  ev <- ics_event(tz = ics_row_tz(d[1, , drop = FALSE]), ics_make_uid("exercise", c(format(dt), st_type), 1), title, dt, start_min, start_min + total,
                  desc, categories = c("Exercise", st_type), alarms = if (alarms) "-PT30M" else NULL)
  list(events = list(ev), notes = notes)
}

# ---- Events Scheduling -----------------------------------------------
ics_events_events <- function(d, alarms = TRUE) {
  if (is.null(d) || nrow(d) == 0) return(ics_empty("Nothing loaded yet."))
  events <- list(); notes <- character(0)
  for (i in seq_len(nrow(d))) {
    r <- d[i, , drop = FALSE]
    nm <- ics_chr(r$event_name, "Event")
    dt <- ics_parse_date(r$event_date)
    if (is.na(dt)) { notes <- c(notes, sprintf("Skipped '%s': no valid date (\"%s\").", nm, ics_chr(r$event_date))); next }
    place <- paste(c(if (ics_real(r$venue_name)) ics_chr(r$venue_name),
                     if (ics_real(r$address)) ics_chr(r$address),
                     if (ics_real(r$city)) ics_chr(r$city)), collapse = ", ")
    desc <- paste(c(if (ics_real(r$description)) ics_chr(r$description),
                    if (ics_real(r$organiser)) paste0("Organiser: ", ics_chr(r$organiser)),
                    if (ics_real(r$price_range)) paste0("Price: ", ics_chr(r$price_range)),
                    if (ics_real(r$ticket_url)) paste0("Tickets: ", ics_chr(r$ticket_url)),
                    if (ics_real(r$source_url)) paste0("Source: ", ics_chr(r$source_url)),
                    if (ics_real(r$extra_info)) paste0("\n", ics_chr(r$extra_info))), collapse = "\n")
    url <- if (ics_real(r$ticket_url)) ics_chr(r$ticket_url) else ics_chr(r$source_url)
    lat <- suppressWarnings(as.numeric(ics_chr(r$latitude))); lon <- suppressWarnings(as.numeric(ics_chr(r$longitude)))
    geo <- if (length(lat) == 1 && length(lon) == 1 && is.finite(lat) && is.finite(lon)) c(lat, lon) else NULL
    cats <- c("Events", ics_chr(r$category), ics_chr(r$subcategory))
    uid <- ics_make_uid("event", c(format(dt), nm), i)
    tr <- ics_parse_time_range(r$event_time)
    if (tr$ok) {
      end <- if (is.na(tr$end)) tr$start + 120 else tr$end        # no end time recorded -> 2 h
      events[[length(events) + 1]] <- ics_event(tz = ics_row_tz(r), uid, nm, dt, tr$start, end, desc, place, url, cats, geo,
                                                alarms = if (alarms) "-PT1H" else NULL)
    } else {
      events[[length(events) + 1]] <- ics_event(tz = ics_row_tz(r), uid, nm, dt, description = desc, location = place, url = url,
                                                categories = cats, geo = geo)    # "All Day" / "TBD"
    }
  }
  list(events = events, notes = notes)
}

# ---- Funding Programmes ----------------------------------------------
# A funding programme is a deadline, not an appointment: the deadline is an
# all-day entry with reminders a week and a day ahead. The application-open
# date is an optional second all-day entry. "Rolling basis" / "Not confirmed"
# have no date, so they are reported, never invented.
ics_events_funding <- function(d, include_opens = TRUE, alarms = TRUE) {
  if (is.null(d) || nrow(d) == 0) return(ics_empty("Nothing loaded yet."))
  events <- list(); notes <- character(0)
  for (i in seq_len(nrow(d))) {
    r <- d[i, , drop = FALSE]
    nm <- ics_chr(r$programme_name, "Programme")
    urls <- if (ics_real(r$verified_urls)) trimws(strsplit(ics_chr(r$verified_urls), "[,\n; ]+")[[1]]) else character(0)
    urls <- urls[grepl("^https?://", urls, ignore.case = TRUE)]
    first_url <- if (length(urls) > 0) urls[1] else ""
    where <- paste(c(if (ics_real(r$city_region) && ics_chr(r$city_region) != "All") ics_chr(r$city_region), if (ics_real(r$country)) ics_chr(r$country)), collapse = ", ")
    desc <- paste(c(if (ics_real(r$category)) paste0("Type: ", ics_chr(r$category)),
                    if (ics_real(r$amount_of_money)) paste0("Funding: ", ics_chr(r$amount_of_money)),
                    if (ics_real(r$key_sponsors)) paste0("Sponsors: ", ics_chr(r$key_sponsors)),
                    if (ics_real(r$areas_of_application)) paste0("Areas: ", ics_chr(r$areas_of_application)),
                    if (ics_real(r$conditions)) paste0("Eligibility: ", ics_chr(r$conditions)),
                    if (ics_real(r$recommendations_for_applying)) paste0("\nTips: ", ics_chr(r$recommendations_for_applying)),
                    if (length(urls) > 0) paste0("\nLinks: ", paste(urls, collapse = "  "))), collapse = "\n")
    cats <- c("Funding", ics_chr(r$category))

    dl <- ics_parse_date(r$deadline)
    if (!is.na(dl)) {
      # "2026-11-30 17:00" -> a timed deadline in the zone saved with the row;
      # a bare date stays an all-day entry (the time is not known, never invented)
      rest <- sub("^\\s*[0-9]{4}[-/][0-9]{1,2}[-/][0-9]{1,2}", "", ics_chr(r$deadline))
      dtr <- ics_parse_time_range(rest)
      events[[length(events) + 1]] <- if (isTRUE(dtr$ok)) {
        ics_event(tz = ics_row_tz(r), ics_make_uid("funding-deadline", c(format(dl), nm), i),
                  paste0("\u23F0 Deadline: ", nm), dl, dtr$start, dtr$start + 30, desc, where,
                  first_url, cats, alarms = if (alarms) c("-P7D", "-P1D", "-PT1H") else NULL)
      } else {
        ics_event(tz = ics_row_tz(r), ics_make_uid("funding-deadline", c(format(dl), nm), i),
                  paste0("\u23F0 Deadline: ", nm), dl, description = desc, location = where,
                  url = first_url, categories = cats,
                  alarms = if (alarms) c("-P7D", "-P1D") else NULL)
      }
    } else {
      notes <- c(notes, sprintf("'%s': deadline \"%s\" is not a date - no deadline entry.", nm, ics_chr(r$deadline, "empty")))
    }
    if (include_opens) {
      op <- ics_parse_date(r$start_date_for_applying)
      if (!is.na(op)) {
        events[[length(events) + 1]] <- ics_event(tz = ics_row_tz(r), ics_make_uid("funding-opens", c(format(op), nm), i),
                                                  paste0("\U0001F7E2 Applications open: ", nm), op, description = desc,
                                                  location = where, url = first_url, categories = cats, transparent = TRUE)
      }
    }
  }
  list(events = events, notes = notes)
}

# Runs a builder safely: a bug or odd data must surface as a readable note
# above the download button, never as a crash or a silently empty file.
ics_safe_build <- function(builder, ...) {
  tryCatch(builder(...), error = function(e) {
    cat("\u274c [ics export] Error:", conditionMessage(e), "\n")
    list(events = list(), notes = paste("Could not build the calendar:", conditionMessage(e)))
  })
}

# Download-handler helpers ---------------------------------------------

ics_filename <- function(prefix, date = NULL) {
  d <- if (is.null(date) || length(date) == 0 || is.na(date[1])) format(Sys.Date(), "%Y%m%d") else as.character(date[1])
  paste0(prefix, "_", gsub("[^A-Za-z0-9_.-]", "", d), ".ics")
}

# If writing ever fails, log it and still hand back a valid (empty) calendar
# file; the status line above the button has already told the user why.
ics_write_safe <- function(get_events, cal_name, file) {
  tryCatch(ics_write_file(get_events(), cal_name, file),
           error = function(e) {
             cat("\u274c [ics export] write failed:", conditionMessage(e), "\n")
             ics_write_file(list(), cal_name, file)
           })
}
