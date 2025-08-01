# Convert GPKG files to CSV format
# This script reads all .gpkg files from route_data folder and saves them as CSV files in route_data_csv folder

library(sf)
library(dplyr)

# Function to convert GPKG to CSV
convert_gpkg_to_csv <- function() {
  
  cat("=== GPKG to CSV Converter ===\n")
  cat("Starting conversion process...\n\n")
  
  # Check if route_data folder exists
  if (!dir.exists("route_data")) {
    cat("✗ ERROR: 'route_data' folder not found!\n")
    cat("Please ensure the route_data folder is in the same directory as this script.\n")
    return()
  }
  
  # Create output directory
  if (!dir.exists("route_data_csv")) {
    dir.create("route_data_csv")
    cat("✓ Created 'route_data_csv' directory\n")
  } else {
    cat("✓ Using existing 'route_data_csv' directory\n")
  }
  
  # Find all GPKG files
  gpkg_files <- list.files("route_data", pattern = "\\.gpkg$", full.names = TRUE)
  
  if (length(gpkg_files) == 0) {
    cat("⚠ No .gpkg files found in route_data folder\n")
    return()
  }
  
  cat("Found", length(gpkg_files), "GPKG files to convert:\n")
  for (file in gpkg_files) {
    cat("  -", basename(file), "\n")
  }
  cat("\n")
  
  # Convert each file
  total_files <- length(gpkg_files)
  successful_conversions <- 0
  
  for (i in seq_along(gpkg_files)) {
    file_path <- gpkg_files[i]
    file_name <- basename(file_path)
    
    cat("Processing", i, "of", total_files, ":", file_name, "\n")
    
    tryCatch({
      # Read the GPKG file
      cat("  Reading GPKG file...\n")
      spatial_data <- st_read(file_path, quiet = TRUE)
      
      # Check if data was loaded
      if (nrow(spatial_data) == 0) {
        cat("  ⚠ Warning: File appears to be empty\n")
      } else {
        cat("  ✓ Loaded", nrow(spatial_data), "features\n")
      }
      
      # Extract coordinates and convert to regular dataframe
      cat("  Converting spatial data to CSV format...\n")
      
      if (st_geometry_type(spatial_data)[1] %in% c("POINT", "MULTIPOINT")) {
        # For point data, extract coordinates directly
        coords <- st_coordinates(spatial_data)
        
        # Create CSV dataframe
        csv_data <- spatial_data %>%
          st_drop_geometry() %>%
          bind_cols(
            longitude = coords[, "X"],
            latitude = coords[, "Y"]
          )
        
        cat("  ✓ Extracted point coordinates\n")
        
      } else if (st_geometry_type(spatial_data)[1] %in% c("LINESTRING", "MULTILINESTRING")) {
        # For line data, extract start and end coordinates
        coords <- st_coordinates(spatial_data)
        
        # Group by line and get start/end points
        coords_summary <- coords %>%
          as.data.frame() %>%
          group_by(L1) %>%
          summarise(
            start_longitude = first(X),
            start_latitude = first(Y),
            end_longitude = last(X),
            end_latitude = last(Y),
            .groups = 'drop'
          )
        
        # Create CSV dataframe
        csv_data <- spatial_data %>%
          st_drop_geometry() %>%
          bind_cols(coords_summary %>% select(-L1))
        
        cat("  ✓ Extracted line start/end coordinates\n")
        
      } else {
        # For polygon data or other types, use centroid
        centroids <- st_centroid(spatial_data)
        coords <- st_coordinates(centroids)
        
        # Create CSV dataframe
        csv_data <- spatial_data %>%
          st_drop_geometry() %>%
          bind_cols(
            centroid_longitude = coords[, "X"],
            centroid_latitude = coords[, "Y"]
          )
        
        cat("  ✓ Extracted polygon centroids\n")
      }
      
      # Create output filename
      csv_filename <- gsub("\\.gpkg$", ".csv", file_name)
      csv_path <- file.path("route_data_csv", csv_filename)
      
      # Save as CSV
      cat("  Saving to CSV...\n")
      write.csv(csv_data, csv_path, row.names = FALSE)
      
      # Verify file was created
      if (file.exists(csv_path)) {
        file_size <- round(file.info(csv_path)$size / 1024, 2)
        cat("  ✓ SUCCESS: Saved", nrow(csv_data), "rows to", csv_filename, "(", file_size, "KB)\n")
        successful_conversions <- successful_conversions + 1
      } else {
        cat("  ✗ ERROR: Failed to create CSV file\n")
      }
      
    }, error = function(e) {
      cat("  ✗ ERROR converting", file_name, ":", e$message, "\n")
    })
    
    cat("\n")
  }
  
  # Summary
  cat("=== CONVERSION SUMMARY ===\n")
  cat("Total files processed:", total_files, "\n")
  cat("Successful conversions:", successful_conversions, "\n")
  cat("Failed conversions:", total_files - successful_conversions, "\n")
  
  if (successful_conversions > 0) {
    cat("\n✓ CSV files saved in 'route_data_csv' directory\n")
    
    # List created files
    csv_files <- list.files("route_data_csv", pattern = "\\.csv$", full.names = FALSE)
    cat("\nCreated files:\n")
    for (file in csv_files) {
      file_path <- file.path("route_data_csv", file)
      file_size <- round(file.info(file_path)$size / 1024, 2)
      cat("  -", file, "(", file_size, "KB)\n")
    }
  }
  
  # Also convert download_summary.csv if it exists
  summary_path <- file.path("route_data", "download_summary.csv")
  if (file.exists(summary_path)) {
    cat("\n📋 Copying download_summary.csv...\n")
    file.copy(summary_path, file.path("route_data_csv", "download_summary.csv"), overwrite = TRUE)
    cat("✓ Copied download_summary.csv\n")
  }
  
  # Also copy metadata.txt if it exists
  metadata_path <- file.path("route_data", "metadata.txt")
  if (file.exists(metadata_path)) {
    cat("📋 Copying metadata.txt...\n")
    file.copy(metadata_path, file.path("route_data_csv", "metadata.txt"), overwrite = TRUE)
    cat("✓ Copied metadata.txt\n")
  }
  
  cat("\n🎉 Conversion process completed!\n")
}

# Run the conversion
convert_gpkg_to_csv()

# Optional: Display summary of created files
cat("\n" , rep("=", 50), "\n", sep = "")
cat("FINAL FILE LISTING\n")
cat(rep("=", 50), "\n")

if (dir.exists("route_data_csv")) {
  all_files <- list.files("route_data_csv", full.names = FALSE)
  
  cat("Files in route_data_csv directory:\n")
  for (file in all_files) {
    file_path <- file.path("route_data_csv", file)
    file_size <- round(file.info(file_path)$size / 1024, 2)
    file_ext <- tools::file_ext(file)
    
    if (file_ext == "csv") {
      # For CSV files, show row count
      tryCatch({
        data <- read.csv(file_path, nrows = 1)
        total_rows <- nrow(read.csv(file_path))
        cat("📊", file, "-", total_rows, "rows,", file_size, "KB\n")
      }, error = function(e) {
        cat("📄", file, "-", file_size, "KB\n")
      })
    } else {
      cat("📄", file, "-", file_size, "KB\n")
    }
  }
  
  total_size <- sum(file.info(file.path("route_data_csv", all_files))$size) / (1024^2)
  cat("\nTotal size:", round(total_size, 2), "MB\n")
} else {
  cat("route_data_csv directory not found\n")
}

cat("\n✅ All done! Your CSV files are ready for use.\n")