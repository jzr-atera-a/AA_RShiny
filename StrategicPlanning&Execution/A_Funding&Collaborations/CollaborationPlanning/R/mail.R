# R/mail.R - sending email over SMTP, and reading emails and documents into text
#
# Sending is ported from DaysPlanningFundingTravel R/utils_titan.R (titan_build_message,
# titan_smtp_deliver, titan_send_mail): libcurl talks SMTP directly, so no mail package is needed.
#   * multipart/mixed with attachments; an optional calendar invite as text/calendar
#   * if the server refuses one recipient, each recipient is tried on its own and the refused ones are named
#   * the login is hidden in every log line
# Settings: smtp_host, smtp_port, smtp_user (Admin > Email). The password comes from SMTP_PASSWORD
# or is pasted in Admin > Email (server memory only). It is never written to the Sheet or BigQuery.
#
# Reading: mail_read_file() turns .eml, .txt, .pdf, .docx files into plain text;
# eml_parse() pulls From / To / Subject / Date and the text body out of a raw email.

smtp_password <- function() { k <- session_key_get("smtp_password"); if (nzchar(k)) k else cfg$smtp_password }

smtp_config <- function(s = get_settings()) {
  list(host = trimws(s$smtp_host %||% ""), port = suppressWarnings(as.integer(s$smtp_port %||% 465)) %||% 465L,
       user = trimws(s$smtp_user %||% ""), pass = smtp_password(),
       always_cc = split_emails(s$smtp_always_cc %||% ""))
}
smtp_ready <- function(s = get_settings()) { c <- smtp_config(s); nzchar(c$host) && nzchar(c$user) && nzchar(c$pass) }

split_emails <- function(x) {
  v <- trimws(unlist(strsplit(paste(as.character(x %||% ""), collapse = ","), "[,;\n]")))
  unique(tolower(v[nzchar(v)]))
}
valid_email <- function(x) grepl("^[^@[:space:]<>]+@[^@[:space:]<>]+\\.[^@[:space:]<>]+$", x)

smtp_url <- function(host, port) paste0(if (as.integer(port) == 465) "smtps://" else "smtp://", host, ":", as.integer(port))

mime_header_text <- function(s) {
  s <- gsub("[\r\n]+", " ", as.character(s %||% ""))
  if (grepl("^[ -~]*$", s)) return(s)
  paste0("=?UTF-8?B?", gsub("\n", "", base64enc::base64encode(charToRaw(enc2utf8(s)))), "?=")
}

b64_lines <- function(x) {
  raw <- if (is.raw(x)) x else charToRaw(enc2utf8(as.character(x)))
  b <- gsub("\n", "", base64enc::base64encode(raw))
  if (!nzchar(b)) return("")
  substring(b, seq(1, nchar(b), 76), pmin(seq(76, nchar(b) + 75, 76), nchar(b)))
}

