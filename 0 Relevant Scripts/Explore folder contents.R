# R Script to analyze folder structure and create summary table
# Shows folders, subfolders, file counts, and sizes in MB

# =============================================================================
# USER CONFIGURATION - MODIFY THIS SECTION
# =============================================================================

# Set the main folder location where your course folders are located
# Examples:
# Windows: "C:/Users/YourName/Documents/MBA_Courses"
# Mac/Linux: "/Users/YourName/Documents/MBA_Courses"
# Current directory: "." or getwd()

MAIN_FOLDER_PATH <- "G:/My Drive/CM/Courses Complementary"  # Change this to your desired path

# Alternative: Uncomment one of these lines and modify as needed
# MAIN_FOLDER_PATH <- "C:/Users/YourName/Documents/MBA_Courses"  # Windows
# MAIN_FOLDER_PATH <- "/Users/YourName/Documents/MBA_Courses"    # Mac/Linux
# MAIN_FOLDER_PATH <- "~/Documents/MBA_Courses"                 # User home directory
# MAIN_FOLDER_PATH <- getwd()                                   # Current working directory

# =============================================================================
# END OF USER CONFIGURATION
# =============================================================================

# Load required libraries
required_packages <- c("here", "dplyr", "knitr", "kableExtra", "tibble")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

# Function to get folder size in MB
get_folder_size_mb <- function(folder_path) {
  if (!dir.exists(folder_path)) return(0)
  
  # Get all files recursively
  files <- list.files(folder_path, recursive = TRUE, full.names = TRUE)
  if (length(files) == 0) return(0)
  
  # Calculate total size
  total_size <- sum(file.info(files)$size, na.rm = TRUE)
  # Convert bytes to MB
  size_mb <- total_size / (1024 * 1024)
  return(round(size_mb, 3))
}

# Function to count files in a folder
count_files <- function(folder_path) {
  if (!dir.exists(folder_path)) return(0)
  
  files <- list.files(folder_path, recursive = TRUE, full.names = TRUE)
  # Filter out directories, count only files
  files <- files[!file.info(files)$isdir]
  return(length(files))
}

# Function to analyze folder structure
analyze_folder_structure <- function(base_dir = MAIN_FOLDER_PATH) {
  
  # Initialize results dataframe
  results <- data.frame(
    Main_Folder = character(),
    Subfolder = character(),
    Full_Path = character(),
    File_Count = integer(),
    Size_MB = numeric(),
    stringsAsFactors = FALSE
  )
  
  # Get main folders (Easter Courses and Lent Courses)
  main_folders <- list.dirs(base_dir, recursive = FALSE, full.names = FALSE)
  main_folders <- main_folders[main_folders %in% c("Easter Courses", "Lent Courses")]
  
  if (length(main_folders) == 0) {
    cat("No 'Easter Courses' or 'Lent Courses' folders found in:", base_dir, "\n")
    cat("Available folders:", paste(list.dirs(base_dir, recursive = FALSE, full.names = FALSE), collapse = ", "), "\n")
    return(NULL)
  }
  
  # Process each main folder
  for (main_folder in main_folders) {
    main_folder_path <- file.path(base_dir, main_folder)
    cat("Processing:", main_folder, "\n")
    
    # Get subfolders (course folders)
    subfolders <- list.dirs(main_folder_path, recursive = FALSE, full.names = FALSE)
    
    if (length(subfolders) == 0) {
      # If no subfolders, analyze the main folder itself
      file_count <- count_files(main_folder_path)
      size_mb <- get_folder_size_mb(main_folder_path)
      
      results <- rbind(results, data.frame(
        Main_Folder = main_folder,
        Subfolder = "[Main Folder]",
        Full_Path = main_folder_path,
        File_Count = file_count,
        Size_MB = size_mb,
        stringsAsFactors = FALSE
      ))
    } else {
      # Process each subfolder
      for (subfolder in subfolders) {
        subfolder_path <- file.path(main_folder_path, subfolder)
        
        file_count <- count_files(subfolder_path)
        size_mb <- get_folder_size_mb(subfolder_path)
        
        cat("  -", subfolder, ":", file_count, "files,", size_mb, "MB\n")
        
        results <- rbind(results, data.frame(
          Main_Folder = main_folder,
          Subfolder = subfolder,
          Full_Path = subfolder_path,
          File_Count = file_count,
          Size_MB = size_mb,
          stringsAsFactors = FALSE
        ))
      }
    }
  }
  
  return(results)
}

