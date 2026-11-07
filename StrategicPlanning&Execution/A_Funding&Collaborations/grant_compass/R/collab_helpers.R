# ---- Shared helpers for the Collaboration Lab ------------------------------------------------

CATEGORIES <- c("Project approach", "Tool", "Capability", "Partner", "Go / no-go", "Other")
STANCE_IN  <- c("Fine with the recommendation" = "support", "I have a concern" = "concern", "I object" = "object")
SYNC_REASONS <- c(
  "Still stuck after one written round" = "stuck",
  "First conversation with a new partner" = "intro",
  "Complex technical point that is hard to write" = "technical",
  "Urgent or deadline-driven" = "urgent",
  "Other (explain in the topic)" = "other")

# ---- icons (inline SVG, stroke style) ---------------------------------------------------------
ICON_PATHS <- list(
  home = "M3 11l9-8 9 8v10a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1z",
  grid = "M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z",
  target = "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM12 18a6 6 0 1 0 0-12 6 6 0 0 0 0 12zM12 14a2 2 0 1 0 0-4 2 2 0 0 0 0 4z",
  bulb = "M9 18h6M10 22h4M12 2a7 7 0 0 0-4 12.7c.6.5 1 1.3 1 2.3h6c0-1 .4-1.8 1-2.3A7 7 0 0 0 12 2z",
  compass = "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM16 8l-2 6-6 2 2-6z",
  check = "M22 11.1V12a10 10 0 1 1-5.9-9.1M22 4L12 14l-3-3",
  book = "M4 19.5A2.5 2.5 0 0 1 6.5 17H20V3H6.5A2.5 2.5 0 0 0 4 5.5zM6.5 17H20v4H6.5a2.5 2.5 0 0 1 0-4z",
  pencil = "M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z",
  calendar = "M3 4h18v18H3zM16 2v4M8 2v4M3 10h18",
  bookopen = "M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2zM22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z",
  shield = "M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z",
  users = "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM23 21v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8",
  flame = "M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.4-.5-2-1-3-1.1-2.1-.2-4 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.2.4-2.4 1-3a2.5 2.5 0 0 0 2.5 2.5z",
  clock = "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM12 6v6l4 2",
  lock = "M5 11h14v10H5zM8 11V7a4 4 0 0 1 8 0v4",
  send = "M22 2L11 13M22 2l-7 20-4-9-9-4z",
  star = "M12 2l3.1 6.3 6.9 1-5 4.9 1.2 6.8L12 17.8 5.8 21l1.2-6.8-5-4.9 6.9-1z",
  sliders = "M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6"
)

ico <- function(name, size = 16) {
  HTML(sprintf('<svg class="ico" width="%d" height="%d" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="%s"/></svg>',
               size, size, ICON_PATHS[[name]] %||% ""))
}

# ---- dates and statuses -------------------------------------------------------------------------
week_start <- function(d = Sys.Date()) {
  d <- as.Date(d); d - (as.integer(format(d, "%u")) - 1L)
}

dec_latest   <- function(df) latest_by(df, "decision_id")
in_latest    <- function(df) latest_by(df, c("decision_id", "email"))
sync_latest  <- function(df) latest_by(df, "req_id")
weekly_latest <- function(df) latest_by(df, c("email", "week"))

deadline_info <- function(deadline) {
  dl <- days_left(deadline)
  if (is.na(dl)) return(list(label = "No deadline", cls = "grey", days = NA_integer_))
  if (dl < 0)  return(list(label = "Input closed", cls = "amber", days = dl))
  if (dl == 0) return(list(label = "Closes today", cls = "mag", days = dl))
  if (dl == 1) return(list(label = "1 day left", cls = "mag", days = dl))
  list(label = sprintf("%d days left", dl), cls = "teal", days = dl)
}

# open -> (deadline passed) -> ready -> decided
eff_status <- function(status, deadline) {
  status <- status %||% "open"
  if (status %in% c("decided", "withdrawn")) return(status)
  dl <- days_left(deadline)
  if (!is.na(dl) && dl < 0) "ready" else "open"
}

