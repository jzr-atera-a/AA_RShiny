# R/utils_common.R
# Shared Utility Functions
# ========================

# Safe SQL escape for preventing injection
safe_sql_escape <- function(input_value) {
  gsub("'", "''", input_value)
}

# Returns TRUE if x is a "real" (non-blank, non-NA, non-"N/A") value. Used
# to decide whether to render formula/numeric_data content per row, and to
# decide whether a book-level visualization section (e.g. the Numeric Data
# Trends chart) should appear at all for a given book.
has_real_value <- function(x) {
  if (is.na(x)) return(FALSE)
  trimmed <- trimws(as.character(x))
  if (nchar(trimmed) == 0) return(FALSE)
  if (tolower(trimmed) %in% c("n/a", "na")) return(FALSE)
  TRUE
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
    
    if (is_metadata_line(line)) {
      metadata_count <- metadata_count + 1
      value <- extract_metadata_value(line)
      
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
generate_summary_prompt <- function(book_title, author, genre = "", topic = "", include_math = FALSE) {
  
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
  
  if (include_math) {
    fields_example <- '[formula]: $$LaTeX mathematical expression$$ (use $...$ for inline, $$...$$ for display math)
[formula_explanation]: Clear explanation of what the formula represents and its significance in 1-2 sentences
[reference_url]: https://example.com/relevant-resource
[reference_description]: Brief description of what the URL contains
[numeric_data]: num1,num2,num3,num4,num5,num6
[numeric_data_description]: Explanation of what each number represents'
    
    math_instructions <- '4. MATHEMATICAL FORMULAS (LaTeX/MathJax format):
   - Use proper LaTeX syntax: $inline$ or $$display$$
   - Include formulas when relevant to chapter content
   - If no formula is relevant, use: [formula]: N/A and [formula_explanation]: No mathematical formula applicable to this chapter

5. NUMERIC DATA (always 6 values, 0-100 range):
   - Suggested metrics: Difficulty, Importance, Prerequisites, Practical Application, Engagement, Success Rate
   - Always include the description field explaining what each value represents

6. REFERENCE URLS:
   - Provide actual, helpful URLs when possible
   - Use reputable sources: Khan Academy, Coursera, academic institutions, official docs
   - If you cannot provide a specific URL, suggest search terms'
  } else {
    fields_example <- '[formula]: N/A
[formula_explanation]: N/A
[reference_url]: https://example.com/relevant-resource
[reference_description]: Brief description of what the URL contains
[numeric_data]: N/A
[numeric_data_description]: N/A'
    
    math_instructions <- '4. DO NOT INCLUDE MATHEMATICAL FORMULAS OR NUMERIC METRICS:
   - This book/summary should not have invented formulas or numeric scores attached to it
   - Write exactly "N/A" for [formula], [formula_explanation], [numeric_data], and [numeric_data_description] on every single chapter entry
   - Do not invent a formula or numbers just to fill the field, and do not omit these bracket lines - include them with "N/A" as the value so the format stays consistent

5. REFERENCE URLS:
   - Provide actual, helpful URLs when possible
   - Use reputable sources: Khan Academy, Coursera, academic institutions, official docs
   - If you cannot provide a specific URL, suggest search terms'
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
', fields_example, '

3. CRITICAL CHAPTER NUMBERING:
   - For chapters 1-9: Use TWO digits with leading zero (Chapter 01, Chapter 02, ..., Chapter 09)
   - For chapters 10+: Use normal numbering (Chapter 10, Chapter 11, etc.)

', math_instructions, '

7. FORMATTING RULES:
   - Separate each chapter entry with ONE blank line
   - NO extra markdown, NO headers with #, NO entry numbers
   - Use exact bracket format shown above

Now generate the complete summary for "', book_title, '" by ', author, ' with ALL required fields for each chapter/section.'
  )
  
  return(prompt)
}

# When include_math is FALSE, force-blanks every chapter's [formula],
# [formula_explanation], [numeric_data], and [numeric_data_description]
# lines to "N/A" regardless of what Claude actually wrote there. Applied
# once right after generation (before the text is stored, displayed, or
# pushed to Bulk Import) so every downstream step - display, Bulk Import
# parsing, BigQuery upload - sees consistently blank fields with zero
# further changes needed anywhere else in the pipeline.
blank_math_fields <- function(text) {
  lines <- strsplit(text, "\n")[[1]]
  
  fields_to_blank <- c("formula", "formula_explanation",
                        "numeric_data", "numeric_data_description")
  
  for (field in fields_to_blank) {
    pattern <- paste0("^(\\s*\\[", field, "\\]\\s*:)\\s*.*$")
    matches <- grepl(pattern, lines, ignore.case = TRUE)
    lines[matches] <- sub(pattern, "\\1 N/A", lines[matches], ignore.case = TRUE)
  }
  
  paste(lines, collapse = "\n")
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

# Force-overwrites the entire metadata header (book title, author, genre,
# topic) of a Claude-generated summary with the exact known values,
# regardless of what Claude actually wrote there. Rather than trying to
# surgically patch individual lines - which breaks the moment Claude
# formats the header differently than expected (e.g. writing
# "[Book Title]: 48 Laws of Power" instead of "[48 Laws of Power]", which
# happens in practice despite instructions not to) - this finds the first
# "[chapter]:" line and replaces EVERYTHING before it with a clean,
# deterministic 4-line header built from values we already know are
# correct. This guarantees the header is always in the exact format
# parse_summary_text() expects, independent of how Claude chose to write it.
overwrite_metadata_header <- function(text, book_title, author, genre, topic) {
  lines <- strsplit(text, "\n")[[1]]
  
  chapter_line_idx <- which(grepl("^\\s*\\[chapter\\]:", lines, ignore.case = TRUE))[1]
  
  if (is.na(chapter_line_idx)) {
    # No chapter marker found at all - something is badly wrong with the
    # response (e.g. severe truncation before any chapter was written).
    # Return unchanged rather than risk destroying the only content present.
    return(text)
  }
  
  remaining_lines <- lines[chapter_line_idx:length(lines)]
  
  header <- c(
    paste0("[", book_title, "]"),
    paste0("[", author, "]"),
    paste0("[", genre, "]"),
    paste0("[", topic, "]"),
    ""
  )
  
  paste(c(header, remaining_lines), collapse = "\n")
}

# Lenient detection/extraction for metadata header lines, used as a
# fallback by parse_summary_text() for text that didn't go through
# overwrite_metadata_header() (e.g. summaries pasted directly into Bulk
# Import from elsewhere). Accepts both the intended pure "[Value]" format
# and the malformed "[Label]: Value" format Claude sometimes produces
# despite instructions, extracting the part after the colon when present.
is_metadata_line <- function(line) {
  trimmed <- trimws(line)
  grepl("^\\[", trimmed) && grepl("\\]", trimmed)
}

extract_metadata_value <- function(line) {
  trimmed <- trimws(line)
  
  open_pos <- regexpr("\\[", trimmed)[1]
  close_pos <- regexpr("\\]", trimmed)[1]
  
  if (open_pos == -1 || close_pos == -1 || close_pos <= open_pos) {
    return(trimmed)
  }
  
  inner <- substr(trimmed, open_pos + 1, close_pos - 1)
  after <- if (close_pos < nchar(trimmed)) substr(trimmed, close_pos + 1, nchar(trimmed)) else ""
  after <- trimws(sub("^:", "", trimws(after)))
  
  if (nchar(after) > 0) after else trimws(inner)
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
