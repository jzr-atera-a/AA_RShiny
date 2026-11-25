# R/collab.R - rules shared by several tabs
#   * fit score (Grant Compass calc_score) and eligibility status per programme
#   * the stage gate: an ineligible programme cannot move to Decide or any later working stage
#   * "Decide whether to bid" decisions, and what recording Go / No go does
#   * partner visibility (a partner sees only bids where they are in the consortium)
#   * small helpers: choices for dropdowns, word counts, money, .ics calendars

# ---- latest views of append-only tables -------------------------------------------------------
latest_consortium <- function(df = store_read("consortium")) {
  df <- latest_by(df, c("programme_id", "email"))
  df$email <- tolower(df$email)
  df
}
latest_people <- function(df = store_read("people")) {
  df <- latest_by(df, "person_id")
  df[!is_true_vec(df$deleted), , drop = FALSE]
}
latest_tasks <- function(df = store_read("tasks")) {
  df <- latest_by(df, "task_id")
  df[!is_true_vec(df$deleted), , drop = FALSE]
}
is_true_vec <- function(x) tolower(as.character(x)) %in% c("true", "1", "yes", "y")

# ---- partner visibility -----------------------------------------------------------------------
partner_programme_ids <- function(email, cons = latest_consortium()) {
  email <- tolower(trimws(email %||% ""))
  unique(cons$programme_id[cons$email == email & cons$status != "declined"])
}

# ---- fit score (Grant Compass) ----------------------------------------------------------------
calc_score <- function(a, i, c, s = get_settings()) {
  w <- suppressWarnings(as.numeric(c(s$w_alignment, s$w_interest, s$w_capability)))
  w[is.na(w)] <- 1
  if (sum(w) == 0) w <- c(1, 1, 1)
  round((w[1] * as.numeric(a) + w[2] * as.numeric(i) + w[3] * as.numeric(c)) / sum(w) * 20)
}

fit_summary <- function(prio = store_read("priorities"), s = get_settings()) {
  p <- latest_by(prio, c("email", "programme_id"))
  p <- p[nzchar(p$alignment) & nzchar(p$programme_id), , drop = FALSE]
  if (!nrow(p)) return(data.frame(programme_id = character(0), fit = numeric(0), scorers = integer(0),
                                  lead = integer(0), partner = integer(0), watch = integer(0), pass = integer(0)))
  p$score <- calc_score(p$alignment, p$interest, p$capability, s)
  ids <- unique(p$programme_id)
  data.frame(programme_id = ids,
             fit = vapply(ids, function(i) round(mean(p$score[p$programme_id == i], na.rm = TRUE)), 1),
             scorers = vapply(ids, function(i) sum(p$programme_id == i), 1L),
             lead = vapply(ids, function(i) sum(p$programme_id == i & p$stance == "lead"), 1L),
             partner = vapply(ids, function(i) sum(p$programme_id == i & p$stance == "partner"), 1L),
             watch = vapply(ids, function(i) sum(p$programme_id == i & p$stance == "watch"), 1L),
             pass = vapply(ids, function(i) sum(p$programme_id == i & p$stance == "pass"), 1L),
             stringsAsFactors = FALSE, row.names = NULL)
}

# ---- eligibility ------------------------------------------------------------------------------
# "ineligible" if any condition is "not met"; "eligible" if all met; "unclear"; or "unchecked"
eligibility_summary <- function(el = store_read("eligibility")) {
  e <- latest_by(el, c("programme_id", "condition"), "checked_at")
  e <- e[nzchar(e$programme_id) & e$result != "removed", , drop = FALSE]
  if (!nrow(e)) return(data.frame(programme_id = character(0), status = character(0), not_met = character(0)))
  ids <- unique(e$programme_id)
  st <- vapply(ids, function(i) {
    r <- e$result[e$programme_id == i]
    if (any(r == "not met")) "ineligible" else if (all(r == "met")) "eligible" else "unclear"
  }, "")
  nm <- vapply(ids, function(i) paste(e$condition[e$programme_id == i & e$result == "not met"], collapse = "; "), "")
  data.frame(programme_id = ids, status = st, not_met = nm, stringsAsFactors = FALSE, row.names = NULL)
}

elig_status_of <- function(pid, es = eligibility_summary()) {
  s <- es$status[es$programme_id == pid]
  if (length(s)) s[1] else "unchecked"
}