# Function to create summary statistics
create_summary <- function(results_df) {
  if (is.null(results_df) || nrow(results_df) == 0) return(NULL)
  
  summary_stats <- results_df %>%
    group_by(Main_Folder) %>%
    summarise(
      Total_Subfolders = n(),
      Total_Files = sum(File_Count),
      Total_Size_MB = round(sum(Size_MB), 3),
      Avg_Files_Per_Subfolder = round(mean(File_Count), 1),
      Avg_Size_Per_Subfolder_MB = round(mean(Size_MB), 3),
      .groups = 'drop'
    )
  
  return(summary_stats)
}

# Function to display results as formatted table
display_results <- function(results_df, summary_df) {
  if (is.null(results_df)) {
    cat("No results to display.\n")
    return()
  }
  
  cat("\n" + "="*80 + "\n")
  cat("FOLDER STRUCTURE ANALYSIS RESULTS\n")
  cat("="*80 + "\n\n")
  
  # Display detailed results
  cat("DETAILED FOLDER ANALYSIS:\n")
  cat("-"*50 + "\n")
  
  if (require(knitr, quietly = TRUE)) {
    # Create a clean display version
    display_df <- results_df %>%
      select(Main_Folder, Subfolder, File_Count, Size_MB) %>%
      rename(
        "Main Folder" = Main_Folder,
        "Course/Subfolder" = Subfolder,
        "Files" = File_Count,
        "Size (MB)" = Size_MB
      )
    
    print(kable(display_df, format = "simple", digits = 3))
  } else {
    print(results_df[, c("Main_Folder", "Subfolder", "File_Count", "Size_MB")])
  }
  
  # Display summary
  if (!is.null(summary_df)) {
    cat("\n\nSUMMARY STATISTICS:\n")
    cat("-"*50 + "\n")
    
    if (require(knitr, quietly = TRUE)) {
      summary_display <- summary_df %>%
        rename(
          "Main Folder" = Main_Folder,
          "Subfolders" = Total_Subfolders,
          "Total Files" = Total_Files,
          "Total Size (MB)" = Total_Size_MB,
          "Avg Files/Subfolder" = Avg_Files_Per_Subfolder,
          "Avg Size/Subfolder (MB)" = Avg_Size_Per_Subfolder_MB
        )
      
      print(kable(summary_display, format = "simple", digits = 3))
    } else {
      print(summary_df)
    }
  }
  
  # Overall totals
  total_files <- sum(results_df$File_Count)
  total_size <- sum(results_df$Size_MB)
  
  cat("\n\nOVERALL TOTALS:\n")
  cat("-"*20 + "\n")
  cat("Total Folders Analyzed:", nrow(results_df), "\n")
  cat("Total Files:", total_files, "\n")
  cat("Total Size:", round(total_size, 3), "MB\n")
  cat("Total Size:", round(total_size/1024, 3), "GB\n")
}

# Main execution
cat("Starting folder structure analysis...\n")
cat("Base directory:", MAIN_FOLDER_PATH, "\n")
cat("Absolute path:", normalizePath(MAIN_FOLDER_PATH, mustWork = FALSE), "\n\n")

# Run the analysis
results <- analyze_folder_structure()

if (!is.null(results)) {
  # Create summary
  summary_stats <- create_summary(results)
  
  # Display results
  display_results(results, summary_stats)
  
  # Optional: Save results to CSV
  write.csv(results, "folder_analysis_detailed.csv", row.names = FALSE)
  if (!is.null(summary_stats)) {
    write.csv(summary_stats, "folder_analysis_summary.csv", row.names = FALSE)
  }
  
  cat("\n\nResults saved to:\n")
  cat("- folder_analysis_detailed.csv\n")
  cat("- folder_analysis_summary.csv\n")
  
} else {
  cat("Analysis could not be completed. Please check that 'Easter Courses' and/or 'Lent Courses' folders exist in your working directory.\n")
}

cat("\nAnalysis complete!\n")