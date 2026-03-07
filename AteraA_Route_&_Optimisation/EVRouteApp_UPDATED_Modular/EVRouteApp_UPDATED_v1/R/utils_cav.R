# R/utils_cav.R - CAV Utilities
# Helper functions for CAV modules

# Haversine distance calculation (in meters)
haversine_distance <- function(lat1, lon1, lat2, lon2) {
  R <- 6371000  # Earth radius in meters
  
  lat1_rad <- lat1 * pi / 180
  lat2_rad <- lat2 * pi / 180
  dlat <- (lat2 - lat1) * pi / 180
  dlon <- (lon2 - lon1) * pi / 180
  
  a <- sin(dlat/2)^2 + cos(lat1_rad) * cos(lat2_rad) * sin(dlon/2)^2
  c <- 2 * atan2(sqrt(a), sqrt(1-a))
  
  return(R * c)
}

# Resample route at fixed intervals
resample_route <- function(coords_df, spacing_m = 50) {
  if (nrow(coords_df) < 2) return(coords_df)
  
  resampled <- list()
  resampled[[1]] <- coords_df[1, ]
  
  cumulative_dist <- 0
  last_lat <- coords_df$lat[1]
  last_lon <- coords_df$lon[1]
  
  for (i in 2:nrow(coords_df)) {
    current_lat <- coords_df$lat[i]
    current_lon <- coords_df$lon[i]
    
    dist <- haversine_distance(last_lat, last_lon, current_lat, current_lon)
    cumulative_dist <- cumulative_dist + dist
    
    if (cumulative_dist >= spacing_m) {
      resampled[[length(resampled) + 1]] <- coords_df[i, ]
      last_lat <- current_lat
      last_lon <- current_lon
      cumulative_dist <- 0
    }
  }
  
  # Ensure last point is included
  if (cumulative_dist > 0) {
    resampled[[length(resampled) + 1]] <- coords_df[nrow(coords_df), ]
  }
  
  result <- do.call(rbind, resampled)
  result$sequence_number <- seq_len(nrow(result))
  
  return(result)
}

# Calculate bearing between two points
calculate_bearing <- function(lat1, lon1, lat2, lon2) {
  lat1_rad <- lat1 * pi / 180
  lat2_rad <- lat2 * pi / 180
  dlon <- (lon2 - lon1) * pi / 180
  
  y <- sin(dlon) * cos(lat2_rad)
  x <- cos(lat1_rad) * sin(lat2_rad) - sin(lat1_rad) * cos(lat2_rad) * cos(dlon)
  
  bearing <- atan2(y, x) * 180 / pi
  bearing <- (bearing + 360) %% 360
  
  return(bearing)
}

# Detect curves based on bearing changes
detect_curves <- function(coords_df, threshold_degrees = 30) {
  if (nrow(coords_df) < 3) return(data.frame())
  
  curves <- list()
  
  for (i in 2:(nrow(coords_df) - 1)) {
    bearing1 <- calculate_bearing(
      coords_df$lat[i-1], coords_df$lon[i-1],
      coords_df$lat[i], coords_df$lon[i]
    )
    
    bearing2 <- calculate_bearing(
      coords_df$lat[i], coords_df$lon[i],
      coords_df$lat[i+1], coords_df$lon[i+1]
    )
    
    angle_change <- abs(bearing2 - bearing1)
    if (angle_change > 180) angle_change <- 360 - angle_change
    
    if (angle_change > threshold_degrees) {
      curves[[length(curves) + 1]] <- data.frame(
        lat = coords_df$lat[i],
        lon = coords_df$lon[i],
        feature_type = "curve",
        angle_change = angle_change,
        sequence = i
      )
    }
  }
  
  if (length(curves) == 0) return(data.frame())
  return(do.call(rbind, curves))
}

# Risk classification
classify_risk <- function(feature_type) {
  critical <- c("roundabout", "tunnel", "junction", "motorway_junction", "pedestrian_crossing")
  medium <- c("lane_merge", "construction_zone", "curve", "obscured_signage", "traffic_signals")
  
  if (tolower(feature_type) %in% critical) {
    return("CRITICAL")
  } else if (tolower(feature_type) %in% medium) {
    return("MEDIUM")
  } else {
    return("LOW")
  }
}

# Generate unique filename for images
generate_image_filename <- function(lat, lon, sequence) {
  sprintf("streetview_%d_%.6f_%.6f.jpg", sequence, lat, lon)
}

# Create data directory structure
ensure_data_dirs <- function(base_dir = "data") {
  dirs <- c(
    file.path(base_dir, "raw", "images"),
    file.path(base_dir, "raw", "routes"),
    file.path(base_dir, "processed", "waypoints"),
    file.path(base_dir, "processed", "detections"),
    file.path(base_dir, "processed", "features"),
    file.path(base_dir, "cache")
  )
  
  for (dir in dirs) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE)
    }
  }
  
  invisible(TRUE)
}

cat("✓ CAV utilities loaded\n")