elig_badge <- function(status) {
  switch(status %||% "unchecked",
    ineligible = span(class = "pill pill-bad", "Ineligible"),
    eligible = span(class = "pill pill-ok", "Eligible"),
    unclear = span(class = "pill pill-warn", "Eligibility unclear"),
    NULL)
}

fit_badge <- function(fit) if (length(fit) && !is.na(fit)) span(class = "pill pill-fit", paste("Fit", fit)) else NULL

# ---- the stage gate ----------------------------------------------------------------------------
GATED_STAGES <- c("Decide", "Plan", "Write", "Deliver")

stage_gate <- function(pid, to_stage, es = eligibility_summary()) {
  if (to_stage %in% GATED_STAGES && identical(elig_status_of(pid, es), "ineligible")) {
    why <- es$not_met[es$programme_id == pid][1]
    return(list(ok = FALSE, msg = paste0("This programme is marked ineligible, so it cannot move to ", to_stage,
                                         ". Condition not met: ", why, ". Change the result in 2 Qualify > Eligibility check if this is wrong.")))
  }
  list(ok = TRUE, msg = "")
}

# Every stage move goes through here, so the gate is applied everywhere
move_programme_stage <- function(pid, to_stage, user) {
  if (!to_stage %in% STAGES) return(list(ok = FALSE, msg = "Unknown stage."))
  g <- stage_gate(pid, to_stage)
  if (!g$ok) return(g)
  all <- store_read("programmes", fresh = TRUE)
  hit <- which(all$programme_id == pid)
  if (!length(hit)) return(list(ok = FALSE, msg = "Programme not found."))
  if (identical(all$stage[hit[1]], to_stage)) return(list(ok = TRUE, msg = paste("Already at", to_stage)))
  all$stage[hit] <- to_stage; all$updated_at[hit] <- now_ts()
  ok <- store_replace("programmes", all, user = user, detail = sprintf("%s moved to %s", all$programme_name[hit[1]], to_stage))
  list(ok = ok, msg = if (ok) paste("Moved to", to_stage) else "Could not save. See Admin > Activity.")
}

update_programme_fields <- function(pid, fields, user, detail = "edited") {
  all <- store_read("programmes", fresh = TRUE)
  hit <- which(all$programme_id == pid)
  if (!length(hit)) return(FALSE)
  for (k in intersect(names(fields), names(all))) all[[k]][hit] <- as.character(fields[[k]])
  all$updated_at[hit] <- now_ts()
  store_replace("programmes", all, user = user, detail = paste(all$programme_name[hit[1]], detail))
}

# ---- decisions ---------------------------------------------------------------------------------
decision_deadline <- function(s = get_settings()) {
  d <- suppressWarnings(as.numeric(s$decision_days)); if (is.na(d)) d <- 3
  format(Sys.Date() + d)
}

create_decision <- function(title, context, options, user, programme_id = "", driver = user, approver = user,
                            contributors = "", recommended = "", kind = "general", tree_inputs = "") {
  did <- new_id("dec")
  opts <- data.frame(decision_id = did, option_id = paste0(did, "_o", seq_along(options)), label = options,
                     detail = "", created_at = now_ts(), stringsAsFactors = FALSE)
  rec_id <- if (nzchar(recommended) && recommended %in% options) opts$option_id[match(recommended, options)] else ""
  store_append("decisions", data.frame(decision_id = did, programme_id = programme_id, title = title, context = context,
    recommended_option = rec_id, driver = driver, approver = approver, contributors = contributors,
    deadline = decision_deadline(), status = "open", outcome_option = "", outcome_rationale = "", revisit_if = "",
    decided_by = "", decided_at = "", created_by = user, created_at = now_ts(), updated_at = now_ts(),
    kind = kind, tree_inputs = tree_inputs, stringsAsFactors = FALSE), user = user)
  store_append("decision_options", opts, user = user, log = FALSE)
  did
}

latest_decisions <- function() latest_by(store_read("decisions"), "decision_id")

