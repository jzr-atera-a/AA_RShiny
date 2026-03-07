# R/utils_omniverse.R
# Helper functions for Omniverse data processing

# Simple helper to handle NULL values
`%||%` <- function(x, y) if (is.null(x)) y else x
