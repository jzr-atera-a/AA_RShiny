# R/utils_omniverse.R
# Utility functions for Omniverse Isaac Sim integration

# Helper function for null coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x

# Parse scenario response from Flask API
parse_scenario_response <- function(response) {
  tryCatch({
    content <- httr::content(response)
    return(content)
  }, error = function(e) {
    warning("Failed to parse scenario response: ", e$message)
    return(NULL)
  })
}

# Validate vehicle configuration
validate_vehicle_config <- function(config) {
  required_fields <- c("name", "category", "mass_properties", "powertrain")
  
  missing <- setdiff(required_fields, names(config))
  if (length(missing) > 0) {
    warning("Vehicle config missing fields: ", paste(missing, collapse = ", "))
    return(FALSE)
  }
  
  return(TRUE)
}

# Format vehicle mass for display
format_vehicle_mass <- function(mass_kg) {
  if (is.null(mass_kg) || is.na(mass_kg)) return("N/A")
  return(format(mass_kg, big.mark = ",", scientific = FALSE))
}

# Format power for display
format_power <- function(power_kw) {
  if (is.null(power_kw) || is.na(power_kw)) return("N/A")
  hp <- round(power_kw * 1.34102, 0)
  return(sprintf("%d kW (%d hp)", power_kw, hp))
}

# Calculate braking distance
calculate_braking_distance <- function(speed_kmh, friction_coefficient) {
  speed_ms <- speed_kmh / 3.6
  g <- 9.81  # m/s²
  deceleration <- friction_coefficient * g
  distance <- (speed_ms^2) / (2 * deceleration)
  return(list(
    distance_m = distance,
    deceleration_ms2 = deceleration,
    stopping_time_s = speed_ms / deceleration
  ))
}

# Extract sensor list from config
get_enabled_sensors <- function(sensor_config) {
  if (is.null(sensor_config)) return(character(0))
  
  sensors <- character(0)
  
  # Camera sensors
  if (!is.null(sensor_config$camera) && length(sensor_config$camera) > 0) {
    sensors <- c(sensors, paste0("Camera: ", paste(sensor_config$camera, collapse = ", ")))
  }
  
  # Other sensors
  if (isTRUE(sensor_config$lidar)) sensors <- c(sensors, "LiDAR")
  if (isTRUE(sensor_config$radar)) sensors <- c(sensors, "Radar")
  if (isTRUE(sensor_config$imu)) sensors <- c(sensors, "IMU")
  if (isTRUE(sensor_config$contact)) sensors <- c(sensors, "Contact Sensors")
  
  return(sensors)
}

# Extract physics list from config
get_enabled_physics <- function(physics_config) {
  if (is.null(physics_config)) return(character(0))
  
  physics <- character(0)
  
  physics_labels <- list(
    mass_inertia = "Mass & Inertia",
    velocity = "Velocity",
    acceleration = "Acceleration",
    momentum = "Momentum",
    wheels = "Wheel Dynamics",
    suspension = "Suspension",
    braking = "Braking",
    drivetrain = "Drivetrain",
    steering = "Steering",
    aerodynamics = "Aerodynamics",
    tire_friction = "Tire Friction",
    contact_forces = "Contact Forces"
  )
  
  for (key in names(physics_config)) {
    if (isTRUE(physics_config[[key]]) && !is.null(physics_labels[[key]])) {
      physics <- c(physics, physics_labels[[key]])
    }
  }
  
  return(physics)
}

# Safe numeric conversion
safe_numeric <- function(x, default = 0) {
  result <- suppressWarnings(as.numeric(x))
  if (is.na(result)) return(default)
  return(result)
}

# Safe list length
safe_length <- function(x) {
  if (is.null(x)) return(0)
  if (is.list(x)) return(length(x))
  if (is.numeric(x)) return(1)
  return(0)
}

# Format quality score
format_quality_score <- function(score) {
  if (is.null(score)) return("N/A")
  score_num <- safe_numeric(score)
  return(sprintf("%.1f/10", score_num))
}

# Get readiness color
get_readiness_color <- function(readiness) {
  if (is.null(readiness)) return("#999999")
  
  colors <- list(
    "GREEN" = "#27ae60",
    "AMBER" = "#f39c12",
    "RED" = "#e74c3c"
  )
  
  return(colors[[toupper(readiness)]] %||% "#999999")
}

# Validate Flask API connection
test_flask_connection <- function(url) {
  tryCatch({
    response <- httr::GET(paste0(url, "/"), httr::timeout(5))
    if (httr::status_code(response) == 200) {
      return(list(success = TRUE, message = "Connected"))
    } else {
      return(list(success = FALSE, message = paste("HTTP", httr::status_code(response))))
    }
  }, error = function(e) {
    return(list(success = FALSE, message = e$message))
  })
}

cat("✓ Omniverse utilities loaded\n")