# RFC 5322 message with CRLF endings. attachments: list(list(path, name)). calendar: list(text, method, filename)
mail_build_message <- function(from, to, subject, body, cc = NULL, attachments = NULL, calendar = NULL) {
  stopifnot(length(to) > 0)
  dom <- sub("^.*@", "", from)
  bd_new <- function() paste0("=_cp_", paste(sample(c(letters, 0:9), 24, TRUE), collapse = ""))
  hdr <- c(paste0("From: ", from), paste0("To: ", paste(to, collapse = ", ")),
           if (length(cc)) paste0("Cc: ", paste(cc, collapse = ", ")),
           paste0("Subject: ", mime_header_text(subject)),
           paste0("Date: ", format(Sys.time(), "%a, %d %b %Y %H:%M:%S +0000", tz = "UTC")),
           paste0("Message-ID: <", bd_new(), "@", if (nzchar(dom)) dom else "localhost", ">"), "MIME-Version: 1.0")
  text_part <- c("Content-Type: text/plain; charset=UTF-8", "Content-Transfer-Encoding: base64", "", b64_lines(body %||% ""))
  atts <- Filter(function(a) !is.null(a$path) && file.exists(a$path), attachments %||% list())
  if (!length(atts) && is.null(calendar)) return(paste0(paste(c(hdr, text_part), collapse = "\r\n"), "\r\n"))
  bd <- bd_new()
  parts <- c(paste0('Content-Type: multipart/mixed; boundary="', bd, '"'), "")
  if (!is.null(calendar) && nzchar(calendar$text %||% "")) {
    alt <- bd_new(); meth <- toupper(calendar$method %||% "REQUEST"); fn <- calendar$filename %||% "invite.ics"
    parts <- c(parts, paste0("--", bd), paste0('Content-Type: multipart/alternative; boundary="', alt, '"'), "",
               paste0("--", alt), text_part, "",
               paste0("--", alt), paste0("Content-Type: text/calendar; charset=UTF-8; method=", meth),
               "Content-Transfer-Encoding: base64", "", b64_lines(calendar$text), "", paste0("--", alt, "--"), "",
               paste0("--", bd), paste0("Content-Type: text/calendar; charset=UTF-8; method=", meth, '; name="', fn, '"'),
               "Content-Transfer-Encoding: base64", paste0('Content-Disposition: attachment; filename="', fn, '"'), "",
               b64_lines(calendar$text), "")
  } else parts <- c(parts, paste0("--", bd), text_part, "")
  for (a in atts) {
    ct <- switch(tolower(tools::file_ext(a$name)), pdf = "application/pdf",
      docx = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      xlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      txt = "text/plain", csv = "text/csv", md = "text/markdown", png = "image/png", jpg = "image/jpeg",
      jpeg = "image/jpeg", ics = "text/calendar", "application/octet-stream")
    nm <- gsub('[\r\n"]', "_", as.character(a$name %||% basename(a$path)))
    parts <- c(parts, paste0("--", bd), paste0("Content-Type: ", ct, '; name="', nm, '"'),
               "Content-Transfer-Encoding: base64", paste0('Content-Disposition: attachment; filename="', nm, '"'), "",
               b64_lines(readBin(a$path, "raw", file.info(a$path)$size)), "")
  }
  paste0(paste(c(hdr, parts, paste0("--", bd, "--")), collapse = "\r\n"), "\r\n")
}

mask_smtp_line <- function(x) {
  x <- sub("^(AUTH\\s+\\w+).*$", "\\1 <hidden>", x, ignore.case = TRUE)
  ifelse(grepl("^[A-Za-z0-9+/=]{8,}$", x), "<hidden>", x)
}

# One delivery. Never stops: list(ok, error, rejected)
smtp_deliver <- function(msg, from, rcpt, url, user, pass, timeout = 60) {
  transcript <- character(0)
  dbgf <- function(type, data) {
    if (!(type %in% c(0L, 1L, 2L))) return(invisible())
    txt <- trimws(unlist(strsplit(rawToChar(data[data != as.raw(0)]), "\r?\n")))
    transcript <<- c(transcript, paste0(c("* ", "< ", "> ")[type + 1L], mask_smtp_line(txt[nzchar(txt)])))
    invisible()
  }
  con <- rawConnection(charToRaw(msg)); on.exit(close(con), add = TRUE)
  h <- curl::new_handle(upload = TRUE, readfunction = function(n, ...) readBin(con, raw(), n),
                        mail_from = from, mail_rcpt = rcpt, use_ssl = 2, verbose = TRUE, debugfunction = dbgf,
                        username = user, password = pass, timeout = timeout, connecttimeout = 20)
  r <- tryCatch(curl::curl_fetch_memory(url, handle = h), error = function(e) e)
  if (!inherits(r, "error")) return(list(ok = TRUE, error = NULL, rejected = NULL))
  rc <- grep("^> RCPT TO:", transcript, value = TRUE)
  rej <- if (grepl("RCPT", conditionMessage(r), ignore.case = TRUE) && length(rc))
    sub("^> RCPT TO:\\s*<?([^>\\s]*)>?.*$", "\\1", utils::tail(rc, 1), perl = TRUE)
  list(ok = FALSE, error = conditionMessage(r), rejected = rej)
}

smtp_error_text <- function(m, host, port) {
  hint <- if (grepl("535|auth|login|denied", m, ignore.case = TRUE)) " Check the mailbox password and that SMTP is allowed for this mailbox."
    else if (grepl("resolve|connect|timed out|timeout", m, ignore.case = TRUE)) paste0(" Could not reach ", host, ":", port, ". Check the server and port in Admin > Email.")
    else if (grepl("RCPT|550|551|553", m)) " The server refused a recipient. Check the spelling of every address."
    else ""
  paste0("Sending failed: ", trimws(m), hint)
}

