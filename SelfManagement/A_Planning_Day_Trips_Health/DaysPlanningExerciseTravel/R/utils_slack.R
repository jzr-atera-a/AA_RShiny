# =============================================================================
# R/utils_slack.R - Slack API layer for the "Online Collaboration" tab group
#
# Pure functions: HTTP calls to the Slack Web API with httr2, no Shiny code.
# Every top-level name starts with slack_ / SLACK_ so nothing can collide with
# the other suites. No token is ever printed or logged.
#
# NOTE: helper names must NOT end in _ui or _server (app.R removes every
# global object matching that pattern on restart).
#
# The API base URL can be overridden with options(bos.slack_base = "...") so
# the whole layer can be tested against a local mock server.
# =============================================================================

SLACK_NEEDED_SCOPES <- c(
  "channels:read"    = "list public channels",
  "groups:read"      = "list private channels the app was invited to",
  "channels:history" = "read public channel messages",
  "groups:history"   = "read private channel messages",
  "chat:write"       = "post updates",
  "users:read"       = "show people's names instead of IDs"
)
SLACK_OPTIONAL_SCOPES <- c(
  "channels:join" = "let the app join public channels itself",
  "team:read"     = "show the workspace name"
)

slack_base_url <- function() getOption("bos.slack_base", "https://slack.com/api")

slack_or <- function(a, b) {
  if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a
}

# ---- error codes -> plain words ------------------------------------------------
slack_error_text <- function(code, needed = NULL, provided = NULL) {
  code <- as.character(slack_or(code, "unknown_error"))
  switch(code,
    invalid_auth        = "Slack rejected the token (invalid_auth). Check that you copied the Bot User OAuth Token (starts with xoxb-).",
    not_authed          = "No token was sent (not_authed).",
    token_revoked       = "This token has been revoked (token_revoked). Reinstall the app and copy the new token.",
    account_inactive    = "The token belongs to a deactivated account or app (account_inactive).",
    not_in_channel      = "The app is not a member of this channel (not_in_channel). Join it from the Channels tab, or invite it in Slack with /invite @AppName.",
    channel_not_found   = "Channel not found (channel_not_found). For a private channel, invite the app to it first.",
    is_archived         = "This channel is archived (is_archived).",
    missing_scope       = paste0("The token is missing a permission (missing_scope)",
                                 if (!is.null(needed) && nzchar(needed)) paste0(": needs ", needed) else "",
                                 if (!is.null(provided) && nzchar(provided)) paste0(" (has: ", provided, ")") else "",
                                 ". Add it under OAuth & Permissions, then reinstall the app."),
    ratelimited         = "Slack rate limit reached (ratelimited). Wait a minute and try again.",
    msg_too_long        = "The message is too long for Slack (msg_too_long).",
    no_text             = "The message is empty (no_text).",
    cant_update_message = "Slack only lets the app edit messages it posted itself (cant_update_message).",
    message_not_found   = "Message not found (message_not_found).",
    thread_not_found    = "Thread not found (thread_not_found).",
    method_not_allowed_for_channel_type = "This action is not allowed for this type of channel.",
    paste0("Slack returned the error '", code, "'.")
  )
}

# ---- the one HTTP wrapper ------------------------------------------------------
# Returns list(ok, data, error, code, scopes, status). Never throws.
slack_call <- function(method, token, params = list(), http = "GET", timeout = 15, retry = TRUE) {
  token <- trimws(as.character(slack_or(token, "")))
  if (!nzchar(token)) {
    return(list(ok = FALSE, data = NULL, code = "not_authed",
                error = slack_error_text("not_authed"), scopes = "", status = NA_integer_))
  }
  params <- params[!vapply(params, function(x) is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x)), TRUE)]
  build <- function() {
    req <- httr2::request(paste0(slack_base_url(), "/", method))
    req <- httr2::req_headers(req, Authorization = paste("Bearer", token))
    req <- httr2::req_user_agent(req, "BusinessOperationsSuite-Slack/1.0")
    req <- httr2::req_timeout(req, timeout)
    req <- httr2::req_error(req, is_error = function(resp) FALSE)
    if (identical(toupper(http), "POST")) {
      httr2::req_body_json(req, params, auto_unbox = TRUE)
    } else if (length(params)) {
      do.call(httr2::req_url_query, c(list(req), lapply(params, function(x) paste(as.character(x), collapse = ","))))
    } else req
  }
  perform <- function() tryCatch(httr2::req_perform(build()), error = function(e) e)

  resp <- perform()
  if (inherits(resp, "error")) {
    return(list(ok = FALSE, data = NULL, code = "network_error", status = NA_integer_, scopes = "",
                error = paste0("Could not reach Slack: ", conditionMessage(resp))))
  }
  if (httr2::resp_status(resp) == 429 && isTRUE(retry)) {
    wait <- suppressWarnings(as.numeric(httr2::resp_header(resp, "Retry-After", "5")))
    if (is.na(wait)) wait <- 5
    wait <- min(max(wait, 0), 30)
    Sys.sleep(wait)
    resp <- perform()
    if (inherits(resp, "error")) {
      return(list(ok = FALSE, data = NULL, code = "network_error", status = NA_integer_, scopes = "",
                  error = paste0("Could not reach Slack: ", conditionMessage(resp))))
    }
  }
  status <- httr2::resp_status(resp)
  scopes <- slack_or(httr2::resp_header(resp, "x-oauth-scopes"), "")
  if (status == 429) {
    return(list(ok = FALSE, data = NULL, code = "ratelimited", status = status, scopes = scopes,
                error = slack_error_text("ratelimited")))
  }
  data <- tryCatch(httr2::resp_body_json(resp, simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(data)) {
    return(list(ok = FALSE, data = NULL, code = "bad_response", status = status, scopes = scopes,
                error = sprintf("Slack sent an unreadable answer (HTTP %s).", status)))
  }
  if (!isTRUE(data$ok)) {
    return(list(ok = FALSE, data = data, code = as.character(slack_or(data$error, "unknown_error")),
                status = status, scopes = scopes,
                error = slack_error_text(data$error, data$needed, data$provided)))
  }
  list(ok = TRUE, data = data, code = "ok", error = NULL, status = status, scopes = scopes)
}

