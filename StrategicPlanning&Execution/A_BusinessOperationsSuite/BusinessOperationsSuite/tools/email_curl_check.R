# tools/email_curl_check.R - send_email_with_curl() and the Gantt to Tickets email against local SMTP servers
# (implicit TLS on 8465, STARTTLS on 8587; user me@test.org / s3cret). Run with CURL_CA_BUNDLE pointing at the test cert.
suppressMessages({ library(shiny); library(R6) })
options(bos.smtps_ports = c("465", "8465"))
for (f in c("R/utils_timezone.R", "R/api_manager.R")) source(f)
log <- Sys.getenv("MAIL_LOG")
pass <- 0; fail <- 0
check <- function(n, ok, d = NULL) { ok <- isTRUE(ok); cat(if (ok) "PASS " else "FAIL ", n, if (!ok && !is.null(d)) paste(" ->", paste(format(d), collapse = " ")), "\n", sep = ""); if (ok) pass <<- pass + 1 else fail <<- fail + 1 }
mails <- function() { if (!file.exists(log)) return(character()); x <- strsplit(paste(readLines(log, warn = FALSE), collapse = "\n"), "=== END")[[1]]; x[nzchar(trimws(x))] }
last <- function() tail(mails(), 1)
att <- tempfile(fileext = ".csv"); writeLines("a,b\n1,2", att)
ok <- tryCatch(send_email_with_curl("me@test.org", c("a@x.org"), "Implicit TLS ñ", "Hola, café", "localhost", 8465, "me@test.org", "s3cret",
                                    attachments = list(list(path = att, name = "data.csv"))), error = function(e) conditionMessage(e))
m <- last()
check("Communications sender, port 465-style (implicit TLS) + attachment", isTRUE(ok) && grepl("TO a@x.org", m) && grepl("data.csv", m), ok)
ok <- tryCatch(send_email_with_curl("me@test.org", "b@x.org", "STARTTLS", "Body", "localhost", 8587, "me@test.org", "s3cret", cc = c("c@x.org", "")),
               error = function(e) conditionMessage(e))
m <- last()
check("port 587-style (STARTTLS) with CC", isTRUE(ok) && grepl("TO b@x.org,c@x.org", m) && grepl("Cc: c@x.org", m), m)
e <- tryCatch({ send_email_with_curl("me@test.org", "b@x.org", "x", "y", "localhost", 8465, "me@test.org", "WRONG"); "sent" }, error = function(e) conditionMessage(e))
check("wrong password -> error (no silent success)", grepl("did not accept", e), e)
pw <- "it's \"quoted\" $pass"
e <- tryCatch({ send_email_with_curl("me@test.org", "b@x.org", "x", "y", "localhost", 8465, "me@test.org", pw); "sent" }, error = function(e) conditionMessage(e))
check("password with quotes/$ reaches the server intact (refused as wrong, no shell error)", grepl("curl 67|Login denied|authentication", e, ignore.case = TRUE), e)
am <- APIManager$new()
am$set_gantt_smtp_config(host = "localhost", port = 8465, user = "me@test.org", password = "s3cret", use_ssl = TRUE)
r <- tryCatch(am$test_gantt_email_connection(), error = function(e) conditionMessage(e))
m <- last()
check("Gantt: Test Email Connection sends a test email to yourself", isTRUE(am$gantt_email_connected) && grepl("Subject: Test Email - Gantt to Tickets", m) && grepl("TO me@test.org", m), r)
r <- tryCatch(am$send_gantt_email("dev@x.org", "New Task Assignment: Build API", "Hi,\nplease start.", cc = "pm@x.org"), error = function(e) conditionMessage(e))
m <- last()
check("Gantt: send task email with CC", grepl("TO dev@x.org,pm@x.org", m) && grepl("New Task Assignment: Build API", m), r)
am2 <- APIManager$new(); am2$set_gantt_smtp_config(host = "localhost", port = 8465, user = "me@test.org", password = "bad", use_ssl = TRUE)
tryCatch(am2$test_gantt_email_connection(), error = function(e) NULL)
check("Gantt: failed test leaves email not connected", !isTRUE(am2$gantt_email_connected))
check("blastula not loaded", !"blastula" %in% loadedNamespaces())
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); quit(status = if (fail) 1 else 0)
