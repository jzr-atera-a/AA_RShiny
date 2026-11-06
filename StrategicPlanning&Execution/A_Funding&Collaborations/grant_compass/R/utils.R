# ---- small helpers ------------------------------------------------------------

`%||%` <- function(a, b) {
  if (is.null(a) || length(a) == 0 || (length(a) == 1 && (is.na(a) || identical(a, "")))) b else a
}

now_ts  <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")
new_id  <- function(prefix) paste0(prefix, format(Sys.time(), "%y%m%d%H%M%S"), sample(100:999, 1))
esc     <- function(x) htmltools::htmlEscape(as.character(x %||% ""))

split_tags <- function(x) {
  x <- trimws(unlist(strsplit(as.character(x %||% ""), "[;,]")))
  x[nzchar(x)]
}

num <- function(x, default = NA_real_) {
  v <- suppressWarnings(as.numeric(gsub("[^0-9.]", "", as.character(x))))
  ifelse(is.na(v), default, v)
}

fmt_gbp <- function(lo, hi) {
  f <- function(v) {
    if (is.na(v)) return("")
    if (v >= 1e6) sprintf("£%.1fm", v / 1e6) else if (v >= 1e3) sprintf("£%.0fk", v / 1e3) else sprintf("£%.0f", v)
  }
  lo <- num(lo); hi <- num(hi)
  if (is.na(lo) && is.na(hi)) return("Value TBC")
  if (is.na(lo)) return(paste("up to", f(hi)))
  if (is.na(hi) || lo == hi) return(f(lo))
  paste(f(lo), "–", f(hi))
}

days_left <- function(d) {
  d <- suppressWarnings(as.Date(as.character(d)))
  if (length(d) == 0 || is.na(d)) NA_integer_ else as.integer(d - Sys.Date())
}

time_ago <- function(ts) {
  t <- suppressWarnings(as.POSIXct(ts, tz = "UTC"))
  s <- as.numeric(difftime(Sys.time(), t, units = "secs"))
  if (is.na(s)) return("")
  if (s < 90) "just now" else if (s < 3600) sprintf("%d min ago", round(s / 60)) else
    if (s < 86400) sprintf("%d h ago", round(s / 3600)) else sprintf("%d d ago", round(s / 86400))
}

chip <- function(text, cls = "") {
  htmltools::tags$span(class = paste("chip", cls), text)
}
chips <- function(x, cls = "") lapply(split_tags(x), chip, cls = cls)

# Alignment / interest / capability (1-5) -> 0-100 weighted score
calc_score <- function(a, i, c, w = c(1.5, 1, 1.5)) {
  round((w[1] * num(a, 0) + w[2] * num(i, 0) + w[3] * num(c, 0)) / sum(w) * 20)
}

# Latest row per key wins (the sheet is append-only for priorities and votes)
latest_by <- function(df, keys) {
  if (nrow(df) == 0) return(df)
  df <- df[order(df$updated_at), , drop = FALSE]
  df[!duplicated(df[keys], fromLast = TRUE), , drop = FALSE]
}

display_name <- function(email, users) {
  nm <- users$name[match(tolower(email), tolower(users$email))]
  fallback <- tools::toTitleCase(gsub("[._]+", " ", sub("@.*", "", email)))
  ifelse(is.na(nm) | nm == "", fallback, nm)
}

onclick_input <- function(input_id, value) {
  sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})", input_id, value)
}
