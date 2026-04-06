# R/utils_python.R - Python Integration via reticulate

library(reticulate)
library(jsonlite)

#' Initialize Python environment for CAV modules
#' 
#' @param python_path Path to Python executable (optional)
#' @param install_packages Whether to install Python packages
#' @return TRUE if successful, FALSE otherwise
init_python_env <- function(python_path = NULL, install_packages = FALSE) {
  
  tryCatch({
    
    # Use specified Python or find system Python
    if (!is.null(python_path)) {
      use_python(python_path, required = TRUE)
    } else {
      # Try to find conda/virtualenv
      if (file.exists("python_backend/venv")) {
        use_virtualenv("python_backend/venv", required = TRUE)
      } else {
        use_python(Sys.which("python3"), required = FALSE)
      }
    }
    
    # Check if reticulate is working
    py_config()
    
    # Install packages if requested
    if (install_packages) {
      cat("Installing Python packages...\n")
      py_install(
        packages = c(
          "torch", "torchvision", "ultralytics", 
          "googlemaps", "requests", "geopy", "polyline",
          "opencv-python", "Pillow", "numpy", "pandas", "tqdm"
        ),
        pip = TRUE
      )
    }
    
    cat("✓ Python environment initialized\n")
    return(TRUE)
    
  }, error = function(e) {
    warning("Failed to initialize Python: ", e$message)
    return(FALSE)
  })
}

#' Call Python script and return JSON result
#' 
#' @param script_name Python script filename
#' @param args Character vector of arguments
#' @return List parsed from JSON output
call_python_script <- function(script_name, args = NULL) {
  
  script_path <- file.path("python_backend", script_name)
  
  if (!file.exists(script_path)) {
    stop("Python script not found: ", script_path)
  }
  
  # Build command
  python_exe <- py_config()$python
  cmd_args <- c(script_path, args)
  
  # Execute
  result <- tryCatch({
    output <- system2(python_exe, args = cmd_args, stdout = TRUE, stderr = TRUE)
    
    # Parse JSON output
    json_output <- paste(output, collapse = "\n")
    fromJSON(json_output)
    
  }, error = function(e) {
    list(success = FALSE, error = as.character(e))
  })
  
  return(result)
}

#' Get route from Google Maps via Python
#' 
#' @param origin Starting location
#' @param destination Ending location
#' @param api_key Google Maps API key
#' @param spacing_meters Waypoint spacing
#' @return List with route information
get_route_python <- function(origin, destination, api_key, spacing_meters = 50) {
  
  args <- c(origin, destination, api_key, as.character(spacing_meters))
  result <- call_python_script("google_maps_routing.py", args)
  
  return(result)
}

#' Download Street View images via Python
#' 
#' @param waypoints Data frame with lat/lng columns
#' @param output_dir Directory to save images
#' @param api_key Google Maps API key
#' @param sample_rate Download every Nth waypoint
#' @param size Image size (e.g., "640x640")
#' @param fov Field of view in degrees
#' @return List with download results
download_streetview_python <- function(waypoints, output_dir, api_key, 
                                      sample_rate = 1, size = "640x640", fov = 90) {
  
  # Convert waypoints to JSON
  waypoints_json <- toJSON(waypoints, auto_unbox = TRUE)
  
  args <- c(
    waypoints_json,
    output_dir,
    api_key,
    as.character(sample_rate),
    size,
    as.character(fov)
  )
  
  result <- call_python_script("streetview_downloader.py", args)
  
  return(result)
}

#' Run YOLO inference via Python
#' 
#' @param model_path Path to YOLO .pt model file
#' @param image_dir Directory containing images
#' @param confidence_threshold Minimum confidence (0-1)
#' @param output_csv Optional path to save CSV
#' @return List with detection results
run_yolo_python <- function(model_path, image_dir, 
                           confidence_threshold = 0.5, 
                           output_csv = NULL) {
  
  args <- c(
    model_path,
    image_dir,
    as.character(confidence_threshold)
  )
  
  if (!is.null(output_csv)) {
    args <- c(args, output_csv)
  }
  
  result <- call_python_script("yolo_inference.py", args)
  
  return(result)
}

#' Check Python environment status
#' 
#' @return List with status information
check_python_status <- function() {
  
  status <- list(
    reticulate_available = requireNamespace("reticulate", quietly = TRUE),
    python_available = FALSE,
    python_version = NULL,
    torch_available = FALSE,
    ultralytics_available = FALSE,
    googlemaps_available = FALSE
  )
  
  if (status$reticulate_available) {
    tryCatch({
      config <- py_config()
      status$python_available <- TRUE
      status$python_version <- config$version
      
      # Check Python packages
      status$torch_available <- py_module_available("torch")
      status$ultralytics_available <- py_module_available("ultralytics")
      status$googlemaps_available <- py_module_available("googlemaps")
      
    }, error = function(e) {
      status$python_available <- FALSE
    })
  }
  
  return(status)
}

cat("✓ Python integration utilities loaded\n")
