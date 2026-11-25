# =============================================================================
# R/utils_zoom.R - Zoom call invites: read an invite screenshot with Claude,
# build the calendar invite (.ics, METHOD:REQUEST) and the joining text.
#
# There is NO Zoom API involved: the Zoom meeting already exists; Claude reads
# its details from a screenshot. Every top-level name starts with zoom_ / ZOOM_
# (helper names must not end in _ui / _server).
# =============================================================================

# Always copied on every email sent from Contact Manager > Send Email
BOS_ALWAYS_CC <- "joseph.zr@atera-analytics.co.uk"

ZOOM_MAX_IMAGES <- 6
ZOOM_IMAGE_TYPES <- c(png = "image/png", jpg = "image/jpeg", jpeg = "image/jpeg",
                      gif = "image/gif", webp = "image/webp")
ZOOM_MAX_IMAGE_BYTES <- 5 * 1024 * 1024        # Claude's per-image limit

zoom_or <- function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a

zoom_valid_email <- function(x) grepl("^[^@[:space:]<>,;]+@[^@[:space:]<>,;]+\\.[^@[:space:]<>,;]+$", x)

# ---- the request to Claude ---------------------------------------------------------
zoom_read_prompt <- function(default_tz, today = Sys.Date(), extra = "", n_images = 1) {
  paste0(
    if (n_images > 1) paste0("You are given ", n_images, " images. They all belong to the SAME single meeting invitation: one may show the ",
      "link and joining details and another the invited people. Combine them into one result; take each field from whichever image shows it, ",
      "and list every email address found in any image.\n\n") else "",
    "You are reading a screenshot or photo of a Zoom meeting invitation. Extract the call details.\n\n",
    "Today's date is ", format(today, "%Y-%m-%d"), ". If the image shows a date without a year, use the next ",
    "occurrence of that date on or after today. Resolve words like 'tomorrow' or 'Friday' against today's date.\n\n",
    "TIME ZONE (important): read the time zone that is shown with the meeting time (for example 'Eastern Time (US and ",
    "Canada)', 'GMT+1', 'CST', 'Mexico City'). Return it as a valid IANA zone name such as America/New_York, ",
    "Europe/London or America/Mexico_City. If an abbreviation is ambiguous, pick the zone that fits the other ",
    "clues in the image (city, country, language, offset). If the image shows NO time zone at all, return null for ",
    "time_zone: the app will then use ", default_tz, ". Never guess a zone that the image does not support.\n\n",
    "Return ONLY one JSON object, no markdown, no commentary, with exactly these keys:\n",
    "{\n",
    '  "subject": "meeting title / topic",\n',
    '  "date": "YYYY-MM-DD",\n',
    '  "start_time": "HH:MM (24-hour) in the meeting time zone",\n',
    '  "time_zone": "IANA zone name or null",\n',
    '  "time_zone_as_shown": "the zone text exactly as written in the image, or null",\n',
    '  "duration_minutes": integer or null (from an end time or a stated length),\n',
    '  "attendees": [ {"name": "...", "email": "..."} ],  (every person invited who has an email address)\n',
    '  "organizer": {"name": "...", "email": "..."} or null,\n',
    '  "zoom_link": "the full https join URL" or null,\n',
    '  "meeting_id": "digits as shown" or null,\n',
    '  "passcode": "as shown" or null,\n',
    '  "join_details": "any other joining text: dial-in numbers, one-tap mobile, SIP, agenda (plain text, \\n for line breaks) or null",\n',
    '  "notes": ["anything you could not read or are unsure about"],\n',
    '  "ics": "a complete iCalendar text (BEGIN:VCALENDAR ... END:VCALENDAR, METHOD:REQUEST) for this meeting, with the ',
    'Zoom link and joining details in LOCATION and DESCRIPTION, DTSTART/DTEND in UTC (Z), and an ATTENDEE line per attendee"\n',
    "}\n\n",
    "Rules: copy email addresses and the Zoom link character by character; never invent an email, a link, a passcode ",
    "or a time. Use null (or an empty list) for anything not in the image and mention it in notes.",
    if (nzchar(trimws(extra))) paste0("\n\nExtra instructions from the user: ", trimws(extra)) else ""
  )
}

# First complete {...} object in Claude's text (it may wrap it in ``` fences).
zoom_extract_json <- function(text) {
  text <- paste(as.character(text), collapse = "\n")
  text <- gsub("```[a-zA-Z]*", "", text)
  start <- regexpr("\\{", text)
  if (start < 0) return(NULL)
  chars <- strsplit(substring(text, start), "")[[1]]
  depth <- 0; in_str <- FALSE; esc <- FALSE; end <- NA
  for (i in seq_along(chars)) {
    ch <- chars[i]
    if (in_str) {
      if (esc) esc <- FALSE else if (ch == "\\") esc <- TRUE else if (ch == "\"") in_str <- FALSE
    } else if (ch == "\"") in_str <- TRUE
    else if (ch == "{") depth <- depth + 1
    else if (ch == "}") { depth <- depth - 1; if (depth == 0) { end <- i; break } }
  }
  if (is.na(end)) return(NULL)
  tryCatch(jsonlite::fromJSON(paste(chars[1:end], collapse = ""), simplifyVector = FALSE), error = function(e) NULL)
}