# ---- timestamps ------------------------------------------------------------------
slack_ts_to_posix <- function(ts) {
  as.POSIXct(suppressWarnings(as.numeric(ts)), origin = "1970-01-01", tz = "UTC")
}
slack_fmt_time <- function(ts, tz = BOS_DEFAULT_TZ) {
  p <- slack_ts_to_posix(ts)
  out <- format(p, "%Y-%m-%d %H:%M", tz = tz)
  out[is.na(p)] <- ""
  out
}

# ---- message text -> display ---------------------------------------------------
slack_html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}
slack_unescape <- function(x) {
  x <- gsub("&lt;", "<", x, fixed = TRUE)
  x <- gsub("&gt;", ">", x, fixed = TRUE)
  gsub("&amp;", "&", x, fixed = TRUE)
}

# Resolves Slack's <...> markup. mode = "html" (escaped, links) or "plain".
slack_format_text <- function(text, users = NULL, channels = NULL, mode = "html") {
  text <- as.character(slack_or(text, ""))
  if (!nzchar(text)) return("")
  pat <- "<[^<>]+>"
  m <- gregexpr(pat, text)
  tokens <- regmatches(text, m)[[1]]
  pieces <- regmatches(text, m, invert = TRUE)[[1]]
  esc <- if (identical(mode, "html")) function(s) slack_html_escape(slack_unescape(s)) else slack_unescape
  lookup <- function(map, key) {
    if (is.null(map) || is.null(names(map)) || !(key %in% names(map))) return(NULL)
    unname(map[[key]])
  }
  render <- function(tk) {
    inner <- substr(tk, 2, nchar(tk) - 1)
    parts <- strsplit(inner, "|", fixed = TRUE)[[1]]
    target <- parts[1]
    label <- if (length(parts) >= 2) paste(parts[-1], collapse = "|") else NULL
    if (grepl("^@", target)) {
      nm <- slack_or(lookup(users, sub("^@", "", target)), label)
      nm <- slack_or(nm, sub("^@", "", target))
      return(esc(paste0("@", nm)))
    }
    if (grepl("^#", target)) {
      id <- sub("^#", "", target)
      nm <- slack_or(label, lookup(channels, id)); nm <- slack_or(nm, id)
      return(esc(paste0("#", nm)))
    }
    if (grepl("^!", target)) {
      kw <- sub("^!", "", target)
      return(esc(paste0("@", slack_or(label, kw))))
    }
    if (grepl("^(https?://|mailto:)", target)) {
      lab <- slack_or(label, target)
      if (identical(mode, "html")) {
        return(sprintf('<a href="%s" target="_blank" rel="noopener noreferrer">%s</a>',
                       slack_html_escape(slack_unescape(target)), slack_html_escape(slack_unescape(lab))))
      }
      return(if (is.null(label)) target else paste0(label, " (", target, ")"))
    }
    esc(inner)
  }
  rendered <- vapply(tokens, render, "", USE.NAMES = FALSE)
  out <- character()
  for (i in seq_along(pieces)) {
    out <- c(out, esc(pieces[i]))
    if (i <= length(rendered)) out <- c(out, rendered[i])
  }
  out <- paste0(out, collapse = "")
  if (identical(mode, "html")) out <- gsub("\n", "<br/>", out, fixed = TRUE)
  out
}

