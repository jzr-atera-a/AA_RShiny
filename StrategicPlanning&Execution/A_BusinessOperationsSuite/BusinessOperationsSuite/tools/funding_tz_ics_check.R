# tools/funding_tz_ics_check.R - time zones + calendar (.ics) for Funding Programmes.
suppressMessages({ library(shiny); library(R6) })
`%||%` <- function(a, b) if (is.null(a)) b else a
source("R/utils_timezone.R"); source("R/utils_ics.R")
src <- readLines("R/api_manager.R")
take <- function(start) { i <- grep(start, src)[1]; j <- i - 1 + which(grepl("^[})]\\s*$", src[i:length(src)]))[1]; eval(parse(text = src[i:j]), envir = globalenv()) }
take("^PROGRAMME_FIELDS <- c\\("); take("^parse_programme_text <- function")
pass <- 0; fail <- 0
check <- function(n, ok, d = NULL) { ok <- isTRUE(ok); cat(if (ok) "PASS " else "FAIL ", n, if (!ok && !is.null(d)) paste(" ->", paste(format(d), collapse = " ")), "\n", sep = ""); if (ok) pass <<- pass + 1 else fail <<- fail + 1 }
txt <- "[programme_name]: Innovate Smart Grants\n[category]: Grant\n[country]: United Kingdom\n[city_region]: All\n[deadline]: 2026-12-10 17:00\n[start_date_for_applying]: 2026-11-30\n[verified_urls]: https://www.ukri.org/x\n\n[programme_name]: Seed Fund\n[category]: Loan\n[country]: United Kingdom\n[city_region]: London\n[deadline]: 2027-01-15\n\n[programme_name]: Rolling Scheme\n[category]: Grant\n[country]: Mexico\n[city_region]: All\n[deadline]: Rolling - check site"
d <- parse_programme_text(bos_tz_set_header(txt, "Europe/London"), default_tz = "America/Mexico_City")
check("parser: 3 programmes", nrow(d) == 3, nrow(d))
check("parser: zone from [time_zone] header wins", all(d$time_zone == "Europe/London"), d$time_zone)
d2 <- parse_programme_text(txt, default_tz = "Asia/Tokyo")
check("parser: no header -> the tab's zone", all(d2$time_zone == "Asia/Tokyo"))
check("parser: invalid tab zone -> default", all(parse_programme_text(txt, default_tz = "Mars/Base")$time_zone == BOS_DEFAULT_TZ))
check("header replaces an old header", sum(grepl("^\\[time_zone\\]", strsplit(bos_tz_set_header(bos_tz_set_header(txt, "UTC"), "Europe/Paris"), "\n")[[1]])) == 1)
check("prompt carries the zone and offset", grepl("Europe/London", bos_tz_wrap_prompt("P", "Europe/London", as.Date("2026-07-01"))) && grepl("UTC\\+01:00", bos_tz_wrap_prompt("P", "Europe/London", as.Date("2026-07-01"))))
r <- ics_events_funding(d, include_opens = TRUE, alarms = TRUE)
check("calendar: 2 deadlines + 1 open date, rolling one noted", length(r$events) == 3 && length(r$notes) == 1, list(length(r$events), r$notes))
r2 <- ics_events_funding(d, include_opens = FALSE, alarms = TRUE)
check("calendar: open dates can be left out", length(r2$events) == 2)
f <- tempfile(fileext = ".ics"); ics_write_safe(function() r$events, "Funding Programmes", f)
ics <- paste(readLines(f, warn = FALSE), collapse = "\n")
check("ics: 17:00 London deadline -> 17:00 UTC (winter)", grepl("DTSTART:20261210T170000Z", ics, fixed = TRUE), regmatches(ics, gregexpr("DTSTART[^\n]*", ics))[[1]])
dm <- d[1, ]; dm$time_zone <- "America/Mexico_City"
fm <- tempfile(fileext = ".ics"); ics_write_safe(function() ics_events_funding(dm)$events, "Funding Programmes", fm)
check("ics: 17:00 Mexico City deadline -> 23:00 UTC", grepl("DTSTART:20261210T230000Z", paste(readLines(fm, warn = FALSE), collapse = "\n"), fixed = TRUE))
check("ics: date-only deadline is all-day", grepl("DTSTART;VALUE=DATE:20270115", ics, fixed = TRUE))
check("ics: reminders 7 days, 1 day, 1 hour", all(vapply(c("TRIGGER:-P7D", "TRIGGER:-P1D", "TRIGGER:-PT1H"), grepl, TRUE, ics, fixed = TRUE)))
check("ics: application-open entry", grepl("Applications open: Innovate Smart Grants", ics, fixed = TRUE))
check("ics: CRLF line endings", grepl("\r\n", rawToChar(readBin(f, "raw", file.size(f))), fixed = TRUE))
fn <- tempfile(fileext = ".ics"); ics_write_safe(function() ics_events_funding(d, alarms = FALSE)$events, "Funding Programmes", fn)
check("ics: no reminders when switched off", !grepl("VALARM", paste(readLines(fn, warn = FALSE), collapse = "\n")))
writeLines(ics, "/home/claude/e2e/funding_test.ics")
check("empty data -> nothing, no error", length(ics_events_funding(d[0, ])$events) == 0)
Sys.setenv(TZ = "Europe/London"); check("dropdown starts on the computer's zone", bos_tz_local_default() == "Europe/London")
Sys.setenv(TZ = "Pacific/Chatham"); check("unknown local zone -> default", bos_tz_local_default() == BOS_DEFAULT_TZ)
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); quit(status = if (fail) 1 else 0)
