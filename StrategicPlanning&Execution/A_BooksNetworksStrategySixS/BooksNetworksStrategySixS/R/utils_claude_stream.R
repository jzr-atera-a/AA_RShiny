# R/utils_claude_stream.R
# Streaming-state helpers for call_claude(), including the server-side
# web search tool. Kept outside the R6 class so they can be unit tested with
# synthetic events.

claude_web_search_tool <- function(max_uses = 4L) {
  list(type = "web_search_20250305", name = "web_search", max_uses = as.integer(max_uses))
}

claude_stream_new_state <- function() {
  st <- new.env(parent = emptyenv())
  st$texts <- list()          # text blocks since the last tool result (the final answer)
  st$all_chars <- 0L
  st$search_urls <- character(0); st$search_titles <- character(0)
  st$cite_urls <- character(0); st$cite_titles <- character(0); st$cite_text <- character(0)
  st$n_search <- 0L
  st$search_errors <- character(0)
  st$usage <- NULL; st$stop_reason <- NULL; st$error <- NULL
  st
}

# Apply one parsed SSE event (a list) to the state. Returns invisible(NULL).
claude_stream_apply <- function(st, ev) {
  type <- ev$type %||% ""
  if (type == "content_block_start") {
    cb <- ev$content_block %||% list()
    bt <- cb$type %||% ""
    if (bt == "text") {
      st$texts[[length(st$texts) + 1L]] <- cb$text %||% ""
    } else if (bt == "server_tool_use") {
      if (identical(cb$name, "web_search")) st$n_search <- st$n_search + 1L
    } else if (bt == "web_search_tool_result") {
      # text written before/between searches is narration: keep only what follows the last result
      st$texts <- list()
      res <- cb$content
      if (is.list(res) && !is.null(res$type) && identical(res$type, "web_search_tool_result_error")) {
        st$search_errors <- c(st$search_errors, res$error_code %||% "error")
      } else if (is.list(res)) {
        for (r in res) {
          if (is.list(r) && !is.null(r$url)) {
            st$search_urls <- c(st$search_urls, as.character(r$url))
            st$search_titles <- c(st$search_titles, as.character(r$title %||% ""))
          }
        }
      }
    }
  } else if (type == "content_block_delta") {
    dl <- ev$delta %||% list()
    if (identical(dl$type, "text_delta")) {
      if (length(st$texts) == 0L) st$texts[[1L]] <- ""
      i <- length(st$texts)
      st$texts[[i]] <- paste0(st$texts[[i]], dl$text %||% "")
      st$all_chars <- st$all_chars + nchar(dl$text %||% "")
    } else if (identical(dl$type, "citations_delta")) {
      ct <- dl$citation %||% list()
      if (!is.null(ct$url)) {
        st$cite_urls <- c(st$cite_urls, as.character(ct$url))
        st$cite_titles <- c(st$cite_titles, as.character(ct$title %||% ""))
        st$cite_text <- c(st$cite_text, as.character(ct$cited_text %||% ""))
      }
    }
  } else if (type == "message_delta") {
    if (!is.null(ev$usage)) st$usage <- ev$usage
    if (!is.null(ev$delta$stop_reason)) st$stop_reason <- ev$delta$stop_reason
  } else if (type == "error") {
    st$error <- ev$error$message %||% "Unknown streaming error from Editing Tool API"
  }
  invisible(NULL)
}

claude_stream_text <- function(st) paste(unlist(st$texts), collapse = "")

# Attach the search metadata to the returned text
claude_stream_attrs <- function(text, st) {
  attr(text, "claude_stop_reason") <- st$stop_reason %||% "unknown"
  attr(text, "claude_n_searches") <- st$n_search
  attr(text, "claude_search_errors") <- st$search_errors
  attr(text, "claude_search_urls") <- data.frame(url = st$search_urls, title = st$search_titles, stringsAsFactors = FALSE)
  attr(text, "claude_citations") <- data.frame(url = st$cite_urls, title = st$cite_titles, cited_text = st$cite_text, stringsAsFactors = FALSE)
  text
}