# Send one email. Returns TRUE or stops with a readable message.
send_mail <- function(to, subject, body, cc = NULL, attachments = NULL, calendar = NULL, conf = smtp_config()) {
  if (!nzchar(conf$host) || !nzchar(conf$user)) stop("Email is not set up. An admin can set it in Admin > Email.", call. = FALSE)
  if (!nzchar(conf$pass)) stop("No email password is set (SMTP_PASSWORD, or Admin > Email).", call. = FALSE)
  to <- split_emails(to); cc <- setdiff(unique(c(split_emails(cc), conf$always_cc)), to)
  if (!length(to)) stop("Add at least one recipient.", call. = FALSE)
  bad <- c(to, cc)[!valid_email(c(to, cc))]
  if (length(bad)) stop("These addresses do not look valid: ", paste(bad, collapse = ", "), call. = FALSE)
  msg <- mail_build_message(conf$user, to, subject, body, cc, attachments, calendar)
  rcpt <- unique(c(to, cc)); url <- smtp_url(conf$host, conf$port)
  log_debug("[Mail] sending '", substr(subject, 1, 60), "' to ", length(rcpt), " recipient(s) via ", conf$host)
  one <- smtp_deliver(msg, conf$user, rcpt, url, conf$user, conf$pass)
  if (one$ok) return(TRUE)
  if (!is.null(one$rejected) && length(rcpt) > 1) {
    res <- vapply(rcpt, function(r) smtp_deliver(msg, conf$user, r, url, conf$user, conf$pass)$ok, TRUE)
    if (all(res)) return(TRUE)
    stop(sprintf("Delivered to: %s. Refused: %s.", paste(rcpt[res], collapse = ", ") %||% "nobody",
                 paste(rcpt[!res], collapse = ", ")), call. = FALSE)
  }
  log_debug("[Mail] failed: ", one$error)
  stop(smtp_error_text(one$error, conf$host, conf$port), call. = FALSE)
}

# Log in and say NOOP: checks the settings without sending anything
smtp_test <- function(conf = smtp_config()) {
  if (!nzchar(conf$host) || !nzchar(conf$user) || !nzchar(conf$pass)) return(list(ok = FALSE, msg = "Server, address and password are all needed."))
  h <- curl::new_handle(username = conf$user, password = conf$pass, timeout = 20, connecttimeout = 15,
                        use_ssl = 3L, customrequest = "NOOP", nobody = TRUE)
  r <- tryCatch(curl::curl_fetch_memory(smtp_url(conf$host, conf$port), handle = h), error = function(e) e)
  if (inherits(r, "error")) return(list(ok = FALSE, msg = smtp_error_text(conditionMessage(r), conf$host, conf$port)))
  list(ok = TRUE, msg = sprintf("Logged in to %s:%s as %s.", conf$host, conf$port, conf$user))
}

# ---- reading emails and documents -------------------------------------------------------------
qp_decode <- function(x) {
  x <- gsub("=\r?\n", "", x)
  m <- gregexpr("=[0-9A-Fa-f]{2}", x)
  regmatches(x, m) <- lapply(regmatches(x, m), function(h) if (length(h)) {
    vapply(h, function(z) rawToChar(as.raw(strtoi(substr(z, 2, 3), 16L))), "") } else h)
  x
}

decode_mime_words <- function(s) {
  m <- gregexpr("=\\?[^?]+\\?[BbQq]\\?[^?]*\\?=", s)
  regmatches(s, m) <- lapply(regmatches(s, m), function(w) vapply(w, function(z) {
    p <- strsplit(z, "?", fixed = TRUE)[[1]]
    out <- tryCatch(if (toupper(p[3]) == "B") rawToChar(base64enc::base64decode(p[4])) else qp_decode(gsub("_", " ", p[4])),
                    error = function(e) z)
    iconv(out, "UTF-8", "UTF-8", sub = "")
  }, ""))
  s
}

