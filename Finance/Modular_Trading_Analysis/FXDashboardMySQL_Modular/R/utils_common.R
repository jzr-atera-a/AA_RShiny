# R/utils_common.R
# Common utility functions

safe_divide <- function(x, y) {
  ifelse(y == 0, NA, x / y)
}

format_number <- function(x, digits = 2) {
  format(round(x, digits), big.mark = ",", scientific = FALSE)
}

pct_change <- function(x) {
  c(NA, diff(x) / x[-length(x)] * 100)
}

is_valid_data <- function(data) {
  !is.null(data) && is.data.frame(data) && nrow(data) > 0
}

calculate_returns <- function(prices, type = "simple") {
  if (type == "log") {
    diff(log(prices))
  } else {
    diff(prices) / prices[-length(prices)]
  }
}

cat("✓ Common utilities loaded\n")
