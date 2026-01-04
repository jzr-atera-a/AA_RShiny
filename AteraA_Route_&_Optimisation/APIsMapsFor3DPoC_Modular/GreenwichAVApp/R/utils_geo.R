# R/utils_geo.R - Geographic Utility Functions
# Greenwich AV Project

# Parse coordinate string to bbox
parse_coordinates <- function(coord_string) {
  tryCatch({
    coords <- as.numeric(strsplit(gsub("\\s+", "", coord_string), ",")[[1]])
    if (length(coords) != 4) {
      stop("Expected 4 coordinates: lat_min, lon_min, lat_max, lon_max")
    }
    
    list(
      ymin = coords[1],
      xmin = coords[2],
      ymax = coords[3],
      xmax = coords[4]
    )
  }, error = function(e) {
    NULL
  })
}

# Get bounding box from place name
get_bbox_from_place <- function(place_name) {
  tryCatch({
    bbox <- tmaptools::geocode_OSM(place_name, return.first.only = TRUE)
    if (!is.null(bbox)) {
      return(bbox$bbox)
    }
    
    # Fallback to tmaptools getbb
    bbox_matrix <- tmaptools::bb(place_name)
    if (!is.null(bbox_matrix)) {
      return(c(
        xmin = bbox_matrix[1, 1],
        ymin = bbox_matrix[2, 1],
        xmax = bbox_matrix[1, 2],
        ymax = bbox_matrix[2, 2]
      ))
    }
    
    return(NULL)
  }, error = function(e) {
    message("Error getting bbox: ", e$message)
    return(NULL)
  })
}

# Calculate area in square meters
calculate_area_m2 <- function(bbox) {
  # Approximate calculation using Haversine
  # bbox format: c(xmin, ymin, xmax, ymax) in degrees
  
  lat_mid <- (bbox[2] + bbox[4]) / 2
  
  # Degrees to meters at this latitude
  meters_per_degree_lat <- 111320
  meters_per_degree_lon <- 111320 * cos(lat_mid * pi / 180)
  
  width_m <- abs(bbox[3] - bbox[1]) * meters_per_degree_lon
  height_m <- abs(bbox[4] - bbox[2]) * meters_per_degree_lat
  
  area_m2 <- width_m * height_m
  
  return(list(
    width = width_m,
    height = height_m,
    area = area_m2
  ))
}

# Format bbox for display
format_bbox_display <- function(bbox) {
  if (is.null(bbox)) return("Not set")
  
  paste0(
    "SW: ", round(bbox[2], 5), "°N, ", round(bbox[1], 5), "°E | ",
    "NE: ", round(bbox[4], 5), "°N, ", round(bbox[3], 5), "°E"
  )
}

# Convert WGS84 to British National Grid (EPSG:27700)
convert_to_bng <- function(sf_object) {
  if (is.null(sf_object)) return(NULL)
  
  tryCatch({
    st_transform(sf_object, crs = 27700)
  }, error = function(e) {
    message("Error converting to BNG: ", e$message)
    sf_object
  })
}

# Create default Greenwich bbox
get_default_greenwich_bbox <- function() {
  c(
    xmin = 0.0020,   # West
    ymin = 51.5025,  # South
    xmax = 0.0035,   # East
    ymax = 51.5035   # North
  )
}

# Validate bbox
validate_bbox <- function(bbox) {
  if (is.null(bbox)) return(FALSE)
  if (length(bbox) != 4) return(FALSE)
  if (any(is.na(bbox))) return(FALSE)
  
  # Check if coordinates are in valid range
  if (bbox[1] < -180 || bbox[1] > 180) return(FALSE)  # xmin
  if (bbox[2] < -90 || bbox[2] > 90) return(FALSE)    # ymin
  if (bbox[3] < -180 || bbox[3] > 180) return(FALSE)  # xmax
  if (bbox[4] < -90 || bbox[4] > 90) return(FALSE)    # ymax
  
  # Check if max > min
  if (bbox[3] <= bbox[1]) return(FALSE)  # xmax > xmin
  if (bbox[4] <= bbox[2]) return(FALSE)  # ymax > ymin
  
  return(TRUE)
}
