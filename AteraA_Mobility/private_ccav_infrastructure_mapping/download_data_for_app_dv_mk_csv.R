# Road Infrastructure Data Download Script - CSV Format
# Downloads road infrastructure data and saves as readable CSV files

library(osmdata)
library(sf)
library(dplyr)
library(readr)

# Create output directory
if (!dir.exists("route_data")) {
  dir.create("route_data")
}

# Define bounding box (replace with your area of interest)
# Example: London area coordinates
bbox <- c(-0.5, 51.3, 0.2, 51.7)  # west, south, east, north

cat("=== DOWNLOADING ROAD INFRASTRUCTURE DATA ===\n")
cat("Bounding box:", paste(bbox, collapse = ", "), "\n\n")

# Initialize storage for all junctions
all_junctions <- list()

# Helper function to convert sf object to readable CSV format
sf_to_csv <- function(sf_data, output_file) {
  if (is.null(sf_data) || nrow(sf_data) == 0) {
    cat("No data to save for", output_file, "\n")
    return(NULL)
  }
  
  # Extract coordinates from geometry
  coords <- st_coordinates(sf_data)
  
  # Create readable dataframe
  csv_data <- sf_data %>%
    st_drop_geometry() %>%
    mutate(
      longitude = coords[,1],
      latitude = coords[,2],
      .after = last_col()
    )
  
  # Write CSV with readable formatting
  write_csv(csv_data, output_file, na = "")
  cat(paste("✓ Saved", nrow(csv_data), "features to", basename(output_file), "\n"))
  
  return(csv_data)
}

# Helper function to safely select and standardize junction columns
safe_select_junctions <- function(data, junction_type_value) {
  if (is.null(data) || nrow(data) == 0) {
    return(NULL)
  }
  
  # Add junction_type column
  data$junction_type <- junction_type_value
  
  # Check which columns exist and add missing ones as NA
  if (!"osm_id" %in% names(data)) data$osm_id <- NA_character_
  if (!"name" %in% names(data)) data$name <- NA_character_
  if (!"highway" %in% names(data)) data$highway <- NA_character_
  if (!"ref" %in% names(data)) data$ref <- NA_character_
  
  # Select standardized columns
  result <- data %>%
    select(osm_id, name, highway, ref, junction_type, geometry)
  
  return(result)
}

# Download highway data
cat("=== DOWNLOADING HIGHWAY DATA ===\n")

# Major highways
cat("Downloading motorways and major roads...\n")
highways_query <- opq(bbox) %>%
  add_osm_feature(key = 'highway', 
                  value = c('motorway', 'trunk', 'primary', 'secondary', 
                            'tertiary', 'motorway_link', 'trunk_link', 
                            'primary_link', 'secondary_link'))

highways_data <- osmdata_sf(highways_query)
highways_lines <- highways_data$osm_lines

if (!is.null(highways_lines) && nrow(highways_lines) > 0) {
  # Save individual highway types
  highway_types <- unique(highways_lines$highway)
  highway_list <- list()
  
  for (htype in highway_types) {
    if (!is.na(htype)) {
      subset_data <- highways_lines[highways_lines$highway == htype, ]
      if (nrow(subset_data) > 0) {
        filename <- paste0("route_data/highways_", gsub("[^A-Za-z0-9]", "_", htype), ".csv")
        csv_data <- sf_to_csv(subset_data, filename)
        if (!is.null(csv_data)) {
          highway_list[[length(highway_list) + 1]] <- csv_data
        }
      }
    }
  }
  
  # Combine all highways
  if (length(highway_list) > 0) {
    all_highways <- do.call(rbind, highway_list)
    write_csv(all_highways, "route_data/all_highways_combined.csv", na = "")
    cat(paste("✓ Saved", nrow(all_highways), "total highway segments to all_highways_combined.csv\n"))
  }
} else {
  cat("⚠ No highway data found\n")
}

# Download junction data
cat("\n=== DOWNLOADING JUNCTION DATA ===\n")