status_chip <- function(es) {
  switch(es,
    open = chip("Open for input", "teal"), ready = chip("Ready to decide", "amber"),
    decided = chip("Decided", "green"), withdrawn = chip("Withdrawn", "grey"), chip(es))
}

people_in <- function(d) {
  p <- unique(tolower(c(d$driver, d$approver, split_tags(d$contributors))))
  p[nzchar(p)]
}
open_to_all <- function(d) length(split_tags(d$contributors)) == 0

# Decisions that need this person: open and not yet weighed in (if invited / open to all),
# or ready and they are the approver.
needs_you <- function(decisions, inputs, email) {
  d <- dec_latest(decisions)
  if (nrow(d) == 0) return(d)
  i <- in_latest(inputs)
  keep <- vapply(seq_len(nrow(d)), function(k) {
    r <- d[k, ]; es <- eff_status(r$status, r$deadline)
    voted <- any(i$decision_id == r$decision_id & i$email == email)
    mine  <- open_to_all(r) || email %in% people_in(r)
    (es == "open" && mine && !voted) || (es == "ready" && tolower(r$approver) == email)
  }, logical(1))
  d[keep, , drop = FALSE]
}

streak_weeks <- function(weekly, email) {
  w <- unique(weekly$week[weekly$email == email & nzchar(weekly$updated_at)])
  w <- as.Date(w); w <- w[!is.na(w)]
  if (length(w) == 0) return(0L)
  cur <- week_start()
  if (!(cur %in% w)) cur <- cur - 7
  n <- 0L
  while (cur %in% w) { n <- n + 1L; cur <- cur - 7 }
  n
}

# ---- points and badges (shared by Welcome and Workspace) -----------------------------------------
team_points <- function(data) {
  pts <- numeric(0)
  add <- function(emails, n) {
    emails <- emails[nzchar(emails)]
    if (length(emails)) pts <<- c(pts, stats::setNames(rep(n, length(emails)), emails))
  }
  p <- latest_by(data$prio, c("email", "grant_id")); add(p$email, 10)
  add(data$ideas$author, 15)
  v <- latest_by(data$votes, c("idea_id", "voter")); add(v$voter[v$vote == "1"], 2)
  d <- dec_latest(data$decisions)
  add(d$created_by[d$reopen_count %in% c("", "0")], 15)
  add(d$decided_by[d$status == "decided"], 10)
  add(in_latest(data$dinputs)$email, 8)
  add(weekly_latest(data$weekly)$email, 10)
  sy <- sync_latest(data$syncs); add(sy$requested_by[sy$status == "held" & nzchar(sy$outcome)], 5)
  if (!length(pts)) return(numeric(0))
  sort(tapply(pts, names(pts), sum), decreasing = TRUE)
}

badges_for <- function(data, email) {
  p <- latest_by(data$prio, c("email", "grant_id"))
  i <- in_latest(data$dinputs)
  d <- dec_latest(data$decisions)
  firsts <- 0
  if (nrow(i)) {
    o <- i[order(i$updated_at), ]
    firsts <- sum(o$email[!duplicated(o$decision_id)] == email)
  }
  list(
    list(id = "scorer", icon = "target", name = "Scorer", desc = "Scored 3 grants", on = sum(p$email == email) >= 3),
    list(id = "spark", icon = "bulb", name = "Idea spark", desc = "Shared an idea", on = any(data$ideas$author == email)),
    list(id = "voice", icon = "users", name = "First voice", desc = "First to weigh in on a decision", on = firsts >= 1),
    list(id = "decider", icon = "check", name = "Decider", desc = "Recorded a decision", on = any(d$decided_by == email & d$status == "decided")),
    list(id = "streak", icon = "flame", name = "On a roll", desc = "2+ weekly updates in a row", on = streak_weeks(data$weekly, email) >= 2))
}

md_escape <- function(x) gsub("\n", "\n  ", x %||% "")