# Turns Claude's answer into a checked list. Never throws.
# Returns list(ok, error, invite, warnings, raw_ics).
zoom_parse_response <- function(text, default_tz = BOS_DEFAULT_TZ) {
  j <- zoom_extract_json(text)
  if (is.null(j)) return(list(ok = FALSE, error = "Claude's answer did not contain readable invite data. Try again, or use a clearer image.", warnings = character()))
  warn <- character()
  str1 <- function(x) { x <- zoom_or(x, ""); if (is.list(x)) x <- ""; x <- trimws(as.character(x)[1]); if (is.na(x)) "" else x }

  subject <- str1(j$subject)
  if (!nzchar(subject)) { subject <- "Zoom meeting"; warn <- c(warn, "No subject was found in the image: using 'Zoom meeting'.") }

  date <- tryCatch(as.Date(str1(j$date)), error = function(e) NA)
  if (length(date) != 1 || is.na(date)) {
    return(list(ok = FALSE, error = "Claude could not read the meeting date from the image.", warnings = warn,
                raw = j))
  }
  st <- str1(j$start_time)
  m <- regmatches(st, regexec("^([01]?[0-9]|2[0-3]):([0-5][0-9])", st))[[1]]
  if (length(m) < 3) {
    return(list(ok = FALSE, error = "Claude could not read the meeting start time from the image.", warnings = warn, raw = j))
  }
  start_min <- as.integer(m[2]) * 60L + as.integer(m[3])

  dur <- suppressWarnings(as.integer(zoom_or(j$duration_minutes, NA)))
  if (is.na(dur) || dur <= 0 || dur > 24 * 60) {
    dur <- 60L; warn <- c(warn, "No length was found in the image: assumed 60 minutes.")
  }

  tz_in <- str1(j$time_zone)
  tz_shown <- str1(j$time_zone_as_shown)
  if (nzchar(tz_in) && tz_in %in% OlsonNames()) {
    tz <- tz_in; tz_from_image <- TRUE
  } else {
    tz <- bos_tz_value(default_tz); tz_from_image <- FALSE
    warn <- c(warn, if (nzchar(tz_in) || nzchar(tz_shown))
      sprintf("The zone in the image ('%s') could not be matched to a valid zone: using %s.", zoom_or(if (nzchar(tz_shown)) tz_shown, tz_in), tz)
      else sprintf("The image shows no time zone: using %s.", tz))
  }

  # attendees
  at <- zoom_or(j$attendees, list())
  emails <- character(); names_v <- character()
  for (a in at) {
    em <- if (is.list(a)) str1(a$email) else str1(a)
    em <- tolower(sub("^mailto:", "", em))
    if (nzchar(em) && zoom_valid_email(em) && !em %in% emails) {
      emails <- c(emails, em); names_v <- c(names_v, if (is.list(a)) str1(a$name) else "")
    } else if (nzchar(em)) warn <- c(warn, sprintf("'%s' does not look like an email address and was skipped.", em))
  }
  if (!length(emails)) warn <- c(warn, "No attendee email addresses were found: fill in the To field by hand.")
  org <- j$organizer
  org_email <- if (is.list(org)) tolower(str1(org$email)) else ""

  link <- str1(j$zoom_link)
  if (nzchar(link) && !grepl("^https://", link)) { warn <- c(warn, "The Zoom link did not start with https:// and was ignored."); link <- "" }
  if (!nzchar(link)) warn <- c(warn, "No Zoom link was found in the image: add it by hand.")

  notes <- unlist(zoom_or(j$notes, list()))
  list(ok = TRUE, error = NULL, warnings = warn,
       raw_ics = str1(j$ics),
       invite = list(
         subject = subject, date = date, start = sprintf("%02d:%02d", start_min %/% 60L, start_min %% 60L),
         duration = dur, tz = tz, tz_from_image = tz_from_image, tz_shown = tz_shown,
         attendees = emails, attendee_names = names_v,
         organizer_email = org_email, organizer_name = if (is.list(org)) str1(org$name) else "",
         zoom_link = link, meeting_id = str1(j$meeting_id), passcode = str1(j$passcode),
         join_details = str1(j$join_details), notes = as.character(notes)))
}

# ---- joining text (used in the Titan event, the email body and the .ics) ---------------
zoom_join_text <- function(link = "", meeting_id = "", passcode = "", details = "") {
  parts <- c(
    if (nzchar(link)) c("Join Zoom Meeting", link) else NULL,
    if (nzchar(meeting_id) || nzchar(passcode)) c("", if (nzchar(meeting_id)) paste0("Meeting ID: ", meeting_id),
                                                   if (nzchar(passcode)) paste0("Passcode: ", passcode)) else NULL,
    if (nzchar(details)) c("", details) else NULL)
  paste(parts, collapse = "\n")
}

