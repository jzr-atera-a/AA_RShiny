# R/utils_common.R
# Shared Utility Functions
# ========================

# Safe SQL escape for preventing injection
safe_sql_escape <- function(input_value) {
  gsub("'", "''", input_value)
}

# Parse summary text into data frame
parse_summary_text <- function(text) {
  
  lines <- strsplit(text, "\n")[[1]]
  
  # Extract metadata (first 4 bracketed lines)
  book_name <- NULL
  author <- NULL
  genre <- NULL
  topic <- NULL
  
  metadata_count <- 0
  for (i in seq_len(min(15, length(lines)))) {
    line <- trimws(lines[i])
    
    if (grepl("^\\[.+\\]$", line)) {
      metadata_count <- metadata_count + 1
      value <- gsub("^\\[|\\]$", "", line)
      
      if (metadata_count == 1) book_name <- value
      else if (metadata_count == 2) author <- value
      else if (metadata_count == 3) genre <- value
      else if (metadata_count == 4) topic <- value
      else break
    }
  }
  
  if (is.null(book_name) || is.null(author)) {
    stop("Could not find book name and author in summary")
  }
  
  if (is.null(genre)) genre <- ""
  if (is.null(topic)) topic <- ""
  
  # Parse entries
  entries <- list()
  current_entry <- list()
  
  for (line in lines) {
    line <- trimws(line)
    
    if (line == "" || grepl("^\\[.+\\]$", line)) {
      if (length(current_entry) >= 4 && !is.null(current_entry$chapter)) {
        entries[[length(entries) + 1]] <- current_entry
        current_entry <- list()
      }
      next
    }
    
    if (grepl("^\\[chapter\\]:", line, ignore.case = TRUE)) {
      current_entry$chapter <- trimws(sub("^\\[chapter\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (grepl("^\\[section\\]:", line, ignore.case = TRUE)) {
      current_entry$section <- trimws(sub("^\\[section\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (grepl("^\\[main_details\\]:", line, ignore.case = TRUE)) {
      current_entry$main_details <- trimws(sub("^\\[main_details\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (grepl("^\\[formula\\]:", line, ignore.case = TRUE)) {
      current_entry$formula <- trimws(sub("^\\[formula\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (grepl("^\\[formula_explanation\\]:", line, ignore.case = TRUE)) {
      current_entry$formula_explanation <- trimws(sub("^\\[formula_explanation\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (grepl("^\\[reference_url\\]:", line, ignore.case = TRUE)) {
      current_entry$reference_url <- trimws(sub("^\\[reference_url\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (grepl("^\\[reference_description\\]:", line, ignore.case = TRUE)) {
      current_entry$reference_description <- trimws(sub("^\\[reference_description\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (grepl("^\\[numeric_data\\]:", line, ignore.case = TRUE)) {
      current_entry$numeric_data <- trimws(sub("^\\[numeric_data\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (grepl("^\\[numeric_data_description\\]:", line, ignore.case = TRUE)) {
      current_entry$numeric_data_description <- trimws(sub("^\\[numeric_data_description\\]:\\s*", "", line, ignore.case = TRUE))
    }
  }
  
  # Add last entry if exists
  if (length(current_entry) >= 4 && !is.null(current_entry$chapter)) {
    entries[[length(entries) + 1]] <- current_entry
  }
  
  if (length(entries) == 0) {
    stop("No valid entries found in summary")
  }
  
  # Convert to data frame
  parsed_df <- data.frame(
    book_name = character(),
    author = character(),
    genre = character(),
    topic = character(),
    chapter = character(),
    section = character(),
    main_details = character(),
    formula = character(),
    formula_explanation = character(),
    reference_url = character(),
    reference_description = character(),
    numeric_data = character(),
    numeric_data_description = character(),
    stringsAsFactors = FALSE
  )
  
  for (entry in entries) {
    parsed_df <- rbind(parsed_df, data.frame(
      book_name = book_name,
      author = author,
      genre = genre,
      topic = topic,
      chapter = entry$chapter,
      section = entry$section,
      main_details = entry$main_details,
      formula = ifelse(is.null(entry$formula), "", entry$formula),
      formula_explanation = ifelse(is.null(entry$formula_explanation), "", entry$formula_explanation),
      reference_url = ifelse(is.null(entry$reference_url), "", entry$reference_url),
      reference_description = ifelse(is.null(entry$reference_description), "", entry$reference_description),
      numeric_data = ifelse(is.null(entry$numeric_data), "", entry$numeric_data),
      numeric_data_description = ifelse(is.null(entry$numeric_data_description), "", entry$numeric_data_description),
      stringsAsFactors = FALSE
    ))
  }
  
  return(parsed_df)
}

# Generate Claude prompt for book summary
generate_summary_prompt <- function(book_title, author, genre = "", topic = "") {
  
  genre_text <- if (nchar(genre) > 0) {
    paste0("[", genre, "]\n")
  } else {
    "[General]\n"
  }
  
  topic_text <- if (nchar(topic) > 0) {
    paste0("[", topic, "]\n")
  } else {
    "[General Topic]\n"
  }
  
  prompt <- paste0(
    'Generate a comprehensive summary of the book "', book_title, '" by ', author, ' following this EXACT format:

Format Requirements:
1. Start with book metadata in brackets (4 lines):
[Book Title]
[Author Name]
', genre_text, topic_text, '

2. For each chapter/section entry use this EXACT pattern with ALL fields:
[chapter]: Chapter XX: Chapter Title
[section]: All Sections (or specific section like "Section X.X")
[main_details]: Write 100-200 words summarizing the chapter/section content
[formula]: $$LaTeX mathematical expression$$ (use $...$ for inline, $$...$$ for display math)
[formula_explanation]: Clear explanation of what the formula represents and its significance in 1-2 sentences
[reference_url]: https://example.com/relevant-resource
[reference_description]: Brief description of what the URL contains
[numeric_data]: num1,num2,num3,num4,num5,num6
[numeric_data_description]: Explanation of what each number represents

3. CRITICAL CHAPTER NUMBERING:
   - For chapters 1-9: Use TWO digits with leading zero (Chapter 01, Chapter 02, ..., Chapter 09)
   - For chapters 10+: Use normal numbering (Chapter 10, Chapter 11, etc.)

4. MATHEMATICAL FORMULAS (LaTeX/MathJax format):
   - Use proper LaTeX syntax: $inline$ or $$display$$
   - Include formulas when relevant to chapter content
   - If no formula is relevant, use: [formula]: N/A and [formula_explanation]: No mathematical formula applicable to this chapter

5. REFERENCE URLS:
   - Provide actual, helpful URLs when possible
   - Use reputable sources: Khan Academy, Coursera, academic institutions, official docs
   - If you cannot provide a specific URL, suggest search terms

6. NUMERIC DATA (always 6 values, 0-100 range):
   - Suggested metrics: Difficulty, Importance, Prerequisites, Practical Application, Engagement, Success Rate
   - Always include the description field explaining what each value represents

7. FORMATTING RULES:
   - Separate each chapter entry with ONE blank line
   - NO extra markdown, NO headers with #, NO entry numbers
   - Use exact bracket format shown above

Now generate the complete summary for "', book_title, '" by ', author, ' with ALL required fields for each chapter/section.'
  )
  
  return(prompt)
}