# Split a raw email into headers and text. Works for plain and multipart messages.
eml_parse <- function(raw) {
  raw <- gsub("\r\n", "\n", paste(raw, collapse = "\n"))
  cut <- regexpr("\n\n", raw)
  if (cut < 0) return(list(from = "", to = "", subject = "", date = "", body = raw))
  head <- substr(raw, 1, cut - 1); body <- substr(raw, cut + 2, nchar(raw))
  head <- gsub("\n[ \t]+", " ", head)
  hv <- function(name) {
    m <- regmatches(head, regexpr(paste0("(?im)^", name, ":[^\n]*"), head, perl = TRUE))
    if (!length(m)) "" else decode_mime_words(trimws(sub("^[^:]+:", "", m)))
  }
  ctype <- hv("Content-Type"); enc <- tolower(hv("Content-Transfer-Encoding"))
  text <- body
  bmatch <- regmatches(ctype, regexec('boundary="?([^";]+)"?', ctype, ignore.case = TRUE))[[1]]
  if (length(bmatch) == 2) {
    parts <- strsplit(body, paste0("--", bmatch[2]), fixed = TRUE)[[1]]
    plain <- NULL; html <- NULL
    for (p in parts) {
      sub_p <- eml_parse(sub("^\n", "", p))
      pc <- tolower(regmatches(p, regexpr("(?i)content-type:[^\n;]*", p, perl = TRUE)) %||% "")
      if (grepl("text/plain", pc) && is.null(plain)) plain <- sub_p$body
      else if (grepl("text/html", pc) && is.null(html)) html <- sub_p$body
      else if (grepl("multipart", pc) && is.null(plain)) plain <- sub_p$body
    }
    text <- plain %||% (if (!is.null(html)) strip_html(html) else body)
  } else {
    if (enc == "base64") text <- tryCatch(rawToChar(base64enc::base64decode(gsub("\\s", "", body))), error = function(e) body)
    else if (enc == "quoted-printable") text <- qp_decode(body)
    if (grepl("text/html", ctype, ignore.case = TRUE)) text <- strip_html(text)
  }
  list(from = hv("From"), to = hv("To"), subject = hv("Subject"), date = hv("Date"),
       body = trimws(iconv(text, "UTF-8", "UTF-8", sub = "")))
}

strip_html <- function(x) {
  x <- gsub("(?is)<(script|style)[^>]*>.*?</\\1>", " ", x, perl = TRUE)
  x <- gsub("(?i)<br\\s*/?>|</p>|</div>", "\n", x, perl = TRUE)
  x <- gsub("<[^>]+>", " ", x)
  x <- gsub("&nbsp;", " ", x, fixed = TRUE); x <- gsub("&amp;", "&", x, fixed = TRUE)
  x <- gsub("&lt;", "<", x, fixed = TRUE); x <- gsub("&gt;", ">", x, fixed = TRUE)
  gsub("[ \t]+", " ", x)
}

# Any uploaded file -> text (emails keep their headers on top)
mail_read_file <- function(path, name = basename(path)) {
  ext <- tolower(tools::file_ext(name))
  if (ext == "pdf") { need_pkg("pdftools"); return(paste(pdftools::pdf_text(path), collapse = "\n")) }
  if (ext == "docx") {
    need_pkg("officer")
    d <- officer::docx_summary(officer::read_docx(path))
    return(paste(d$text[nzchar(d$text)], collapse = "\n"))
  }
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  if (ext %in% c("eml", "msg") || grepl("^(Received|From|Return-Path|Delivered-To|MIME-Version):", txt)) {
    e <- eml_parse(txt)
    return(paste0("From: ", e$from, "\nTo: ", e$to, "\nDate: ", e$date, "\nSubject: ", e$subject, "\n\n", e$body))
  }
  txt
}

# A meeting invitation (.ics REQUEST) so the recipient's mail app shows Yes / No / Maybe.
# start_local: "YYYY-MM-DD HH:MM" in Europe/London (or tz).
meeting_ics <- function(title, start_local, minutes, organizer, attendees, location = "", description = "", tz = "Europe/London",
                        uid = paste0(new_id("mtg"), "@collaboration-planning")) {
  st <- as.POSIXct(start_local, format = "%Y-%m-%d %H:%M", tz = tz)
  if (is.na(st)) stop("Meeting start must be a date and a time like 14:30.", call. = FALSE)
  f <- function(t) format(t, "%Y%m%dT%H%M%SZ", tz = "UTC")
  lines <- c("BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Collaboration Planning//EN", "METHOD:REQUEST", "BEGIN:VEVENT",
             paste0("UID:", uid), paste0("DTSTAMP:", f(Sys.time())), paste0("DTSTART:", f(st)), paste0("DTEND:", f(st + 60 * minutes)),
             ics_fold(paste0("SUMMARY:", ics_escape(title))), ics_fold(paste0("LOCATION:", ics_escape(location))),
             ics_fold(paste0("DESCRIPTION:", ics_escape(description))), paste0("ORGANIZER:mailto:", organizer),
             unlist(lapply(attendees, function(a) ics_fold(paste0("ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE:mailto:", a)))),
             "SEQUENCE:0", "STATUS:CONFIRMED", "END:VEVENT", "END:VCALENDAR")
  paste0(paste(unlist(lines), collapse = "\r\n"), "\r\n")
}
