# R Script to create folder structure for MBA courses
# Creates main folders for Easter and Lent courses with subfolders for each course



# Define the main directory (current working directory)
main_dir <- 'G:/My Drive/CM/Courses Complementary/'

# Easter Courses (Not Started - 0% complete)
easter_courses <- c(
  "MBA111 Thinking Strategically",
  "MBA138 Implementing Generative AI Ethically", 
  "MBA139 Sustainable Finance",
  "MBA142 Entrepreneurial Strategy",
  "MBA16 Cost Management Control",
  "MBA28 Private Equity",
  "MBA38 Consumer Behaviour",
  "MBA43 Entrepreneurship How to Start a Company",
  "MBA57 Mergers and Acquisitions",
  "MBA64 Strategic Brand Management",
  "MBA73 The Entertainment Industries",
  "MBA88 Strategies for Energy and Climate",
  "MBA97 Supply Chain Strategy"
)

# Lent Courses (Not Started - 0% complete)  
lent_courses <- c(
  "MBA103 Risk Management & Strategic Planning",
  "MBA107 Strategic Pricing",
  "MBA121 Innovating Healthcare Services How to make high quality healthcare affordable for all",
  "MBA125 Leadership in Organisations",
  "MBA129 Net Zero Entrepreneurship", 
  "MBA145 Foundations of New Venture Creation",
  "MBA27 Philosophy of Business",
  "MBA41 Energy and Emissions Markets and Policies",
  "MBA52 Social Impact Through Enterprise",
  "MBA78 Topics in Financial Statement Analysis",
  "MBA79 Digital Marketing",
  "MBA81 Leading Effective Projects"
)

# Function to sanitize folder names (remove special characters)
sanitize_name <- function(name) {
  # Replace special characters with spaces or remove them
  name <- gsub("[&:]", "", name)  # Remove & and :
  name <- gsub("\\s+", " ", name)  # Replace multiple spaces with single space
  name <- trimws(name)  # Remove leading/trailing whitespace
  return(name)
}

# Function to create folders
create_course_folders <- function(course_list, main_folder_name) {
  # Create main folder
  main_folder_path <- file.path(main_dir, main_folder_name)
  if (!dir.exists(main_folder_path)) {
    dir.create(main_folder_path, recursive = TRUE)
    cat("Created main folder:", main_folder_name, "\n")
  } else {
    cat("Main folder already exists:", main_folder_name, "\n")
  }
  
  # Create subfolders for each course
  for (course in course_list) {
    sanitized_course <- sanitize_name(course)
    course_folder_path <- file.path(main_folder_path, sanitized_course)
    
    if (!dir.exists(course_folder_path)) {
      dir.create(course_folder_path, recursive = TRUE)
      cat("  Created subfolder:", sanitized_course, "\n")
    } else {
      cat("  Subfolder already exists:", sanitized_course, "\n")
    }
  }
}

# Create folder structure
cat("Creating folder structure for MBA courses...\n\n")

# Create Easter Courses folders
cat("=== EASTER COURSES ===\n")
create_course_folders(easter_courses, "Easter Courses")

cat("\n=== LENT COURSES ===\n")  
create_course_folders(lent_courses, "Lent Courses")

cat("\nFolder structure creation completed!\n")

# Display the created structure
cat("\n=== FOLDER STRUCTURE SUMMARY ===\n")
cat("Main Directory:", main_dir, "\n")
cat("├── Easter Courses/\n")
for (i in 1:length(easter_courses)) {
  prefix <- if (i == length(easter_courses)) "    └──" else "    ├──"
  cat(prefix, sanitize_name(easter_courses[i]), "/\n")
}

cat("└── Lent Courses/\n") 
for (i in 1:length(lent_courses)) {
  prefix <- if (i == length(lent_courses)) "    └──" else "    ├──"
  cat(prefix, sanitize_name(lent_courses[i]), "/\n")
}