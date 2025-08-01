# Dover to Milton Keynes Route Data Download Script
# This script downloads all relevant OSM data for the route and saves it locally

library(osmdata)
library(sf)
library(dplyr)

# Set up parameters
cat("Starting Dover to Milton Keynes route data download...\n")

# Define bounding box for Dover to Milton Keynes corridor
# Covers southeastern England from Dover to Milton Keynes
bbox <- c(-1.5, 51.1, 1.4, 52.1)  # [west, south, east, north]

# Create output directory
if (!dir.exists("route_data")) {
  dir.create("route_data")
  cat("Created 'route_data' directory\n")
}

# Function to safely download and save OSM data
download_osm_data <- function(query, filename, data_type = "lines") {
  cat(paste("Downloading", filename, "...\n"))
  
  tryCatch({
    osm_data <- osmdata_sf(query)
    
    if (data_type == "lines" && !is.null(osm_data$osm_lines) && nrow(osm_data$osm_lines) > 0) {
      result <- osm_data$osm_lines
      st_write(result, paste0("route_data/", filename, ".gpkg"), delete_dsn = TRUE)
      cat(paste("✓ Saved", nrow(result), "line features to", filename, ".gpkg\n"))
      return(result)
    } else if (data_type == "points" && !is.null(osm_data$osm_points) && nrow(osm_data$osm_points) > 0) {
      result <- osm_data$osm_points
      st_write(result, paste0("route_data/", filename, ".gpkg"), delete_dsn = TRUE)
      cat(paste("✓ Saved", nrow(result), "point features to", filename, ".gpkg\n"))
      return(result)
    } else {
      cat(paste("⚠ No data found for", filename, "\n"))
      return(NULL)
    }
  }, error = function(e) {
    cat(paste("✗ Error downloading", filename, ":", e$message, "\n"))
    return(NULL)
  })
}

# 1. Download Motorways (M-roads)
cat("\n=== DOWNLOADING MOTORWAYS ===\n")
motorway_query <- opq(bbox) %>%
  add_osm_feature(key = "highway", value = "motorway")

motorways <- download_osm_data(motorway_query, "motorways", "lines")

# 2. Download Primary Roads (A-roads)
cat("\n=== DOWNLOADING PRIMARY ROADS ===\n")
primary_query <- opq(bbox) %>%
  add_osm_feature(key = "highway", value = "primary")

primary_roads <- download_osm_data(primary_query, "primary_roads", "lines")

# 3. Download Secondary Roads
cat("\n=== DOWNLOADING SECONDARY ROADS ===\n")
secondary_query <- opq(bbox) %>%
  add_osm_feature(key = "highway", value = "secondary")

secondary_roads <- download_osm_data(secondary_query, "secondary_roads", "lines")

# 4. Download Trunk Roads
cat("\n=== DOWNLOADING TRUNK ROADS ===\n")
trunk_query <- opq(bbox) %>%
  add_osm_feature(key = "highway", value = "trunk")

trunk_roads <- download_osm_data(trunk_query, "trunk_roads", "lines")

# 5. Download Motorway Links (on/off ramps)
cat("\n=== DOWNLOADING MOTORWAY LINKS ===\n")
motorway_link_query <- opq(bbox) %>%
  add_osm_feature(key = "highway", value = "motorway_link")

motorway_links <- download_osm_data(motorway_link_query, "motorway_links", "lines")

# 6. Download Primary Links
cat("\n=== DOWNLOADING PRIMARY LINKS ===\n")
primary_link_query <- opq(bbox) %>%
  add_osm_feature(key = "highway", value = "primary_link")

primary_links <- download_osm_data(primary_link_query, "primary_links", "lines")

# 7. Download Motorway Junctions
cat("\n=== DOWNLOADING MOTORWAY JUNCTIONS ===\n")
motorway_junction_query <- opq(bbox) %>%
  add_osm_feature(key = "highway", value = "motorway_junction")

motorway_junctions <- download_osm_data(motorway_junction_query, "motorway_junctions", "points")

# 8. Download General Junctions
cat("\n=== DOWNLOADING GENERAL JUNCTIONS ===\n")
junction_query <- opq(bbox) %>%
  add_osm_feature(key = "junction")

general_junctions <- download_osm_data(junction_query, "general_junctions", "points")

