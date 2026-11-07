# R/utils_common.R
# Common Utility Functions for EV Route Optimizer

# Helper function for NULL coalescing
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Clean LINESTRING geometries from OSM data
clean_linestrings <- function(sf_object) {
  # Keep only LINESTRING geometries
  sf_object <- sf_object[st_geometry_type(sf_object) == "LINESTRING", ]
  
  # Remove invalid geometries
  valid_geoms <- st_is_valid(sf_object)
  sf_object <- sf_object[valid_geoms, ]
  
  # Remove empty geometries
  sf_object <- sf_object[!st_is_empty(sf_object), ]
  
  return(sf_object)
}

# Format distance for display
format_distance <- function(meters) {
  if (is.na(meters) || is.infinite(meters)) {
    return("N/A")
  }
  
  km <- meters / 1000
  sprintf("%.2f km", km)
}

# Validate coordinates
is_valid_coordinate <- function(lat, lon) {
  !is.na(lat) && !is.na(lon) &&
    lat >= -90 && lat <= 90 &&
    lon >= -180 && lon <= 180
}

# Create status message div (for UI feedback)
create_status_div <- function(type = "success", title, message) {
  class_name <- paste0("status-", type)
  
  div(class = class_name,
      h5(title),
      p(message))
}

# Safe numeric conversion
safe_numeric <- function(x) {
  result <- suppressWarnings(as.numeric(x))
  if (is.na(result)) NULL else result
}

# Validate float (used for BigQuery data cleaning)
is_valid_float <- function(x) {
  !is.na(suppressWarnings(as.numeric(x)))
}