# ---- the calendar invite -------------------------------------------------------------
# method "REQUEST" (invitation: invitees get Yes / No / Maybe and their reply goes
# to the ORGANIZER) or "CANCEL". Times are written as UTC instants.
zoom_invite_ics <- function(uid, title, date, start_min, duration_min, tz,
                            organizer_email, to = character(), cc = character(),
                            location = "", description = "", url = "",
                            method = "REQUEST", sequence = 0L, reminder_min = 15L,
                            organizer_name = "") {
  tz <- bos_tz_value(tz)
  s <- bos_tz_utc_stamp(date, start_min, tz)
  e <- bos_tz_utc_stamp(date, start_min + duration_min, tz)
  stamp <- format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")
  org <- tolower(trimws(organizer_email))
  cn <- function(x) paste0('CN="', gsub('["\r\n]', "", x), '"')
  to <- unique(tolower(trimws(to[nzchar(trimws(to))]))); to <- setdiff(to, org)
  cc <- setdiff(unique(tolower(trimws(cc[nzchar(trimws(cc))]))), c(to, org))
  lines <- c(
    "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Business Operations Suite//Zoom Invite//EN",
    "CALSCALE:GREGORIAN", paste0("METHOD:", method),
    "BEGIN:VEVENT", ics_prop("UID", uid), paste0("DTSTAMP:", stamp),
    paste0("DTSTART:", s), paste0("DTEND:", e),
    paste0("SEQUENCE:", as.integer(sequence)),
    ics_prop("SUMMARY", ics_escape_text(title)),
    if (nzchar(description)) ics_prop("DESCRIPTION", ics_escape_text(description)),
    if (nzchar(location)) ics_prop("LOCATION", ics_escape_text(location)),
    if (nzchar(url) && grepl("^https?://", url)) ics_prop("URL", url),
    ics_fold_line(paste0("ORGANIZER;", cn(if (nzchar(organizer_name)) organizer_name else org), ":mailto:", org)),
    unlist(lapply(to, function(a) ics_fold_line(paste0("ATTENDEE;", cn(a), ";CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE:mailto:", a)))),
    unlist(lapply(cc, function(a) ics_fold_line(paste0("ATTENDEE;", cn(a), ";CUTYPE=INDIVIDUAL;ROLE=OPT-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=FALSE:mailto:", a)))),
    paste0("STATUS:", if (identical(method, "CANCEL")) "CANCELLED" else "CONFIRMED"),
    "TRANSP:OPAQUE",
    if (!identical(method, "CANCEL") && reminder_min > 0) c(
      "BEGIN:VALARM", "ACTION:DISPLAY", ics_prop("DESCRIPTION", ics_escape_text(title)),
      paste0("TRIGGER:-PT", as.integer(reminder_min), "M"), "END:VALARM"),
    "END:VEVENT", "END:VCALENDAR")
  paste0(paste(unlist(lines), collapse = "\r\n"), "\r\n")
}


# ---- the invite email waiting in Send Email -----------------------------------------------
# item: a saved Events-to-Calendar queue item whose $ev carries $invite.
zoom_make_draft <- function(item, organizer_email) {
  ev <- item$ev; inv <- ev$invite
  tz <- bos_tz_value(item$tz)
  smin <- ev$start; emin <- if (is.na(ev$end)) smin + 60 else ev$end
  dur <- max(5L, as.integer(round(emin - smin)))
  start_ct <- bos_tz_local_posix(ev$date, smin, tz)
  end_ct <- bos_tz_local_posix(ev$date, smin + dur, tz)
  title <- as.character(zoom_or(ev$summary, "Zoom meeting"))
  join <- as.character(zoom_or(ev$description, ""))
  when <- sprintf("%s, %s - %s %s (%s)", format(start_ct, "%A %d %B %Y", tz = tz), format(start_ct, "%H:%M", tz = tz),
                  format(end_ct, "%H:%M", tz = tz), format(start_ct, "%Z", tz = tz), tz)
  body <- paste0("Hello,\n\nYou are invited to: ", title, "\n\nWhen: ", when, "\n\n",
                 if (nzchar(join)) paste0(join, "\n\n") else "",
                 "Please reply Yes or No to this invitation (the Yes / No buttons appear in your email app, ",
                 "and the .ics file attached adds the meeting to your calendar).\n\nBest regards")
  list(uid = item$uid, title = title, date = as.Date(ev$date), start = sprintf("%02d:%02d", smin %/% 60, round(smin) %% 60),
       duration = dur, tz = tz,
       to = inv$attendees, cc = BOS_ALWAYS_CC,
       location = as.character(zoom_or(ev$location, "")), join = join, url = as.character(zoom_or(inv$zoom_link, "")),
       subject = sprintf("Invitation: %s - %s %s (%s)", title, format(start_ct, "%a %d %b %Y %H:%M", tz = tz), format(start_ct, "%Z", tz = tz), tz),
       body = body, organizer = organizer_email)
}