# ---- API functions -----------------------------------------------------------------
# slack_test: verifies the token. Returns the slack_call result with $info added.
slack_test <- function(token) {
  r <- slack_call("auth.test", token)
  if (!isTRUE(r$ok)) return(r)
  d <- r$data
  team_name <- slack_or(d$team, "")
  tm <- slack_call("team.info", token)           # optional (needs team:read)
  if (isTRUE(tm$ok) && !is.null(tm$data$team$name)) team_name <- tm$data$team$name
  scopes <- trimws(strsplit(slack_or(r$scopes, ""), ",")[[1]])
  r$info <- list(
    team = team_name, team_id = slack_or(d$team_id, ""), url = slack_or(d$url, ""),
    bot_user = slack_or(d$user, ""), bot_user_id = slack_or(d$user_id, ""),
    scopes = scopes[nzchar(scopes)],
    team_info_ok = isTRUE(tm$ok)
  )
  r
}

slack_empty_channels <- function() {
  data.frame(id = character(), name = character(), is_private = logical(), is_member = logical(),
             num_members = integer(), topic = character(), purpose = character(),
             stringsAsFactors = FALSE)
}

# Lists channels (public + private the app can see). Cursor paging with a time
# budget; returns list(ok, df, error, truncated).
slack_channels <- function(token, budget = 25, max_pages = 30) {
  t0 <- Sys.time(); cursor <- NULL; rows <- list(); pages <- 0; truncated <- FALSE
  repeat {
    r <- slack_call("conversations.list", token, list(
      types = "public_channel,private_channel", exclude_archived = "true", limit = 200, cursor = cursor))
    if (!isTRUE(r$ok)) return(list(ok = FALSE, df = slack_empty_channels(), error = r$error, code = r$code, truncated = FALSE))
    for (ch in slack_or(r$data$channels, list())) {
      rows[[length(rows) + 1]] <- data.frame(
        id = as.character(slack_or(ch$id, "")), name = as.character(slack_or(ch$name, "")),
        is_private = isTRUE(ch$is_private), is_member = isTRUE(ch$is_member),
        num_members = as.integer(slack_or(ch$num_members, NA_integer_)),
        topic = as.character(slack_or(ch$topic$value, "")),
        purpose = as.character(slack_or(ch$purpose$value, "")),
        stringsAsFactors = FALSE)
    }
    pages <- pages + 1
    cursor <- slack_or(r$data$response_metadata$next_cursor, "")
    if (!nzchar(cursor)) break
    if (pages >= max_pages || as.numeric(difftime(Sys.time(), t0, units = "secs")) > budget) { truncated <- TRUE; break }
  }
  df <- if (length(rows)) do.call(rbind, rows) else slack_empty_channels()
  df <- df[order(df$name), , drop = FALSE]; rownames(df) <- NULL
  list(ok = TRUE, df = df, error = NULL, truncated = truncated)
}

# Messages of one channel since `oldest` (POSIXct). Newest first. Capped by
# max_messages and a time budget; `latest_ts` lets "load more" continue older.
slack_history <- function(token, channel, oldest = NULL, latest = NULL,
                          max_messages = 1000, budget = 25) {
  t0 <- Sys.time(); cursor <- NULL; msgs <- list(); truncated <- FALSE
  repeat {
    r <- slack_call("conversations.history", token, list(
      channel = channel, limit = min(200, max_messages - length(msgs)),
      oldest = if (!is.null(oldest)) sprintf("%.6f", as.numeric(oldest)) else NULL,
      latest = if (!is.null(latest)) sprintf("%.6f", as.numeric(latest)) else NULL,
      cursor = cursor))
    if (!isTRUE(r$ok)) return(list(ok = FALSE, messages = list(), error = r$error, code = r$code, truncated = FALSE))
    msgs <- c(msgs, slack_or(r$data$messages, list()))
    cursor <- slack_or(r$data$response_metadata$next_cursor, "")
    if (!nzchar(cursor) && !isTRUE(r$data$has_more)) break
    if (!nzchar(cursor)) break
    if (length(msgs) >= max_messages || as.numeric(difftime(Sys.time(), t0, units = "secs")) > budget) { truncated <- TRUE; break }
  }
  list(ok = TRUE, messages = msgs, error = NULL, truncated = truncated)
}

slack_replies <- function(token, channel, ts, max_messages = 500, budget = 20) {
  t0 <- Sys.time(); cursor <- NULL; msgs <- list()
  repeat {
    r <- slack_call("conversations.replies", token, list(channel = channel, ts = ts, limit = 200, cursor = cursor))
    if (!isTRUE(r$ok)) return(list(ok = FALSE, messages = list(), error = r$error, code = r$code))
    msgs <- c(msgs, slack_or(r$data$messages, list()))
    cursor <- slack_or(r$data$response_metadata$next_cursor, "")
    if (!nzchar(cursor) || length(msgs) >= max_messages ||
        as.numeric(difftime(Sys.time(), t0, units = "secs")) > budget) break
  }
  list(ok = TRUE, messages = msgs, error = NULL)
}

