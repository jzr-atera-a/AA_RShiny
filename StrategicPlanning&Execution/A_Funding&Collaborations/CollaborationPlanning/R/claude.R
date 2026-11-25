# R/claude.R - the one Claude helper every tab uses
#
# claude_call(prompt, system, max_tokens, web_search, model) returns a list:
#   text      all text blocks of the reply joined together
#   urls      citation / search-result URLs returned with the text (unique)
#   model, input_tokens, output_tokens, searches
# It stops with a readable message on any failure; tabs show it with note("bad", safe_error_text(e)).
#
# Web search uses Anthropic's server tool. The tool version is cfg$web_tool
# (CP_WEB_SEARCH_TOOL, default web_search_20250305). Checked against docs.claude.com on 23 Nov 2026:
# web_search_20250305 is the basic tool; web_search_20260209 and later add dynamic filtering and
# default allowed_callers to code execution, so for those we send allowed_callers = ["direct"].

CLAUDE_URL <- "https://api.anthropic.com/v1/messages"

claude_web_tool <- function(max_uses = 8) {
  tool <- list(type = cfg$web_tool, name = "web_search", max_uses = max_uses)
  ver <- suppressWarnings(as.numeric(sub("^web_search_", "", cfg$web_tool)))
  if (!is.na(ver) && ver >= 20260209) tool$allowed_callers <- list("direct")
  tool
}

# Low-level POST (kept separate so tests can replace it)
claude_post <- function(body, key, timeout_secs = 120) {
  httr::POST(CLAUDE_URL,
    httr::add_headers(`x-api-key` = key, `anthropic-version` = "2023-06-01", `content-type` = "application/json"),
    body = jsonlite::toJSON(body, auto_unbox = TRUE, null = "null"), encode = "raw", httr::timeout(timeout_secs))
}

claude_call <- function(prompt, system = NULL, max_tokens = 4000, web_search = FALSE,
                        model = get_settings()$claude_model, timeout_secs = 120) {
  key <- claude_key()
  if (!nzchar(key)) stop("No Claude API key is set. An admin can add one in Admin > Claude API.")
  model <- if (model %in% CLAUDE_MODELS) model else CLAUDE_MODELS[1]
  use_web <- isTRUE(web_search) && is_true(get_settings()$claude_web_search)
  messages <- list(list(role = "user", content = prompt))
  texts <- character(0); urls <- character(0); tin <- 0; tout <- 0; searches <- 0
  # A long web search can stop with "pause_turn": send the reply back and let Claude carry on (max 3 times)
  for (round in 1:4) {
    body <- list(model = model, max_tokens = max_tokens, messages = messages)
    if (!is.null(system)) body$system <- system
    if (use_web) body$tools <- list(claude_web_tool())
    t0 <- Sys.time()
    resp <- tryCatch(claude_post(body, key, timeout_secs), error = function(e) {
      if (grepl("timed? ?out|Timeout", conditionMessage(e), ignore.case = TRUE))
        stop("Claude did not answer within ", timeout_secs, " seconds. Try again, or ask for fewer results.", call. = FALSE)
      stop("Could not reach Claude: ", conditionMessage(e), call. = FALSE)
    })
    out <- tryCatch(httr::content(resp, as = "parsed", simplifyVector = FALSE), error = function(e) list())
    code <- httr::status_code(resp)
    if (code >= 300) {
      msg <- out$error$message %||% paste("HTTP", code)
      if (code == 401) msg <- "The Claude API key was refused. Check it in Admin > Claude API."
      if (code == 429) msg <- "Claude is busy (rate limit). Wait a minute and try again."
      log_debug("[Claude] error ", code, ": ", msg)
      stop(msg, call. = FALSE)
    }
    for (b in out$content %||% list()) {
      if (identical(b$type, "text")) {
        texts <- c(texts, b$text %||% "")
        for (ci in b$citations %||% list()) if (!is.null(ci$url)) urls <- c(urls, ci$url)
      } else if (identical(b$type, "server_tool_use")) searches <- searches + 1
      else if (identical(b$type, "web_search_tool_result") && is.list(b$content))
        for (r in b$content) if (!is.null(r$url)) urls <- c(urls, r$url)
    }
    tin <- tin + (out$usage$input_tokens %||% 0); tout <- tout + (out$usage$output_tokens %||% 0)
    log_debug(sprintf("[Claude] %s round %d: %s in, %s out, %d search(es), %.1fs, stop=%s", model, round,
                      tin, tout, searches, as.numeric(difftime(Sys.time(), t0, units = "secs")), out$stop_reason %||% "?"))
    if (!identical(out$stop_reason, "pause_turn")) break
    messages <- c(messages, list(list(role = "assistant", content = out$content)))
  }
  list(text = trimws(paste(texts, collapse = "")), urls = unique(urls), model = model,
       input_tokens = tin, output_tokens = tout, searches = searches)
}

# Ask for JSON and parse it. Strips code fences and any words before the first { or [.
claude_json <- function(prompt, system = NULL, max_tokens = 3000, web_search = FALSE, simplify = TRUE) {
  r <- claude_call(prompt, system = system, max_tokens = max_tokens, web_search = web_search)
  val <- parse_json_loose(r$text, simplify = simplify)
  attr(val, "urls") <- r$urls
  val
}

parse_json_loose <- function(txt, simplify = TRUE) {
  t <- gsub("```(json)?", "", txt %||% "")
  starts <- regexpr("[\\[{]", t)
  if (starts < 0) stop("Claude did not return the expected data. Try again.", call. = FALSE)
  t <- substring(t, starts)
  close <- if (substr(t, 1, 1) == "[") "\\]" else "\\}"
  ends <- gregexpr(close, t)[[1]]
  t <- substr(t, 1, max(ends))
  tryCatch(jsonlite::fromJSON(t, simplifyVector = simplify),
           error = function(e) stop("Claude's reply could not be read (", conditionMessage(e), "). Try again.", call. = FALSE))
}

claude_ready <- function() nzchar(claude_key())