# "Decide whether to bid": Go / No go, pre-filled with the fit score, eligibility and the go/no-go tree
create_bid_decision <- function(pid, user) {
  p <- store_read("programmes"); r <- p[p$programme_id == pid, , drop = FALSE]
  if (!nrow(r)) stop("Programme not found.")
  g <- stage_gate(pid, "Decide"); if (!g$ok) stop(g$msg)
  open <- latest_decisions(); open <- open[open$programme_id == pid & open$kind == "bid" & open$status == "open", , drop = FALSE]
  if (nrow(open)) return(open$decision_id[1])
  fs <- fit_summary(); f <- fs[fs$programme_id == pid, , drop = FALSE]
  es <- latest_by(store_read("eligibility"), c("programme_id", "condition"), "checked_at"); es <- es[es$programme_id == pid, , drop = FALSE]
  gt <- latest_by(store_read("gonogo"), "programme_id"); gt <- gt[gt$programme_id == pid, , drop = FALSE]
  ctx_lines <- c(
    sprintf("Programme: %s (%s). Closes: %s.", r$programme_name, r$funder, r$closes_date %|% r$deadline_text %|% "not known"),
    if (nrow(f)) sprintf("Team fit score: %s from %s scorer(s). Stances: %s lead, %s partner, %s watch, %s pass.",
                         f$fit, f$scorers, f$lead, f$partner, f$watch, f$pass) else "Team fit score: not scored yet.",
    if (nrow(es)) paste0("Eligibility: ", paste(sprintf("%s = %s", es$condition, es$result), collapse = "; "), ".")
    else "Eligibility: not checked yet.",
    if (nrow(gt)) sprintf("Go/no-go tree: expected value of bidding GBP %s (cost GBP %s, %s%% chance to win GBP %s); not bidding = GBP 0.",
                          fmt_num(gt$ev_bid_gbp), fmt_num(gt$bid_cost_gbp), gt$win_prob_pct, fmt_num(gt$win_value_gbp))
    else "Go/no-go tree: not filled in yet.")
  rec <- if (nrow(gt) && suppressWarnings(as.numeric(gt$ev_bid_gbp)) > 0) "Go" else if (nrow(gt)) "No go" else ""
  tree <- if (nrow(gt)) as.character(jsonlite::toJSON(as.list(gt[1, ]), auto_unbox = TRUE)) else ""
  did <- create_decision(paste("Bid for", r$programme_name, "?"), paste(ctx_lines, collapse = "\n"), c("Go", "No go"),
                         user, programme_id = pid, recommended = rec, kind = "bid", tree_inputs = tree)
  move_programme_stage(pid, "Decide", user)
  did
}

# Record the outcome. For bid decisions: Go -> Plan + a project; No go -> Learn + outcome "not pursued".
record_decision_outcome <- function(did, option_id, rationale, revisit_if, user) {
  d <- latest_decisions(); d <- d[d$decision_id == did, , drop = FALSE]
  if (!nrow(d)) stop("Decision not found.")
  opts <- store_read("decision_options"); label <- opts$label[opts$option_id == option_id][1] %||% ""
  d$status <- "decided"; d$outcome_option <- option_id; d$outcome_rationale <- rationale %||% ""
  d$revisit_if <- revisit_if %||% ""; d$decided_by <- user; d$decided_at <- now_ts(); d$updated_at <- now_ts()
  store_append("decisions", d, user = user)
  msg <- paste("Decision recorded:", label)
  if (identical(d$kind, "bid") && nzchar(d$programme_id)) {
    if (identical(label, "Go")) {
      m <- move_programme_stage(d$programme_id, "Plan", user)
      pid <- create_project_for(d$programme_id, user)
      msg <- paste0(msg, ". ", m$msg, ", project created (", pid, ").")
    } else if (identical(label, "No go")) {
      move_programme_stage(d$programme_id, "Learn", user)
      store_append("outcomes", data.frame(programme_id = d$programme_id, result = "not pursued", score = "",
        feedback = "", lessons = rationale %||% "", recorded_by = user, recorded_at = now_ts(), stringsAsFactors = FALSE), user = user)
      msg <- paste0(msg, ". Moved to Learn as not pursued.")
    }
  }
  msg
}

create_project_for <- function(pid, user) {
  pr <- store_read("projects", fresh = TRUE)
  if (any(pr$programme_id == pid)) return(pr$project_id[pr$programme_id == pid][1])
  p <- store_read("programmes"); r <- p[p$programme_id == pid, , drop = FALSE]
  start <- Sys.Date() + 90
  if (nrow(r) && nzchar(r$closes_date)) start <- tryCatch(as.Date(r$closes_date) + 90, error = function(e) start)
  id <- new_id("proj")
  store_append("projects", data.frame(project_id = id, programme_id = pid, title = if (nrow(r)) r$programme_name else "Project",
    start_date = format(start), end_date = format(seq(start, by = "12 months", length.out = 2)[2] - 1),
    budget_gbp = if (nrow(r)) r$max_gbp else "", status = "planning", created_by = user, created_at = now_ts(),
    updated_at = now_ts(), lead_email = user, stringsAsFactors = FALSE), user = user)
  id
}