# 9. Download Roundabouts (as lines)
cat("\n=== DOWNLOADING ROUNDABOUTS ===\n")
roundabout_query <- opq(bbox) %>%
  add_osm_feature(key = "junction", value = "roundabout")

roundabouts <- download_osm_data(roundabout_query, "roundabouts", "lines")

# 10. Download Traffic Signals
cat("\n=== DOWNLOADING TRAFFIC SIGNALS ===\n")
traffic_signals_query <- opq(bbox) %>%
  add_osm_feature(key = "highway", value = "traffic_signals")

traffic_signals <- download_osm_data(traffic_signals_query, "traffic_signals", "points")

# 11. Download Bridges
cat("\n=== DOWNLOADING BRIDGES ===\n")
bridge_query <- opq(bbox) %>%
  add_osm_feature(key = "bridge", value = "yes")

bridges <- download_osm_data(bridge_query, "bridges", "lines")

# 12. Download Tunnels
cat("\n=== DOWNLOADING TUNNELS ===\n")
tunnel_query <- opq(bbox) %>%
  add_osm_feature(key = "tunnel", value = "yes")

tunnels <- download_osm_data(tunnel_query, "tunnels", "lines")

# 13. Create combined highway dataset
cat("\n=== CREATING COMBINED DATASETS ===\n")

# Combine all highway types
all_highways <- list()

if (!is.null(motorways)) {
  motorways$road_type <- "motorway"
  all_highways[[length(all_highways) + 1]] <- motorways %>% 
    select(osm_id, name, highway, lanes, oneway, maxspeed, ref, road_type, geometry)
}

if (!is.null(primary_roads)) {
  primary_roads$road_type <- "primary"
  all_highways[[length(all_highways) + 1]] <- primary_roads %>% 
    select(osm_id, name, highway, lanes, oneway, maxspeed, ref, road_type, geometry)
}

if (!is.null(secondary_roads)) {
  secondary_roads$road_type <- "secondary"
  all_highways[[length(all_highways) + 1]] <- secondary_roads %>% 
    select(osm_id, name, highway, lanes, oneway, maxspeed, ref, road_type, geometry)
}

if (!is.null(trunk_roads)) {
  trunk_roads$road_type <- "trunk"
  all_highways[[length(all_highways) + 1]] <- trunk_roads %>% 
    select(osm_id, name, highway, lanes, oneway, maxspeed, ref, road_type, geometry)
}

if (!is.null(motorway_links)) {
  motorway_links$road_type <- "motorway_link"
  all_highways[[length(all_highways) + 1]] <- motorway_links %>% 
    select(osm_id, name, highway, lanes, oneway, maxspeed, ref, road_type, geometry)
}

if (!is.null(primary_links)) {
  primary_links$road_type <- "primary_link"
  all_highways[[length(all_highways) + 1]] <- primary_links %>% 
    select(osm_id, name, highway, lanes, oneway, maxspeed, ref, road_type, geometry)
}

# Combine all highway data
if (length(all_highways) > 0) {
  combined_highways <- do.call(rbind, all_highways)
  st_write(combined_highways, "route_data/all_highways_combined.gpkg", delete_dsn = TRUE)
  cat(paste("✓ Saved", nrow(combined_highways), "total highway segments to all_highways_combined.gpkg\n"))
}
#----Error apparently here...
all_junctions <- list()

# Helper function to safely select columns
safe_select_junctions <- function(data, junction_type_value) {
  # Add junction_type column
  data$junction_type <- junction_type_value
  
  # Check which columns exist and select only available ones
  available_cols <- names(data)
  desired_cols <- c("osm_id", "name", "highway", "ref", "junction_type", "geometry")
  cols_to_select <- intersect(desired_cols, available_cols)
  
  # Add missing columns as NA if they don't exist
  if (!"osm_id" %in% available_cols) data$osm_id <- NA_character_
  if (!"name" %in% available_cols) data$name <- NA_character_
  if (!"highway" %in% available_cols) data$highway <- NA_character_
  if (!"ref" %in% available_cols) data$ref <- NA_character_
  
  # Select the standardized columns
  result <- data %>%
    select(osm_id, name, highway, ref, junction_type, geometry)
  
  return(result)
}

