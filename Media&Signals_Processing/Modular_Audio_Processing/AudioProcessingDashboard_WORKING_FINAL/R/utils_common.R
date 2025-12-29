# ============================================================================
# COMMON UTILITIES
# ============================================================================
# 
# Shared utility functions used across modules
#
# ============================================================================

# NULL coalescing operator
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Get volumes for directory browsing (cross-platform)
getAppVolumes <- function() {
  volumes <- c(Home = fs::path_home())
  
  # Add system volumes
  sys_volumes <- tryCatch({
    shinyFiles::getVolumes()()
  }, error = function(e) {
    c()
  })
  
  volumes <- c(volumes, sys_volumes)
  
  # Windows: Add all drive letters
  if (.Platform$OS.type == "windows") {
    drive_letters <- LETTERS[3:26]  # C through Z
    for (letter in drive_letters) {
      drive_path <- paste0(letter, ":/")
      if (dir.exists(drive_path)) {
        volumes[[paste0(letter, ":")]] <- drive_path
      }
    }
  }
  
  return(volumes)
}

# Safe file size formatting
format_file_size <- function(bytes) {
  if (is.na(bytes) || bytes < 0) return("Unknown")
  
  units <- c("B", "KB", "MB", "GB", "TB")
  idx <- 1
  size <- bytes
  
  while (size >= 1024 && idx < length(units)) {
    size <- size / 1024
    idx <- idx + 1
  }
  
  paste(round(size, 2), units[idx])
}

# Safe word count
count_words <- function(text) {
  if (is.null(text) || nchar(trimws(text)) == 0) return(0)
  length(strsplit(trimws(text), "\\s+")[[1]])
}

# Create timestamped filename
create_timestamped_filename <- function(prefix = "file", extension = "txt") {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  paste0(prefix, "_", timestamp, ".", extension)
}

# Safe directory creation
ensure_directory <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  return(dir.exists(path))
}
