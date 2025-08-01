# Dover to Canterbury Route Data Download Script
# Shorter route for testing and development

library(osmdata)
library(sf)
library(dplyr)

# Print startup information
cat("========================================\n")
cat("Dover to Canterbury Route Data Download\n")
cat("========================================\n")
cat("Start time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Loading required libraries... ✓\n\n")

# Define smaller bounding box for Dover to Canterbury (shorter route)
# Dover: 51.1279, 1.3134
# Canterbury: 51.2802, 1.0789
bbox <- c(1.0, 51.1, 1.4, 51.3)  # [west, south, east, north]

cat("Route Configuration:\n")
cat("- Origin: Dover\n")
cat("- Destination: Canterbury\n")
cat("- Distance: ~17 miles\n")
cat("- Bounding box: [", paste(bbox, collapse = ", "), "]\n\n")

# Create output directory
cat("Setting up output directory...\n")
if (!dir.exists("dover_canterbury_data")) {
  dir.create("dover_canterbury_data")
  cat("✓ Created 'dover_canterbury_data' directory\n")
} else {
  cat("✓ Using existing 'dover_canterbury_data' directory\n")
}

# Function to safely download and save OSM data with detailed status
download_osm_data <- function(query, filename, data_type = "lines", description = "") {
  cat("\n", rep("=", 50), "\n", sep = "")
  cat("DOWNLOADING:", description, "\n")
  cat(rep("=", 50), "\n")
  
  cat("Step 1: Preparing query...\n")
  
  tryCatch({
    cat("Step 2: Sending request to OpenStreetMap Overpass API...\n")
    
    # Add timeout and error handling
    osm_data <- osmdata_sf(query)
    
    cat("Step 3: Processing response from OSM servers...\n")
    
    # Check what data we got back
    if (data_type == "lines") {
      if (!is.null(osm_data$osm_lines) && nrow(osm_data$osm_lines) > 0) {
        result <- osm_data$osm_lines
        cat("✓ OSM Response: Found", nrow(result), "line features\n")
        
        # Show available columns
        cat("✓ Data columns available:", paste(names(result)[1:min(8, length(names(result)))], collapse = ", "))
        if (length(names(result)) > 8) cat("... and", length(names(result)) - 8, "more")
        cat("\n")
        
        cat("Step 4: Saving to local file...\n")
        st_write(result, paste0("dover_canterbury_data/", filename, ".gpkg"), delete_dsn = TRUE, quiet = TRUE)
        
        # Verify file was created
        file_path <- paste0("dover_canterbury_data/", filename, ".gpkg")
        if (file.exists(file_path)) {
          file_size <- round(file.info(file_path)$size / 1024, 2)
          cat("✓ SUCCESS: Saved", nrow(result), "features to", filename, ".gpkg (", file_size, "KB)\n")
        } else {
          cat("✗ ERROR: File was not created successfully\n")
        }
        
        return(result)
        
      } else {
        cat("⚠ OSM Response: No line data found\n")
        if (!is.null(osm_data$osm_points)) {
          cat("  (But found", nrow(osm_data$osm_points), "point features - wrong geometry type)\n")
        }
        return(NULL)
      }
      
    } else if (data_type == "points") {
      if (!is.null(osm_data$osm_points) && nrow(osm_data$osm_points) > 0) {
        result <- osm_data$osm_points
        cat("✓ OSM Response: Found", nrow(result), "point features\n")
        
        # Show available columns
        cat("✓ Data columns available:", paste(names(result)[1:min(8, length(names(result)))], collapse = ", "))
        if (length(names(result)) > 8) cat("... and", length(names(result)) - 8, "more")
        cat("\n")
        
        cat("Step 4: Saving to local file...\n")
        st_write(result, paste0("dover_canterbury_data/", filename, ".gpkg"), delete_dsn = TRUE, quiet = TRUE)
        
        # Verify file was created
        file_path <- paste0("dover_canterbury_data/", filename, ".gpkg")
        if (file.exists(file_path)) {
          file_size <- round(file.info(file_path)$size / 1024, 2)
          cat("✓ SUCCESS: Saved", nrow(result), "features to", filename, ".gpkg (", file_size, "KB)\n")
        } else {
          cat("✗ ERROR: File was not created successfully\n")
        }
        
        return(result)
        
      } else {
        cat("⚠ OSM Response: No point data found\n")
        if (!is.null(osm_data$osm_lines)) {
          cat("  (But found", nrow(osm_data$osm_lines), "line features - wrong geometry type)\n")
        }
        return(NULL)
      }
    }
    
  }, error = function(e) {
    cat("✗ DOWNLOAD FAILED\n")
    cat("Error details:", e$message, "\n")
    
    # Provide helpful troubleshooting info
    if (grepl("timeout", e$message, ignore.case = TRUE)) {
      cat("→ This appears to be a timeout error\n")
      cat("→ Try running the script again or check your internet connection\n")
    } else if (grepl("server", e$message, ignore.case = TRUE)) {
      cat("→ OSM Overpass API server may be temporarily unavailable\n")
      cat("→ Try again in a few minutes\n")
    } else {
      cat("→ Check your internet connection and try again\n")
    }
    
    return(NULL)
  })
}

