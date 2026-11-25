# tools/merge_fgc_check.R - pieces merged from FundingGanttContactsCollaboration:
# Gantt timeline .ics, meeting invitation email (curl), Slack layer on httr, registry order.
# Needs the local SMTP test server on 8465 (see email_curl_check.R): MAIL_LOG and CURL_CA_BUNDLE set.
suppressMessages({ library(shiny); library(R6); library(httr); library(jsonlite) })
options(bos.smtps_ports = c("465", "8465"))
for (f in c("R/utils_timezone.R", "R/api_manager.R", "R/utils_ics.R", "R/utils_slack.R")) source(f)
pass <- 0; fail <- 0
check <- function(n, ok, d = NULL) { ok <- isTRUE(ok); cat(if (ok) "PASS " else "FAIL ", n, if (!ok && !is.null(d)) paste(" ->", paste(format(d), collapse = " ")), "\n", sep = ""); if (ok) pass <<- pass + 1 else fail <<- fail + 1 }

# --- Gantt timeline
g <- data.frame(Task_Name = c("Design", "Build", "No dates"), Start_Date = c("2026-12-01", "2026-12-05", NA),
                End_Date = c("2026-12-03", "2026-12-04", NA), Assignee = c("Ana", "Ben", ""), Priority = c("High", "", ""),
                stringsAsFactors = FALSE)
r <- ics_safe_build(ics_events_gantt, g)
txt <- ics_calendar_text(r$events, "Project Task Timeline")
check("gantt: 2 events, undated task noted", length(r$events) == 2 && length(r$notes) == 1, r$notes)
check("gantt: span Dec 1-3 written as DTEND Dec 4 (exclusive)", grepl("DTSTART;VALUE=DATE:20261201\r\nDTEND;VALUE=DATE:20261204", txt, fixed = TRUE))
check("gantt: end before start falls back to one day", grepl("DTSTART;VALUE=DATE:20261205\r\nDTEND;VALUE=DATE:20261206", txt, fixed = TRUE))
check("gantt: assignee in description + reminder", grepl("Assignee: Ana", txt) && grepl("TRIGGER:-P1D", txt))
check("funding events unchanged (single-day DTEND)", {
  f <- ics_events_funding(data.frame(programme_name = "X", deadline = "2026-12-10", start_date_for_applying = "", time_zone = "Europe/London"))
  grepl("DTEND;VALUE=DATE:20261211", ics_calendar_text(f$events)) })

# --- invitation
inv <- ics_invite_text("u1@x", "Kickoff", as.Date("2026-12-02"), 10 * 60, 45, "Europe/London", "me@test.org",
                       to = "a@x.org", cc = c("c@x.org", "a@x.org"), location = "https://zoom.us/j/1")
check("invite: METHOD:REQUEST, 10:00 London = 10:00Z in December", grepl("METHOD:REQUEST", inv) && grepl("DTSTART:20261202T100000Z", inv) && grepl("DTEND:20261202T104500Z", inv))
check("invite: organizer, required + optional attendees (no duplicates)",
      grepl("ORGANIZER;CN=\"me@test.org\":mailto:me@test.org", inv) && length(gregexpr("ATTENDEE", inv)[[1]]) == 2 && grepl("ROLE=OPT-PARTICIPANT", inv))
last_mail <- function() { x <- strsplit(paste(readLines(log, warn = FALSE), collapse = "\n"), "=== END")[[1]]; tail(x[nzchar(trimws(x))], 1) }
log <- Sys.getenv("MAIL_LOG"); n0 <- if (file.exists(log)) length(grep("=== END", readLines(log))) else 0
ok <- tryCatch(send_email_with_curl("me@test.org", "a@x.org", "Kickoff", "See you there", "localhost", 8465, "me@test.org", "s3cret",
                                    cc = "c@x.org", calendar = list(text = inv, method = "REQUEST", filename = "invite.ics")),
               error = function(e) conditionMessage(e))
m <- last_mail()
check("invite email accepted by the server (to + cc)", isTRUE(ok) && grepl("TO a@x.org,c@x.org", m), ok)
check("invite email: inline text/calendar method=REQUEST inside multipart/alternative",
      grepl("multipart/alternative", m) && grepl("text/calendar; charset=UTF-8; method=REQUEST", m, fixed = TRUE))