# Motorway junctions
cat("Downloading motorway junctions...\n")
motorway_junctions_query <- opq(bbox) %>%
  add_osm_feature(key = 'highway', value = 'motorway_junction')
motorway_junctions_data <- osmdata_sf(motorway_junctions_query)
motorway_junctions <- motorway_junctions_data$osm_points

# General junctions
cat("Downloading general junctions...\n")
general_junctions_query <- opq(bbox) %>%
  add_osm_feature(key = 'junction', value = c('yes', 'roundabout'))
general_junctions_data <- osmdata_sf(general_junctions_query)
general_junctions <- general_junctions_data$osm_points

# Traffic signals
cat("Downloading traffic signals...\n")
traffic_signals_query <- opq(bbox) %>%
  add_osm_feature(key = 'highway', value = 'traffic_signals')
traffic_signals_data <- osmdata_sf(traffic_signals_query)
traffic_signals <- traffic_signals_data$osm_points

# Process and save junction data
cat("\n=== PROCESSING JUNCTION DATA ===\n")

if (!is.null(motorway_junctions) && nrow(motorway_junctions) > 0) {
  cat(paste("Processing", nrow(motorway_junctions), "motorway junctions...\n"))
  processed_mj <- safe_select_junctions(motorway_junctions, "motorway_junction")
  if (!is.null(processed_mj)) {
    sf_to_csv(processed_mj, "route_data/motorway_junctions.csv")
    all_junctions[[length(all_junctions) + 1]] <- processed_mj
  }
}

if (!is.null(general_junctions) && nrow(general_junctions) > 0) {
  cat(paste("Processing", nrow(general_junctions), "general junctions...\n"))
  processed_gj <- safe_select_junctions(general_junctions, "general_junction")
  if (!is.null(processed_gj)) {
    sf_to_csv(processed_gj, "route_data/general_junctions.csv")
    all_junctions[[length(all_junctions) + 1]] <- processed_gj
  }
}

if (!is.null(traffic_signals) && nrow(traffic_signals) > 0) {
  cat(paste("Processing", nrow(traffic_signals), "traffic signals...\n"))
  processed_ts <- safe_select_junctions(traffic_signals, "traffic_signals")
  if (!is.null(processed_ts)) {
    sf_to_csv(processed_ts, "route_data/traffic_signals.csv")
    all_junctions[[length(all_junctions) + 1]] <- processed_ts
  }
}

# Combine all junction data
if (length(all_junctions) > 0) {
  combined_junctions <- do.call(rbind, all_junctions)
  sf_to_csv(combined_junctions, "route_data/all_junctions_combined.csv")
  
  # Show summary of junction types
  junction_summary <- combined_junctions %>%
    st_drop_geometry() %>%
    count(junction_type, sort = TRUE)
  cat("\nJunction breakdown:\n")
  print(junction_summary)
} else {
  cat("⚠ No junction data to combine\n")
}

# Download additional infrastructure
cat("\n=== DOWNLOADING ADDITIONAL INFRASTRUCTURE ===\n")

# Bridges
cat("Downloading bridges...\n")
bridges_query <- opq(bbox) %>%
  add_osm_feature(key = 'bridge', value = 'yes')
bridges_data <- osmdata_sf(bridges_query)
if (!is.null(bridges_data$osm_lines) && nrow(bridges_data$osm_lines) > 0) {
  sf_to_csv(bridges_data$osm_lines, "route_data/bridges.csv")
}

# Tunnels
cat("Downloading tunnels...\n")
tunnels_query <- opq(bbox) %>%
  add_osm_feature(key = 'tunnel', value = 'yes')
tunnels_data <- osmdata_sf(tunnels_query)
if (!is.null(tunnels_data$osm_lines) && nrow(tunnels_data$osm_lines) > 0) {
  sf_to_csv(tunnels_data$osm_lines, "route_data/tunnels.csv")
}

# Roundabouts
cat("Downloading roundabouts...\n")
roundabouts_query <- opq(bbox) %>%
  add_osm_feature(key = 'junction', value = 'roundabout')