# Named character vector: user id -> display name.
slack_users <- function(token, budget = 25, max_pages = 20) {
  t0 <- Sys.time(); cursor <- NULL; out <- character(); pages <- 0
  repeat {
    r <- slack_call("users.list", token, list(limit = 200, cursor = cursor))
    if (!isTRUE(r$ok)) return(list(ok = FALSE, users = out, error = r$error, code = r$code))
    for (u in slack_or(r$data$members, list())) {
      nm <- slack_or(u$profile$display_name, "")
      if (!nzchar(nm)) nm <- slack_or(u$profile$real_name, "")
      if (!nzchar(nm)) nm <- slack_or(u$real_name, "")
      if (!nzchar(nm)) nm <- slack_or(u$name, u$id)
      out[[as.character(u$id)]] <- as.character(nm)
    }
    pages <- pages + 1
    cursor <- slack_or(r$data$response_metadata$next_cursor, "")
    if (!nzchar(cursor) || pages >= max_pages ||
        as.numeric(difftime(Sys.time(), t0, units = "secs")) > budget) break
  }
  list(ok = TRUE, users = out, error = NULL)
}

slack_join <- function(token, channel) slack_call("conversations.join", token, list(channel = channel), http = "POST")

slack_post <- function(token, channel, text, thread_ts = NULL) {
  slack_call("chat.postMessage", token,
             list(channel = channel, text = text, thread_ts = if (!is.null(thread_ts) && nzchar(thread_ts)) thread_ts else NULL),
             http = "POST")
}

slack_update <- function(token, channel, ts, text) {
  slack_call("chat.update", token, list(channel = channel, ts = ts, text = text), http = "POST")
}

# ---- messages -> data frame ------------------------------------------------------------
# One row per message, newest first. users / channels: named vectors for names.
slack_messages_df <- function(msgs, users = NULL, channels = NULL, tz = BOS_DEFAULT_TZ) {
  if (length(msgs) == 0) {
    return(data.frame(ts = character(), time = character(), author = character(), text = character(),
                      text_html = character(), replies = integer(), reactions = character(),
                      thread_ts = character(), stringsAsFactors = FALSE))
  }
  author_of <- function(m) {
    uid <- as.character(slack_or(m$user, ""))
    if (nzchar(uid) && !is.null(users) && uid %in% names(users)) return(unname(users[[uid]]))
    if (nzchar(slack_or(m$username, ""))) return(as.character(m$username))
    if (nzchar(slack_or(m$bot_profile$name, ""))) return(as.character(m$bot_profile$name))
    if (nzchar(uid)) return(uid)
    if (nzchar(slack_or(m$bot_id, ""))) return(paste0("bot ", m$bot_id))
    "(unknown)"
  }
  body_of <- function(m, mode) {
    txt <- as.character(slack_or(m$text, ""))
    if (!nzchar(trimws(txt))) {
      att <- slack_or(m$attachments, list())
      if (length(att)) txt <- slack_or(att[[1]]$fallback, slack_or(att[[1]]$text, ""))
    }
    if (!nzchar(trimws(txt)) && length(slack_or(m$files, list()))) {
      txt <- paste0("(file: ", slack_or(m$files[[1]]$name, "attachment"), ")")
    }
    if (!nzchar(trimws(txt))) {
      st <- slack_or(m$subtype, "")
      return(if (identical(mode, "html")) "<em>(no text)</em>" else paste0("(no text", if (nzchar(st)) paste0(": ", st) else "", ")"))
    }
    slack_format_text(txt, users, channels, mode)
  }
  react_of <- function(m) {
    rx <- slack_or(m$reactions, list())
    if (!length(rx)) return("")
    paste(vapply(rx, function(r) sprintf(":%s: %s", slack_or(r$name, "?"), slack_or(r$count, 1)), ""), collapse = " ")
  }
  data.frame(
    ts = vapply(msgs, function(m) as.character(slack_or(m$ts, "")), ""),
    time = slack_fmt_time(vapply(msgs, function(m) as.character(slack_or(m$ts, "")), ""), tz),
    author = vapply(msgs, author_of, ""),
    text = vapply(msgs, body_of, "", mode = "plain"),
    text_html = vapply(msgs, body_of, "", mode = "html"),
    replies = vapply(msgs, function(m) as.integer(slack_or(m$reply_count, 0L)), 1L),
    reactions = vapply(msgs, react_of, ""),
    thread_ts = vapply(msgs, function(m) as.character(slack_or(m$thread_ts, "")), ""),
    stringsAsFactors = FALSE)
}
