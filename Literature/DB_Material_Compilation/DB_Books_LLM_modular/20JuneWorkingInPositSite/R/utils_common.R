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

# ============================================================
# GENRE / TOPIC HIERARCHICAL CLASSIFICATION
# ============================================================
# Topic is a sub-category of Genre. These sentinel values mark the
# "create a new one" option in the Genre/Topic dropdowns. They use a
# format ("__...__") that can't realistically collide with a real
# genre or topic name typed by a user.
GENRE_ADD_NEW_VALUE <- "__ADD_NEW_GENRE__"
TOPIC_ADD_NEW_VALUE <- "__ADD_NEW_TOPIC__"

# Force-overwrites the [Genre] and [Topic] bracketed metadata lines in a
# Claude-generated summary with the exact strings the user selected in the
# UI, regardless of what Claude actually wrote. This guarantees the saved
# data always matches the user's selection exactly (no paraphrasing,
# capitalization drift, etc. from the model).
#
# Expects the first ~15 lines to contain, in order: [Book Title],
# [Author Name], [Genre], [Topic] - matching the format
# generate_summary_prompt() instructs Claude to produce. If Claude omitted
# the genre/topic lines (or produced fewer than 4 bracketed lines), this
# inserts them in the correct position instead of failing.
overwrite_genre_topic_lines <- function(text, genre, topic) {
  lines <- strsplit(text, "\n")[[1]]
  
  bracket_idx <- c()
  for (i in seq_len(min(15, length(lines)))) {
    if (grepl("^\\[.+\\]$", trimws(lines[i]))) {
      bracket_idx <- c(bracket_idx, i)
    }
    if (length(bracket_idx) >= 4) break
  }
  
  # Need at least [Book Title] and [Author Name] to know where to anchor
  if (length(bracket_idx) < 2) {
    return(text)
  }
  
  author_line <- bracket_idx[2]
  
  if (length(bracket_idx) >= 3) {
    lines[bracket_idx[3]] <- paste0("[", genre, "]")
  } else {
    lines <- append(lines, paste0("[", genre, "]"), after = author_line)
    bracket_idx <- c(bracket_idx, author_line + 1)
  }
  
  genre_line <- bracket_idx[3]
  
  if (length(bracket_idx) >= 4) {
    lines[bracket_idx[4]] <- paste0("[", topic, "]")
  } else {
    lines <- append(lines, paste0("[", topic, "]"), after = genre_line)
  }
  
  paste(lines, collapse = "\n")
}

# Reusable UI block: a Genre dropdown (with "+ Add New Genre") and a Topic
# dropdown (with "+ Add New Topic"), each with a conditional text box that
# appears when "add new" is selected. Used by generate_summary and
# add_single. `ns` must be the calling module's own NS(id) function so the
# generated input IDs are correctly namespaced.
genre_topic_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("genre_select"), "Genre: *",
                choices = c("+ Add New Genre" = GENRE_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("genre_select"), GENRE_ADD_NEW_VALUE),
      textInput(ns("new_genre_text"), "New Genre Name:", placeholder = "e.g., Business")
    ),
    selectInput(ns("topic_select"), "Topic: *",
                choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("topic_select"), TOPIC_ADD_NEW_VALUE),
      textInput(ns("new_topic_text"), "New Topic Name:", placeholder = "e.g., Entrepreneurship")
    )
  )
}

# Wires up the reactive cascade for a Genre/Topic dropdown block created by
# genre_topic_dropdown_ui(). Call once inside a module's moduleServer(),
# passing that module's own input/output/session and the shared
# api_manager. Returns a reactive() yielding list(genre = ..., topic = ...)
# with the resolved final values (either the selected existing value, or
# the typed "new" value when "+ Add New..." is chosen).
setup_genre_topic_cascade <- function(input, output, session, api_manager) {
  
  taxonomy <- reactive({
    api_manager$state_trigger()
    if (!api_manager$bq_authenticated) {
      return(data.frame(genre = character(), topic = character(),
                         book_name = character(), author = character(),
                         stringsAsFactors = FALSE))
    }
    tryCatch(api_manager$bq_get_taxonomy(), error = function(e) {
      data.frame(genre = character(), topic = character(),
                 book_name = character(), author = character(),
                 stringsAsFactors = FALSE)
    })
  })
  
  # Populate/refresh the Genre dropdown whenever the taxonomy changes
  # (e.g. after a new upload elsewhere fires state_trigger). Preserves the
  # current selection if it's still valid.
  observeEvent(taxonomy(), {
    tax <- taxonomy()
    genres <- sort(unique(tax$genre[nchar(trimws(tax$genre)) > 0]))
    choices <- c("+ Add New Genre" = GENRE_ADD_NEW_VALUE, setNames(genres, genres))
    
    current <- isolate(input$genre_select)
    selected <- if (!is.null(current) && current %in% choices) current else GENRE_ADD_NEW_VALUE
    
    updateSelectInput(session, "genre_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)
  
  # Cascade: Topic choices depend on the selected Genre. A brand-new genre,
  # or an existing genre with no topics linked yet, only offers "+ Add New
  # Topic" - there is nothing else it could mean.
  observeEvent(input$genre_select, {
    tax <- taxonomy()
    
    if (is.null(input$genre_select) || input$genre_select == GENRE_ADD_NEW_VALUE) {
      updateSelectInput(session, "topic_select",
                         choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE))
      return()
    }
    
    topics <- sort(unique(tax$topic[tax$genre == input$genre_select & nchar(trimws(tax$topic)) > 0]))
    
    if (length(topics) == 0) {
      updateSelectInput(session, "topic_select",
                         choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE))
    } else {
      updateSelectInput(session, "topic_select",
                         choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE,
                                     setNames(topics, topics)))
    }
  }, ignoreInit = TRUE)
  
  # Resolved final genre/topic strings
  reactive({
    genre <- if (identical(input$genre_select, GENRE_ADD_NEW_VALUE)) {
      trimws(input$new_genre_text %||% "")
    } else {
      input$genre_select %||% ""
    }
    
    topic <- if (identical(input$topic_select, TOPIC_ADD_NEW_VALUE)) {
      trimws(input$new_topic_text %||% "")
    } else {
      input$topic_select %||% ""
    }
    
    list(genre = genre, topic = topic)
  })
}
