# R/utils_common.R
# Common utility functions shared across modules
# ==============================================

# Safe null coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# Calculate Sharpe Ratio
calculate_sharpe <- function(returns, rf_rate, annualize = TRUE) {
  rf_daily <- rf_rate / 100 / 252
  excess_returns <- returns - rf_daily
  sharpe <- mean(excess_returns, na.rm = TRUE) / sd(excess_returns, na.rm = TRUE)
  if (annualize) sharpe <- sharpe * sqrt(252)
  return(sharpe)
}

# Calculate Sortino Ratio
calculate_sortino <- function(returns, target_return, annualize = TRUE) {
  target_daily <- target_return / 100 / 252
  excess_returns <- returns - target_daily
  downside_returns <- pmin(excess_returns, 0)
  downside_dev <- sqrt(mean(downside_returns^2, na.rm = TRUE))
  if (downside_dev == 0) return(NA)
  sortino <- mean(excess_returns, na.rm = TRUE) / downside_dev
  if (annualize) sortino <- sortino * sqrt(252)
  return(sortino)
}

# Calculate Calmar Ratio
calculate_calmar <- function(returns, annualize = TRUE) {
  cumulative <- cumprod(1 + returns)
  running_max <- cummax(cumulative)
  drawdown <- (cumulative - running_max) / running_max
  max_dd <- min(drawdown, na.rm = TRUE)
  if (max_dd == 0) return(NA)
  
  ann_return <- mean(returns, na.rm = TRUE) * 252
  calmar <- ann_return / abs(max_dd)
  return(calmar)
}

# Calculate Omega Ratio
calculate_omega <- function(returns, threshold = 0) {
  threshold_daily <- threshold / 252
  gains <- sum(pmax(returns - threshold_daily, 0), na.rm = TRUE)
  losses <- sum(abs(pmin(returns - threshold_daily, 0)), na.rm = TRUE)
  if (losses == 0) return(Inf)
  return(gains / losses)
}

# Format currency
format_currency <- function(value, decimals = 2) {
  paste0("$", format(round(value, decimals), big.mark = ",", nsmall = decimals))
}

# Format percentage
format_percentage <- function(value, decimals = 2) {
  paste0(ifelse(value > 0, "+", ""), format(round(value, decimals), nsmall = decimals), "%")
}

# Safe SQL escaping (for potential future database integration)
escape_sql <- function(value) {
  gsub("'", "''", as.character(value))
}

cat("✓ Common utilities loaded\n")
