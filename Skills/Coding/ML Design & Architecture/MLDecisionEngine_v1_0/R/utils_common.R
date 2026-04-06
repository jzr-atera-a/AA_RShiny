# R/utils_common.R
progress_colour <- function(pct) {
  if (pct >= 80) "#2e7d32"
  else if (pct >= 50) "#e65100"
  else "#c0392b"
}