update_project <- function(project_id, fields, user) {
  pr <- store_read("projects", fresh = TRUE)
  hit <- which(pr$project_id == project_id); if (!length(hit)) return(FALSE)
  for (k in intersect(names(fields), names(pr))) pr[[k]][hit] <- as.character(fields[[k]])
  pr$updated_at[hit] <- now_ts()
  store_replace("projects", pr, user = user, detail = paste("project", project_id, paste(names(fields), collapse = ",")))
}

# ---- dropdown choices ---------------------------------------------------------------------------
programme_choices <- function(p, stages = NULL, none = NULL) {
  if (!is.null(stages)) p <- p[p$stage %in% stages, , drop = FALSE]
  p <- p[order(p$programme_name), , drop = FALSE]
  ch <- setNames(p$programme_id, paste0(p$programme_name, ifelse(nzchar(p$funder), paste0(" (", p$funder, ")"), "")))
  if (!is.null(none)) ch <- c(setNames("", none), ch)
  ch
}

project_choices <- function(pr, progs) {
  pr <- pr[pr$programme_id %in% progs$programme_id | !nzchar(pr$programme_id), , drop = FALSE]
  if (!nrow(pr)) return(character(0))
  setNames(pr$project_id, paste0(pr$title, " [", pr$status, "]"))
}

# People who can be named on a project: consortium members (not declined) + the signed-in team
project_people <- function(programme_id, cons = latest_consortium(), users = get_users()) {
  c <- cons[cons$programme_id == programme_id & cons$status != "declined", , drop = FALSE]
  team <- users[users$role %in% c("admin", "member") & !(toupper(users$active) %in% c("FALSE", "PENDING")), , drop = FALSE]
  e <- unique(c(c$email, team$email)); e <- e[nzchar(e)]
  nm <- vapply(e, function(x) {
    n <- c(c$name[c$email == x], team$name[team$email == x], c$organisation[c$email == x]); n <- n[nzchar(n)]
    if (length(n)) paste0(n[1], " <", x, ">") else x
  }, "")
  setNames(e, nm)
}

# ---- small helpers -------------------------------------------------------------------------------
# a, or b where a is missing or empty (element by element for columns)
`%|%` <- function(a, b) {
  if (is.null(a) || !length(a)) return(b)
  bad <- is.na(a) | !nzchar(as.character(a))
  if (!any(bad)) return(a)
  if (length(a) == 1) return(b)
  if (!length(b)) b <- ""
  b <- rep_len(as.character(b), length(a)); a <- as.character(a); a[bad] <- b[bad]; a
}

word_count <- function(x) {
  x <- trimws(x %||% "")
  if (!nzchar(x)) return(0L)
  length(strsplit(x, "\\s+")[[1]])
}

# text -> number: plain numbers and R's "9e+05" first, then numbers inside text such as "GBP 25,000"
num <- function(x) {
  x <- as.character(x); v <- suppressWarnings(as.numeric(x))
  bad <- is.na(v) & !is.na(x)
  if (any(bad)) v[bad] <- suppressWarnings(as.numeric(gsub("[^0-9.-]", "", x[bad])))
  v[is.na(v)] <- 0; v
}
fmt_num <- function(x) format(round(num(x)), big.mark = ",", scientific = FALSE, trim = TRUE)
fmt_gbp <- function(x) paste0("GBP ", fmt_num(x))

STOPWORDS <- c("and", "the", "for", "with", "from", "that", "this", "into", "their", "they", "have", "will", "your",
               "must", "been", "also", "such", "more", "than", "each", "other", "which", "where", "what", "when",
               "about", "over", "under", "based", "including", "projects", "project", "programme", "programmes",
               "funding", "applicants", "applicant", "company", "companies", "business", "businesses", "should")
key_words <- function(x) {
  w <- unlist(strsplit(tolower(paste(x, collapse = " ")), "[^a-z0-9]+"))
  w <- w[nchar(w) >= 4 & !w %in% STOPWORDS]
  unique(sub("(ies)$", "y", sub("([^s])s$", "\\1", w)))
}

