# ============================================================================
# COMMON UTILITIES
# ============================================================================

# Setup volume roots for directory browsing
get_volume_roots <- function() {
  if (.Platform$OS.type == "windows") {
    volumes <- c("C:" = "C:/", "D:" = "D:/", "E:" = "E:/", "Home" = fs::path_home())
    volumes <- volumes[sapply(volumes, dir.exists)]
  } else {
    volumes <- c(
      "Home" = fs::path_home(),
      "Root" = "/",
      "Documents" = path.expand("~/Documents"),
      "Desktop" = path.expand("~/Desktop"),
      "Downloads" = path.expand("~/Downloads")
    )
    volumes <- volumes[sapply(volumes, dir.exists)]
  }
  return(volumes)
}

# Convert cm to inches
cm_to_inches <- function(cm) {
  return(cm / 2.54)
}

# Convert inches to cm
inches_to_cm <- function(inches) {
  return(inches * 2.54)
}

# Calculate width from height and aspect ratio
calculate_width <- function(height, aspect_ratio, unit = "cm") {
  # Parse aspect ratio (e.g., "16:9" -> c(16, 9))
  ratio_parts <- as.numeric(strsplit(aspect_ratio, ":")[[1]])
  width_ratio <- ratio_parts[1]
  height_ratio <- ratio_parts[2]
  
  # Calculate width
  width <- height * (width_ratio / height_ratio)
  
  return(round(width, 2))
}

# Map aspect ratio to DALL-E image sizes
get_dalle_size <- function(aspect_ratio, model) {
  if (model == "dall-e-3") {
    # DALL-E 3 supports: 1024x1024, 1024x1792, 1792x1024
    # Map aspect ratios to closest available size
    size_map <- list(
      "1:1" = "1024x1024",     # Perfect square
      "4:3" = "1024x1024",     # Close to square (1.33:1 → 1:1)
      "3:4" = "1024x1024",     # Close to square (0.75:1 → 1:1)
      "16:9" = "1792x1024",    # Landscape (1.78:1 → 1.75:1)
      "9:16" = "1024x1792"     # Portrait (0.56:1 → 0.57:1)
    )
  } else {
    # DALL-E 2 supports: 256x256, 512x512, 1024x1024 (all square)
    # Use highest quality available
    size_map <- list(
      "1:1" = "1024x1024",
      "4:3" = "1024x1024",
      "3:4" = "1024x1024",
      "16:9" = "1024x1024",
      "9:16" = "1024x1024"
    )
  }
  
  return(size_map[[aspect_ratio]] %||% "1024x1024")
}

# Enhance prompt based on style
enhance_prompt <- function(description, style) {
  if (style == "art") {
    prefix <- "Create an artistic illustration of: "
    suffix <- ". Style: digital art, vibrant colors, creative composition, artistic interpretation."
  } else if (style == "photo") {
    prefix <- "Create a photorealistic photograph of: "
    suffix <- ". Style: high-resolution photography, natural lighting, sharp focus, professional quality."
  } else {
    prefix <- ""
    suffix <- ""
  }
  
  enhanced <- paste0(prefix, description, suffix)
  return(enhanced)
}