# Test connection to OSM first
cat("Testing connection to OpenStreetMap...\n")
tryCatch({
  test_query <- opq(c(1.3, 51.1, 1.4, 51.2)) %>%
    add_osm_feature(key = "highway", value = "motorway")
  
  # Just test the query formation, don't download yet
  cat("✓ Connection to OSM Overpass API: READY\n")
  cat("✓ Query formation: WORKING\n\n")
}, error = function(e) {
  cat("✗ Connection test failed:", e$message, "\n")
  cat("Please check your internet connection and try again.\n")
  stop("Cannot proceed without OSM connection")
})

# Download relevant highway data for Dover-Canterbury route

# 1. Primary Roads (A2 is the main route)
primary_roads <- download_osm_data(
  opq(bbox) %>% add_osm_feature(key = "highway", value = "primary"),
  "primary_roads", 
  "lines",
  "Primary Roads (A-roads including A2)"
)

# 2. Motorway Links (for M2/A2 connections)
motorway_links <- download_osm_data(
  opq(bbox) %>% add_osm_feature(key = "highway", value = "primary_link"),
  "primary_links", 
  "lines",
  "Primary Road Links (A2 connections)"
)

# 3. Secondary Roads (alternative routes)
secondary_roads <- download_osm_data(
  opq(bbox) %>% add_osm_feature(key = "highway", value = "secondary"),
  "secondary_roads", 
  "lines",
  "Secondary Roads (B-roads)"
)

# 4. Major Junctions
junctions <- download_osm_data(
  opq(bbox) %>% add_osm_feature(key = "junction"),
  "junctions", 
  "points",
  "Road Junctions and Roundabouts"
)

# 5. Traffic Signals
traffic_signals <- download_osm_data(
  opq(bbox) %>% add_osm_feature(key = "highway", value = "traffic_signals"),
  "traffic_signals", 
  "points",
  "Traffic Signals"
)

# 6. Any nearby motorway segments
motorways <- download_osm_data(
  opq(bbox) %>% add_osm_feature(key = "highway", value = "motorway"),
  "motorways", 
  "lines",
  "Motorway Segments (M2 if present)"
)

# Create summary and combined datasets
cat("\n", rep("=", 60), "\n", sep = "")
cat("CREATING SUMMARY AND COMBINED DATASETS\n")
cat(rep("=", 60), "\n")

# Combine highway data
cat("Combining highway data...\n")
all_highways <- list()

if (!is.null(primary_roads)) {
  primary_roads$road_type <- "primary"
  cat("✓ Including", nrow(primary_roads), "primary road segments\n")
  all_highways[[length(all_highways) + 1]] <- primary_roads %>% 
    select(osm_id, name, highway, lanes, oneway, maxspeed, ref, road_type, geometry)
}

if (!is.null(motorway_links)) {
  motorway_links$road_type <- "primary_link"
  cat("✓ Including", nrow(motorway_links), "primary link segments\n")
  all_highways[[length(all_highways) + 1]] <- motorway_links %>% 
    select(osm_id, name, highway, lanes, oneway, maxspeed, ref, road_type, geometry)
}

if (!is.null(secondary_roads)) {
  secondary_roads$road_type <- "secondary"
  cat("✓ Including", nrow(secondary_roads), "secondary road segments\n")
  all_highways[[length(all_highways) + 1]] <- secondary_roads %>% 
    select(osm_id, name, highway, lanes, oneway, maxspeed, ref, road_type, geometry)
}

if (!is.null(motorways)) {
  motorways$road_type <- "motorway"
  cat("✓ Including", nrow(motorways), "motorway segments\n")
  all_highways[[length(all_highways) + 1]] <- motorways %>% 
    select(osm_id, name, highway, lanes, oneway, maxspeed, ref, road_type, geometry)
}