roundabouts_data <- osmdata_sf(roundabouts_query)
if (!is.null(roundabouts_data$osm_ways) && nrow(roundabouts_data$osm_ways) > 0) {
  sf_to_csv(roundabouts_data$osm_ways, "route_data/roundabouts.csv")
}

# Create comprehensive summary statistics
cat("\n=== GENERATING SUMMARY REPORT ===\n")

summary_data <- data.frame(
  dataset = character(),
  feature_count = numeric(),
  file_size_mb = numeric(),
  columns = character(),
  stringsAsFactors = FALSE
)

# Get file info for all created CSV files
csv_files <- list.files("route_data", pattern = "\\.csv$", full.names = TRUE)

for (file in csv_files) {
  if (!file.exists(file)) next  # Skip if file doesn't exist
  
  file_info <- file.info(file)
  file_size_mb <- round(file_info$size / (1024^2), 2)
  
  # Try to read and analyze CSV
  tryCatch({
    data <- read_csv(file, show_col_types = FALSE)
    feature_count <- nrow(data)
    column_names <- paste(names(data), collapse = ", ")
    cat(paste("✓ Verified", basename(file), ":", feature_count, "features\n"))
  }, error = function(e) {
    feature_count <- 0
    column_names <- "Error reading file"
    cat(paste("✗ Error reading", basename(file), ":", e$message, "\n"))
  })
  
  summary_data <- rbind(summary_data, data.frame(
    dataset = basename(file),
    feature_count = feature_count,
    file_size_mb = file_size_mb,
    columns = column_names,
    stringsAsFactors = FALSE
  ))
}

# Save summary
write_csv(summary_data, "route_data/download_summary.csv")

# Print detailed summary
cat("\n=== DOWNLOAD SUMMARY ===\n")
print(summary_data, width = Inf)

total_features <- sum(summary_data$feature_count)
total_size_mb <- sum(summary_data$file_size_mb)

cat(paste("\nTotal features downloaded:", total_features, "\n"))
cat(paste("Total data size:", round(total_size_mb, 2), "MB\n"))

# Create detailed metadata file
metadata_content <- paste0(
  "Road Infrastructure Data Download Report\n",
  "=====================================\n\n",
  "Download completed: ", Sys.time(), "\n",
  "Bounding box (west, south, east, north): ", paste(bbox, collapse = ", "), "\n",
  "Total features: ", total_features, "\n",
  "Total size: ", round(total_size_mb, 2), " MB\n\n",
  "Files created:\n",
  paste("- ", summary_data$dataset, " (", summary_data$feature_count, " features)", collapse = "\n"), "\n\n",
  "Data Format: CSV with longitude/latitude coordinates\n",
  "Coordinate System: WGS84 (EPSG:4326)\n\n",
  "Column explanations:\n",
  "- osm_id: OpenStreetMap unique identifier\n",
  "- name: Feature name (if available)\n",
  "- highway: Road type classification\n",
  "- ref: Reference number (e.g., A40, M25)\n",
  "- junction_type: Type of junction (for junction files)\n",
  "- longitude: X coordinate (decimal degrees)\n",
  "- latitude: Y coordinate (decimal degrees)\n",
  "- Additional columns vary by feature type\n"
)

cat(metadata_content, file = "route_data/README.txt")

cat("\n✓ All data downloaded successfully!")
cat("\n✓ Files saved in 'route_data' directory as CSV format")
cat("\n✓ Summary saved as 'download_summary.csv'")
cat("\n✓ Detailed documentation saved as 'README.txt'")

cat("\n\nCSV Files Created:")
for (file in basename(csv_files)) {
  cat(paste("\n-", file))
}

cat("\n\nNext steps:")
cat("\n1. Check the 'route_data' directory for all CSV files")
cat("\n2. Open CSV files in Excel, R, Python, or any spreadsheet application")
cat("\n3. Use 'all_highways_combined.csv' and 'all_junctions_combined.csv' for comprehensive analysis")
cat("\n4. Individual files available for specific infrastructure types")
cat("\n5. Coordinates are in longitude/latitude format (WGS84)")
cat("\n6. Read 'README.txt' for detailed column explanations\n")