# .ics calendar text from a data frame with uid, summary, date (YYYY-MM-DD), description, alarm_days
ics_escape <- function(x) { x <- gsub("\\\\", "\\\\\\\\", x); x <- gsub("([,;])", "\\\\\\1", x); gsub("\r?\n", "\\\\n", x) }
ics_fold <- function(line) {
  if (nchar(line, "bytes") <= 74) return(line)
  ch <- strsplit(line, "")[[1]]; out <- character(0); cur <- ""
  for (c in ch) { if (nchar(paste0(cur, c), "bytes") > 74) { out <- c(out, cur); cur <- paste0(" ", c) } else cur <- paste0(cur, c) }
  c(out, cur)
}
ics_calendar <- function(ev, cal_name = APP_NAME) {
  stamp <- format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")
  lines <- c("BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Collaboration Planning//EN", "CALSCALE:GREGORIAN",
             "METHOD:PUBLISH", paste0("X-WR-CALNAME:", ics_escape(cal_name)))
  for (i in seq_len(nrow(ev))) {
    d <- as.Date(ev$date[i])
    lines <- c(lines, "BEGIN:VEVENT", paste0("UID:", ev$uid[i]), paste0("DTSTAMP:", stamp),
               paste0("DTSTART;VALUE=DATE:", format(d, "%Y%m%d")), paste0("DTEND;VALUE=DATE:", format(d + 1, "%Y%m%d")),
               ics_fold(paste0("SUMMARY:", ics_escape(ev$summary[i]))),
               ics_fold(paste0("DESCRIPTION:", ics_escape(ev$description[i] %||% ""))))
    a <- suppressWarnings(as.integer(ev$alarm_days[i] %||% NA))
    if (!is.na(a)) lines <- c(lines, "BEGIN:VALARM", "ACTION:DISPLAY", ics_fold(paste0("DESCRIPTION:", ics_escape(ev$summary[i]))),
                              paste0("TRIGGER:-P", a, "D"), "END:VALARM")
    lines <- c(lines, "END:VEVENT")
  }
  paste0(paste(c(lines, "END:VCALENDAR"), collapse = "\r\n"), "\r\n")
}

# Writes a click that sends an event value to a module input (for buttons inside rendered HTML)
js_click <- function(input_id, value) sprintf("Shiny.setInputValue('%s', %s, {priority: 'event'})", input_id, jsonlite::toJSON(value, auto_unbox = TRUE))

# Empty-state helper
empty_note <- function(...) note("info", ...)

# ---- people (contacts and partners) ------------------------------------------------------------
# Add a person, or update the one with the same email (append a newer row; latest per person_id wins)
upsert_person <- function(fields, user) {
  f <- lapply(fields, function(x) trimws(as.character(x %||% "")))
  f$email <- tolower(f$email %||% "")
  ppl <- latest_people(store_read("people", fresh = TRUE))
  hit <- if (nzchar(f$email)) ppl[ppl$email == f$email, , drop = FALSE] else ppl[0, ]
  if (!nrow(hit) && nzchar(f$name %||% "")) hit <- ppl[tolower(ppl$name) == tolower(f$name) & ppl$organisation == (f$organisation %||% ""), , drop = FALSE]
  row <- if (nrow(hit)) hit[1, , drop = FALSE] else conform(data.frame(person_id = new_id("per"), added_by = user, added_at = now_ts(),
                                                                       type = "contact", stringsAsFactors = FALSE), "people")
  for (k in intersect(names(f), SCHEMAS$people)) if (nzchar(f[[k]]) || !nrow(hit)) row[[k]] <- f[[k]]
  row$updated_at <- now_ts(); row$deleted <- "FALSE"
  store_append("people", row, user = user)
  list(person_id = row$person_id, new = !nrow(hit))
}

# Read text from an upload (CV, signature, email) using R/mail.R
upload_text <- function(fi) if (is.null(fi)) "" else tryCatch(mail_read_file(fi$datapath, fi$name), error = function(e) {
  showNotification(safe_error_text(e), type = "error", duration = 10); "" })

CONTACT_FIELDS <- c(name = "Name", email = "Email", organisation = "Organisation", role_title = "Job title", country = "Country",
                    phone = "Phone", linkedin = "LinkedIn", interests = "Interests (separated by ;)",
                    past_projects = "Past projects (separated by ;)", notes = "Notes")