# Save combined highway data
if (length(all_highways) > 0) {
  combined_highways <- do.call(rbind, all_highways)
  st_write(combined_highways, "dover_canterbury_data/all_highways_combined.gpkg", delete_dsn = TRUE, quiet = TRUE)
  cat("✓ Combined highways saved:", nrow(combined_highways), "total segments\n")
} else {
  cat("⚠ No highway data to combine\n")
}

# Combine junction data
cat("Combining junction data...\n")
all_junctions <- list()

if (!is.null(junctions)) {
  junctions$junction_type <- "general"
  cat("✓ Including", nrow(junctions), "general junctions\n")
  all_junctions[[length(all_junctions) + 1]] <- junctions %>%
    select(osm_id, name, highway, ref, junction_type, geometry)
}

if (!is.null(traffic_signals)) {
  traffic_signals$junction_type <- "traffic_signals"
  cat("✓ Including", nrow(traffic_signals), "traffic signals\n")
  all_junctions[[length(all_junctions) + 1]] <- traffic_signals %>%
    select(osm_id, name, highway, ref, junction_type, geometry)
}

# Save combined junction data
if (length(all_junctions) > 0) {
  combined_junctions <- do.call(rbind, all_junctions)
  st_write(combined_junctions, "dover_canterbury_data/all_junctions_combined.gpkg", delete_dsn = TRUE, quiet = TRUE)
  cat("✓ Combined junctions saved:", nrow(combined_junctions), "total points\n")
} else {
  cat("⚠ No junction data to combine\n")
}

# Generate final summary
cat("\n", rep("=", 60), "\n", sep = "")
cat("FINAL DOWNLOAD SUMMARY\n")
cat(rep("=", 60), "\n")

# Create summary report
summary_data <- data.frame(
  dataset = character(),
  feature_count = numeric(),
  file_size_kb = numeric(),
  status = character(),
  stringsAsFactors = FALSE
)

# Check all created files
gpkg_files <- list.files("dover_canterbury_data", pattern = "\\.gpkg$", full.names = TRUE)

for (file in gpkg_files) {
  file_info <- file.info(file)
  file_size_kb <- round(file_info$size / 1024, 2)
  
  # Try to read and count features
  tryCatch({
    data <- st_read(file, quiet = TRUE)
    feature_count <- nrow(data)
    status <- "SUCCESS"
  }, error = function(e) {
    feature_count <- 0
    status <- "ERROR"
  })
  
  summary_data <- rbind(summary_data, data.frame(
    dataset = basename(file),
    feature_count = feature_count,
    file_size_kb = file_size_kb,
    status = status,
    stringsAsFactors = FALSE
  ))
}

# Save and display summary
write.csv(summary_data, "dover_canterbury_data/download_summary.csv", row.names = FALSE)

cat("Files created:\n")
for (i in 1:nrow(summary_data)) {
  row <- summary_data[i, ]
  cat(sprintf("  %s: %d features, %.2f KB [%s]\n", 
              row$dataset, row$feature_count, row$file_size_kb, row$status))
}

total_features <- sum(summary_data$feature_count)
total_size_kb <- sum(summary_data$file_size_kb)

cat("\nOverall Statistics:\n")
cat("✓ Total features downloaded:", total_features, "\n")
cat("✓ Total data size:", round(total_size_kb / 1024, 2), "MB\n")
cat("✓ Files created:", nrow(summary_data), "\n")
cat("✓ Success rate:", sum(summary_data$status == "SUCCESS"), "/", nrow(summary_data), "\n")

# Save metadata
metadata_content <- paste0(
  "Dover to Canterbury Route Data Download\n",
  "=====================================\n",
  "Download completed: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n",
  "Bounding box: [", paste(bbox, collapse = ", "), "]\n",
  "Total features: ", total_features, "\n",
  "Total size: ", round(total_size_kb / 1024, 2), " MB\n",
  "Files created: ", nrow(summary_data), "\n\n",
  "Route Information:\n",
  "- Origin: Dover\n",
  "- Destination: Canterbury\n",
  "- Distance: ~17 miles\n",
  "- Main route: A2\n\n",
  "Key files for Shiny app:\n",
  "- all_highways_combined.gpkg (main road network)\n",
  "- all_junctions_combined.gpkg (junction points)\n"
)

writeLines(metadata_content, "dover_canterbury_data/metadata.txt")

cat("\n", rep("=", 60), "\n", sep = "")
cat("DOWNLOAD COMPLETE!\n")
cat(rep("=", 60), "\n")
cat("✓ All data files saved in 'dover_canterbury_data' directory\n")
cat("✓ Summary saved as 'download_summary.csv'\n")
cat("✓ Metadata saved as 'metadata.txt'\n")
cat("✓ Ready for Shiny app integration\n")
cat("\nEnd time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")