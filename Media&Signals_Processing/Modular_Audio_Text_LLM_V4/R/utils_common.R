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