# Claude reads a CV, signature or pasted text into contact fields (ported from BOS process_contact.R)
extract_contact <- function(text) {
  prompt <- paste0("Extract the contact details of the main person in this text. Reply with JSON only, with these keys: ",
    "name, email, organisation, role_title, country, phone, linkedin, interests (research or business interests, separated by ;), ",
    "past_projects (named projects, grants or programmes they worked on, separated by ;), notes (one line on who they are). ",
    "Use an empty string for anything not in the text. Do not invent details.\n\nText:\n", substr(text, 1, 30000))
  r <- claude_json(prompt, max_tokens = 1500)
  out <- lapply(names(CONTACT_FIELDS), function(k) { v <- r[[k]] %||% ""; paste(as.character(unlist(v)), collapse = "; ") })
  setNames(out, names(CONTACT_FIELDS))
}

split_list <- function(x) { v <- trimws(unlist(strsplit(as.character(x %||% ""), "[;\n]+"))); v[nzchar(v)] }

# ---- projects (phases 4 and 5) ------------------------------------------------------------------
# Project picker shared by Plan, Write and Deliver: projects of programmes this person may see
project_picker_choices <- function(ctx) {
  pr <- ctx$data$projects(); vis <- ctx$programmes()
  pr <- pr[pr$programme_id %in% vis$programme_id, , drop = FALSE]
  if (!nrow(pr)) return(character(0))
  setNames(pr$project_id, paste0(pr$title, " [", pr$status, "]"))
}
project_empty_note <- function() empty_note("No projects yet. A project is created when a bid decision is recorded as Go (4 Decide > Decisions).")

# Work-package template used for new projects (same four packages for every category, tasks differ a little)
WP_TEMPLATE <- list(
  "WP1 Project management" = c("Kick-off and partner agreement", "Monthly progress reports", "Final report and claim"),
  "WP2 Technical work" = c("Requirements and design", "Build the first version", "Improve after testing"),
  "WP3 Testing and validation" = c("Test plan", "Trials with users or partners", "Results and evaluation"),
  "WP4 Dissemination and exploitation" = c("Communications plan", "Route to market plan", "Final showcase"))

template_tasks <- function(project, category, user) {
  st <- tryCatch(as.Date(project$start_date), error = function(e) Sys.Date()); en <- tryCatch(as.Date(project$end_date), error = function(e) st + 364)
  if (is.na(st)) st <- Sys.Date(); if (is.na(en) || en <= st) en <- st + 364
  span <- as.numeric(en - st)
  wp <- WP_TEMPLATE
  if (category %in% c("Accelerator", "Incubator")) names(wp)[2] <- "WP2 Programme activities"
  rows <- list()
  for (w in names(wp)) for (k in seq_along(wp[[w]])) {
    frac <- switch(substr(w, 1, 3), WP1 = c(0, 1), WP2 = c(0.05, 0.75), WP3 = c(0.5, 0.95), c(0.1, 1))
    a <- st + round(span * (frac[1] + (frac[2] - frac[1]) * (k - 1) / length(wp[[w]])))
    b <- st + round(span * (frac[1] + (frac[2] - frac[1]) * k / length(wp[[w]])))
    rows[[length(rows) + 1]] <- data.frame(task_id = new_id("task"), project_id = project$project_id, work_package = w,
      task = wp[[w]][k], start_date = format(a), end_date = format(b), owner_email = "", partner = "", status = "to do",
      trello_card_id = "", updated_at = now_ts(), description = "", trello_url = "", deleted = "FALSE", updated_by = user,
      stringsAsFactors = FALSE)
  }
  do.call(rbind, rows)
}

TASK_STATUS <- c("to do", "in progress", "done", "blocked")

# setNames that copes with no rows (paste0 of empty columns still returns one string)
named <- function(values, labels) if (!length(values)) character(0) else setNames(values, labels)

# The choice to keep selected when a dropdown's choices are refreshed: the current one if still offered,
# else the preferred one, else the first (an empty "" from a fresh input counts as nothing chosen)
pick_sel <- function(current, choices, prefer = NULL) {
  v <- unname(as.character(choices))
  for (c in list(current, prefer)) if (length(c) == 1 && !is.na(c) && nzchar(c) && c %in% v) return(c)
  if (length(v)) v[1] else NULL
}
