# R/utils_common.R - Welch Group Fleet Monitor
# Shared helper functions

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

# Format bytes to human-readable
format_bytes <- function(x) {
  if (x < 1024) return(paste(x, "B"))
  if (x < 1024^2) return(sprintf("%.1f KB", x / 1024))
  sprintf("%.1f MB", x / 1024^2)
}

# Safe JSON extract with default
safe_extract <- function(lst, ..., default = NA) {
  tryCatch({
    keys <- list(...)
    val  <- lst
    for (k in keys) val <- val[[k]]
    if (is.null(val)) default else val
  }, error = function(e) default)
}

# Timestamp to readable
fmt_ts <- function(ts) {
  if (is.null(ts) || is.na(ts)) return("—")
  tryCatch(format(as.POSIXct(ts, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
                  "%d %b %Y  %H:%M UTC"), error = function(e) as.character(ts))
}

# Status badge HTML
status_badge <- function(label, colour = "#17a2b8") {
  sprintf('<span style="background:%s;color:#fff;padding:3px 10px;border-radius:12px;font-size:12px;font-weight:600;">%s</span>',
          colour, label)
}

# Metric card HTML
metric_card <- function(title, value, icon_name = "info", colour = "#1a9b9b") {
  sprintf(
    '<div style="background:#1e2a3a;border-left:4px solid %s;padding:12px 16px;border-radius:6px;margin:6px 0;">
       <div style="font-size:11px;color:#8fa0b5;text-transform:uppercase;letter-spacing:.5px;">%s</div>
       <div style="font-size:22px;font-weight:700;color:#e0eaf5;margin-top:4px;">%s</div>
     </div>',
    colour, title, value
  )
}

# Generate request ID
new_request_id <- function() {
  paste0("welch_", format(Sys.time(), "%Y%m%d%H%M%S"), "_",
         paste(sample(c(letters, 0:9), 6, replace = TRUE), collapse = ""))
}

cat("  ✓ utils_common loaded\n")
