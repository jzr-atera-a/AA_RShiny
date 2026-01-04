# R/utils_common.R - Common Utility Functions
# Greenwich AV Project

# Format file sizes
format_file_size <- function(bytes) {
  if (is.na(bytes) || bytes == 0) return("0 B")
  
  units <- c("B", "KB", "MB", "GB", "TB")
  i <- floor(log(bytes, 1024))
  i <- min(i, length(units) - 1)
  
  size <- bytes / (1024^i)
  paste(round(size, 2), units[i + 1])
}

# Create export directory
create_export_dir <- function(base_name = "Greenwich_Data_Export") {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  dir_name <- paste0(base_name, "_", timestamp)
  
  if (!dir.exists(dir_name)) {
    dir.create(dir_name, recursive = TRUE)
  }
  
  return(dir_name)
}

# Save metadata JSON
save_metadata <- function(data_manager, export_dir) {
  metadata <- list(
    export_date = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    location = data_manager$location_name,
    bbox = data_manager$bbox,
    coordinate_system = "WGS84 (EPSG:4326)",
    target_area_size = "200m x 200m",
    project = "Greenwich AV VR Simulation",
    platform = "Meta Quest 3 / Jetson Nano",
    data_layers = list()
  )
  
  if (!is.null(data_manager$osm_data)) {
    metadata$data_layers$osm <- list(
      source = "OpenStreetMap",
      type = "Buildings, Roads, POI",
      format = "GeoJSON"
    )
  }
  
  if (!is.null(data_manager$terrain_data)) {
    metadata$data_layers$terrain <- list(
      source = "OS Terrain / LIDAR",
      type = "Elevation data",
      format = "GeoTIFF"
    )
  }
  
  if (!is.null(data_manager$imagery_data)) {
    metadata$data_layers$imagery <- list(
      source = "Satellite Imagery",
      type = "Aerial imagery",
      format = "PNG/GeoTIFF"
    )
  }
  
  metadata_path <- file.path(export_dir, "metadata.json")
  write(jsonlite::toJSON(metadata, pretty = TRUE, auto_unbox = TRUE), metadata_path)
  
  return(metadata_path)
}

# Create zip bundle
create_zip_bundle <- function(export_dir) {
  zip_file <- paste0(export_dir, ".zip")
  
  files_to_zip <- list.files(export_dir, full.names = TRUE, recursive = TRUE)
  
  if (length(files_to_zip) > 0) {
    zip(zipfile = zip_file, files = files_to_zip, flags = "-r9Xq")
    return(zip_file)
  } else {
    return(NULL)
  }
}

# Download handler helper
create_download_handler <- function(filename_func, content_func) {
  downloadHandler(
    filename = filename_func,
    content = content_func
  )
}

# Status message helper
status_message <- function(type = "info", title, message) {
  class_name <- switch(type,
    "success" = "status-success",
    "error" = "status-error",
    "warning" = "status-warning",
    "info" = "status-info",
    "status-info"
  )
  
  div(class = class_name,
    h5(title),
    p(message)
  )
}

# Progress wrapper
with_progress_safe <- function(expr, message = "Processing...", detail = NULL) {
  tryCatch({
    withProgress(message = message, detail = detail, value = 0, {
      expr
    })
  }, error = function(e) {
    showNotification(paste("Error:", e$message), type = "error", duration = 10)
    NULL
  })
}