check("invite email: .ics also attached", grepl('filename="invite.ics"', m, fixed = TRUE))
b64 <- regmatches(m, regexpr("method=REQUEST\nContent-Transfer-Encoding: base64\n\n[A-Za-z0-9+/=\n]+", m))
dec <- rawToChar(base64enc::base64decode(sub("^.*base64\n\n", "", b64)))
check("invite email: calendar part decodes back to the same .ics", identical(dec, inv))
ok <- tryCatch(send_email_with_curl("me@test.org", "a@x.org", "Plain", "Body", "localhost", 8465, "me@test.org", "s3cret"), error = function(e) conditionMessage(e))
m <- last_mail()
check("plain email still single-part text", isTRUE(ok) && !grepl("multipart", m) && grepl("text/plain", m))

# --- Slack layer on httr against a mock
srv <- httpuv::startServer("127.0.0.1", 8931, list(call = function(req) {
  auth <- req$HTTP_AUTHORIZATION; path <- req$PATH_INFO
  body <- if (!identical(auth, "Bearer xoxb-good")) list(ok = FALSE, error = "invalid_auth")
          else if (path == "/api/auth.test") list(ok = TRUE, team = "Acme", user = "bot", url = "https://acme.slack.com/")
          else if (path == "/api/chat.postMessage") { p <- jsonlite::fromJSON(rawToChar(req$rook.input$read())); list(ok = TRUE, channel = p$channel, ts = "1.1", echo = p$text) }
          else list(ok = FALSE, error = "unknown_method")
  list(status = 200L, headers = list("Content-Type" = "application/json", "x-oauth-scopes" = "chat:write,channels:read"),
       body = jsonlite::toJSON(body, auto_unbox = TRUE))
}))
options(bos.slack_base = "http://127.0.0.1:8931/api")
res <- NULL; later::run_now(); 
call_bg <- function(...) { out <- NULL; p <- parallel::mcparallel(slack_call(...)); while (is.null(out)) { httpuv::service(50); out <- parallel::mccollect(p, wait = FALSE)[[1]] }; out }
r1 <- call_bg("auth.test", "xoxb-good")
check("slack: auth.test ok with scopes header read", isTRUE(r1$ok) && r1$data$team == "Acme" && grepl("chat:write", r1$scopes), r1$error)
r2 <- call_bg("auth.test", "xoxb-bad")
check("slack: bad token -> readable error", !isTRUE(r2$ok) && r2$code == "invalid_auth" && nzchar(r2$error))
r3 <- call_bg("chat.postMessage", "xoxb-good", list(channel = "C1", text = "héllo"), http = "POST")
check("slack: POST sends JSON body", isTRUE(r3$ok) && r3$data$echo == "héllo" && r3$data$channel == "C1", r3)
check("slack: no token -> not_authed without a call", identical(slack_call("auth.test", "")$code, "not_authed"))
httpuv::stopServer(srv)

# --- registry
y <- yaml::read_yaml("modules/_module_registry.yml")
lab <- vapply(y$groups, `[[`, "", "label")
check("sidebar: API Settings and Funding Programmes first, Online Collaboration inside Communications",
      identical(lab[1:2], c("API Settings", "Funding Programmes")) && "Online Collaboration" %in% vapply(y$groups[[match("Communications", lab)]]$sections, `[[`, "", "label"), lab)
adj <- function(...) all(diff(match(c(...), lab)) == 1)
check("sidebar: related groups adjacent", adj("Funding Programmes", "Project Application", "Strategy Canvases") &&
      adj("Events Scheduling", "Day Planner", "Gantt to Tickets") && adj("Health Tracker", "Media Processing"), lab)
miss <- unlist(lapply(y$groups, function(g) setdiff(g$modules, names(y$modules))))
check("every listed tab has a module entry and file", !length(miss) && all(vapply(unlist(lapply(y$groups, `[[`, "modules")), function(m) file.exists(file.path("modules", y$modules[[m]]$folder, paste0(y$modules[[m]]$file, ".R"))), TRUE)), miss)
cat(sprintf("%d passed, %d failed\n", pass, fail))