if (!is.null(motorway_junctions)) {
  cat(paste("Processing", nrow(motorway_junctions), "motorway junctions...\n"))
  processed_mj <- safe_select_junctions(motorway_junctions, "motorway_junction")
  all_junctions[[length(all_junctions) + 1]] <- processed_mj
}

if (!is.null(general_junctions)) {
  cat(paste("Processing", nrow(general_junctions), "general junctions...\n"))
  processed_gj <- safe_select_junctions(general_junctions, "general_junction")
  all_junctions[[length(all_junctions) + 1]] <- processed_gj
}

if (!is.null(traffic_signals)) {
  cat(paste("Processing", nrow(traffic_signals), "traffic signals...\n"))
  processed_ts <- safe_select_junctions(traffic_signals, "traffic_signals")
  all_junctions[[length(all_junctions) + 1]] <- processed_ts
}

# Combine all junction data
if (length(all_junctions) > 0) {
  combined_junctions <- do.call(rbind, all_junctions)
  st_write(combined_junctions, "route_data/all_junctions_combined.gpkg", delete_dsn = TRUE)
  cat(paste("✓ Saved", nrow(combined_junctions), "total junction points to all_junctions_combined.gpkg\n"))
  
  # Show summary of junction types
  junction_summary <- combined_junctions %>%
    st_drop_geometry() %>%
    count(junction_type, sort = TRUE)
  cat("Junction breakdown:\n")
  print(junction_summary)
} else {
  cat("⚠ No junction data to combine\n")
}

# Create summary statistics
cat("\n=== GENERATING SUMMARY REPORT ===\n")

summary_data <- data.frame(
  dataset = character(),
  feature_count = numeric(),
  file_size_mb = numeric(),
  stringsAsFactors = FALSE
)

# Get file info for all created files
gpkg_files <- list.files("route_data", pattern = "\\.gpkg$", full.names = TRUE)

for (file in gpkg_files) {
  file_info <- file.info(file)
  file_size_mb <- round(file_info$size / (1024^2), 2)
  
  # Try to read and count features
  tryCatch({
    data <- st_read(file, quiet = TRUE)
    feature_count <- nrow(data)
    cat(paste("✓ Verified", basename(file), ":", feature_count, "features\n"))
  }, error = function(e) {
    feature_count <- 0
    cat(paste("✗ Error reading", basename(file), ":", e$message, "\n"))
  })
  
  summary_data <- rbind(summary_data, data.frame(
    dataset = basename(file),
    feature_count = feature_count,
    file_size_mb = file_size_mb,
    stringsAsFactors = FALSE
  ))
}

# Save summary
write.csv(summary_data, "route_data/download_summary.csv", row.names = FALSE)

# Print summary
cat("\n=== DOWNLOAD SUMMARY ===\n")
print(summary_data)

total_features <- sum(summary_data$feature_count)
total_size_mb <- sum(summary_data$file_size_mb)

cat(paste("\nTotal features downloaded:", total_features, "\n"))
cat(paste("Total data size:", round(total_size_mb, 2), "MB\n"))

# Create metadata file
metadata <- list(
  download_date = Sys.time(),
  bounding_box = bbox,
  total_features = total_features,
  total_size_mb = round(total_size_mb, 2),
  files_created = summary_data$dataset
)

# Save metadata as JSON-like text file
cat(paste("Download completed on:", metadata$download_date, "\n"), 
    file = "route_data/metadata.txt")
cat(paste("Bounding box (west, south, east, north):", paste(bbox, collapse = ", "), "\n"), 
    file = "route_data/metadata.txt", append = TRUE)
cat(paste("Total features:", metadata$total_features, "\n"), 
    file = "route_data/metadata.txt", append = TRUE)
cat(paste("Total size:", metadata$total_size_mb, "MB\n"), 
    file = "route_data/metadata.txt", append = TRUE)

cat("\n✓ All data downloaded successfully!")
cat("\n✓ Files saved in 'route_data' directory")
cat("\n✓ Summary saved as 'download_summary.csv'")
cat("\n✓ Metadata saved as 'metadata.txt'")

cat("\n\nNext steps:")
cat("\n1. Check the 'route_data' directory for all downloaded files")
cat("\n2. Use 'all_highways_combined.gpkg' and 'all_junctions_combined.gpkg' for your app")
cat("\n3. Individual highway type files are also available for detailed analysis\n")