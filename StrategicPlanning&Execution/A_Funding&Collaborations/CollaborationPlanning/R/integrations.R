# R/integrations.R - Claude and Trello connections
# Keys come from environment variables. An admin can also paste a key for the running app;
# it is kept in server memory only (never written to the Sheet, BigQuery or the browser) and is
# lost when the app restarts. For a permanent key, set it in shinyapps.io > Settings > Variables.

.keys <- new.env(parent = emptyenv())
session_key_set <- function(name, value) assign(name, value, envir = .keys)
session_key_get <- function(name) if (exists(name, envir = .keys)) get(name, envir = .keys) else ""

claude_key <- function() { k <- session_key_get("anthropic"); if (nzchar(k)) k else cfg$anthropic_key }
trello_key <- function() { k <- session_key_get("trello_key"); if (nzchar(k)) k else cfg$trello_key }
trello_token <- function() { k <- session_key_get("trello_token"); if (nzchar(k)) k else cfg$trello_token }

key_hint <- function(k) if (nzchar(k)) paste0(substr(k, 1, 7), "...", substr(k, nchar(k) - 3, nchar(k))) else "not set"

# Short test call to the Anthropic Messages API
claude_ping <- function(model) {
  key <- claude_key()
  if (!nzchar(key)) stop("No Claude API key set")
  resp <- httr::POST("https://api.anthropic.com/v1/messages",
    httr::add_headers(`x-api-key` = key, `anthropic-version` = "2023-06-01", `content-type` = "application/json"),
    body = list(model = model, max_tokens = 16, messages = list(list(role = "user", content = "Reply with the word ready."))),
    encode = "json", httr::timeout(30))
  out <- httr::content(resp, as = "parsed")
  if (httr::status_code(resp) >= 300) stop(out$error$message %||% paste("HTTP", httr::status_code(resp)))
  paste(vapply(out$content, function(b) b$text %||% "", ""), collapse = " ")
}

trello_get <- function(path, query = list()) trello_req("GET", path, query)

trello_boards <- function() {
  b <- trello_get("members/me/boards", list(fields = "name,url,closed"))
  b <- Filter(function(x) !isTRUE(x$closed), b)
  if (!length(b)) return(data.frame(id = character(0), name = character(0), url = character(0)))
  data.frame(id = vapply(b, `[[`, "", "id"), name = vapply(b, `[[`, "", "name"),
             url = vapply(b, `[[`, "", "url"), stringsAsFactors = FALSE)
}

# ---- Trello writes (ported from the Gantt to Tickets tabs of Business Operations Suite) ------------
# One list per work package, one card per task. The card id is stored on the task, so sending again
# updates the card instead of making a copy. Ticking "due complete" on Trello (or moving the card to a
# list whose name contains "done") marks the task done when the status is pulled back.
trello_req <- function(method, path, query = list()) {
  if (!nzchar(trello_key()) || !nzchar(trello_token())) stop("Trello key and token are not set (Admin > Trello).")
  url <- paste0("https://api.trello.com/1/", path)
  q <- c(list(key = trello_key(), token = trello_token()), query)
  resp <- switch(method,
    GET = httr::GET(url, query = q, httr::timeout(20)),
    POST = httr::POST(url, query = q, httr::timeout(20)),
    PUT = httr::PUT(url, query = q, httr::timeout(20)))
  if (httr::status_code(resp) >= 300) stop("Trello said: ", substr(httr::content(resp, as = "text", encoding = "UTF-8"), 1, 200))
  httr::content(resp, as = "parsed")
}

trello_lists <- function(board_id) {
  l <- trello_req("GET", paste0("boards/", board_id, "/lists"), list(fields = "name,closed"))
  if (!length(l)) return(data.frame(id = character(0), name = character(0)))
  data.frame(id = vapply(l, `[[`, "", "id"), name = vapply(l, `[[`, "", "name"), stringsAsFactors = FALSE)
}

trello_list_create <- function(board_id, name) trello_req("POST", "lists", list(name = name, idBoard = board_id, pos = "bottom"))$id

trello_card_upsert <- function(card_id, list_id, name, desc, due = "", done = FALSE) {
  q <- list(name = substr(name, 1, 16000), desc = substr(desc, 1, 16000), idList = list_id,
            dueComplete = tolower(as.character(isTRUE(done))))
  if (nzchar(due)) q$due <- paste0(due, "T17:00:00.000Z")
  if (nzchar(card_id %||% "")) trello_req("PUT", paste0("cards/", card_id), q)
  else trello_req("POST", "cards", c(q, list(pos = "bottom")))
}

trello_board_cards <- function(board_id) {
  c <- trello_req("GET", paste0("boards/", board_id, "/cards/all"), list(fields = "name,idList,dueComplete,closed,url"))
  if (!length(c)) return(data.frame(id = character(0), idList = character(0), dueComplete = logical(0), closed = logical(0), url = character(0)))
  data.frame(id = vapply(c, `[[`, "", "id"), idList = vapply(c, `[[`, "", "idList"),
             dueComplete = vapply(c, function(x) isTRUE(x$dueComplete), TRUE),
             closed = vapply(c, function(x) isTRUE(x$closed), TRUE),
             url = vapply(c, function(x) x$url %||% "", ""), stringsAsFactors = FALSE)
}
