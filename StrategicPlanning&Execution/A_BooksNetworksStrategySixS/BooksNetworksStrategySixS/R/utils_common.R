# R/utils_common.R
# Shared Utility Functions - UNIFIED Book Summary + Flex Table + Mind
# Map + Knowledge Graph Suite
# =====================================================================
# This file merges the four sibling apps' utils_common.R files. Only
# genuinely IDENTICAL helpers are shared once (safe_sql_escape, %||%,
# the 3-level Category/Domain/Topic cascade - parametrized by method
# name since Mind Map and Knowledge Graph each have their own table).
# Everything else keeps its original per-app name, since the four
# data models (book summaries / flexible comparison tables / versioned
# trees / versioned entity-relationship graphs) are genuinely different
# and their parsers, validators, and prompt builders should not be
# conflated.

safe_sql_escape <- function(input_value) {
  gsub("'", "''", input_value)
}

# ====================================================================
# BOOK SUMMARY - core parsing/prompt/Genre-Topic cascade
# ====================================================================

# Returns TRUE if x is a "real" (non-blank, non-NA, non-"N/A") value. Used
# to decide whether to render formula/numeric_data content per row, and to
# decide whether a book-level visualization section (e.g. the Numeric Data
# Trends chart) should appear at all for a given book. Critical distinction
# from a plain blank/NA check: blank_math_fields() writes the literal
# string "N/A" (not an empty string) when math is excluded, so a check
# that only tests for "" would incorrectly treat "N/A" as real data.
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
# GENRE / TOPIC HIERARCHICAL CLASSIFICATION (Book Summary, 2-level)
# ============================================================
# Topic is a sub-category of Genre. Reuses the same TOPIC_ADD_NEW_VALUE
# sentinel defined once in the shared 3-level cascade section below
# (identical value, no need to redefine).
GENRE_ADD_NEW_VALUE <- "__ADD_NEW_GENRE__"

# Force-overwrites the ENTIRE metadata header (book title, author, genre,
# topic) of a Claude-generated summary with the exact known values,
# regardless of what Claude actually wrote there. Rather than trying to
# surgically patch individual lines - which breaks the moment Claude
# formats the header differently than expected (e.g. writing
# "[Book Title]: 48 Laws of Power" instead of "[48 Laws of Power]", which
# happens in practice despite instructions not to) - this finds the first
# "[chapter]:" line and replaces EVERYTHING before it with a clean,
# deterministic 4-line header built from values already known to be
# correct. This is the authoritative version (supersedes the narrower
# overwrite_genre_topic_lines() below, which only patched 2 of the 4
# header lines and could still leave a malformed title/author line).
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
#
# NOTE: overwrite_metadata_header() above is now used by generate_summary
# for the initial generation flow (more robust - rewrites all 4 header
# lines at once). This narrower function is kept for any other caller
# that only wants to patch genre/topic without touching title/author.
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
    api_manager$state_trigger_books()
    if (!api_manager$bq_authenticated) {
      return(api_manager$empty_books_taxonomy())
    }
    tryCatch(api_manager$bq_get_books_taxonomy(), error = function(e) {
      api_manager$empty_books_taxonomy()
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
  #
  # Uses observe() rather than observeEvent(input$genre_select, ...): the
  # latter isolates everything inside its handler body except the event
  # expression itself, so a read of taxonomy() inside it is NOT a real
  # dependency - meaning if a new topic is uploaded under a Genre string
  # that happens to already be selected, the Topic dropdown would never
  # refresh to show it, since the Genre value itself never changed.
  # observe() tracks every reactive read in its body, so it correctly
  # re-runs whenever EITHER the taxonomy changes OR the Genre selection
  # changes.
  observe({
    tax <- taxonomy()
    genre_val <- input$genre_select

    if (is.null(genre_val) || genre_val == GENRE_ADD_NEW_VALUE) {
      updateSelectInput(session, "topic_select",
                         choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE))
      return()
    }

    topics <- sort(unique(tax$topic[tax$genre == genre_val & nchar(trimws(tax$topic)) > 0]))
    choices <- c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE, if (length(topics) > 0) setNames(topics, topics) else NULL)

    current <- isolate(input$topic_select)
    selected <- if (!is.null(current) && current %in% choices) current else TOPIC_ADD_NEW_VALUE
    updateSelectInput(session, "topic_select", choices = choices, selected = selected)
  })
  
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

# ============================================================
# DELIMITER CONTRACT
# ============================================================
# These exact literal tokens are what separate one "column" from the
# next, and a column's header from its value, inside the single
# columns_data STRING field. They are deliberately long, punctuation-
# heavy, and namespaced so Claude is very unlikely to ever produce them
# by accident inside normal prose, numbers, or LaTeX. The generation
# prompt instructs Claude to use these EXACT tokens and nothing else.
COL_SEP <- "|||COL|||"   # separates one column entry from the next
KV_SEP  <- "|||KV|||"    # separates a column header from its value

# Build a single columns_data string from a named vector/list of
# header -> value pairs, e.g. build_columns_data(c("Model A" = "Fast but noisy", "Model B" = "Slow but stable"))
build_columns_data <- function(headers, values) {
  stopifnot(length(headers) == length(values))
  entries <- mapply(function(h, v) paste0(trimws(h), KV_SEP, trimws(v)),
                     headers, values, SIMPLIFY = TRUE)
  paste(entries, collapse = COL_SEP)
}

# Parse a columns_data string back into a data.frame(header, value)
parse_columns_data <- function(columns_data) {
  if (is.na(columns_data) || trimws(columns_data) == "") {
    return(data.frame(header = character(), value = character(), stringsAsFactors = FALSE))
  }

  entries <- strsplit(as.character(columns_data), COL_SEP, fixed = TRUE)[[1]]
  entries <- entries[trimws(entries) != ""]

  headers <- character(length(entries))
  values <- character(length(entries))

  for (i in seq_along(entries)) {
    parts <- strsplit(entries[i], KV_SEP, fixed = TRUE)[[1]]
    headers[i] <- trimws(parts[1])
    values[i] <- if (length(parts) >= 2) trimws(paste(parts[-1], collapse = KV_SEP)) else ""
  }

  data.frame(header = headers, value = values, stringsAsFactors = FALSE)
}

# ============================================================
# PARSE CLAUDE-GENERATED TABLE TEXT
# ============================================================
# Expected format (see generate_table_prompt() below for the exact
# instructions sent to Claude):
#
# [Category]
# [Topic]
# [Table Title]
# [Row Dimension Label]
# [Column Dimension Label]
#
# [row_index]: Equities
# [columns_data]: Header1|||KV|||Value1|||COL|||Header2|||KV|||Value2
# [notes]: optional free-text note about this row
#
# [row_index]: Fixed Income
# [columns_data]: ...
# [notes]: ...
parse_table_text <- function(text) {

  lines <- strsplit(text, "\n")[[1]]

  category <- NULL; topic <- NULL; table_title <- NULL
  row_dimension_label <- NULL; column_dimension_label <- NULL

  metadata_count <- 0
  for (i in seq_len(min(20, length(lines)))) {
    line <- trimws(lines[i])
    if (grepl("^\\[.+\\]$", line)) {
      metadata_count <- metadata_count + 1
      value <- gsub("^\\[|\\]$", "", line)

      if (metadata_count == 1) category <- value
      else if (metadata_count == 2) topic <- value
      else if (metadata_count == 3) table_title <- value
      else if (metadata_count == 4) row_dimension_label <- value
      else if (metadata_count == 5) column_dimension_label <- value
      else break
    }
  }

  if (is.null(category) || is.null(topic)) {
    stop("Could not find Category and Topic metadata in generated table text")
  }
  if (is.null(table_title)) table_title <- topic
  if (is.null(row_dimension_label)) row_dimension_label <- "Row"
  if (is.null(column_dimension_label)) column_dimension_label <- "Column"

  # Parse row entries
  entries <- list()
  current_entry <- list()

  flush_entry <- function() {
    if (!is.null(current_entry$row_index)) {
      entries[[length(entries) + 1]] <<- current_entry
    }
    current_entry <<- list()
  }

  for (line in lines) {
    trimmed <- trimws(line)

    if (trimmed == "" || grepl("^\\[.+\\]$", trimmed)) {
      flush_entry()
      next
    }

    if (grepl("^\\[row_index\\]:", trimmed, ignore.case = TRUE)) {
      flush_entry()
      current_entry$row_index <- trimws(sub("^\\[row_index\\]:\\s*", "", trimmed, ignore.case = TRUE))
    }
    else if (grepl("^\\[columns_data\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$columns_data <- trimws(sub("^\\[columns_data\\]:\\s*", "", trimmed, ignore.case = TRUE))
    }
    else if (grepl("^\\[notes\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$notes <- trimws(sub("^\\[notes\\]:\\s*", "", trimmed, ignore.case = TRUE))
    }
    else if (!is.null(current_entry$columns_data)) {
      # Claude sometimes wraps a long columns_data value across lines;
      # re-attach continuation lines that aren't a new [tag]: line.
      current_entry$columns_data <- paste0(current_entry$columns_data, " ", trimmed)
    }
  }
  flush_entry()

  if (length(entries) == 0) {
    stop("No valid [row_index] entries found in generated table text")
  }

  parsed_df <- data.frame(
    category = character(), topic = character(), table_title = character(),
    row_dimension_label = character(), column_dimension_label = character(),
    row_index = character(), columns_data = character(), notes = character(),
    stringsAsFactors = FALSE
  )

  for (entry in entries) {
    parsed_df <- rbind(parsed_df, data.frame(
      category = category,
      topic = topic,
      table_title = table_title,
      row_dimension_label = row_dimension_label,
      column_dimension_label = column_dimension_label,
      row_index = entry$row_index,
      columns_data = ifelse(is.null(entry$columns_data), "", entry$columns_data),
      notes = ifelse(is.null(entry$notes), "", entry$notes),
      stringsAsFactors = FALSE
    ))
  }

  return(parsed_df)
}

# ============================================================
# GENERATE CLAUDE PROMPT FOR A COMPARISON TABLE
# ============================================================
generate_table_prompt <- function(category, topic, table_title,
                                   row_dimension_label, column_dimension_label,
                                   request_description,
                                   include_latex = FALSE,
                                   words_per_cell = 40,
                                   expected_rows = NULL,
                                   expected_columns = NULL) {

  size_guidance <- if (!is.null(expected_rows) && !is.null(expected_columns)) {
    paste0(
      'As a rough target, aim for around ', expected_rows, ' rows and ', expected_columns,
      ' columns - UNLESS the user request below clearly implies a different exact count ',
      '(e.g. "top 5"), in which case follow the user request instead.\n\n'
    )
  } else {
    ""
  }

  latex_instruction <- if (isTRUE(include_latex)) {
    paste0(
      '4. MATHEMATICAL / QUANTITATIVE CONTENT (LaTeX/MathJax):\n',
      '   - Where a formula, metric definition, or equation is genuinely relevant inside a column VALUE, include it using LaTeX syntax: $inline$ or $$display$$.\n',
      '   - Do not force LaTeX where it is not relevant - plain text is fine otherwise.\n\n'
    )
  } else {
    paste0(
      '4. NO LATEX:\n',
      '   - Do NOT use any LaTeX syntax anywhere in your response (no $...$, no $$...$$, no \\frac, \\sum, etc).\n',
      '   - Express any formulas, metrics, or equations in plain text instead (e.g. "annualized return = (ending value / starting value) - 1").\n\n'
    )
  }

  prompt <- paste0(
    'You are generating data for a comparison table in a web app. ',
    'The table has ROWS representing "', row_dimension_label, '" and ',
    'COLUMNS representing "', column_dimension_label, '". ',
    'The number of columns is NOT fixed - decide the right number of "',
    column_dimension_label, '" entries yourself based on what is genuinely relevant.\n\n',

    size_guidance,

    'User request: ', request_description, '\n\n',

    'Format Requirements - follow this EXACTLY:\n\n',
    '1. Start with 5 metadata lines, each on its own line, wrapped in single square brackets:\n',
    '[', category, ']\n',
    '[', topic, ']\n',
    '[', table_title, ']\n',
    '[', row_dimension_label, ']\n',
    '[', column_dimension_label, ']\n\n',

    '2. Then, for EACH row (each "', row_dimension_label, '"), output a block with EXACTLY these 3 tagged lines, separated from the next block by ONE blank line:\n\n',
    '[row_index]: <the specific row label, e.g. one specific ', row_dimension_label, '>\n',
    '[columns_data]: <Header1>', KV_SEP, '<Value1>', COL_SEP, '<Header2>', KV_SEP, '<Value2>', COL_SEP, '<Header3>', KV_SEP, '<Value3> ... (continue for every column you decide is relevant)\n',
    '[notes]: <optional one-sentence note about this row as a whole, or leave blank>\n\n',

    '3. CRITICAL DELIMITER RULES (this is machine-parsed, follow precisely):\n',
    '   - Use the EXACT literal token "', COL_SEP, '" to separate one column entry from the next inside [columns_data].\n',
    '   - Use the EXACT literal token "', KV_SEP, '" to separate a column HEADER from its VALUE inside each column entry.\n',
    '   - NEVER use "', COL_SEP, '" or "', KV_SEP, '" anywhere else in your response (not in headers, values, notes, or metadata).\n',
    '   - Each column HEADER should be short (a few words) - it is the "', column_dimension_label, '" name for that column.\n',
    '   - Each column VALUE must be no more than approximately ', words_per_cell, ' words - concise, dense, no filler, specific to that row/column intersection.\n',
    '   - Keep the same set of column headers consistent across every [row_index] block, in the same order, so the table aligns correctly.\n\n',

    latex_instruction,

    '5. FORMATTING RULES:\n',
    '   - NO extra markdown, NO headers with #, NO numbered list markers, NO tables in markdown syntax.\n',
    '   - Separate each [row_index] block with exactly ONE blank line.\n',
    '   - Use the exact bracket tag format shown above ([row_index]:, [columns_data]:, [notes]:).\n\n',

    'Now generate the complete table for: "', table_title, '" (Category: ', category, ', Topic: ', topic,
    '), with rows = ', row_dimension_label, ' and columns = ', column_dimension_label, '.'
  )

  return(prompt)
}

# ============================================================
# TOKEN BUDGET ESTIMATION
# ============================================================
# Converts the user's row/column/word-per-cell expectations into a
# max_tokens value to pass to call_claude() for this specific
# generation. Deliberately generous (rounds up, adds overhead) since
# under-budgeting truncates the response mid-table, which is far worse
# than a slightly larger request.
estimate_max_tokens <- function(expected_rows, expected_columns, words_per_cell,
                                 include_latex = FALSE) {
  expected_rows <- max(1, as.numeric(expected_rows))
  expected_columns <- max(1, as.numeric(expected_columns))
  words_per_cell <- max(1, as.numeric(words_per_cell))

  cell_words <- expected_rows * expected_columns * words_per_cell

  # LaTeX syntax ($...$, \frac{}{}, etc.) is token-dense relative to
  # plain prose, so pad the budget when it's enabled.
  latex_factor <- if (isTRUE(include_latex)) 1.35 else 1.0

  # Per-row overhead: [row_index] label, [notes] line, the two
  # delimiter tokens per column, and column HEADER words (not counted
  # in cell_words above, which only covers VALUE text).
  per_row_overhead_words <- 15 + (expected_columns * 6)

  total_words <- (cell_words * latex_factor) + (expected_rows * per_row_overhead_words) + 60

  # ~1.5 tokens per English word is a safe (slightly generous) ratio for
  # this kind of dense, technical, sometimes-LaTeX prose.
  estimated_tokens <- ceiling(total_words * 1.5)

  # Clamp to sane bounds - never so small the response is guaranteed to
  # truncate, never absurdly large.
  max(1500, min(estimated_tokens, 64000))
}

# ============================================================
# CATEGORY / TOPIC HIERARCHICAL CLASSIFICATION (Flex Table, 2-level)
# ============================================================
# Topic is a sub-category of Category (e.g. Category = "Finance",
# Topic = "ML Models for Asset Class Price Forecasting"). Uses the
# same CATEGORY_ADD_NEW_VALUE/TOPIC_ADD_NEW_VALUE sentinels defined
# once below in the shared 3-level cascade section (identical values,
# no need to redefine here).

# Reusable UI block: a Category dropdown (with "+ Add New Category") and
# a Topic dropdown (with "+ Add New Topic"), each with a conditional text
# box that appears when "add new" is selected. `ns` must be the calling
# module's own NS(id) function.
category_topic_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("category_select"), "Category: *",
                choices = c("+ Add New Category" = CATEGORY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("category_select"), CATEGORY_ADD_NEW_VALUE),
      textInput(ns("new_category_text"), "New Category Name:", placeholder = "e.g., Finance")
    ),
    selectInput(ns("topic_select"), "Topic: *",
                choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("topic_select"), TOPIC_ADD_NEW_VALUE),
      textInput(ns("new_topic_text"), "New Topic Name:", placeholder = "e.g., ML Models for Price Forecasting")
    )
  )
}

# Wires up the reactive cascade for a Category/Topic dropdown block
# created by category_topic_dropdown_ui(). Returns a reactive() yielding
# list(category = ..., topic = ...) with the resolved final values.
setup_category_topic_cascade <- function(input, output, session, api_manager) {

  taxonomy <- reactive({
    api_manager$state_trigger_flex()
    if (!api_manager$bq_authenticated) {
      return(api_manager$empty_flex_taxonomy())
    }
    tryCatch(api_manager$bq_get_flex_taxonomy(), error = function(e) {
      api_manager$empty_flex_taxonomy()
    })
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    categories <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
    choices <- c("+ Add New Category" = CATEGORY_ADD_NEW_VALUE, setNames(categories, categories))

    current <- isolate(input$category_select)
    selected <- if (!is.null(current) && current %in% choices) current else CATEGORY_ADD_NEW_VALUE

    updateSelectInput(session, "category_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  observe({
    tax <- taxonomy()
    cat_val <- input$category_select

    if (is.null(cat_val) || cat_val == CATEGORY_ADD_NEW_VALUE) {
      updateSelectInput(session, "topic_select",
                         choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE))
      return()
    }

    topics <- sort(unique(tax$topic[tax$category == cat_val & nchar(trimws(tax$topic)) > 0]))
    choices <- c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE, if (length(topics) > 0) setNames(topics, topics) else NULL)

    current <- isolate(input$topic_select)
    selected <- if (!is.null(current) && current %in% choices) current else TOPIC_ADD_NEW_VALUE
    updateSelectInput(session, "topic_select", choices = choices, selected = selected)
  })

  reactive({
    category <- if (identical(input$category_select, CATEGORY_ADD_NEW_VALUE)) {
      trimws(input$new_category_text %||% "")
    } else {
      input$category_select %||% ""
    }

    topic <- if (identical(input$topic_select, TOPIC_ADD_NEW_VALUE)) {
      trimws(input$new_topic_text %||% "")
    } else {
      input$topic_select %||% ""
    }

    list(category = category, topic = topic)
  })
}

# ============================================================
# CATEGORY / DOMAIN / TOPIC HIERARCHICAL CLASSIFICATION
# ============================================================
# Shared by BOTH Mind Map's and Knowledge Graph's "Generate" tabs (the
# only two callers - Edit/Visualize tabs in each app use existing-only
# dropdowns plus a 4th "version" selector, written inline in their own
# server.R rather than through this shared "add new" helper). Since
# Mind Map and Knowledge Graph each have their OWN BigQuery table and
# their own APIManager methods (bq_get_mindmap_taxonomy vs
# bq_get_kg_taxonomy), this function is parametrized by METHOD NAME
# (a string, dispatched via api_manager[[...]]()) rather than being
# duplicated per app.
CATEGORY_ADD_NEW_VALUE <- "__ADD_NEW_CATEGORY__"
DOMAIN_ADD_NEW_VALUE <- "__ADD_NEW_DOMAIN__"
TOPIC_ADD_NEW_VALUE <- "__ADD_NEW_TOPIC__"

category_domain_topic_dropdown_ui <- function(ns) {
  tagList(
    fluidRow(
      column(6,
        selectInput(ns("category_select"), "Category: *",
                    choices = c("+ Add New Category" = CATEGORY_ADD_NEW_VALUE)),
        conditionalPanel(
          condition = sprintf("input['%s'] == '%s'", ns("category_select"), CATEGORY_ADD_NEW_VALUE),
          textInput(ns("new_category_text"), "New Category Name:", placeholder = "e.g., Science")
        )
      ),
      column(6,
        selectInput(ns("domain_select"), "Domain: *",
                    choices = c("+ Add New Domain" = DOMAIN_ADD_NEW_VALUE)),
        conditionalPanel(
          condition = sprintf("input['%s'] == '%s'", ns("domain_select"), DOMAIN_ADD_NEW_VALUE),
          textInput(ns("new_domain_text"), "New Domain Name:", placeholder = "e.g., Biology")
        )
      )
    ),
    fluidRow(
      column(6,
        selectInput(ns("topic_select"), "Topic: *",
                    choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE)),
        conditionalPanel(
          condition = sprintf("input['%s'] == '%s'", ns("topic_select"), TOPIC_ADD_NEW_VALUE),
          textInput(ns("new_topic_text"), "New Topic Name:", placeholder = "e.g., Cell Structure")
        )
      )
    )
  )
}

# Wires up the reactive 3-level cascade. `taxonomy_method` and
# `empty_taxonomy_method` are STRING method names on api_manager (e.g.
# "bq_get_mindmap_taxonomy" / "empty_mindmap_taxonomy", or
# "bq_get_kg_taxonomy" / "empty_kg_taxonomy"), dispatched dynamically
# via api_manager[[...]](), so this one function correctly serves
# whichever sub-app's Generate tab calls it. `state_trigger_field` is
# likewise a STRING field name ("state_trigger_mindmap" or
# "state_trigger_kg") so this listens to only its OWN sub-app's scoped
# trigger, not the other one - an update in Knowledge Graph should
# never cause Mind Map's taxonomy dropdowns to needlessly re-query.
# Returns reactive() -> list(category=, domain=, topic=) with resolved
# final values.
setup_category_domain_topic_cascade <- function(input, output, session, api_manager,
                                                  taxonomy_method, empty_taxonomy_method,
                                                  state_trigger_field) {

  taxonomy <- reactive({
    api_manager[[state_trigger_field]]()
    if (!api_manager$bq_authenticated) return(api_manager[[empty_taxonomy_method]]())
    tryCatch(api_manager[[taxonomy_method]](), error = function(e) api_manager[[empty_taxonomy_method]]())
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    categories <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
    choices <- c("+ Add New Category" = CATEGORY_ADD_NEW_VALUE, setNames(categories, categories))

    current <- isolate(input$category_select)
    selected <- if (!is.null(current) && current %in% choices) current else CATEGORY_ADD_NEW_VALUE

    updateSelectInput(session, "category_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  observe({
    tax <- taxonomy()
    cat_val <- input$category_select

    if (is.null(cat_val) || cat_val == CATEGORY_ADD_NEW_VALUE) {
      updateSelectInput(session, "domain_select", choices = c("+ Add New Domain" = DOMAIN_ADD_NEW_VALUE))
      return()
    }

    domains <- sort(unique(tax$domain[tax$category == cat_val & nchar(trimws(tax$domain)) > 0]))
    choices <- c("+ Add New Domain" = DOMAIN_ADD_NEW_VALUE, if (length(domains) > 0) setNames(domains, domains) else NULL)

    current <- isolate(input$domain_select)
    selected <- if (!is.null(current) && current %in% choices) current else DOMAIN_ADD_NEW_VALUE
    updateSelectInput(session, "domain_select", choices = choices, selected = selected)
  })

  observe({
    tax <- taxonomy()
    cat_val <- input$category_select
    dom_val <- input$domain_select

    if (is.null(cat_val) || cat_val == CATEGORY_ADD_NEW_VALUE ||
        is.null(dom_val) || dom_val == DOMAIN_ADD_NEW_VALUE) {
      updateSelectInput(session, "topic_select", choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE))
      return()
    }

    topics <- sort(unique(tax$topic[tax$category == cat_val &
                                     tax$domain == dom_val &
                                     nchar(trimws(tax$topic)) > 0]))
    choices <- c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE, if (length(topics) > 0) setNames(topics, topics) else NULL)

    current <- isolate(input$topic_select)
    selected <- if (!is.null(current) && current %in% choices) current else TOPIC_ADD_NEW_VALUE
    updateSelectInput(session, "topic_select", choices = choices, selected = selected)
  })

  reactive({
    category <- if (identical(input$category_select, CATEGORY_ADD_NEW_VALUE)) {
      trimws(input$new_category_text %||% "")
    } else {
      input$category_select %||% ""
    }

    domain <- if (identical(input$domain_select, DOMAIN_ADD_NEW_VALUE)) {
      trimws(input$new_domain_text %||% "")
    } else {
      input$domain_select %||% ""
    }

    topic <- if (identical(input$topic_select, TOPIC_ADD_NEW_VALUE)) {
      trimws(input$new_topic_text %||% "")
    } else {
      input$topic_select %||% ""
    }

    list(category = category, domain = domain, topic = topic)
  })
}


# ====================================================================
# MIND MAP - core parsing/validation/D3-data-prep
# ====================================================================
# ============================================================
# DELIMITER CONTRACT (cross_links field)
# ============================================================
# Same convention as the Flexible Comparison Table Suite's
# columns_data field: literal tokens Claude is instructed never to use
# elsewhere. One cross_links string can hold multiple links.
CROSS_LINK_SEP <- "|||COL|||"   # separates one cross-link entry from the next
CROSS_LINK_KV_SEP <- "|||KV|||" # separates a target node_id from its relationship label

ROOT_MARKER <- "ROOT"  # literal parent_id value for the single root node

# Generates a unique map_id for a NEW mind map (assigned by the app, not
# by Claude, so uniqueness is guaranteed regardless of what Claude returns).
generate_new_map_id <- function(topic) {
  slug <- tolower(gsub("[^a-zA-Z0-9]+", "-", trimws(topic)))
  slug <- gsub("^-+|-+$", "", slug)
  if (nchar(slug) == 0) slug <- "map"
  if (nchar(slug) > 40) slug <- substr(slug, 1, 40)
  paste0(slug, "-", format(Sys.time(), "%Y%m%d%H%M%S"))
}

build_cross_links <- function(target_ids, labels) {
  if (length(target_ids) == 0) return("")
  stopifnot(length(target_ids) == length(labels))
  entries <- mapply(function(t, l) paste0(trimws(t), CROSS_LINK_KV_SEP, trimws(l)),
                     target_ids, labels, SIMPLIFY = TRUE)
  paste(entries, collapse = CROSS_LINK_SEP)
}

parse_cross_links <- function(cross_links_text) {
  if (is.na(cross_links_text) || trimws(cross_links_text) == "" ||
      grepl("^\\(?none\\)?$", trimws(cross_links_text), ignore.case = TRUE)) {
    return(data.frame(target_node_id = character(), relationship_label = character(),
                       stringsAsFactors = FALSE))
  }

  raw <- as.character(cross_links_text)

  # Split into individual link entries using a LOOKAHEAD for the start of
  # the next entry, rather than requiring the exact literal COL_SEP
  # token. Node ids in this app are always "N" + digits, immediately
  # followed by the KV separator - so "N<digits>|||KV|||" is an
  # unambiguous marker for "a new link starts here", regardless of how
  # many pipe characters happen to precede it. This robustly handles
  # BOTH the well-formed case (a full |||COL||| precedes it) AND a
  # Claude slip observed in practice where only a bare "|||" was written
  # between two links instead of the full |||COL||| token - both leave
  # that same "N<digits>|||KV|||" marker right after the split point.
  entries <- strsplit(raw, "\\|+(?=N[0-9]+\\|\\|\\|KV\\|\\|\\|)", perl = TRUE)[[1]]
  entries <- trimws(entries)
  entries <- entries[entries != ""]
  # A well-formed |||COL||| leaves a trailing "COL" fragment stuck to
  # the end of the PRECEDING entry once the split above consumes the
  # pipes around it - strip that leftover fragment.
  entries <- sub("\\|\\|\\|COL$", "", entries)

  targets <- character(length(entries))
  labels <- character(length(entries))

  for (i in seq_along(entries)) {
    parts <- strsplit(entries[i], CROSS_LINK_KV_SEP, fixed = TRUE)[[1]]
    targets[i] <- trimws(parts[1])
    labels[i] <- if (length(parts) >= 2) trimws(paste(parts[-1], collapse = CROSS_LINK_KV_SEP)) else "related to"
  }

  data.frame(target_node_id = targets, relationship_label = labels, stringsAsFactors = FALSE)
}

# Detects the specific malformed pattern above (2+ links present but no
# full |||COL||| token anywhere) purely for a transparency WARNING -
# parse_cross_links() already repairs it via the lookahead split, so
# this never blocks anything, it just tells the user a shorthand was
# auto-corrected so they can eyeball the result rather than trust it blindly.
cross_links_used_shorthand_separator <- function(cross_links_text) {
  if (is.na(cross_links_text) || trimws(cross_links_text) == "") return(FALSE)
  raw <- as.character(cross_links_text)
  kv_matches <- gregexpr(CROSS_LINK_KV_SEP, raw, fixed = TRUE)[[1]]
  kv_count <- if (kv_matches[1] == -1) 0 else length(kv_matches)
  kv_count >= 2 && !grepl(CROSS_LINK_SEP, raw, fixed = TRUE)
}

# ============================================================
# PARSE CLAUDE'S INITIAL FULL-TREE GENERATION
# ============================================================
# Expected format:
#
# [Category]
# [Domain]
# [Topic]
# [Map Title]
#
# [node_id]: N1
# [label]: <short title>
# [content]: <summary text>
# [parent_id]: ROOT
# [cross_links]: (none)
#
# [node_id]: N2
# [label]: ...
# [content]: ...
# [parent_id]: N1
# [cross_links]: N5|||KV|||shares energy pathway with
parse_mindmap_creation_text <- function(text) {

  lines <- strsplit(text, "\n")[[1]]

  # Accepts EITHER of two metadata-line formats, since Claude's exact
  # phrasing of "wrap the value in brackets" has been observed to drift:
  #   Format A (intended): [AI]                    - bare value only
  #   Format B (also seen): [Category]: AI          - labeled, colon-separated
  # Format B is detected first (more specific pattern) so it isn't
  # accidentally swallowed by Format A's broader match.
  labeled_metadata_re <- "^\\[(Category|Domain|Topic|Map Title)\\]:\\s*(.*)$"
  bare_metadata_re <- "^\\[.+\\]$"

  category <- NULL; domain <- NULL; topic <- NULL; map_title <- NULL
  metadata_count <- 0
  for (i in seq_len(min(20, length(lines)))) {
    line <- trimws(lines[i])

    value <- NULL
    if (grepl(labeled_metadata_re, line, ignore.case = TRUE)) {
      value <- trimws(sub(labeled_metadata_re, "\\2", line, ignore.case = TRUE))
    } else if (grepl(bare_metadata_re, line)) {
      value <- gsub("^\\[|\\]$", "", line)
    }

    if (!is.null(value)) {
      metadata_count <- metadata_count + 1
      if (metadata_count == 1) category <- value
      else if (metadata_count == 2) domain <- value
      else if (metadata_count == 3) topic <- value
      else if (metadata_count == 4) map_title <- value
      else break
    }
  }

  if (is.null(category) || is.null(domain) || is.null(topic)) {
    stop("Could not find Category, Domain, and Topic metadata in generated mind map text")
  }
  if (is.null(map_title)) map_title <- topic

  entries <- list()
  current_entry <- list()

  flush_entry <- function() {
    if (!is.null(current_entry$node_id)) {
      entries[[length(entries) + 1]] <<- current_entry
    }
    current_entry <<- list()
  }

  for (line in lines) {
    trimmed <- trimws(line)

    if (trimmed == "" || grepl("^\\[.+\\]$", trimmed)) {
      flush_entry()
      next
    }

    if (grepl("^\\[node_id\\]:", trimmed, ignore.case = TRUE)) {
      flush_entry()
      current_entry$node_id <- trimws(sub("^\\[node_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[label\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$node_label <- trimws(sub("^\\[label\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[content\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$node_content <- trimws(sub("^\\[content\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[parent_id\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$parent_node_id <- trimws(sub("^\\[parent_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[cross_links\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$cross_links <- trimws(sub("^\\[cross_links\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (!is.null(current_entry$node_content)) {
      current_entry$node_content <- paste0(current_entry$node_content, " ", trimmed)
    }
  }
  flush_entry()

  if (length(entries) == 0) {
    stop("No valid [node_id] entries found in generated mind map text")
  }

  nodes_df <- data.frame(
    node_id = character(), node_label = character(), node_content = character(),
    parent_node_id = character(), cross_links = character(), sort_order = integer(),
    stringsAsFactors = FALSE
  )

  # If the response was cut off by the API's token limit mid-generation,
  # it typically stops mid-way through the LAST node - most often right
  # before or during its [parent_id] line. Previously this silently
  # defaulted the missing parent_id to ROOT_MARKER, which turned a
  # truncated response into a confusing "2 nodes claim ROOT" validation
  # error instead of a clear "response was cut off" message. Now:
  #   - if it's the LAST entry and [parent_id] never appeared at all,
  #     treat it as truncation: drop the incomplete node and report it.
  #   - if any OTHER (non-last) entry is missing [parent_id], that's a
  #     genuine formatting problem, not truncation - leave its
  #     parent_node_id unresolvable ("") so validate_tree_structure()'s
  #     existing "parent_id references a node that doesn't exist" check
  #     catches it with an accurate message, instead of guessing ROOT.
  truncated_node_id <- NULL

  for (i in seq_along(entries)) {
    e <- entries[[i]]
    is_last_entry <- (i == length(entries))

    if (is.null(e$parent_node_id)) {
      if (is_last_entry) {
        truncated_node_id <- e$node_id
        next
      }
      parent_id <- ""  # genuinely malformed - let validation report it clearly
    } else {
      parent_id <- e$parent_node_id
      if (toupper(trimws(parent_id)) %in% c("", "(ROOT)", "NONE", "NA")) parent_id <- ROOT_MARKER
    }

    nodes_df <- rbind(nodes_df, data.frame(
      node_id = e$node_id,
      node_label = ifelse(is.null(e$node_label), e$node_id, e$node_label),
      node_content = ifelse(is.null(e$node_content), "", e$node_content),
      parent_node_id = parent_id,
      cross_links = ifelse(is.null(e$cross_links), "", e$cross_links),
      sort_order = i,
      stringsAsFactors = FALSE
    ))
  }

  list(category = category, domain = domain, topic = topic, map_title = map_title,
       nodes = nodes_df, truncated_node_id = truncated_node_id)
}

# ============================================================
# PARSE CLAUDE'S EDIT DELTA
# ============================================================
# Expected format - ONLY the changed nodes, one block per change:
#
# [change]: CREATE
# [node_id]: N15
# [label]: ...
# [content]: ...
# [parent_id]: N3
# [cross_links]: ...
#
# [change]: UPDATE
# [node_id]: N2
# [label]: ...
# [content]: ...
# [parent_id]: N1
# [cross_links]: ...
#
# [change]: DELETE
# [node_id]: N7
parse_mindmap_delta_text <- function(text) {
  lines <- strsplit(text, "\n")[[1]]

  entries <- list()
  current_entry <- list()

  flush_entry <- function() {
    if (!is.null(current_entry$change_type) && !is.null(current_entry$node_id)) {
      entries[[length(entries) + 1]] <<- current_entry
    }
    current_entry <<- list()
  }

  for (line in lines) {
    trimmed <- trimws(line)

    if (trimmed == "") {
      next
    }

    if (grepl("^\\[change\\]:", trimmed, ignore.case = TRUE)) {
      flush_entry()
      current_entry$change_type <- toupper(trimws(sub("^\\[change\\]:\\s*", "", trimmed, ignore.case = TRUE)))
    } else if (grepl("^\\[node_id\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$node_id <- trimws(sub("^\\[node_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[label\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$node_label <- trimws(sub("^\\[label\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[content\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$node_content <- trimws(sub("^\\[content\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[parent_id\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$parent_node_id <- trimws(sub("^\\[parent_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[cross_links\\]:", trimmed, ignore.case = TRUE)) {
      current_entry$cross_links <- trimws(sub("^\\[cross_links\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (!is.null(current_entry$node_content)) {
      current_entry$node_content <- paste0(current_entry$node_content, " ", trimmed)
    }
  }
  flush_entry()

  if (length(entries) == 0) {
    stop("No valid [change]/[node_id] entries found in the edit response")
  }

  delta_df <- data.frame(
    change_type = character(), node_id = character(), node_label = character(),
    node_content = character(), parent_node_id = character(), cross_links = character(),
    stringsAsFactors = FALSE
  )

  for (e in entries) {
    if (!e$change_type %in% c("CREATE", "UPDATE", "DELETE")) {
      stop(sprintf("Unknown [change] type '%s' for node_id '%s' - expected CREATE, UPDATE, or DELETE",
                   e$change_type, e$node_id))
    }

    delta_df <- rbind(delta_df, data.frame(
      change_type = tolower(e$change_type),
      node_id = e$node_id,
      node_label = ifelse(is.null(e$node_label), NA, e$node_label),
      node_content = ifelse(is.null(e$node_content), NA, e$node_content),
      parent_node_id = ifelse(is.null(e$parent_node_id), NA, e$parent_node_id),
      cross_links = ifelse(is.null(e$cross_links), "", e$cross_links),
      stringsAsFactors = FALSE
    ))
  }

  delta_df
}

# ============================================================
# TREE STRUCTURE HELPERS
# ============================================================

# Computes depth (root = 0) for every node by walking parent_node_id
# chains. Guards against accidental cycles (shouldn't happen given the
# generation contract, but a broken edit could theoretically introduce
# one) with an iteration cap, flagging affected nodes rather than
# infinite-looping.
compute_node_levels <- function(nodes_df) {
  nodes_df$level <- NA_integer_
  root_idx <- which(nodes_df$parent_node_id == ROOT_MARKER | trimws(nodes_df$parent_node_id) == "")
  nodes_df$level[root_idx] <- 0

  max_iterations <- nrow(nodes_df) + 2
  for (iter in seq_len(max_iterations)) {
    unresolved <- which(is.na(nodes_df$level))
    if (length(unresolved) == 0) break

    changed <- FALSE
    for (i in unresolved) {
      parent_idx <- which(nodes_df$node_id == nodes_df$parent_node_id[i])
      if (length(parent_idx) == 1 && !is.na(nodes_df$level[parent_idx])) {
        nodes_df$level[i] <- nodes_df$level[parent_idx] + 1
        changed <- TRUE
      }
    }
    if (!changed) break  # remaining unresolved nodes have a broken/cyclic parent chain
  }

  # Any node whose level never resolved has an invalid parent reference
  # (points to a non-existent node_id, or is part of a cycle) - treat as
  # a second-class root so it still renders instead of vanishing.
  nodes_df$level[is.na(nodes_df$level)] <- 0
  nodes_df
}

# Validates a freshly parsed tree BEFORE upload, catching malformed
# Claude output early with a clear error instead of silently corrupting
# the stored map. Returns TWO separate lists:
#   - issues:   structural problems that BLOCK the upload (bad root,
#               duplicate node_id, a parent_id pointing nowhere - any of
#               these would corrupt the tree itself)
#   - warnings: non-structural problems that do NOT block the upload,
#               currently just a cross_links target that doesn't exist.
#               A dangling cross-link doesn't corrupt the tree - the
#               renderer already silently skips it - but the user should
#               still be told, rather than it fail invisibly.
validate_tree_structure <- function(nodes_df, max_root_children = NULL, max_children_per_node = NULL) {
  issues <- c()
  warnings <- c()

  if (sum(nodes_df$parent_node_id == ROOT_MARKER) == 0) {
    issues <- c(issues, "No node has parent_id = ROOT - a mind map needs exactly one root node.")
  }
  if (sum(nodes_df$parent_node_id == ROOT_MARKER) > 1) {
    issues <- c(issues, sprintf(
      "%d nodes claim parent_id = ROOT - a mind map should have exactly one root.",
      sum(nodes_df$parent_node_id == ROOT_MARKER)
    ))
  }
  if (any(duplicated(nodes_df$node_id))) {
    dupes <- unique(nodes_df$node_id[duplicated(nodes_df$node_id)])
    issues <- c(issues, sprintf("Duplicate node_id(s) found: %s", paste(dupes, collapse = ", ")))
  }

  non_root <- nodes_df[nodes_df$parent_node_id != ROOT_MARKER, ]
  missing_parents <- setdiff(non_root$parent_node_id, nodes_df$node_id)
  if (length(missing_parents) > 0) {
    issues <- c(issues, sprintf(
      "%d node(s) reference a parent_id that doesn't exist among the generated nodes: %s",
      length(missing_parents), paste(missing_parents, collapse = ", ")
    ))
  }

  # ---- Cross-link target existence (non-blocking) ----
  dangling <- c()
  for (i in seq_len(nrow(nodes_df))) {
    cl <- parse_cross_links(nodes_df$cross_links[i])
    if (nrow(cl) == 0) next
    bad_targets <- setdiff(cl$target_node_id, nodes_df$node_id)
    if (length(bad_targets) > 0) {
      dangling <- c(dangling, sprintf("%s -> %s", nodes_df$node_id[i], paste(bad_targets, collapse = ", ")))
    }
  }
  if (length(dangling) > 0) {
    warnings <- c(warnings, sprintf(
      "%d cross-link(s) point to a node_id that doesn't exist and will be silently skipped when rendered: %s",
      length(dangling), paste(dangling, collapse = "; ")
    ))
  }

  shorthand_nodes <- nodes_df$node_id[vapply(nodes_df$cross_links, cross_links_used_shorthand_separator, logical(1))]
  if (length(shorthand_nodes) > 0) {
    warnings <- c(warnings, sprintf(
      "%d node(s) had multiple cross-links joined with a shorthand '|||' instead of the full '|||COL|||' token - auto-corrected, but worth double-checking: %s",
      length(shorthand_nodes), paste(shorthand_nodes, collapse = ", ")
    ))
  }

  # ---- Branching-factor cap verification (defense-in-depth) ----
  # These are enforced as HARD CAPS in the generation prompt (see
  # build_mindmap_rules_block()), but LLM output isn't infallible at
  # obeying numeric constraints, so double-check the actual result here.
  # Non-blocking: exceeding a branching cap doesn't corrupt the tree,
  # it's a "the map is a bit bushier than requested" issue.
  if (!is.null(max_root_children)) {
    root_id <- nodes_df$node_id[nodes_df$parent_node_id == ROOT_MARKER]
    if (length(root_id) == 1) {
      root_children_count <- sum(nodes_df$parent_node_id == root_id)
      if (root_children_count > max_root_children) {
        warnings <- c(warnings, sprintf(
          "The root node has %d direct children, exceeding the requested cap of %d.",
          root_children_count, max_root_children
        ))
      }
    }
  }
  if (!is.null(max_children_per_node)) {
    non_root_ids <- nodes_df$node_id[nodes_df$parent_node_id != ROOT_MARKER]
    child_counts <- table(nodes_df$parent_node_id[nodes_df$parent_node_id %in% non_root_ids])
    over_cap <- child_counts[child_counts > max_children_per_node]
    if (length(over_cap) > 0) {
      warnings <- c(warnings, sprintf(
        "%d node(s) exceed the requested cap of %d children each: %s",
        length(over_cap), max_children_per_node,
        paste(sprintf("%s (%d)", names(over_cap), as.integer(over_cap)), collapse = ", ")
      ))
    }
  }

  list(valid = length(issues) == 0, issues = issues, warnings = warnings)
}

# ============================================================
# AUTO-PRUNE SPURIOUS EMPTY/DISCONNECTED NODES
# ============================================================
# Occasionally Claude's response includes a trailing, malformed extra
# node block - empty label, empty content, no children, not referenced
# by any cross-link - most commonly a second bogus [parent_id]: ROOT
# block tacked on at the very end. It carries no information and isn't
# connected to anything, so it's safe to silently drop BEFORE
# validation runs, rather than blocking the whole upload over an
# artifact the user never asked for and would almost certainly just
# want removed anyway.
#
# Deliberately conservative: a node is only ever pruned if ALL of the
# following hold, so a genuine (if oddly-placed) real node is never
# touched:
#   - its label is blank OR merely echoes its own node_id (the parser's
#     fallback when [label] was omitted - see parse_mindmap_creation_text)
#   - its content is blank
#   - no other node claims it as a parent (it has zero children)
#   - no cross-link, from any node, targets it
# Runs iteratively so a short CHAIN of empty stray nodes (rare, but
# possible) is fully cleared, not just the first one.
prune_empty_disconnected_nodes <- function(nodes_df) {
  pruned_ids <- character(0)
  is_blank <- function(x) is.na(x) || trimws(x) == ""

  max_iterations <- nrow(nodes_df) + 2
  for (iter in seq_len(max_iterations)) {
    if (nrow(nodes_df) == 0) break

    referenced_as_parent <- unique(nodes_df$parent_node_id)
    referenced_as_crosslink_target <- unique(unlist(lapply(seq_len(nrow(nodes_df)), function(i) {
      parse_cross_links(nodes_df$cross_links[i])$target_node_id
    })))

    is_candidate <- vapply(seq_len(nrow(nodes_df)), function(i) {
      row <- nodes_df[i, ]
      label_is_empty_or_selfref <- is_blank(row$node_label) || identical(row$node_label, row$node_id)
      content_is_empty <- is_blank(row$node_content)
      has_no_children <- !(row$node_id %in% referenced_as_parent)
      not_a_crosslink_target <- !(row$node_id %in% referenced_as_crosslink_target)
      label_is_empty_or_selfref && content_is_empty && has_no_children && not_a_crosslink_target
    }, logical(1))

    if (!any(is_candidate)) break

    pruned_ids <- c(pruned_ids, nodes_df$node_id[is_candidate])
    nodes_df <- nodes_df[!is_candidate, ]
  }

  list(nodes = nodes_df, pruned_ids = unique(pruned_ids))
}

# Given the CURRENT tree (data.frame with node_id, parent_node_id) and a
# node_id to delete, returns that node_id plus every descendant - the
# full cascade set. Computed by the APP, not by Claude, so it can never
# miss a node the way an LLM enumerating a large subtree by hand might.
compute_cascade_delete <- function(nodes_df, node_id_to_delete) {
  to_delete <- character(0)
  frontier <- node_id_to_delete

  max_iterations <- nrow(nodes_df) + 2
  for (iter in seq_len(max_iterations)) {
    if (length(frontier) == 0) break
    to_delete <- c(to_delete, frontier)
    children <- nodes_df$node_id[nodes_df$parent_node_id %in% frontier]
    frontier <- setdiff(children, to_delete)
  }

  unique(to_delete)
}

# Compact indented outline of the CURRENT tree, used as context inside
# the edit prompt so Claude can see the existing structure without
# needing to be sent the entire raw delimited storage format.
serialize_tree_for_prompt <- function(nodes_df, max_words_per_node = 60) {
  if (nrow(nodes_df) == 0) return("(empty map)")

  nodes_df <- compute_node_levels(nodes_df)
  nodes_df <- nodes_df[order(nodes_df$level, nodes_df$sort_order %||% 0), ]

  truncate_words <- function(text, n) {
    words <- strsplit(text, "\\s+")[[1]]
    if (length(words) <= n) return(text)
    paste0(paste(words[seq_len(n)], collapse = " "), " ...")
  }

  lines <- c()
  for (i in seq_len(nrow(nodes_df))) {
    indent <- strrep("  ", nodes_df$level[i])
    root_tag <- if (nodes_df$parent_node_id[i] == ROOT_MARKER) " (ROOT)" else ""
    content_preview <- truncate_words(nodes_df$node_content[i], max_words_per_node)
    lines <- c(lines, sprintf("%s%s: %s%s - %s",
                              indent, nodes_df$node_id[i], nodes_df$node_label[i],
                              root_tag, content_preview))
  }

  cross_link_lines <- c()
  for (i in seq_len(nrow(nodes_df))) {
    cl <- parse_cross_links(nodes_df$cross_links[i])
    if (nrow(cl) > 0) {
      for (j in seq_len(nrow(cl))) {
        cross_link_lines <- c(cross_link_lines, sprintf("%s -> %s (%s)",
                                                          nodes_df$node_id[i], cl$target_node_id[j],
                                                          cl$relationship_label[j]))
      }
    }
  }

  paste0(
    "TREE STRUCTURE (indented by depth):\n",
    paste(lines, collapse = "\n"),
    if (length(cross_link_lines) > 0) paste0("\n\nCROSS-LINKS:\n", paste(cross_link_lines, collapse = "\n")) else "\n\nCROSS-LINKS: (none)"
  )
}

# Given existing node_ids like "N1", "N7", "N14", returns the next
# unused integer suffix (15 in this example) so new CREATE nodes in an
# edit delta never collide with existing ids.
next_available_node_id_num <- function(nodes_df) {
  if (nrow(nodes_df) == 0) return(1)
  nums <- suppressWarnings(as.integer(gsub("^N", "", nodes_df$node_id, ignore.case = TRUE)))
  nums <- nums[!is.na(nums)]
  if (length(nums) == 0) return(1)
  max(nums) + 1
}

# ============================================================
# D3 VISUALIZATION DATA PREP
# ============================================================
# The D3-based mind map renderer (modules/visualize_mindmap) needs two
# JSON-serializable structures built from the flat nodes_df:
#   1. A NESTED hierarchy (d3.hierarchy() requires {id, label, content,
#      children: [...]}), built by walking parent_node_id downward from
#      the single ROOT node.
#   2. A FLAT array of cross-links ({source, target, label}), drawn as
#      a second, visually distinct layer of curved edges once the tree
#      layout has assigned every node a position.

# Recursively builds the nested tree from a flat nodes_df. Returns NULL
# if there isn't exactly one root (should already have been caught by
# validate_tree_structure() before this is ever called).
build_d3_tree <- function(nodes_df) {
  root_rows <- nodes_df[nodes_df$parent_node_id == ROOT_MARKER, ]
  if (nrow(root_rows) != 1) return(NULL)

  build_node <- function(node_id) {
    row <- nodes_df[nodes_df$node_id == node_id, ][1, ]
    child_ids <- nodes_df$node_id[nodes_df$parent_node_id == node_id]

    node <- list(
      id = row$node_id,
      label = row$node_label,
      content = row$node_content
    )
    if (length(child_ids) > 0) {
      node$children <- lapply(child_ids, build_node)
    }
    node
  }

  build_node(root_rows$node_id[1])
}

# Flat {source, target, label} list for every cross-link whose target
# actually exists in the current tree (dangling targets are silently
# skipped here too, matching the same rule used elsewhere).
build_d3_cross_links <- function(nodes_df) {
  links <- list()
  for (i in seq_len(nrow(nodes_df))) {
    cl <- parse_cross_links(nodes_df$cross_links[i])
    if (nrow(cl) == 0) next
    for (j in seq_len(nrow(cl))) {
      if (cl$target_node_id[j] %in% nodes_df$node_id) {
        links[[length(links) + 1]] <- list(
          source = nodes_df$node_id[i],
          target = cl$target_node_id[j],
          label = cl$relationship_label[j]
        )
      }
    }
  }
  links
}

# ============================================================
# GENERATE CLAUDE PROMPT - INITIAL FULL TREE CREATION
# ============================================================
# Structured as RULES FIRST, REQUEST SECOND: Claude is given the full
# structural "constitution" of how a mind map must be built (root rule,
# ordering rule, tag format, delimiter contract, branching HARD CAPS,
# LaTeX policy, formatting rules) before it ever sees the specific
# topic being asked for. This is deliberate - for a structured-output
# task like this, giving the model the complete rule set as context
# BEFORE the task description tends to produce more reliable adherence
# than stating the task first and appending rules afterward.
build_mindmap_rules_block <- function(include_latex = FALSE, words_per_node = 40,
                                       max_root_children = 6, max_children_per_node = 5) {

  latex_instruction <- if (isTRUE(include_latex)) {
    paste0(
      '- Where a formula or equation is genuinely relevant inside a node\'s [content], you may use LaTeX ',
      'syntax: $inline$ or $$display$$. Do not force it where not relevant.\n'
    )
  } else {
    paste0(
      '- Do NOT use any LaTeX syntax anywhere (no $...$, no $$...$$, no \\frac, \\sum, etc). ',
      'Express any formulas in plain text instead.\n'
    )
  }

  paste0(
    'You are an assistant that generates MIND MAPS (hierarchical trees with optional cross-links) ',
    'for a web app. Before you see the specific topic to build, read and internalize ALL of the ',
    'following rules - they apply to every mind map you generate, no exceptions.\n\n',

    '========== MIND MAP STRUCTURAL RULES ==========\n\n',

    '1. OUTPUT FORMAT - the response must consist of:\n',
    '   - Exactly 4 metadata lines at the very top, each on its own line. Each line must contain ONLY the actual value wrapped in single square brackets - do NOT include a field name, label, or colon inside or around the brackets. For example, if the Category is "Finance", the Domain is "Investing", the Topic is "Value Investing", and the Map Title is "Principles of Value Investing", the first 4 lines of your entire response must be EXACTLY:\n',
    '     [Finance]\n',
    '     [Investing]\n',
    '     [Value Investing]\n',
    '     [Principles of Value Investing]\n',
    '     Do NOT write "[Category]: Finance" or "[Category] Finance" or add any other text on these lines - only the bracketed value itself, nothing else.\n',
    '   - Then ONE block per node, in the order you introduce them (a node\'s parent must always be introduced before it), with EXACTLY these 5 tagged lines per block, separated from the next block by ONE blank line:\n',
    '      [node_id]: <a short unique id, e.g. N1, N2, N3, ... incrementing for every node>\n',
    '      [label]: <a SHORT title shown directly on the map node itself - a few words max>\n',
    '      [content]: <a longer summary shown when the node is clicked/expanded - approx ', words_per_node, ' words max>\n',
    '      [parent_id]: <the node_id of this node\'s ONE primary parent in the hierarchy>\n',
    '      [cross_links]: <optional additional relationships to OTHER nodes - see rule 3 - or "(none)">\n\n',

    '2. THE ROOT NODE AND HIERARCHY (critical, non-negotiable):\n',
    '   - Exactly ONE node must have [parent_id]: ROOT (this literal word) - this is the single root of the map.\n',
    '   - EVERY other node\'s [parent_id] MUST be the node_id of a node ALREADY introduced earlier in this same response - never reference a node_id that comes later or does not exist. This guarantees the tree has no cycles.\n',
    '   - HARD CAP: the root node may have AT MOST ', max_root_children, ' direct children (nodes whose [parent_id] is the root\'s node_id). Never exceed this, even if more items would seem relevant - if there are more candidates than fit, select only the ', max_root_children, ' most important/representative ones.\n',
    '   - HARD CAP: any OTHER (non-root) node may have AT MOST ', max_children_per_node, ' direct children. Never exceed this either, for the same reason.\n\n',

    '3. CROSS-LINKS (optional, structurally separate from parent_id):\n',
    '   - A cross_link is an ADDITIONAL relationship from this node to any OTHER node anywhere in the map - including nodes introduced LATER, or nodes higher up the hierarchy (e.g. a node linking back to an ancestor or to a node under a completely different branch). This is different from parent_id, which is strictly the primary hierarchy position, and cross-links do NOT count toward the branching HARD CAPS in rule 2 (those only govern parent_id/child relationships).\n',
    '   - Format for ONE cross-link: <target_node_id>', CROSS_LINK_KV_SEP, '<short relationship label, e.g. "builds on", "contrasts with", "depends on">\n',
    '   - Format for MULTIPLE cross-links on the same node: join them with the FULL literal token "', CROSS_LINK_SEP, '" between each complete entry - never just a bare "|||". For example, a node linking to both N5 and N3 must be written EXACTLY like this:\n',
    '     [cross_links]: N5', CROSS_LINK_KV_SEP, 'builds on', CROSS_LINK_SEP, 'N3', CROSS_LINK_KV_SEP, 'extends\n',
    '     NOT like this (missing the "COL" part of the separator - this is a common mistake, avoid it): [cross_links]: N5', CROSS_LINK_KV_SEP, 'builds on|||N3', CROSS_LINK_KV_SEP, 'extends\n',
    '   - Use cross-links sparingly and only where a genuinely meaningful relationship exists beyond the tree structure - most nodes will have [cross_links]: (none).\n',
    '   - NEVER use "', CROSS_LINK_SEP, '" or "', CROSS_LINK_KV_SEP, '" anywhere else in your response (not in labels, content, or metadata).\n\n',

    '4. CONTENT RULES:\n',
    latex_instruction,
    '   - Each [content] value must stay close to the ', words_per_node, '-word target - concise and specific, not padded.\n\n',

    '5. FORMATTING RULES:\n',
    '   - NO extra markdown, NO headers with #, NO numbered list markers, NO markdown tables.\n',
    '   - Separate each node block with exactly ONE blank line.\n',
    '   - Use the exact bracket tag format shown in rule 1 - do not deviate, add extra tags, or omit any of the 5.\n\n',

    '========== END OF RULES ==========\n\n'
  )
}

generate_mindmap_prompt <- function(category, domain, topic, map_title,
                                     request_description,
                                     include_latex = FALSE,
                                     words_per_node = 40,
                                     max_nodes = 12,
                                     max_depth = 3,
                                     max_root_children = 6,
                                     max_children_per_node = 5) {

  rules_block <- build_mindmap_rules_block(
    include_latex = include_latex, words_per_node = words_per_node,
    max_root_children = max_root_children, max_children_per_node = max_children_per_node
  )

  request_block <- paste0(
    '========== YOUR TASK ==========\n\n',
    'Now build a mind map following ALL the rules above, for:\n\n',
    'Category: ', category, '\n',
    'Domain: ', domain, '\n',
    'Topic: ', topic, '\n',
    'Map Title: ', map_title, '\n\n',

    'User request: ', request_description, '\n\n',

    'SIZE TARGET (soft - a guideline, not a hard cap like the branching rules above): aim for around ',
    max_nodes, ' nodes total, with a maximum depth of ', max_depth, ' levels below the root (root = depth 0) ',
    '- UNLESS the user request above clearly implies a different count, in which case follow the user request, ',
    'while still always respecting the HARD branching caps from rule 2.\n\n',

    'Begin your response now with the 4 metadata lines, then the node blocks, exactly as specified in rule 1.'
  )

  paste0(rules_block, request_block)
}

# ============================================================
# GENERATE CLAUDE PROMPT - EDIT DELTA (existing map)
# ============================================================
# Claude receives the CURRENT tree (compact serialization) and an
# edit request, and returns ONLY what changed - never the whole tree.
# Cascade deletion of a node's descendants is computed by the APP
# afterward (see compute_cascade_delete()), not requested from Claude.
generate_mindmap_edit_prompt <- function(category, domain, topic, map_title,
                                          current_tree_text, edit_request,
                                          next_id_start,
                                          include_latex = FALSE,
                                          words_per_node = 40) {

  latex_instruction <- if (isTRUE(include_latex)) {
    '- Where a formula is genuinely relevant, you may use LaTeX ($inline$ or $$display$$).\n'
  } else {
    '- Do NOT use any LaTeX syntax anywhere - plain text only.\n'
  }

  prompt <- paste0(
    'You are editing an EXISTING mind map for a web app. You must output ONLY the CHANGES needed - ',
    'never re-output nodes that are not changing.\n\n',

    'Category: ', category, ' | Domain: ', domain, ' | Topic: ', topic, ' | Map Title: ', map_title, '\n\n',

    'CURRENT TREE (for your reference only - do not re-output unchanged nodes):\n',
    current_tree_text, '\n\n',

    'EDIT REQUEST: ', edit_request, '\n\n',

    'Format Requirements - follow this EXACTLY:\n\n',

    '1. Output ONE block per CHANGE, separated by ONE blank line, with these tagged lines:\n\n',

    'For a NEW node:\n',
    '[change]: CREATE\n',
    '[node_id]: <a NEW id starting at N', next_id_start, ' and incrementing - NEVER reuse an existing node_id>\n',
    '[label]: <short title>\n',
    '[content]: <approx ', words_per_node, ' words max>\n',
    '[parent_id]: <an EXISTING node_id from the current tree above, or ROOT if this somehow becomes a new root (rare)>\n',
    '[cross_links]: <optional, same format as before, or "(none)">\n\n',

    'For an EXISTING node whose content/label/parent/cross_links changed:\n',
    '[change]: UPDATE\n',
    '[node_id]: <the EXISTING node_id being changed>\n',
    '[label]: <the FULL new label (even if only content changed, repeat the label)>\n',
    '[content]: <the FULL new content (even if only the label changed, repeat the content)>\n',
    '[parent_id]: <the FULL current or new parent_id (repeat existing value if not moving this node)>\n',
    '[cross_links]: <the FULL current or new cross_links (repeat existing value if unchanged), or "(none)">\n\n',

    'For a node to remove:\n',
    '[change]: DELETE\n',
    '[node_id]: <the EXISTING node_id to delete>\n',
    '(no other tags needed for DELETE - the app will automatically also remove any descendants of this node, so you do NOT need to individually list its children as separate DELETE blocks unless you specifically want ONLY that one node removed and its children re-attached elsewhere, in which case issue UPDATE blocks for those children with a new parent_id INSTEAD of deleting them)\n\n',

    '2. CRITICAL RULES:\n',
    '   - Do NOT output blocks for nodes that are not changing.\n',
    '   - Do NOT re-output the entire tree.\n',
    '   - For CREATE, only reference an EXISTING node_id (from the current tree above) as [parent_id], unless chaining multiple new CREATE nodes together, in which case you may reference a node_id you just created earlier in this same response.\n',
    '   - NEVER invent a change to a node_id that does not exist in the current tree (for UPDATE/DELETE).\n',
    latex_instruction, '\n',

    'Now output ONLY the delta needed to satisfy the edit request above.'
  )

  return(prompt)
}

# ============================================================
# TOKEN BUDGET ESTIMATION
# ============================================================
# Deliberately generous. Under-budgeting doesn't just waste a little
# headroom - it causes Claude's response to be cut off by the API's own
# max_tokens limit mid-generation, which almost always happens at the
# LAST node, right before or during its [parent_id] line. That's a far
# worse failure mode than a slightly oversized request: a truncated
# response produces an incomplete tree that used to (before this fix)
# masquerade as a confusing "2 nodes claim ROOT" structural error. See
# parse_mindmap_creation_text()'s truncated_node_id handling.
estimate_mindmap_max_tokens <- function(max_nodes, words_per_node, include_latex = FALSE) {
  max_nodes <- max(1, as.numeric(max_nodes))
  words_per_node <- max(1, as.numeric(words_per_node))

  latex_factor <- if (isTRUE(include_latex)) 1.3 else 1.0

  # Structural overhead per node: the 5 tag labels, a short label field,
  # a parent_id, and - critically - headroom for cross_links. The
  # ||| delimiter tokens do NOT compress well under BPE tokenization
  # (punctuation-heavy, unusual sequences typically cost several real
  # API tokens each, not "one word"), and a meaningful fraction of nodes
  # carry 1-2 cross-links in practice. 25 words/node badly undercounted
  # this; 55 is a much safer real-world estimate.
  per_node_overhead_words <- 55

  total_words <- (max_nodes * words_per_node * latex_factor) + (max_nodes * per_node_overhead_words) + 150

  # ~1.8 tokens/word (vs. a plain-prose ~1.3-1.5) to absorb the
  # delimiter-heavy, punctuation-dense format, plus an explicit 20%
  # safety margin on top of that - erring toward "too large" is nearly
  # free, while erring toward "too small" corrupts the upload.
  estimated_tokens <- ceiling(total_words * 1.8 * 1.2)

  max(2500, min(estimated_tokens, 64000))
}



# ====================================================================
# KNOWLEDGE GRAPH - core parsing/validation/D3+Cytoscape-data-prep
# ====================================================================
# Generates a unique graph_id for a NEW knowledge graph (assigned by
# the app, not by Claude, so uniqueness is guaranteed).
generate_new_graph_id <- function(topic) {
  slug <- tolower(gsub("[^a-zA-Z0-9]+", "-", trimws(topic)))
  slug <- gsub("^-+|-+$", "", slug)
  if (nchar(slug) == 0) slug <- "graph"
  if (nchar(slug) > 40) slug <- substr(slug, 1, 40)
  paste0(slug, "-", format(Sys.time(), "%Y%m%d%H%M%S"))
}

# ============================================================
# PARSE CLAUDE'S INITIAL FULL-GRAPH GENERATION
# ============================================================
# Expected format:
#
# [Category]
# [Domain]
# [Topic]
# [Graph Title]
#
# [entity_id]: E1
# [label]: Marie Curie
# [type]: Person
# [description]: <~N words>
#
# [entity_id]: E2
# ...
#
# [relationship_id]: R1
# [source]: E1
# [predicate]: won
# [target]: E2
# [description]: <~N words>
#
# Order of entity vs relationship blocks does NOT matter for parsing
# correctness (unlike the Mind Map's tree, references here don't need
# an "already introduced" guarantee) - entities-before-relationships is
# only requested as a style preference in the prompt, for readability.
parse_kg_creation_text <- function(text) {

  lines <- strsplit(text, "\n")[[1]]

  # Tolerant of both bare [Value] and labeled [Category]: Value forms -
  # lesson learned from the Mind Map Suite, where Claude occasionally
  # drifted to the labeled form despite instructions.
  labeled_metadata_re <- "^\\[(Category|Domain|Topic|Graph Title)\\]:\\s*(.*)$"
  bare_metadata_re <- "^\\[.+\\]$"

  category <- NULL; domain <- NULL; topic <- NULL; graph_title <- NULL
  metadata_count <- 0
  for (i in seq_len(min(20, length(lines)))) {
    line <- trimws(lines[i])
    value <- NULL
    if (grepl(labeled_metadata_re, line, ignore.case = TRUE)) {
      value <- trimws(sub(labeled_metadata_re, "\\2", line, ignore.case = TRUE))
    } else if (grepl(bare_metadata_re, line)) {
      value <- gsub("^\\[|\\]$", "", line)
    }
    if (!is.null(value)) {
      metadata_count <- metadata_count + 1
      if (metadata_count == 1) category <- value
      else if (metadata_count == 2) domain <- value
      else if (metadata_count == 3) topic <- value
      else if (metadata_count == 4) graph_title <- value
      else break
    }
  }

  if (is.null(category) || is.null(domain) || is.null(topic)) {
    stop("Could not find Category, Domain, and Topic metadata in generated knowledge graph text")
  }
  if (is.null(graph_title)) graph_title <- topic

  blocks <- list()
  current_block <- list()

  flush_block <- function() {
    if (!is.null(current_block$.kind)) {
      blocks[[length(blocks) + 1]] <<- current_block
    }
    current_block <<- list()
  }

  for (line in lines) {
    trimmed <- trimws(line)

    if (trimmed == "") { flush_block(); next }

    if (grepl("^\\[entity_id\\]:", trimmed, ignore.case = TRUE)) {
      flush_block()
      current_block$.kind <- "entity"
      current_block$entity_id <- trimws(sub("^\\[entity_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[relationship_id\\]:", trimmed, ignore.case = TRUE)) {
      flush_block()
      current_block$.kind <- "relationship"
      current_block$relationship_id <- trimws(sub("^\\[relationship_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[label\\]:", trimmed, ignore.case = TRUE)) {
      current_block$label <- trimws(sub("^\\[label\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[type\\]:", trimmed, ignore.case = TRUE)) {
      current_block$type <- trimws(sub("^\\[type\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[source\\]:", trimmed, ignore.case = TRUE)) {
      current_block$source <- trimws(sub("^\\[source\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[predicate\\]:", trimmed, ignore.case = TRUE)) {
      current_block$predicate <- trimws(sub("^\\[predicate\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[target\\]:", trimmed, ignore.case = TRUE)) {
      current_block$target <- trimws(sub("^\\[target\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[description\\]:", trimmed, ignore.case = TRUE)) {
      current_block$description <- trimws(sub("^\\[description\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (!is.null(current_block$description)) {
      current_block$description <- paste0(current_block$description, " ", trimmed)
    }
  }
  flush_block()

  if (length(blocks) == 0) {
    stop("No valid [entity_id] or [relationship_id] blocks found in generated knowledge graph text")
  }

  entities_list <- list()
  relationships_list <- list()
  truncated_id <- NULL

  # If the response was cut off by the API's token limit, it typically
  # stops mid-way through the LAST block. Only the LAST block missing a
  # required field is treated as truncation (dropped + reported); any
  # OTHER block missing a required field is a genuine formatting
  # problem, left as blank so validate_kg_structure() reports it
  # accurately instead of guessing.
  for (i in seq_along(blocks)) {
    b <- blocks[[i]]
    is_last <- (i == length(blocks))

    if (b$.kind == "entity") {
      missing_required <- is.null(b$label) || is.null(b$type) || is.null(b$description)
      if (missing_required && is_last) { truncated_id <- b$entity_id; next }

      entities_list[[length(entities_list) + 1]] <- data.frame(
        entity_id = b$entity_id,
        entity_label = ifelse(is.null(b$label), "", b$label),
        entity_type = ifelse(is.null(b$type), "", b$type),
        entity_description = ifelse(is.null(b$description), "", b$description),
        sort_order = i,
        stringsAsFactors = FALSE
      )
    } else {
      missing_required <- is.null(b$source) || is.null(b$predicate) || is.null(b$target)
      if (missing_required && is_last) { truncated_id <- b$relationship_id; next }

      relationships_list[[length(relationships_list) + 1]] <- data.frame(
        relationship_id = b$relationship_id,
        source_entity_id = ifelse(is.null(b$source), "", b$source),
        predicate = ifelse(is.null(b$predicate), "", b$predicate),
        target_entity_id = ifelse(is.null(b$target), "", b$target),
        relationship_description = ifelse(is.null(b$description), "", b$description),
        sort_order = i,
        stringsAsFactors = FALSE
      )
    }
  }

  entities_df <- if (length(entities_list) > 0) do.call(rbind, entities_list) else data.frame(
    entity_id = character(), entity_label = character(), entity_type = character(),
    entity_description = character(), sort_order = integer(), stringsAsFactors = FALSE
  )
  relationships_df <- if (length(relationships_list) > 0) do.call(rbind, relationships_list) else data.frame(
    relationship_id = character(), source_entity_id = character(), predicate = character(),
    target_entity_id = character(), relationship_description = character(), sort_order = integer(),
    stringsAsFactors = FALSE
  )

  list(category = category, domain = domain, topic = topic, graph_title = graph_title,
       entities = entities_df, relationships = relationships_df, truncated_id = truncated_id)
}

# ============================================================
# PARSE CLAUDE'S EDIT DELTA
# ============================================================
# ONLY the changed items, one block per change, each starting with
# [change]: CREATE|UPDATE|DELETE and [kind]: ENTITY|RELATIONSHIP.
parse_kg_delta_text <- function(text) {
  lines <- strsplit(text, "\n")[[1]]

  blocks <- list()
  current_block <- list()

  flush_block <- function() {
    if (!is.null(current_block$change_type) && !is.null(current_block$kind)) {
      blocks[[length(blocks) + 1]] <<- current_block
    }
    current_block <<- list()
  }

  for (line in lines) {
    trimmed <- trimws(line)
    if (trimmed == "") next

    if (grepl("^\\[change\\]:", trimmed, ignore.case = TRUE)) {
      flush_block()
      current_block$change_type <- toupper(trimws(sub("^\\[change\\]:\\s*", "", trimmed, ignore.case = TRUE)))
    } else if (grepl("^\\[kind\\]:", trimmed, ignore.case = TRUE)) {
      current_block$kind <- toupper(trimws(sub("^\\[kind\\]:\\s*", "", trimmed, ignore.case = TRUE)))
    } else if (grepl("^\\[entity_id\\]:", trimmed, ignore.case = TRUE)) {
      current_block$entity_id <- trimws(sub("^\\[entity_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[relationship_id\\]:", trimmed, ignore.case = TRUE)) {
      current_block$relationship_id <- trimws(sub("^\\[relationship_id\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[label\\]:", trimmed, ignore.case = TRUE)) {
      current_block$label <- trimws(sub("^\\[label\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[type\\]:", trimmed, ignore.case = TRUE)) {
      current_block$type <- trimws(sub("^\\[type\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[source\\]:", trimmed, ignore.case = TRUE)) {
      current_block$source <- trimws(sub("^\\[source\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[predicate\\]:", trimmed, ignore.case = TRUE)) {
      current_block$predicate <- trimws(sub("^\\[predicate\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[target\\]:", trimmed, ignore.case = TRUE)) {
      current_block$target <- trimws(sub("^\\[target\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (grepl("^\\[description\\]:", trimmed, ignore.case = TRUE)) {
      current_block$description <- trimws(sub("^\\[description\\]:\\s*", "", trimmed, ignore.case = TRUE))
    } else if (!is.null(current_block$description)) {
      current_block$description <- paste0(current_block$description, " ", trimmed)
    }
  }
  flush_block()

  if (length(blocks) == 0) {
    stop("No valid [change]/[kind] entries found in the edit response")
  }

  entity_changes <- list()
  relationship_changes <- list()

  for (b in blocks) {
    if (is.null(b$change_type) || !b$change_type %in% c("CREATE", "UPDATE", "DELETE")) {
      stop(sprintf("Unknown or missing [change] type '%s'", b$change_type %||% "(none)"))
    }
    if (is.null(b$kind) || !b$kind %in% c("ENTITY", "RELATIONSHIP")) {
      stop(sprintf("Unknown or missing [kind] '%s' - expected ENTITY or RELATIONSHIP", b$kind %||% "(none)"))
    }

    if (b$kind == "ENTITY") {
      entity_changes[[length(entity_changes) + 1]] <- data.frame(
        change_type = tolower(b$change_type),
        entity_id = b$entity_id,
        entity_label = ifelse(is.null(b$label), NA, b$label),
        entity_type = ifelse(is.null(b$type), NA, b$type),
        entity_description = ifelse(is.null(b$description), NA, b$description),
        stringsAsFactors = FALSE
      )
    } else {
      relationship_changes[[length(relationship_changes) + 1]] <- data.frame(
        change_type = tolower(b$change_type),
        relationship_id = b$relationship_id,
        source_entity_id = ifelse(is.null(b$source), NA, b$source),
        predicate = ifelse(is.null(b$predicate), NA, b$predicate),
        target_entity_id = ifelse(is.null(b$target), NA, b$target),
        relationship_description = ifelse(is.null(b$description), NA, b$description),
        stringsAsFactors = FALSE
      )
    }
  }

  entity_delta <- if (length(entity_changes) > 0) do.call(rbind, entity_changes) else data.frame(
    change_type = character(), entity_id = character(), entity_label = character(),
    entity_type = character(), entity_description = character(), stringsAsFactors = FALSE
  )
  relationship_delta <- if (length(relationship_changes) > 0) do.call(rbind, relationship_changes) else data.frame(
    change_type = character(), relationship_id = character(), source_entity_id = character(),
    predicate = character(), target_entity_id = character(), relationship_description = character(),
    stringsAsFactors = FALSE
  )

  list(entity_delta = entity_delta, relationship_delta = relationship_delta)
}

# ============================================================
# VALIDATION
# ============================================================
# Simpler than the Mind Map's tree validation: no root, no depth, no
# cycle concerns (cycles are normal in a knowledge graph). Just:
# uniqueness, completeness, and that every relationship's source/target
# actually exists.
validate_kg_structure <- function(entities_df, relationships_df, max_relationships_per_entity = NULL) {
  issues <- c()
  warnings <- c()

  if (nrow(entities_df) > 0 && any(duplicated(entities_df$entity_id))) {
    dupes <- unique(entities_df$entity_id[duplicated(entities_df$entity_id)])
    issues <- c(issues, sprintf("Duplicate entity_id(s) found: %s", paste(dupes, collapse = ", ")))
  }
  if (nrow(relationships_df) > 0 && any(duplicated(relationships_df$relationship_id))) {
    dupes <- unique(relationships_df$relationship_id[duplicated(relationships_df$relationship_id)])
    issues <- c(issues, sprintf("Duplicate relationship_id(s) found: %s", paste(dupes, collapse = ", ")))
  }

  if (nrow(entities_df) > 0) {
    incomplete <- entities_df[trimws(entities_df$entity_label) == "" |
                              trimws(entities_df$entity_type) == "" |
                              trimws(entities_df$entity_description) == "", ]
    if (nrow(incomplete) > 0) {
      issues <- c(issues, sprintf("%d entit(y/ies) are missing a label, type, or description: %s",
                                  nrow(incomplete), paste(incomplete$entity_id, collapse = ", ")))
    }
  }

  if (nrow(relationships_df) > 0) {
    blank_predicate <- relationships_df[trimws(relationships_df$predicate) == "", ]
    if (nrow(blank_predicate) > 0) {
      issues <- c(issues, sprintf("%d relationship(s) are missing a predicate: %s",
                                  nrow(blank_predicate), paste(blank_predicate$relationship_id, collapse = ", ")))
    }

    missing_sources <- setdiff(relationships_df$source_entity_id[trimws(relationships_df$source_entity_id) != ""],
                               entities_df$entity_id)
    blank_source_rels <- relationships_df$relationship_id[trimws(relationships_df$source_entity_id) == ""]
    if (length(missing_sources) > 0 || length(blank_source_rels) > 0) {
      bad_rel_ids <- relationships_df$relationship_id[
        relationships_df$source_entity_id %in% missing_sources | relationships_df$relationship_id %in% blank_source_rels
      ]
      issues <- c(issues, sprintf("%d relationship(s) reference a source entity_id that doesn't exist or is blank: %s",
                                  length(bad_rel_ids), paste(bad_rel_ids, collapse = ", ")))
    }

    missing_targets <- setdiff(relationships_df$target_entity_id[trimws(relationships_df$target_entity_id) != ""],
                               entities_df$entity_id)
    blank_target_rels <- relationships_df$relationship_id[trimws(relationships_df$target_entity_id) == ""]
    if (length(missing_targets) > 0 || length(blank_target_rels) > 0) {
      bad_rel_ids <- relationships_df$relationship_id[
        relationships_df$target_entity_id %in% missing_targets | relationships_df$relationship_id %in% blank_target_rels
      ]
      issues <- c(issues, sprintf("%d relationship(s) reference a target entity_id that doesn't exist or is blank: %s",
                                  length(bad_rel_ids), paste(bad_rel_ids, collapse = ", ")))
    }

    self_loops <- relationships_df[relationships_df$source_entity_id == relationships_df$target_entity_id &
                                   trimws(relationships_df$source_entity_id) != "", ]
    if (nrow(self_loops) > 0) {
      warnings <- c(warnings, sprintf("%d relationship(s) connect an entity to itself: %s",
                                      nrow(self_loops), paste(self_loops$relationship_id, collapse = ", ")))
    }

    if (!is.null(max_relationships_per_entity)) {
      degree <- table(c(relationships_df$source_entity_id, relationships_df$target_entity_id))
      over_cap <- degree[degree > max_relationships_per_entity]
      if (length(over_cap) > 0) {
        warnings <- c(warnings, sprintf(
          "%d entit(y/ies) exceed the requested cap of %d relationships each: %s",
          length(over_cap), max_relationships_per_entity,
          paste(sprintf("%s (%d)", names(over_cap), as.integer(over_cap)), collapse = ", ")
        ))
      }
    }
  }

  list(valid = length(issues) == 0, issues = issues, warnings = warnings)
}

# ============================================================
# AUTO-PRUNE SPURIOUS EMPTY/DISCONNECTED ENTITIES
# ============================================================
# Same rationale as the Mind Map Suite: occasionally a trailing,
# malformed extra entity block sneaks in - blank label/type/description,
# not referenced by any relationship. Safe to silently drop before
# validation, deliberately conservative (a real entity always has a
# non-blank description).
prune_empty_disconnected_entities <- function(entities_df, relationships_df) {
  pruned_ids <- character(0)
  is_blank <- function(x) is.na(x) || trimws(x) == ""

  max_iterations <- nrow(entities_df) + 2
  for (iter in seq_len(max_iterations)) {
    if (nrow(entities_df) == 0) break

    referenced <- unique(c(relationships_df$source_entity_id, relationships_df$target_entity_id))

    is_candidate <- vapply(seq_len(nrow(entities_df)), function(i) {
      row <- entities_df[i, ]
      label_empty_or_selfref <- is_blank(row$entity_label) || identical(row$entity_label, row$entity_id)
      label_empty_or_selfref && is_blank(row$entity_type) && is_blank(row$entity_description) &&
        !(row$entity_id %in% referenced)
    }, logical(1))

    if (!any(is_candidate)) break
    pruned_ids <- c(pruned_ids, entities_df$entity_id[is_candidate])
    entities_df <- entities_df[!is_candidate, ]
  }

  list(entities = entities_df, pruned_ids = unique(pruned_ids))
}

# ============================================================
# CASCADE DELETE (entity -> its relationships)
# ============================================================
# Deleting an entity must also remove every relationship that touches
# it (as source OR target), or the graph would contain a dangling
# reference. Unlike the Mind Map's subtree cascade, this needs no
# recursive traversal - relationships don't have their own dependents,
# so it's a single filter, not a BFS.
compute_relationship_cascade_delete <- function(relationships_df, entity_ids_to_delete) {
  if (nrow(relationships_df) == 0) return(character(0))
  relationships_df$relationship_id[
    relationships_df$source_entity_id %in% entity_ids_to_delete |
    relationships_df$target_entity_id %in% entity_ids_to_delete
  ]
}

# ============================================================
# COMPACT SERIALIZATION (for edit-prompt context)
# ============================================================
serialize_graph_for_prompt <- function(entities_df, relationships_df, max_words_per_item = 40) {
  if (nrow(entities_df) == 0) return("(empty graph)")

  truncate_words <- function(text, n) {
    words <- strsplit(text, "\\s+")[[1]]
    if (length(words) <= n) return(text)
    paste0(paste(words[seq_len(n)], collapse = " "), " ...")
  }

  entity_lines <- sprintf("%s [%s]: %s - %s", entities_df$entity_id, entities_df$entity_type,
                          entities_df$entity_label,
                          vapply(entities_df$entity_description, truncate_words, character(1), n = max_words_per_item))

  rel_lines <- if (nrow(relationships_df) > 0) {
    sprintf("%s: %s --[%s]--> %s (%s)", relationships_df$relationship_id,
            relationships_df$source_entity_id, relationships_df$predicate, relationships_df$target_entity_id,
            vapply(relationships_df$relationship_description, truncate_words, character(1), n = max_words_per_item))
  } else character(0)

  paste0(
    "ENTITIES:\n", paste(entity_lines, collapse = "\n"),
    "\n\nRELATIONSHIPS:\n", if (length(rel_lines) > 0) paste(rel_lines, collapse = "\n") else "(none)"
  )
}

# Given existing ids like "E1", "E7", "E14", returns the next unused
# integer suffix, so new CREATE items in an edit delta never collide.
next_available_entity_id_num <- function(entities_df) {
  if (nrow(entities_df) == 0) return(1)
  nums <- suppressWarnings(as.integer(gsub("^E", "", entities_df$entity_id, ignore.case = TRUE)))
  nums <- nums[!is.na(nums)]
  if (length(nums) == 0) return(1)
  max(nums) + 1
}
next_available_relationship_id_num <- function(relationships_df) {
  if (nrow(relationships_df) == 0) return(1)
  nums <- suppressWarnings(as.integer(gsub("^R", "", relationships_df$relationship_id, ignore.case = TRUE)))
  nums <- nums[!is.na(nums)]
  if (length(nums) == 0) return(1)
  max(nums) + 1
}
# GENERATE CLAUDE PROMPT - INITIAL FULL GRAPH CREATION
# ============================================================
# Rules-first structure (lesson learned from the Mind Map Suite):
# Claude gets the complete structural "constitution" BEFORE the
# specific topic, which produces more reliable format adherence than
# appending rules after the task description.
build_kg_rules_block <- function(include_latex = FALSE, words_per_entity = 30, words_per_relationship = 25,
                                  max_relationships_per_entity = 8) {

  latex_instruction <- if (isTRUE(include_latex)) {
    '- Where a formula is genuinely relevant inside a description, you may use LaTeX ($inline$ or $$display$$). Do not force it where not relevant.\n'
  } else {
    '- Do NOT use any LaTeX syntax anywhere (no $...$, no $$...$$, no \\frac, \\sum, etc). Express any formulas in plain text instead.\n'
  }

  paste0(
    'You are an assistant that generates KNOWLEDGE GRAPHS for a web app - a set of typed ENTITIES ',
    'connected by typed, directed RELATIONSHIPS (subject-predicate-object triples). Unlike a hierarchy ',
    'or mind map, a knowledge graph has NO root and NO required tree structure: entities can connect to ',
    'any other entities, cycles are fine, and an entity may have zero, one, or many relationships. Before ',
    'you see the specific topic, read and internalize ALL of the following rules.\n\n',

    '========== KNOWLEDGE GRAPH STRUCTURAL RULES ==========\n\n',

    '1. OUTPUT FORMAT - the response must consist of:\n',
    '   - Exactly 4 metadata lines at the very top, each on its own line. Each line must contain ONLY the actual value wrapped in single square brackets - do NOT include a field name, label, or colon inside or around the brackets. For example, if the Category is "Science", the Domain is "Physics", the Topic is "Nobel Laureates", and the Graph Title is "Physics Nobel Laureates Network", the first 4 lines of your entire response must be EXACTLY:\n',
    '     [Science]\n',
    '     [Physics]\n',
    '     [Nobel Laureates]\n',
    '     [Physics Nobel Laureates Network]\n',
    '     Do NOT write "[Category]: Science" or add any other text on these lines - only the bracketed value itself.\n',
    '   - Then output ALL entity blocks FIRST, followed by ALL relationship blocks. Separate every block from the next with exactly ONE blank line.\n\n',

    '2. ENTITY BLOCKS - EXACTLY these 4 tagged lines:\n',
    '   [entity_id]: <a short unique id, e.g. E1, E2, E3, ... incrementing for every entity>\n',
    '   [label]: <the entity\'s name/title - a few words>\n',
    '   [type]: <a short category for this entity, e.g. Person, Organization, Concept, Event, Location, Technology, Publication - choose whatever types genuinely fit this topic, you are not restricted to this list>\n',
    '   [description]: <approx ', words_per_entity, ' words describing this entity specifically>\n\n',

    '3. RELATIONSHIP BLOCKS - EXACTLY these 5 tagged lines:\n',
    '   [relationship_id]: <a short unique id, e.g. R1, R2, R3, ... incrementing for every relationship>\n',
    '   [source]: <the entity_id this relationship starts FROM>\n',
    '   [predicate]: <a short verb phrase describing the relationship, e.g. "won", "influenced", "located in", "founded", "collaborated with">\n',
    '   [target]: <the entity_id this relationship points TO>\n',
    '   [description]: <approx ', words_per_relationship, ' words of specific detail about THIS relationship - not a generic restatement of the predicate>\n\n',

    '4. HARD CAPS (non-negotiable):\n',
    '   - Both [source] and [target] of every relationship MUST reference an entity_id you actually defined in an entity block above - never invent a reference to an entity_id that does not exist.\n',
    '   - No entity may be involved (as source OR target, combined) in more than ', max_relationships_per_entity, ' relationships. If more connections would be relevant, keep only the ', max_relationships_per_entity, ' most important ones for that entity.\n\n',

    '5. CONTENT RULES:\n',
    latex_instruction,
    '   - Each entity description must stay close to the ', words_per_entity, '-word target; each relationship description close to the ', words_per_relationship, '-word target - concise and specific, not padded.\n',
    '   - A relationship\'s description should say something SPECIFIC about that particular connection, not just restate the predicate in different words.\n\n',

    '6. FORMATTING RULES:\n',
    '   - NO extra markdown, NO headers with #, NO numbered list markers.\n',
    '   - Separate every block (entity or relationship) with exactly ONE blank line.\n',
    '   - Use the exact bracket tag format shown above.\n\n',

    '========== END OF RULES ==========\n\n'
  )
}

generate_kg_prompt <- function(category, domain, topic, graph_title, request_description,
                                include_latex = FALSE, words_per_entity = 30, words_per_relationship = 25,
                                max_entities = 15, max_relationships = 20, max_relationships_per_entity = 8) {

  rules_block <- build_kg_rules_block(include_latex = include_latex, words_per_entity = words_per_entity,
                                      words_per_relationship = words_per_relationship,
                                      max_relationships_per_entity = max_relationships_per_entity)

  request_block <- paste0(
    '========== YOUR TASK ==========\n\n',
    'Now build a knowledge graph following ALL the rules above, for:\n\n',
    'Category: ', category, '\n',
    'Domain: ', domain, '\n',
    'Topic: ', topic, '\n',
    'Graph Title: ', graph_title, '\n\n',

    'User request: ', request_description, '\n\n',

    'SIZE TARGET (soft - a guideline, not a hard cap like rule 4 above): aim for around ', max_entities,
    ' entities and around ', max_relationships, ' relationships total - UNLESS the user request above ',
    'clearly implies a different count, in which case follow the user request, while still always ',
    'respecting the HARD per-entity relationship cap from rule 4.\n\n',

    'Begin your response now with the 4 metadata lines, then all entity blocks, then all relationship blocks, exactly as specified in rule 1.'
  )

  paste0(rules_block, request_block)
}

# ============================================================
# GENERATE CLAUDE PROMPT - EDIT DELTA (existing graph)
# ============================================================
generate_kg_edit_prompt <- function(category, domain, topic, graph_title, current_graph_text, edit_request,
                                     next_entity_id_start, next_relationship_id_start,
                                     include_latex = FALSE, words_per_entity = 30, words_per_relationship = 25) {

  latex_instruction <- if (isTRUE(include_latex)) {
    '- Where a formula is genuinely relevant, you may use LaTeX ($inline$ or $$display$$).\n'
  } else {
    '- Do NOT use any LaTeX syntax anywhere - plain text only.\n'
  }

  paste0(
    'You are editing an EXISTING knowledge graph for a web app. You must output ONLY the CHANGES needed - ',
    'never re-output entities or relationships that are not changing.\n\n',

    'Category: ', category, ' | Domain: ', domain, ' | Topic: ', topic, ' | Graph Title: ', graph_title, '\n\n',

    'CURRENT GRAPH (for your reference only - do not re-output unchanged items):\n',
    current_graph_text, '\n\n',

    'EDIT REQUEST: ', edit_request, '\n\n',

    'Format Requirements - follow this EXACTLY:\n\n',

    '1. Output ONE block per CHANGE, separated by ONE blank line, with these tagged lines:\n\n',

    'For a NEW entity:\n',
    '[change]: CREATE\n[kind]: ENTITY\n',
    '[entity_id]: <a NEW id starting at E', next_entity_id_start, ' and incrementing - NEVER reuse an existing entity_id>\n',
    '[label]: <name>\n[type]: <type>\n[description]: <approx ', words_per_entity, ' words>\n\n',

    'For an EXISTING entity whose label/type/description changed:\n',
    '[change]: UPDATE\n[kind]: ENTITY\n',
    '[entity_id]: <the EXISTING entity_id being changed>\n',
    '[label]: <the FULL new label (repeat existing value if unchanged)>\n',
    '[type]: <the FULL new type (repeat existing value if unchanged)>\n',
    '[description]: <the FULL new description (repeat existing value if unchanged)>\n\n',

    'For an entity to remove:\n',
    '[change]: DELETE\n[kind]: ENTITY\n',
    '[entity_id]: <the EXISTING entity_id to delete>\n',
    '(no other tags needed - the app will automatically also remove every relationship touching this entity, so you do NOT need to separately DELETE those relationships)\n\n',

    'For a NEW relationship:\n',
    '[change]: CREATE\n[kind]: RELATIONSHIP\n',
    '[relationship_id]: <a NEW id starting at R', next_relationship_id_start, ' and incrementing - NEVER reuse an existing relationship_id>\n',
    '[source]: <an EXISTING or newly-CREATEd-in-this-response entity_id>\n',
    '[predicate]: <verb phrase>\n',
    '[target]: <an EXISTING or newly-CREATEd-in-this-response entity_id>\n',
    '[description]: <approx ', words_per_relationship, ' words>\n\n',

    'For an EXISTING relationship whose source/predicate/target/description changed:\n',
    '[change]: UPDATE\n[kind]: RELATIONSHIP\n',
    '[relationship_id]: <the EXISTING relationship_id being changed>\n',
    '[source]: <FULL current or new source (repeat if unchanged)>\n',
    '[predicate]: <FULL current or new predicate (repeat if unchanged)>\n',
    '[target]: <FULL current or new target (repeat if unchanged)>\n',
    '[description]: <FULL current or new description (repeat if unchanged)>\n\n',

    'For a relationship to remove:\n',
    '[change]: DELETE\n[kind]: RELATIONSHIP\n',
    '[relationship_id]: <the EXISTING relationship_id to delete>\n\n',

    '2. CRITICAL RULES:\n',
    '   - Do NOT output blocks for entities/relationships that are not changing.\n',
    '   - Do NOT re-output the entire graph.\n',
    '   - For CREATE relationships, [source]/[target] may reference an EXISTING entity_id OR one you just CREATEd earlier in this same response.\n',
    '   - NEVER invent a change to an entity_id or relationship_id that does not exist in the current graph (for UPDATE/DELETE).\n',
    latex_instruction, '\n',

    'Now output ONLY the delta needed to satisfy the edit request above.'
  )
}

# ============================================================
# TOKEN BUDGET ESTIMATION
# ============================================================
estimate_kg_max_tokens <- function(max_entities, max_relationships, words_per_entity, words_per_relationship,
                                    include_latex = FALSE) {
  max_entities <- max(1, as.numeric(max_entities))
  max_relationships <- max(1, as.numeric(max_relationships))
  words_per_entity <- max(1, as.numeric(words_per_entity))
  words_per_relationship <- max(1, as.numeric(words_per_relationship))

  latex_factor <- if (isTRUE(include_latex)) 1.3 else 1.0

  entity_overhead_words <- 20
  relationship_overhead_words <- 20

  total_words <- (max_entities * (words_per_entity + entity_overhead_words) * latex_factor) +
                 (max_relationships * (words_per_relationship + relationship_overhead_words) * latex_factor) +
                 150

  estimated_tokens <- ceiling(total_words * 1.8 * 1.2)

  max(2000, min(estimated_tokens, 64000))
}

# ============================================================
# D3 / CYTOSCAPE DATA PREP
# ============================================================
build_d3_graph_data <- function(entities_df, relationships_df) {
  nodes <- lapply(seq_len(nrow(entities_df)), function(i) {
    list(id = entities_df$entity_id[i], label = entities_df$entity_label[i],
         type = entities_df$entity_type[i], description = entities_df$entity_description[i])
  })
  links <- lapply(seq_len(nrow(relationships_df)), function(i) {
    list(source = relationships_df$source_entity_id[i], target = relationships_df$target_entity_id[i],
         predicate = relationships_df$predicate[i], description = relationships_df$relationship_description[i])
  })
  list(nodes = nodes, links = links)
}

build_cytoscape_elements <- function(entities_df, relationships_df) {
  node_elements <- lapply(seq_len(nrow(entities_df)), function(i) {
    list(data = list(id = entities_df$entity_id[i], label = entities_df$entity_label[i],
                     type = entities_df$entity_type[i], description = entities_df$entity_description[i]))
  })
  edge_elements <- lapply(seq_len(nrow(relationships_df)), function(i) {
    list(data = list(id = paste0("edge_", relationships_df$relationship_id[i]),
                     source = relationships_df$source_entity_id[i],
                     target = relationships_df$target_entity_id[i],
                     predicate = relationships_df$predicate[i],
                     description = relationships_df$relationship_description[i]))
  })
  c(node_elements, edge_elements)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# ============================================================
# STRATEGIC ANALYSIS (AI-generated strategy diagrams)
# ============================================================
# Own BigQuery table (strategy_diagrams), own APIManager methods
# (bq_get_diagram_taxonomy / bq_get_diagram_components / bq_insert_diagram
# in R/utils_api.R), own state trigger / taxonomy cache / bulk-import
# handoff buffer (state_trigger_diagram, diagram_taxonomy_cache,
# pending_bulk_text_diagram) - same suite-scoping discipline as
# Book Summary/Flex Table/Mind Map/Knowledge Graph above, since this
# suite's required columns and target table are DIFFERENT from all four.
#
# One row in strategy_diagrams = one visual component (a grid cell, a
# quadrant, an axis, a chart series). List-like content within a single
# component (bullets in a SWOT cell, points in a chart series) is packed
# into one column using DIAG_ITEM_SEP, following the exact same
# DELIMITER CONTRACT pattern as Flex Table's COL_SEP/KV_SEP and Mind
# Map's CROSS_LINK_SEP above: a long, punctuation-heavy, namespaced
# literal token Claude is very unlikely to produce by accident, with the
# generation prompt explicitly instructing Claude to use it and nothing
# else.
#
# Position is DELIBERATELY not something Claude is asked to compute
# freely. LLMs are unreliable at spatial arithmetic - that's the actual
# source of overlapping/disorganized diagrams, not the choice of
# renderer. So Claude only ever supplies CATEGORICAL layout slots
# (grid_row/grid_col, quadrant_position, sequence_order), and the
# renderer computes real geometry deterministically:
#   - grid / quadrant / table / stacked_list / linear_flow -> HTML+CSS
#     Grid/Flexbox (browser layout engine guarantees no overlap)
#   - radial / network                                     -> server-
#     computed SVG (R computes evenly-spaced angles/node positions)
#   - line_chart / bar_chart / funnel / dual_axis_timeseries -> plotly
#     (real numeric axes, auto-scaling, native to this app already via
#     Book Summary's visualizations tab)
# pos_x/pos_y/width/height remain in the schema purely as an OPTIONAL
# manual override layer for a human hand-editing a saved diagram later -
# never populated by Claude on first generation.

# ============================================================
# DELIMITER CONTRACT (items_packed field)
# ============================================================
DIAG_ITEM_SEP <- "|||DIAGITEM|||"   # separates multiple items packed into one items_packed field

DIAGRAM_FIELDS <- c(
  "component_type", "layout_role",
  "grid_row", "grid_col", "quadrant_position", "sequence_order",
  "label_text", "sub_text", "items_packed",
  "value_numeric", "value_axis", "series_name", "unit_label",
  "axis_type", "axis_min", "axis_max", "metric_name",
  "color_hint", "icon_name"
)

# ============================================================
# FRAMEWORK CATALOG - Diagram Group -> specific named Framework,
# mirroring Six Sigma's DMAIC Group -> Tool design exactly. Each
# framework has its OWN explicit, detailed instruction block (see
# diagram_type_instructions() below) rather than a generic "grid" or
# "quadrant" hint - the goal is that picking "BCG Growth-Share Matrix"
# gets Claude precise instructions naming its actual four quadrants and
# axes, not a vague "arrange in 2x2" hint that leaves the specifics to
# guesswork.
#
# "diagram_type" (the column already in the BigQuery schema, and the
# value stored/parsed/selected everywhere in this suite) now holds the
# SPECIFIC FRAMEWORK id (e.g. "swot", "bcg_matrix", "five_forces") - it
# is no longer the render shape name directly. DIAGRAM_RENDER_SHAPE maps
# each framework id to the underlying renderer family (grid/quadrant/
# table/etc.) that actually draws it, exactly the same indirection Six
# Sigma already uses (SIXSIGMA_TYPES_BY_GROUP holds specific tools;
# render_sixsigma()'s html_family/svg_family/plotly_family lists decide
# how each one is actually drawn). This required NO new BigQuery column -
# diagram_type already existed and simply now holds finer-grained values.
# ============================================================
DIAGRAM_GROUPS <- c(
  "situational_analysis", "competitive_positioning", "business_model_design",
  "decision_making_process", "organizational_alignment", "timing_lifecycle", "foundational"
)
DIAGRAM_GROUP_LABELS <- c(
  situational_analysis = "Situational Analysis",
  competitive_positioning = "Competitive Positioning",
  business_model_design = "Business Model & Design",
  decision_making_process = "Decision-Making & Process",
  organizational_alignment = "Organizational Alignment",
  timing_lifecycle = "Timing & Lifecycle",
  foundational = "Foundational"
)

DIAGRAM_TYPES_BY_GROUP <- list(
  situational_analysis    = c("swot", "pestel", "five_forces", "vrio", "value_chain"),
  competitive_positioning = c("bcg_matrix", "ge_mckinsey_matrix", "ansoff_matrix",
                              "porters_generic_strategies", "tows_matrix",
                              "blue_ocean_errc", "value_curve"),
  business_model_design   = c("business_model_canvas", "lean_canvas"),
  decision_making_process = c("frame_diagnose_choose_act", "pdca_cycle", "weighted_decision_matrix"),
  organizational_alignment = c("mckinsey_7s", "raci_matrix"),
  timing_lifecycle        = c("disruptive_innovation", "product_lifecycle",
                              "technology_adoption_lifecycle", "trend_to_commoditization",
                              "active_waiting", "economic_profit_mobility", "kano_model"),
  foundational            = c("purpose_of_strategy", "strategic_planning_wheel", "strategy_diamond")
)

DIAGRAM_TYPE_LABELS <- c(
  swot = "SWOT Analysis",
  pestel = "PESTEL Analysis",
  five_forces = "Porter's Five Forces",
  vrio = "VRIO Analysis",
  value_chain = "Porter's Value Chain",
  bcg_matrix = "BCG Growth-Share Matrix",
  ge_mckinsey_matrix = "GE-McKinsey Nine-Box Matrix",
  ansoff_matrix = "Ansoff Matrix",
  porters_generic_strategies = "Porter's Generic Strategies",
  tows_matrix = "TOWS Matrix",
  blue_ocean_errc = "Blue Ocean ERRC Grid",
  value_curve = "Blue Ocean Value Curve",
  business_model_canvas = "Business Model Canvas",
  lean_canvas = "Lean Canvas",
  frame_diagnose_choose_act = "Frame-Diagnose-Choose-Act Process",
  pdca_cycle = "PDCA Cycle (Plan-Do-Check-Act)",
  weighted_decision_matrix = "Weighted Decision Matrix",
  mckinsey_7s = "McKinsey 7S Framework",
  raci_matrix = "RACI Matrix",
  disruptive_innovation = "Disruptive Innovation Curve",
  product_lifecycle = "Product Lifecycle Curve",
  technology_adoption_lifecycle = "Technology Adoption Lifecycle",
  trend_to_commoditization = "Trend to Commoditization",
  active_waiting = "Active Waiting (Opportunity vs. Threat)",
  economic_profit_mobility = "Economic Profit Mobility Funnel",
  kano_model = "Kano Model",
  purpose_of_strategy = "Purpose of Strategy Pyramid",
  strategic_planning_wheel = "Strategic Planning Wheel",
  strategy_diamond = "Strategy Diamond"
)

DIAGRAM_TYPES <- unlist(DIAGRAM_TYPES_BY_GROUP, use.names = FALSE)

# Framework -> underlying renderer family. Every value here must be one
# of the shapes render_diagram() knows how to dispatch: grid, quadrant,
# table, stacked_list, linear_flow, radial, network, line_chart,
# bar_chart, funnel, dual_axis_timeseries, business_model_canvas,
# value_chain (the last two are new, purpose-built shapes - see
# render_diagram_business_model_canvas()/render_diagram_value_chain()
# below - because no existing shape does justice to a real 9-block
# canvas or Porter's primary/support-activity arrow diagram).
DIAGRAM_RENDER_SHAPE <- c(
  swot = "grid", pestel = "grid", five_forces = "network", vrio = "table", value_chain = "value_chain",
  bcg_matrix = "quadrant", ge_mckinsey_matrix = "grid", ansoff_matrix = "quadrant",
  porters_generic_strategies = "quadrant", tows_matrix = "table",
  blue_ocean_errc = "grid", value_curve = "line_chart",
  business_model_canvas = "business_model_canvas", lean_canvas = "business_model_canvas",
  frame_diagnose_choose_act = "linear_flow", pdca_cycle = "radial", weighted_decision_matrix = "table",
  mckinsey_7s = "network", raci_matrix = "table",
  disruptive_innovation = "line_chart", product_lifecycle = "line_chart",
  technology_adoption_lifecycle = "bar_chart", trend_to_commoditization = "bar_chart",
  active_waiting = "dual_axis_timeseries", economic_profit_mobility = "funnel", kano_model = "line_chart",
  purpose_of_strategy = "stacked_list", strategic_planning_wheel = "radial", strategy_diamond = "radial",

  # ---- Backward compatibility: diagrams already stored in BigQuery from
  #     before this framework catalog existed have diagram_type set to a
  #     raw SHAPE name (e.g. "network", "grid") rather than a specific
  #     framework id. These identity entries let render_diagram()'s
  #     DIAGRAM_RENDER_SHAPE[[diagram_type]] lookup keep resolving them
  #     correctly without needing to regenerate old diagrams. New
  #     generations never produce these values (the Framework dropdown
  #     only offers the ~27 specific framework ids above). ----
  grid = "grid", quadrant = "quadrant", table = "table", stacked_list = "stacked_list",
  linear_flow = "linear_flow", radial = "radial", network = "network",
  line_chart = "line_chart", bar_chart = "bar_chart", funnel = "funnel",
  dual_axis_timeseries = "dual_axis_timeseries"
)

# Generates a unique diagram_id for a NEW diagram (assigned by the app,
# not by Claude, so uniqueness is guaranteed regardless of what Claude
# returns) - same slug + timestamp scheme as generate_new_map_id() /
# generate_new_graph_id() above, for consistency across the app.
generate_new_diagram_id <- function(topic) {
  slug <- tolower(gsub("[^a-zA-Z0-9]+", "-", trimws(topic)))
  slug <- gsub("^-+|-+$", "", slug)
  if (nchar(slug) == 0) slug <- "diagram"
  if (nchar(slug) > 40) slug <- substr(slug, 1, 40)
  paste0(slug, "-", format(Sys.time(), "%Y%m%d%H%M%S"))
}

# ---- Per-FRAMEWORK specific guidance - one entry per named strategy
#     framework in DIAGRAM_TYPES, giving Claude the framework's ACTUAL
#     fixed quadrant/cell/segment names and axis labels rather than a
#     generic "arrange in 2x2" hint. This is what makes asking for
#     "BCG Growth-Share Matrix" produce Stars/Question Marks/Cash Cows/
#     Dogs specifically, not four unnamed boxes Claude has to guess at. --
framework_specific_guidance <- function(diagram_type) {
  switch(diagram_type,
    "swot" = paste0(
      'FRAMEWORK = SWOT Analysis. Exactly 4 cells in a 2x2 grid, in this fixed layout: ',
      'Strengths (grid_row=1, grid_col=1), Weaknesses (grid_row=1, grid_col=2), ',
      'Opportunities (grid_row=2, grid_col=1), Threats (grid_row=2, grid_col=2). ',
      'Each cell needs 3-5 specific, concrete items_packed bullets - not vague generalities.\n\n'
    ),
    "pestel" = paste0(
      'FRAMEWORK = PESTEL Analysis. Exactly 6 cells in a 2 rows x 3 columns grid, in this fixed reading ',
      'order: Political (row=1,col=1), Economic (row=1,col=2), Social (row=1,col=3), ',
      'Technological (row=2,col=1), Environmental (row=2,col=2), Legal (row=2,col=3).\n\n'
    ),
    "ge_mckinsey_matrix" = paste0(
      'FRAMEWORK = GE-McKinsey Nine-Box Matrix. Exactly 9 cells in a 3x3 grid PLUS 2 axis_label blocks. ',
      'Cell strategic recommendations by position (row=1 is TOP/high attractiveness, col=1 is LEFT/high ',
      'business strength): (1,1)=Invest/Grow, (1,2)=Invest/Grow, (1,3)=Selective Investment, ',
      '(2,1)=Invest/Grow, (2,2)=Selective Investment, (2,3)=Harvest/Divest, ',
      '(3,1)=Selective Investment, (3,2)=Harvest/Divest, (3,3)=Harvest/Divest. ',
      'label_text = the recommendation (e.g. "Invest/Grow"); items_packed = 2-3 specific reasons this cell ',
      'applies to a specific business unit/product relevant to the topic. ',
      'Axis blocks: [component_type]: axis_label [value_axis]: y [label_text]: Industry Attractiveness ',
      '(High to Low, top to bottom) -- and -- [value_axis]: x [label_text]: Business Unit Strength ',
      '(High to Low, left to right).\n\n'
    ),
    "blue_ocean_errc" = paste0(
      'FRAMEWORK = Blue Ocean ERRC Grid. Exactly 4 cells in a SINGLE ROW (1 row x 4 columns), in this ',
      'fixed left-to-right order: Eliminate (col=1), Reduce (col=2), Raise (col=3), Create (col=4). Each ',
      'cell\'s items_packed names specific factors of competition in this industry that would be ',
      'eliminated/reduced/raised/created.\n\n'
    ),
    "bcg_matrix" = paste0(
      'FRAMEWORK = BCG Growth-Share Matrix. Quadrants: top_left = Stars, top_right = Question Marks, ',
      'bottom_left = Cash Cows, bottom_right = Dogs. Axis labels: y = "Market Growth Rate (High to Low)", ',
      'x = "Relative Market Share (High to Low)". Each quadrant\'s items_packed names specific products, ',
      'business units, or initiatives from the topic that plausibly belong there.\n\n'
    ),
    "ansoff_matrix" = paste0(
      'FRAMEWORK = Ansoff Matrix. Quadrants: top_left = Market Penetration (Existing Products, Existing ',
      'Markets), top_right = Product Development (New Products, Existing Markets), bottom_left = Market ',
      'Development (Existing Products, New Markets), bottom_right = Diversification (New Products, New ',
      'Markets). Axis labels: y = "Markets (Existing to New)", x = "Products (Existing to New)".\n\n'
    ),
    "porters_generic_strategies" = paste0(
      'FRAMEWORK = Porter\'s Generic Strategies. Quadrants: top_left = Cost Leadership (Broad Scope + Low ',
      'Cost), top_right = Differentiation (Broad Scope + Differentiation), bottom_left = Cost Focus ',
      '(Narrow Scope + Low Cost), bottom_right = Differentiation Focus (Narrow Scope + Differentiation). ',
      'Axis labels: y = "Competitive Scope (Broad to Narrow)", x = "Source of Advantage (Cost to ',
      'Differentiation)".\n\n'
    ),
    "vrio" = paste0(
      'FRAMEWORK = VRIO Analysis. A table with header row 1: Resource/Capability, Valuable?, Rare?, Costly ',
      'to Imitate?, Organized to Capture Value?, Competitive Implication (6 columns). One data row per ',
      'resource/capability being assessed (3-5 rows) - cell content in items_packed answers Yes/No/Partial ',
      'with a brief justification; the final column states the competitive implication (Competitive ',
      'Disadvantage / Competitive Parity / Temporary Competitive Advantage / Sustained Competitive ',
      'Advantage).\n\n'
    ),
    "tows_matrix" = paste0(
      'FRAMEWORK = TOWS Matrix (the action-oriented counterpart to SWOT). A 3x3 grid where the 4 INTERIOR ',
      'cells matter most: SO strategies at (row=2,col=2) - use Strengths to capture Opportunities; ',
      'WO strategies at (row=2,col=3) - overcome Weaknesses by exploiting Opportunities; ',
      'ST strategies at (row=3,col=2) - use Strengths to avoid Threats; ',
      'WT strategies at (row=3,col=3) - minimize Weaknesses and avoid Threats. ',
      'Header cells: (1,2)=label_text "Strengths", (1,3)=label_text "Weaknesses", ',
      '(2,1)=label_text "Opportunities", (3,1)=label_text "Threats", (1,1)=label_text "N/A" (blank corner). ',
      'Each interior cell\'s items_packed lists 2-3 specific strategic actions.\n\n'
    ),
    "weighted_decision_matrix" = paste0(
      'FRAMEWORK = Weighted Decision Matrix. Header row (grid_row=1): blank corner cell, then one cell per ',
      'option being compared (label_text = option name). Column 1 (grid_row=2+): criterion names WITH their ',
      'weight in parentheses, e.g. "Cost (30%)". Interior cells: this option\'s raw score against this ',
      'criterion, 1-10, as label_text - DO NOT calculate weighted totals or a final ranking, state raw ',
      'scores only.\n\n'
    ),
    "raci_matrix" = paste0(
      'FRAMEWORK = RACI Matrix. Header row (grid_row=1): blank corner, then one cell per role/stakeholder ',
      '(label_text = role name). Column 1 (grid_row=2+): task/activity names. Interior cells: exactly one ',
      'letter as label_text - R (Responsible), A (Accountable), C (Consulted), or I (Informed) - for that ',
      'role\'s involvement in that task.\n\n'
    ),
    "purpose_of_strategy" = paste0(
      'FRAMEWORK = Purpose of Strategy Pyramid. An ordered stack (3-5 levels) moving from the most ',
      'fundamental/abstract purpose at the TOP (sequence_order=1) to the most concrete/operational actions ',
      'at the bottom - typically Purpose -> Vision -> Strategic Objectives -> Initiatives.\n\n'
    ),
    "frame_diagnose_choose_act" = paste0(
      'FRAMEWORK = Frame-Diagnose-Choose-Act strategic decision process. Exactly 4 boxes in this fixed ',
      'sequence: 1) Frame - define the strategic question/decision at stake, 2) Diagnose - analyze the ',
      'situation and root causes, 3) Choose - evaluate options and select a course of action, 4) Act - ',
      'implement and monitor. sub_text for each box must describe what this phase means SPECIFICALLY for ',
      'this topic, not the generic dictionary definition of the phase.\n\n'
    ),
    "pdca_cycle" = paste0(
      'FRAMEWORK = PDCA Cycle (a continuous-improvement loop). Exactly 4 outer segments in clockwise ',
      'order: Plan, Do, Check, Act. No center rings needed for this framework.\n\n'
    ),
    "strategic_planning_wheel" = paste0(
      'FRAMEWORK = Strategic Planning Wheel. Choose 5-8 outer segments representing the sequential phases ',
      'of a strategic planning cycle relevant to this topic (e.g. Situation Analysis, Goal Setting, ',
      'Strategy Formulation, Resource Allocation, Implementation, Monitoring & Review), arranged clockwise ',
      'in logical order.\n\n'
    ),
    "strategy_diamond" = paste0(
      'FRAMEWORK = Strategy Diamond (Hambrick & Fredrickson). Exactly 5 outer segments, in this fixed ',
      'order: Arenas (where will we be active?), Vehicles (how will we get there?), Differentiators (how ',
      'will we win?), Staging (what is our speed and sequence of moves?), Economic Logic (how will we ',
      'obtain our returns?). No center rings needed.\n\n'
    ),
    "five_forces" = paste0(
      'FRAMEWORK = Porter\'s Five Forces. Central node = the industry/market being analyzed. Exactly 5 ',
      'satellite nodes, in this fixed order: Competitive Rivalry, Threat of New Entrants, Bargaining Power ',
      'of Buyers, Bargaining Power of Suppliers, Threat of Substitutes. Each satellite\'s sub_text must give ',
      'a substantive, request-specific assessment of that force\'s intensity and why - not a generic ',
      'textbook definition.\n\n'
    ),
    "mckinsey_7s" = paste0(
      'FRAMEWORK = McKinsey 7S Framework. Central node = "Shared Values" (the organization\'s core values/',
      'culture). Exactly 6 satellite nodes, in this fixed order: Strategy, Structure, Systems, Skills, ',
      'Style, Staff. Each satellite\'s sub_text describes the current or desired state of that element for ',
      'this specific organization/topic.\n\n'
    ),
    "disruptive_innovation" = paste0(
      'FRAMEWORK = Disruptive Innovation Curve (Christensen). Two or three series over time: "Incumbent ',
      'Performance" (a line that improves steadily, often overshooting mainstream needs), "Disruptor ',
      'Performance" (starts below mainstream needs but improves faster, eventually crossing the incumbent), ',
      'and optionally a flat reference series "Mainstream Customer Needs" to show the crossover clearly. ',
      'X-axis = Time, Y-axis = Performance/Value Delivered.\n\n'
    ),
    "product_lifecycle" = paste0(
      'FRAMEWORK = Product Lifecycle Curve. One series ("Sales" or "Revenue") over time following the ',
      'classic bell/S-curve shape across 4 stages in order: Introduction (slow initial growth), Growth ',
      '(rapid increase), Maturity (plateau), Decline (fall-off). Use label_text on the point at each stage ',
      'transition to name that stage.\n\n'
    ),
    "kano_model" = paste0(
      'FRAMEWORK = Kano Model. Three series across shared X-axis "Feature Functionality/Investment" (Not ',
      'Implemented to Fully Implemented) and Y-axis "Customer Satisfaction" (Dissatisfied to Delighted): ',
      '"Basic/Must-Be" (flat-ish curve, low satisfaction ceiling regardless of investment, sharply negative ',
      'if absent), "Performance" (roughly linear - more investment steadily raises satisfaction), ',
      '"Excitement/Delighter" (starts flat near neutral, then rises sharply). Give each series a realistic ',
      '5-7 point shape matching this description, not straight lines for all three.\n\n'
    ),
    "value_curve" = paste0(
      'FRAMEWORK = Blue Ocean Strategy Value Curve. Each series is a competitor (or your own strategy) ',
      'being compared. The shared X-axis is a sequence of 5-8 industry competitive factors relevant to this ',
      'topic (each point\'s label_text names the factor), Y-axis is relative offering level (Low to High) ',
      'on that factor. Include your own strategy as one series and at least one incumbent/competitor as ',
      'another series so the curve shapes visibly diverge - that divergence is the whole point of this ',
      'chart.\n\n'
    ),
    "technology_adoption_lifecycle" = paste0(
      'FRAMEWORK = Technology Adoption Lifecycle (Diffusion of Innovation). Exactly 5 bars in this fixed ',
      'order, forming a bell-curve shape via their values: Innovators (~2.5), Early Adopters (~13.5), Early ',
      'Majority (~34), Late Majority (~34), Laggards (~16) - use these approximate percentages as ',
      'value_numeric unless the topic gives a clear reason to adjust them. unit_label = "%". Describe who ',
      'these segments are for THIS specific topic/product in sub_text (via items_packed).\n\n'
    ),
    "trend_to_commoditization" = paste0(
      'FRAMEWORK = Trend to Commoditization chart. Bars represent successive product/service generations ',
      'or time periods (label_text = generation/period name), value_numeric = a price or margin metric ',
      'that DECREASES across the sequence, illustrating commoditization pressure over time for this topic.\n\n'
    ),
    "economic_profit_mobility" = paste0(
      'FRAMEWORK = Economic Profit Mobility Funnel. Stages represent a population of companies/business ',
      'units narrowing through economic performance tiers over time, e.g.: "All Companies Analyzed" -> ',
      '"Above-Average Economic Profit" -> "Top Quintile Economic Profit" -> "Sustained Top Quintile (10yr)". ',
      'value_numeric = the count or percentage remaining at each stage, illustrating how few companies ',
      'sustain top-tier economic performance.\n\n'
    ),
    "active_waiting" = paste0(
      'FRAMEWORK = Active Waiting (balancing opportunity readiness against the downside risk of delaying a ',
      'strategic commitment). Two series over time: "Opportunity" (the upside case/option value of ',
      'waiting) and "Threat" (the downside risk/cost of delay) - these should generally trend in opposite ',
      'directions. Use label_text call-outs at the point where they cross or reach a decision trigger.\n\n'
    ),
    "business_model_canvas" = paste0(
      'FRAMEWORK = Business Model Canvas. Exactly 9 blocks at these FIXED (grid_row, grid_col) positions ',
      '(a 3-row x 5-column layout): Key Partners (1,1); Key Activities (1,2); Value Propositions (1,3); ',
      'Customer Relationships (1,4); Customer Segments (1,5); Key Resources (2,2); Channels (2,4); Cost ',
      'Structure (3,1); Revenue Streams (3,4). label_text = the block name exactly as given; items_packed = ',
      '2-4 specific points for this business.\n\n'
    ),
    "lean_canvas" = paste0(
      'FRAMEWORK = Lean Canvas. Exactly 9 blocks at these FIXED (grid_row, grid_col) positions (a 3-row x ',
      '5-column layout): Problem (1,1); Solution (1,2); Unique Value Proposition (1,3); Unfair Advantage ',
      '(1,4); Customer Segments (1,5); Key Metrics (2,2); Channels (2,4); Cost Structure (3,1); Revenue ',
      'Streams (3,4). label_text = the block name exactly as given; items_packed = 2-4 specific points for ',
      'this business.\n\n'
    ),
    "value_chain" = paste0(
      'FRAMEWORK = Porter\'s Value Chain. TWO categories of activities. Support Activities (exactly 4, ',
      'drawn along the top, sequence_order 1-4, layout_role="support_activity"): Firm Infrastructure, ',
      'Human Resource Management, Technology Development, Procurement. Primary Activities (exactly 5, ',
      'drawn along the bottom as a left-to-right sequence, sequence_order 1-5, ',
      'layout_role="primary_activity"): Inbound Logistics, Operations, Outbound Logistics, Marketing & ',
      'Sales, Service. Each activity\'s items_packed lists 2-3 specific actions/capabilities this ',
      'organization has or needs, specific to the topic. Also output exactly one final block: ',
      '[component_type]: margin_label [layout_role]: margin [label_text]: Margin - representing the value ',
      'captured (the classic value chain diagram\'s margin wedge).\n\n'
    ),
    ''  # unknown framework -> no extra guidance, generic shape instructions still apply
  )
}

# ---- Per-SHAPE mechanical format instructions - preloaded, never typed
#     by the user, always prepended (after the framework-specific
#     guidance above) to the free-text prompt. Each block spells out
#     exactly which fields to fill for that structural family, the
#     delimiter rule, and the field format so Claude's output is directly
#     copy-parseable by parse_diagram_text(). --------------------------
diagram_type_instructions <- function(diagram_type, diagram_group, category, domain, topic, title_hint) {
  sep <- DIAG_ITEM_SEP
  shape <- DIAGRAM_RENDER_SHAPE[[diagram_type]]
  if (is.null(shape)) stop("Unknown diagram_type (no render shape mapped): ", diagram_type)
  specific <- framework_specific_guidance(diagram_type)

  title_line <- if (nchar(trimws(title_hint %||% "")) > 0) {
    paste0('[', trimws(title_hint), ']')
  } else {
    '[<invent a concise, specific title for this diagram based on the user request>]'
  }

  common_header <- paste0(
    'You are generating the DATA for a strategy diagram, not a picture. Output ONLY the metadata block ',
    'below followed by bracket-tag component rows in the exact format specified - no markdown, no prose ',
    'commentary, no code fences.\n\n',

    '1. Start with EXACTLY 6 metadata lines, each on its own line. Each line must contain ONLY the actual ',
    'value wrapped in single square brackets - do NOT include a field name, label, or colon inside or around ',
    'the brackets. Lines 1-5 must be EXACTLY these values (they are fixed by the user\'s selection, not yours ',
    'to change); line 6 is the diagram title as instructed below. The first 6 lines of your entire response ',
    'must be EXACTLY:\n',
    '[', diagram_type, ']\n[', diagram_group, ']\n',
    '[', category, ']\n[', domain, ']\n[', topic, ']\n', title_line, '\n\n',

    '2. Leave exactly ONE blank line after the metadata block. Then output the component blocks. ',
    'Every component is its own block of "[field]: value" lines, separated by a single blank line from the ',
    'next component. Do not skip a field - if genuinely not applicable, write "N/A".\n\n',

    'CRITICAL: within [items_packed], separate multiple items with the EXACT literal token "', sep, '". ',
    'NEVER use "', sep, '" anywhere else - not in a label, not in a sentence, not for emphasis. ',
    'If you need a normal dash or separator inside real text, use a comma or a single hyphen instead.\n\n',

    specific
  )

  shape_block <- switch(shape,
    "grid" = paste0(
      'This diagram is drawn as a RECTANGULAR grid of ROWS and COLUMNS - the exact arrangement is given ',
      'above; do NOT default to a single row. For EACH cell, output one block with its ACTUAL 1-indexed ',
      '(grid_row, grid_col) position - these are real 2D coordinates the renderer places directly, not a ',
      'sequential counter:\n',
      '[component_type]: shape_rectangle\n[layout_role]: grid_cell\n[grid_row]: <this cell\'s actual row>\n',
      '[grid_col]: <this cell\'s actual column>\n',
      '[sequence_order]: <reading order: left-to-right within a row, then top-to-bottom>\n',
      '[label_text]: <header, exactly as specified above if this framework fixes the label, else a short header>\n',
      '[sub_text]: <single letter or icon glyph if applicable, else N/A>\n',
      '[items_packed]: <bullet 1>', sep, '<bullet 2>', sep, '<bullet 3>', sep, '<bullet 4>\n',
      '[color_hint]: <accent_blue|accent_orange|accent_green|accent_purple|neutral_dark, one distinct hint per cell>\n\n',
      'If the framework above calls for axis_label blocks, output them too:\n',
      '[component_type]: axis_label\n[layout_role]: axis\n[value_axis]: <x|y>\n[label_text]: <axis label>\n\n',
      'Also output exactly ONE title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "quadrant" = paste0(
      'Output exactly 4 blocks, one per quadrant (positions and names given above), plus one title block ',
      'and two axis-label blocks.\n\nFor EACH quadrant:\n',
      '[component_type]: region_quadrant\n[layout_role]: quadrant_region\n',
      '[quadrant_position]: <top_left|top_right|bottom_left|bottom_right>\n',
      '[label_text]: <quadrant name exactly as specified above>\n[sub_text]: <1-sentence definition>\n',
      '[items_packed]: <bullet 1>', sep, '<bullet 2> (N/A if none)\n',
      '[color_hint]: <distinct hint per quadrant>\n\n',
      'Axis blocks (exactly 2):\n[component_type]: axis_label\n[layout_role]: axis\n',
      '[value_axis]: <x|y>\n[label_text]: <axis label exactly as specified above>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "table" = paste0(
      'Output one block per cell using its ACTUAL 1-indexed grid_row/grid_col position (the layout is given ',
      'above) - these are real 2D coordinates the renderer places directly, not a sequential counter. Use ',
      'them for BOTH header cells and content cells.\n\nFor EACH cell:\n',
      '[component_type]: table_cell\n[layout_role]: grid_cell\n[grid_row]: <this cell\'s actual row>\n',
      '[grid_col]: <this cell\'s actual column>\n',
      '[label_text]: <cell header if this is a header row/col, else N/A>\n',
      '[items_packed]: <content item 1>', sep, '<content item 2> (N/A for pure header cells)\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "stacked_list" = paste0(
      'A vertical stack of N items (N given by the framework above), sequence_order = 1..N top to bottom.\n\n',
      'For EACH item:\n[component_type]: bullet_list_item\n[layout_role]: list_item\n',
      '[sequence_order]: <1..N>\n[label_text]: <level name>\n',
      '[sub_text]: <optional definition line, else N/A>\n[color_hint]: <accent color, can repeat across items>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "linear_flow" = paste0(
      'A horizontal left-to-right sequence of boxes (count and names given above), sequence_order = 1..N.\n\n',
      'For EACH box:\n[component_type]: shape_rectangle\n[layout_role]: node\n',
      '[sequence_order]: <1..N>\n[label_text]: <box name exactly as specified above>\n',
      '[sub_text]: <what this phase means specifically for this topic>\n',
      '[items_packed]: <sub-item 1>', sep, '<sub-item 2> (N/A if none)\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "radial" = paste0(
      'N segments arranged in a circle (count and names given above), sequence_order = 1..N clockwise, plus ',
      'optional concentric center rings if the framework calls for them.\n\n',
      'For EACH outer segment:\n[component_type]: region_quadrant\n[layout_role]: node\n',
      '[sequence_order]: <1..N clockwise>\n[label_text]: <segment name exactly as specified above>\n',
      '[sub_text]: <1-line descriptor specific to this topic>\n[color_hint]: <accent color>\n\n',
      'For EACH center ring, if any (innermost = highest sequence_order, e.g. N+1, N+2):\n',
      '[component_type]: shape_circle\n[layout_role]: node\n[sequence_order]: <N+1, N+2, ...>\n',
      '[label_text]: <ring label>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "network" = paste0(
      'One central node plus N satellite nodes (count and names given above).\n\n',
      'Central node (exactly one):\n[component_type]: shape_circle\n[layout_role]: node\n',
      '[sequence_order]: 0\n[label_text]: <central node name>\n\n',
      'For EACH satellite node:\n[component_type]: shape_rectangle\n[layout_role]: node\n',
      '[sequence_order]: <1..N, in the fixed order specified above>\n[label_text]: <satellite name exactly as specified above>\n',
      '[sub_text]: <substantive, request-specific description, else N/A>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "line_chart" = paste0(
      'One or more named series (per the framework above), each a sequence of (x,y) data points.\n\n',
      'Axis blocks (exactly 2):\n[component_type]: axis\n[layout_role]: axis\n',
      '[value_axis]: <x|y>\n[metric_name]: <axis name>\n[axis_type]: <linear|log|categorical|time>\n\n',
      'For EACH data point:\n[component_type]: data_point\n[layout_role]: node\n',
      '[series_name]: <which series this belongs to, exactly as named above>\n[sequence_order]: <point order along x>\n',
      '[value_axis]: x\n[value_numeric]: <x value>\n[label_text]: <category/stage label if applicable, else N/A>\n',
      '\n(repeat the same sequence_order/series_name with [value_axis]: y and the y value as a SEPARATE block)\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "bar_chart" = paste0(
      'Categories on X, one or more series (clustered bars) on Y, per the framework above.\n\n',
      'For EACH bar:\n[component_type]: data_point\n[layout_role]: node\n',
      '[series_name]: <cluster/series this bar belongs to>\n[label_text]: <category name, X-axis tick, exactly as specified above>\n',
      '[value_numeric]: <bar value>\n[unit_label]: <units>\n[color_hint]: <one per series>\n',
      '[items_packed]: <optional descriptive bullet(s) for this bar, else N/A>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "funnel" = paste0(
      'Ordered stages (per the framework above), sequence_order = 1..N, each with a value.\n\n',
      'For EACH stage:\n[component_type]: data_point\n[layout_role]: node\n',
      '[sequence_order]: <1..N>\n[label_text]: <stage name exactly as specified above>\n[value_numeric]: <stage value>\n',
      '[unit_label]: <units>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "dual_axis_timeseries" = paste0(
      'Two diverging series over time (named above).\n\n',
      'Axis blocks (exactly 2):\n[component_type]: axis\n[layout_role]: axis\n',
      '[value_axis]: <x|y>\n[metric_name]: <axis name>\n\n',
      'For EACH data point:\n[component_type]: data_point\n[layout_role]: node\n',
      '[series_name]: <series name exactly as specified above>\n',
      '[sequence_order]: <point order along x>\n[value_numeric]: <y value, signed>\n',
      '[label_text]: <callout label if this is a spike/inflection/crossover point, else N/A>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "business_model_canvas" = paste0(
      'Exactly 9 blocks at the FIXED (grid_row, grid_col) positions given above - these are real 2D ',
      'coordinates the renderer places directly.\n\n',
      'For EACH block:\n[component_type]: canvas_block\n[layout_role]: grid_cell\n',
      '[grid_row]: <this block\'s fixed row given above>\n[grid_col]: <this block\'s fixed column given above>\n',
      '[label_text]: <the block name, exactly as specified above>\n',
      '[items_packed]: <point 1>', sep, '<point 2>', sep, '<point 3>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "value_chain" = paste0(
      'Exactly 4 Support Activities plus exactly 5 Primary Activities plus one margin label, per the exact ',
      'names and order given above.\n\n',
      'For EACH support activity:\n[component_type]: shape_rectangle\n[layout_role]: support_activity\n',
      '[sequence_order]: <1..4, in the fixed order given above>\n[label_text]: <activity name exactly as specified above>\n',
      '[items_packed]: <capability 1>', sep, '<capability 2>\n\n',
      'For EACH primary activity:\n[component_type]: shape_rectangle\n[layout_role]: primary_activity\n',
      '[sequence_order]: <1..5, in the fixed order given above>\n[label_text]: <activity name exactly as specified above>\n',
      '[items_packed]: <capability 1>', sep, '<capability 2>\n\n',
      'Margin block (exactly one):\n[component_type]: margin_label\n[layout_role]: margin\n[label_text]: Margin\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    stop("Unknown render shape: ", shape)
  )

  paste0(common_header, shape_block)
}

generate_diagram_prompt <- function(diagram_type, diagram_group, category, domain, topic, title_hint, user_request) {
  type_instructions <- diagram_type_instructions(diagram_type, diagram_group, category, domain, topic, title_hint)

  paste0(
    'You are a strategy consultant building a "', DIAGRAM_TYPE_LABELS[[diagram_type]], '" (',
    DIAGRAM_GROUP_LABELS[[diagram_group]], ') diagram. ',
    'Category: ', category, '. Domain: ', domain, '. Topic: ', topic, '.\n\n',
    'The user\'s specific request: "', user_request, '"\n\n',
    'Populate the diagram with content genuinely specific to this request (not generic placeholder text) - ',
    'reason about the actual decision/situation described before writing labels and bullets.\n\n',
    type_instructions,
    '\n\nOutput format rules: one blank line between component blocks, no markdown headers, no numbering ',
    'outside the bracket fields, every field present on every block ("N/A" rather than omitting a line).\n\n',
    'Now generate the diagram, beginning with the 6 metadata lines.'
  )
}

# After generation, force-overwrite the metadata block's first 5 positional
# bare-bracket lines (diagram_type/diagram_group/category/domain/topic -
# fixed by the user's dropdown selection, never Claude's to change) back to
# the authoritative values, regardless of what Claude actually wrote. The
# 6th line (title) is only forced when the user supplied an explicit
# title_hint - otherwise Claude's own invented title (per the instruction
# in diagram_type_instructions) is left untouched. Mirrors the positional
# metadata convention used by Flex Table (parse_table_text) and Mind
# Map/Knowledge Graph above, rather than the old (and never actually
# emitted) "[field]: value" tag search.
overwrite_diagram_header <- function(text, diagram_type, diagram_group, category, domain, topic, title_override = NULL) {
  lines <- strsplit(text, "\n")[[1]]
  metadata_line_idx <- which(grepl("^\\[.+\\]$", trimws(lines)))
  metadata_line_idx <- head(metadata_line_idx, 6)

  values <- list(diagram_type, diagram_group, category, domain, topic, title_override)
  for (i in seq_along(metadata_line_idx)) {
    v <- values[[i]]
    if (!is.null(v) && !is.na(v) && nchar(trimws(v)) > 0) {
      lines[metadata_line_idx[i]] <- paste0("[", trimws(v), "]")
    }
  }
  paste(lines, collapse = "\n")
}

# Parser: mirrors parse_table_text()'s two-part structure exactly.
#
# Part 1 - METADATA: the first 6 bare "[value]" lines (no field name, no
# colon - matching Flex Table's positional metadata convention and Mind
# Map/Knowledge Graph's "N metadata lines" convention) give diagram_type/
# diagram_group/category/domain/topic/title. This means Bulk Import and any
# hand-pasted text carry their own classification - no separate dropdowns
# needed there, same as every other suite in this app.
#
# Part 2 - COMPONENTS: "[field]: value" tagged blocks, blank-line (or bare
# "[...]" metadata line) separated.
#
# IMPORTANT SCOPING NOTE: a `for` loop does NOT create a new environment in
# R, so code directly inside the loop body uses plain `<-` to modify
# `current`/`last_field` (they live in THIS function's frame already).
# `<<-` is reserved for flush_block()'s own body, since flush_block is a
# genuinely nested closure and needs superassignment to reach back into
# this function's `blocks`. Mixing `<<-` into the top-level loop itself
# (the original bug here) makes R search from the PARENT of this function
# instead of this function's own frame - it creates or mutates an
# unrelated variable up the call stack rather than the local `current`,
# and the first attempted read-modify-write (`current[[field]] <<- value`)
# throws exactly "object 'current' not found" because there was nothing to
# read at that outer scope yet. parse_table_text's flush_entry() above
# gets this right (plain `<-` in the loop, `<<-` only inside flush_entry) -
# this function now follows the same pattern.
parse_diagram_text <- function(text, diagram_id, is_template = FALSE, source_diagram_id = NA, created_by = "claude_agent") {
  lines <- strsplit(text, "\n")[[1]]

  # ---- Part 1: metadata block (diagram_type, diagram_group, category, domain, topic, title) ----
  diagram_type <- NULL; diagram_group <- NULL; category <- NULL; domain <- NULL; topic <- NULL; title <- NULL
  metadata_count <- 0
  for (i in seq_len(min(20, length(lines)))) {
    line <- trimws(lines[i])
    if (grepl("^\\[.+\\]$", line)) {
      metadata_count <- metadata_count + 1
      value <- gsub("^\\[|\\]$", "", line)
      if (metadata_count == 1) diagram_type <- value
      else if (metadata_count == 2) diagram_group <- value
      else if (metadata_count == 3) category <- value
      else if (metadata_count == 4) domain <- value
      else if (metadata_count == 5) topic <- value
      else if (metadata_count == 6) title <- value
      else break
    }
  }
  if (is.null(diagram_type) || !diagram_type %in% DIAGRAM_TYPES) {
    stop("Could not find a valid diagram type in the first metadata line of the generated text (expected one of: ",
         paste(DIAGRAM_TYPES, collapse = ", "), ")")
  }
  if (is.null(diagram_group) || !diagram_group %in% DIAGRAM_GROUPS) {
    stop("Could not find a valid diagram group in the second metadata line (expected one of: ",
         paste(DIAGRAM_GROUPS, collapse = ", "), "). If this text was generated before the framework catalog ",
         "update, it used an older 5-line metadata format and needs to be regenerated.")
  }
  if (is.null(category) || is.null(domain) || is.null(topic)) {
    stop("Could not find Category, Domain, and Topic metadata in the generated diagram text")
  }
  if (is.null(title) || nchar(trimws(title)) == 0) title <- topic
  diagram_name <- DIAGRAM_TYPE_LABELS[[diagram_type]]

  # ---- Part 2: component blocks ("[field]: value" tags) ----
  blocks <- list()
  current <- list()
  last_field <- NULL

  flush_block <- function() {
    if (length(current) > 0 && !is.null(current$component_type)) {
      blocks[[length(blocks) + 1]] <<- current
    }
  }

  for (line in lines) {
    line <- trimws(line)

    # A blank line OR a bare "[...]" metadata-style line both close the
    # current block (the latter matters because the 5 metadata lines at
    # the top would otherwise be silently absorbed as continuation text
    # of nothing, since they're processed by this same loop).
    if (line == "" || grepl("^\\[.+\\]$", line)) {
      flush_block()
      current <- list()
      last_field <- NULL
      next
    }

    matched <- FALSE
    for (field in DIAGRAM_FIELDS) {
      pat <- paste0("^\\[", field, "\\]:\\s*(.*)$")
      if (grepl(pat, line, ignore.case = TRUE)) {
        value <- trimws(sub(pat, "\\1", line, ignore.case = TRUE))
        if (field == "component_type" && !is.null(current$component_type)) {
          flush_block()
          current <- list()
        }
        current[[field]] <- value
        last_field <- field
        matched <- TRUE
        break
      }
    }
    if (!matched && length(current) > 0 && !is.null(last_field)) {
      current[[last_field]] <- paste(current[[last_field]], line)
    }
  }
  flush_block()

  if (length(blocks) == 0) stop("No valid diagram component blocks found in text")

  df <- data.frame(
    diagram_id = character(), diagram_name = character(), diagram_type = character(), diagram_group = character(),
    category = character(), domain = character(), topic = character(), title = character(), is_template = logical(),
    source_diagram_id = character(),
    component_type = character(), layout_role = character(),
    grid_row = integer(), grid_col = integer(), quadrant_position = character(), sequence_order = integer(),
    z_index = integer(), pos_x = numeric(), pos_y = numeric(), width = numeric(), height = numeric(),
    label_text = character(), sub_text = character(), items_packed = character(),
    value_numeric = numeric(), value_axis = character(), series_name = character(), unit_label = character(),
    axis_type = character(), axis_min = numeric(), axis_max = numeric(), metric_name = character(),
    color_hint = character(), icon_name = character(), created_by = character(),
    stringsAsFactors = FALSE
  )

  na_int <- function(x) suppressWarnings(as.integer(x %||% NA))
  na_num <- function(x) suppressWarnings(as.numeric(x %||% NA))

  for (b in blocks) {
    df <- rbind(df, data.frame(
      diagram_id = diagram_id, diagram_name = diagram_name, diagram_type = diagram_type, diagram_group = diagram_group,
      category = category, domain = domain, topic = topic, title = title, is_template = is_template,
      source_diagram_id = as.character(source_diagram_id %||% NA),
      component_type = b$component_type %||% "", layout_role = b$layout_role %||% "",
      grid_row = na_int(b$grid_row), grid_col = na_int(b$grid_col),
      quadrant_position = b$quadrant_position %||% NA_character_, sequence_order = na_int(b$sequence_order),
      z_index = na_int(b$z_index), pos_x = NA_real_, pos_y = NA_real_, width = NA_real_, height = NA_real_,
      label_text = b$label_text %||% "", sub_text = b$sub_text %||% "", items_packed = b$items_packed %||% "",
      value_numeric = na_num(b$value_numeric), value_axis = b$value_axis %||% NA_character_,
      series_name = b$series_name %||% NA_character_, unit_label = b$unit_label %||% NA_character_,
      axis_type = b$axis_type %||% NA_character_, axis_min = na_num(b$axis_min), axis_max = na_num(b$axis_max),
      metric_name = b$metric_name %||% NA_character_,
      color_hint = b$color_hint %||% NA_character_, icon_name = b$icon_name %||% NA_character_,
      created_by = created_by,
      stringsAsFactors = FALSE
    ))
  }
  df
}

# Splits a packed items string back into a character vector for
# rendering. Empty/NA/"N/A" -> character(0).
diagram_unpack_items <- function(items_packed) {
  if (!has_real_value(items_packed)) return(character(0))
  trimws(strsplit(items_packed, DIAG_ITEM_SEP, fixed = TRUE)[[1]])
}

# ============================================================
# STRATEGIC ANALYSIS DROPDOWNS
# ============================================================
# Category/Domain/Topic classification reuses the SAME shared
# category_domain_topic_dropdown_ui()/setup_category_domain_topic_cascade()
# helpers defined above for Mind Map/Knowledge Graph - no diagram-specific
# cascade needed. Call sites pass this suite's own method/field names:
#   category_domain_topic_dropdown_ui(ns)
#   setup_category_domain_topic_cascade(input, output, session, api_manager,
#     taxonomy_method = "bq_get_diagram_taxonomy",
#     empty_taxonomy_method = "empty_diagram_taxonomy",
#     state_trigger_field = "state_trigger_diagram")
# This gives Generate/Add Single the same 3-level "+Add New at every level"
# UX as every other classified suite in this app, backed by this suite's
# own diagram_taxonomy_cache/state_trigger_diagram (never cross-firing
# another suite's dropdowns).
#
# diagram_group/diagram_type are a SEPARATE two-level selector (which
# strategy-framework family, then which specific named framework within
# it) - not part of the Category/Domain/Topic classification hierarchy.
# Mirrors Six Sigma's sixsigma_group_dropdown_ui()/sixsigma_type_dropdown_ui()/
# setup_sixsigma_group_type_cascade() exactly: Group narrows the ~27
# frameworks down to the handful relevant to that strategic lens, so the
# Framework dropdown never shows an unmanageable flat list.
diagram_group_dropdown_ui <- function(ns) {
  selectInput(ns("diagram_group_select"), "Diagram Group (strategic lens): *",
              choices = setNames(DIAGRAM_GROUPS, DIAGRAM_GROUP_LABELS[DIAGRAM_GROUPS]))
}

diagram_type_dropdown_ui <- function(ns) {
  selectInput(ns("diagram_type_select"), "Framework (specific diagram): *", choices = NULL)
}

# Wires the Framework dropdown's choices to whichever Group is currently
# selected. Called once per module that shows both dropdowns.
setup_diagram_group_type_cascade <- function(input, output, session) {
  observeEvent(input$diagram_group_select, {
    grp <- input$diagram_group_select
    types <- DIAGRAM_TYPES_BY_GROUP[[grp]]
    if (is.null(types) || length(types) == 0) {
      updateSelectInput(session, "diagram_type_select", choices = c("(no frameworks in this group)" = ""))
    } else {
      updateSelectInput(session, "diagram_type_select",
                        choices = setNames(types, DIAGRAM_TYPE_LABELS[types]))
    }
  }, ignoreNULL = FALSE)
}

# NOTE ON VISUALIZATIONS/BROWSE: the actual diagram-picker cascade (Category
# -> Domain -> Topic -> Diagram) is implemented directly inside
# diagram_visualizations/server.R as FOUR separate, chained selectInputs -
# deliberately NOT a single dropdown with concatenated labels like
# "Grid - Hedge Fund Startup AI SWOT (generated)". A mega-dropdown that
# concatenates every field becomes unusable once there are more than a
# handful of diagrams; four small chained dropdowns (mirroring
# visualize_kg_d3/server.R's own Category -> Domain -> Topic -> Graph
# Version cascade exactly) keep each list short and let the person narrow
# down step by step, the same way every other suite's Visualize/Browse tab
# already works in this app.

# ============================================================
# STRATEGIC ANALYSIS - GENERIC RENDERERS
# ============================================================
# One dispatcher, three renderer families - see the design note at the
# top of this section for why each family uses the tool it uses. Every
# renderer takes the SAME components_df shape returned by
# bq_get_diagram_components() and NEVER trusts pos_x/pos_y for initial
# layout - geometry is always computed from grid_row/grid_col/
# quadrant_position/sequence_order.

render_diagram <- function(components_df, diagram_type) {
  shape <- DIAGRAM_RENDER_SHAPE[[diagram_type]] %||% diagram_type
  cat(sprintf("🎨 [Strategic Analysis][DEBUG] Rendering diagram_type=%s (shape=%s) with %d component row(s)\n",
              diagram_type, shape, nrow(components_df)))

  if (nrow(components_df) == 0) {
    return(tags$div(class = "status-warning", "No components found for this diagram."))
  }

  html_family <- c("grid", "quadrant", "table", "stacked_list", "linear_flow", "business_model_canvas", "value_chain")
  svg_family <- c("radial", "network")
  plotly_family <- c("line_chart", "bar_chart", "funnel", "dual_axis_timeseries")

  if (shape %in% html_family) {
    cat("🎨 [Strategic Analysis][DEBUG] Dispatching to render_diagram_html_grid()\n")
    render_diagram_html_grid(components_df, shape)
  } else if (shape %in% svg_family) {
    cat("🎨 [Strategic Analysis][DEBUG] Dispatching to render_diagram_svg()\n")
    render_diagram_svg(components_df, shape)
  } else if (shape %in% plotly_family) {
    cat("🎨 [Strategic Analysis][DEBUG] Dispatching to render_diagram_plotly()\n")
    render_diagram_plotly(components_df, shape)
  } else {
    tags$div(class = "status-error", sprintf("Unknown diagram_type/shape: %s / %s", diagram_type, shape))
  }
}

# HTML/CSS Grid family (grid, quadrant, table, stacked_list, linear_flow):
# layout comes from CSS Grid/Flexbox, not from any position field Claude
# wrote - the browser's layout engine makes overlap impossible by
# construction. Uses the same HTML-fragment-string + HTML() pattern as
# Flex Table's table_viewer/server.R.
render_diagram_html_grid <- function(components_df, diagram_type) {
  title_row <- components_df[components_df$component_type == "title", , drop = FALSE]
  title_text <- if (nrow(title_row) > 0) title_row$label_text[1] else components_df$diagram_name[1]
  body_rows <- components_df[components_df$component_type != "title", , drop = FALSE]

  html_parts <- c(sprintf('<div class="diagram-card"><div class="chapter-title"><i class="fa fa-project-diagram"></i> %s</div>', htmltools::htmlEscape(title_text)))

  if (diagram_type == "linear_flow") {
    # Genuinely sequential - a single row, DOM order = sequence_order.
    ordered <- body_rows[order(body_rows$sequence_order), , drop = FALSE]
    n_cols <- max(ordered$sequence_order, 1, na.rm = TRUE)
    html_parts <- c(html_parts, sprintf('<div class="diagram-grid" style="grid-template-columns: repeat(%d, 1fr);">', n_cols))
    for (i in seq_len(nrow(ordered))) {
      row <- ordered[i, ]
      items <- diagram_unpack_items(row$items_packed)
      items_html <- if (length(items) > 0) {
        paste0('<ul class="diagram-item-list">', paste0('<li>', htmltools::htmlEscape(items), '</li>', collapse = ""), '</ul>')
      } else ""
      color_style <- if (has_real_value(row$color_hint)) sprintf(' data-color-hint="%s"', row$color_hint) else ""
      html_parts <- c(html_parts, sprintf(
        '<div class="diagram-cell"%s><div class="section-tag">%s</div>%s%s</div>',
        color_style,
        htmltools::htmlEscape(row$label_text %||% ""),
        if (has_real_value(row$sub_text)) sprintf('<div class="details-text">%s</div>', htmltools::htmlEscape(row$sub_text)) else "",
        items_html
      ))
    }
    html_parts <- c(html_parts, '</div>')

  } else if (diagram_type %in% c("grid", "table")) {
    # TRUE 2D placement: every cell gets an EXPLICIT CSS grid-row/grid-column
    # position taken directly from Claude's own (grid_row, grid_col)
    # assignment, rather than relying on document order in a single row of
    # N columns. This is what makes a 4-cell SWOT render as an actual 2x2
    # square (not a 1x4 strip), a 6-cell PESTEL as 2x3, etc. - whatever
    # rows x columns arrangement diagram_type_instructions() asked Claude
    # to use for that specific framework.
    cell_rows <- body_rows[body_rows$component_type != "axis_label", , drop = FALSE]
    axis_rows <- body_rows[body_rows$component_type == "axis_label", , drop = FALSE]

    # Some frameworks in this shape (e.g. GE-McKinsey Nine-Box) also carry
    # axis labels, exactly like the quadrant family - shown as simple
    # captions above/beside the grid rather than full quadrant axis bars,
    # since a 3x3 (or larger) grid doesn't have the same fixed 4-corner
    # geometry a quadrant does.
    if (nrow(axis_rows) > 0) {
      y_label <- axis_rows$label_text[axis_rows$value_axis == "y"][1] %||% ""
      x_label <- axis_rows$label_text[axis_rows$value_axis == "x"][1] %||% ""
      if (has_real_value(y_label)) {
        html_parts <- c(html_parts, sprintf('<div class="diagram-axis-label diagram-axis-y">%s</div>', htmltools::htmlEscape(y_label)))
      }
    }

    n_rows <- max(cell_rows$grid_row, 1, na.rm = TRUE)
    n_cols <- max(cell_rows$grid_col, 1, na.rm = TRUE)
    html_parts <- c(html_parts, sprintf(
      '<div class="diagram-grid" style="grid-template-columns: repeat(%d, 1fr); grid-template-rows: repeat(%d, auto);">',
      n_cols, n_rows
    ))

    ordered <- cell_rows[order(cell_rows$grid_row, cell_rows$grid_col, cell_rows$sequence_order), , drop = FALSE]
    for (i in seq_len(nrow(ordered))) {
      row <- ordered[i, ]
      items <- diagram_unpack_items(row$items_packed)
      items_html <- if (length(items) > 0) {
        paste0('<ul class="diagram-item-list">', paste0('<li>', htmltools::htmlEscape(items), '</li>', collapse = ""), '</ul>')
      } else ""
      color_style <- if (has_real_value(row$color_hint)) sprintf(' data-color-hint="%s"', row$color_hint) else ""
      # Fall back gracefully if Claude ever omits grid_row/grid_col despite
      # the instructions - place sequentially rather than crashing/hiding.
      grid_row_val <- if (!is.na(row$grid_row)) row$grid_row else 1
      grid_col_val <- if (!is.na(row$grid_col)) row$grid_col else i
      html_parts <- c(html_parts, sprintf(
        '<div class="diagram-cell" style="grid-row: %d; grid-column: %d;"%s><div class="section-tag">%s</div>%s%s</div>',
        grid_row_val, grid_col_val, color_style,
        htmltools::htmlEscape(row$label_text %||% ""),
        if (has_real_value(row$sub_text)) sprintf('<div class="details-text">%s</div>', htmltools::htmlEscape(row$sub_text)) else "",
        items_html
      ))
    }
    html_parts <- c(html_parts, '</div>')

    if (nrow(axis_rows) > 0) {
      x_label <- axis_rows$label_text[axis_rows$value_axis == "x"][1] %||% ""
      if (has_real_value(x_label)) {
        html_parts <- c(html_parts, sprintf('<div class="diagram-axis-label diagram-axis-x">%s</div>', htmltools::htmlEscape(x_label)))
      }
    }

  } else if (diagram_type == "business_model_canvas") {
    # 9-block canvas (Business Model Canvas / Lean Canvas) - a fixed
    # 3-row x 5-column CSS grid where Claude supplies each block's
    # (grid_row, grid_col) per the exact layout given in
    # framework_specific_guidance(). Same "explicit CSS placement, never
    # trust sequential order" principle as the grid/table shape above.
    n_rows <- max(body_rows$grid_row, 1, na.rm = TRUE)
    n_cols <- max(body_rows$grid_col, 1, na.rm = TRUE)
    html_parts <- c(html_parts, sprintf(
      '<div class="diagram-grid diagram-bmc-grid" style="grid-template-columns: repeat(%d, 1fr); grid-template-rows: repeat(%d, auto);">',
      n_cols, n_rows
    ))
    ordered <- body_rows[order(body_rows$grid_row, body_rows$grid_col), , drop = FALSE]
    for (i in seq_len(nrow(ordered))) {
      row <- ordered[i, ]
      items <- diagram_unpack_items(row$items_packed)
      items_html <- if (length(items) > 0) {
        paste0('<ul class="diagram-item-list">', paste0('<li>', htmltools::htmlEscape(items), '</li>', collapse = ""), '</ul>')
      } else ""
      grid_row_val <- if (!is.na(row$grid_row)) row$grid_row else 1
      grid_col_val <- if (!is.na(row$grid_col)) row$grid_col else i
      html_parts <- c(html_parts, sprintf(
        '<div class="diagram-cell diagram-bmc-block" style="grid-row: %d; grid-column: %d;"><div class="section-tag">%s</div>%s</div>',
        grid_row_val, grid_col_val, htmltools::htmlEscape(row$label_text %||% ""), items_html
      ))
    }
    html_parts <- c(html_parts, '</div>')

  } else if (diagram_type == "value_chain") {
    # Porter's Value Chain - support activities as horizontal bars along
    # the top (sequence_order 1-4), primary activities as a left-to-right
    # arrow sequence along the bottom (sequence_order 1-5), plus a margin
    # wedge on the right. Genuinely different geometry from every other
    # shape - own dedicated CSS classes (.diagram-vc-*).
    support_rows <- body_rows[body_rows$layout_role == "support_activity", , drop = FALSE]
    support_rows <- support_rows[order(support_rows$sequence_order), , drop = FALSE]
    primary_rows <- body_rows[body_rows$layout_role == "primary_activity", , drop = FALSE]
    primary_rows <- primary_rows[order(primary_rows$sequence_order), , drop = FALSE]
    margin_row <- body_rows[body_rows$component_type == "margin_label", , drop = FALSE]

    render_vc_block <- function(row, css_class) {
      items <- diagram_unpack_items(row$items_packed)
      items_html <- if (length(items) > 0) paste0('<ul class="diagram-item-list">', paste0('<li>', htmltools::htmlEscape(items), '</li>', collapse = ""), '</ul>') else ""
      sprintf('<div class="%s"><div class="section-tag">%s</div>%s</div>', css_class, htmltools::htmlEscape(row$label_text %||% ""), items_html)
    }

    html_parts <- c(html_parts, '<div class="diagram-vc-wrapper">')
    html_parts <- c(html_parts, '<div class="diagram-vc-support-row">')
    for (i in seq_len(nrow(support_rows))) html_parts <- c(html_parts, render_vc_block(support_rows[i, ], "diagram-vc-support"))
    html_parts <- c(html_parts, '</div>')

    html_parts <- c(html_parts, '<div class="diagram-vc-primary-row">')
    for (i in seq_len(nrow(primary_rows))) html_parts <- c(html_parts, render_vc_block(primary_rows[i, ], "diagram-vc-primary"))
    margin_label <- if (nrow(margin_row) > 0) margin_row$label_text[1] else "Margin"
    html_parts <- c(html_parts, sprintf('<div class="diagram-vc-margin"><span>%s</span></div>', htmltools::htmlEscape(margin_label)))
    html_parts <- c(html_parts, '</div>')
    html_parts <- c(html_parts, '</div>')

  } else if (diagram_type == "quadrant") {
    quad_rows <- body_rows[body_rows$component_type == "region_quadrant", , drop = FALSE]
    axis_rows <- body_rows[body_rows$component_type == "axis_label", , drop = FALSE]
    x_label <- axis_rows$label_text[axis_rows$value_axis == "x"][1] %||% ""
    y_label <- axis_rows$label_text[axis_rows$value_axis == "y"][1] %||% ""

    html_parts <- c(html_parts, sprintf('<div class="diagram-axis-label diagram-axis-y">%s</div>', htmltools::htmlEscape(y_label)))
    html_parts <- c(html_parts, '<div class="diagram-quadrant-grid">')
    for (pos in c("top_left", "top_right", "bottom_left", "bottom_right")) {
      row <- quad_rows[quad_rows$quadrant_position == pos, , drop = FALSE]
      if (nrow(row) == 0) { html_parts <- c(html_parts, '<div class="diagram-quadrant-cell"></div>'); next }
      row <- row[1, ]
      items <- diagram_unpack_items(row$items_packed)
      items_html <- if (length(items) > 0) paste0('<ul class="diagram-item-list">', paste0('<li>', htmltools::htmlEscape(items), '</li>', collapse = ""), '</ul>') else ""
      html_parts <- c(html_parts, sprintf(
        '<div class="diagram-quadrant-cell" data-quadrant="%s"><div class="section-tag">%s</div><div class="details-text">%s</div>%s</div>',
        pos, htmltools::htmlEscape(row$label_text %||% ""), htmltools::htmlEscape(row$sub_text %||% ""), items_html
      ))
    }
    html_parts <- c(html_parts, '</div>')
    html_parts <- c(html_parts, sprintf('<div class="diagram-axis-label diagram-axis-x">%s</div>', htmltools::htmlEscape(x_label)))

  } else if (diagram_type == "stacked_list") {
    ordered <- body_rows[order(body_rows$sequence_order), , drop = FALSE]
    html_parts <- c(html_parts, '<div class="diagram-stacked-list">')
    for (i in seq_len(nrow(ordered))) {
      row <- ordered[i, ]
      html_parts <- c(html_parts, sprintf(
        '<div class="diagram-list-bar" data-color-hint="%s"><span class="diagram-list-bar-label">%s</span>%s</div>',
        row$color_hint %||% "neutral_dark",
        htmltools::htmlEscape(row$label_text %||% ""),
        if (has_real_value(row$sub_text)) sprintf('<div class="details-text">%s</div>', htmltools::htmlEscape(row$sub_text)) else ""
      ))
    }
    html_parts <- c(html_parts, '</div>')
  }

  html_parts <- c(html_parts, '</div>')
  HTML(paste(html_parts, collapse = ""))
}

# SVG family (radial, network) - geometry (angles, node coordinates)
# computed server-side in R via trigonometry, using sequence_order only.
# Claude never supplies a coordinate for these.
#
# Text handling: SVG <text> elements cannot wrap, so every node's label is
# rendered inside a <foreignObject> containing a normal HTML div - which
# DOES wrap - sized generously enough for full framework labels (e.g.
# "Bargaining Power of Suppliers") with no truncation. sub_text (the
# detailed explanation Claude writes) is genuinely too long to fit inside
# a small circle/rectangle regardless of size, so it is NOT crammed into
# the shape - instead: (1) a native SVG <title> element gives a hover
# tooltip with the full label + sub_text at zero JS cost, and (2) an
# always-visible "Details" panel is rendered below the diagram listing
# every node's full label and sub_text as plain text - this is the
# guaranteed path to reading everything Claude wrote, since hover tooltips
# don't work on touch devices.
render_diagram_svg <- function(components_df, diagram_type) {
  title_row <- components_df[components_df$component_type == "title", , drop = FALSE]
  title_text <- if (nrow(title_row) > 0) title_row$label_text[1] else components_df$diagram_name[1]
  nodes <- components_df[components_df$layout_role == "node", , drop = FALSE]

  details_items <- character(0)

  add_detail <- function(label, sub_text) {
    if (has_real_value(sub_text)) {
      details_items[length(details_items) + 1] <<- sprintf(
        '<div class="diagram-cell" style="margin-bottom:10px;"><div class="section-tag">%s</div><div class="details-text">%s</div></div>',
        htmltools::htmlEscape(label %||% ""), htmltools::htmlEscape(sub_text)
      )
    }
  }

  if (diagram_type == "radial") {
    # component_type distinguishes outer segments (region_quadrant) from
    # optional center rings (shape_circle) - more robust than inferring
    # from sequence_order, since both kinds share the "node" layout_role.
    outer <- nodes[nodes$component_type == "region_quadrant", , drop = FALSE]
    outer <- outer[order(outer$sequence_order), , drop = FALSE]
    n <- nrow(outer)

    box_w <- 160; box_h <- 64
    # Radius scales with node count and box size so boxes never overlap,
    # rather than a fixed radius that only happens to work for small n.
    r_outer <- max(230, (box_w * n) / (2 * pi) * 1.35)
    W <- r_outer * 2 + box_w + 40
    H <- W
    cx <- W / 2; cy <- H / 2

    svg_nodes <- character(0)
    if (n > 0) {
      for (i in seq_len(n)) {
        angle <- (2 * pi * (i - 1) / n) - pi / 2
        x <- cx + r_outer * cos(angle); y <- cy + r_outer * sin(angle)
        label <- outer$label_text[i] %||% ""
        tooltip <- if (has_real_value(outer$sub_text[i])) paste0(label, ": ", outer$sub_text[i]) else label
        svg_nodes <- c(svg_nodes, sprintf(
          '<g><title>%s</title>
           <rect x="%.1f" y="%.1f" width="%d" height="%d" rx="14" fill="var(--diagram-accent-teal, #008A82)" />
           <foreignObject x="%.1f" y="%.1f" width="%d" height="%d"><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;align-items:center;justify-content:center;height:100%%;text-align:center;color:white;font-size:12px;font-weight:600;padding:6px;line-height:1.25;box-sizing:border-box;">%s</div></foreignObject></g>',
          htmltools::htmlEscape(tooltip),
          x - box_w / 2, y - box_h / 2, box_w, box_h,
          x - box_w / 2, y - box_h / 2, box_w, box_h,
          htmltools::htmlEscape(label)
        ))
        add_detail(label, outer$sub_text[i])
      }
    }

    center_r <- 85
    svg <- sprintf(
      '<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">
         %s
         <circle cx="%.1f" cy="%.1f" r="%d" fill="var(--diagram-accent-dark, #002C3C)" />
         <foreignObject x="%.1f" y="%.1f" width="%d" height="%d"><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;align-items:center;justify-content:center;height:100%%;text-align:center;color:white;font-size:13px;font-weight:bold;padding:10px;line-height:1.3;box-sizing:border-box;">%s</div></foreignObject>
       </svg>',
      W, H, paste(svg_nodes, collapse = ""), cx, cy, center_r,
      cx - center_r + 8, cy - center_r + 8, (center_r - 8) * 2, (center_r - 8) * 2,
      htmltools::htmlEscape(title_text)
    )

  } else { # network
    satellites <- nodes[nodes$sequence_order > 0, , drop = FALSE]
    satellites <- satellites[order(satellites$sequence_order), , drop = FALSE]
    n <- nrow(satellites)

    box_w <- 190; box_h <- 78
    r <- max(260, (box_w * n) / (2 * pi) * 1.35)
    W <- r * 2 + box_w + 40
    H <- W
    cx <- W / 2; cy <- H / 2

    svg_edges <- character(0); svg_nodes <- character(0)
    if (n > 0) {
      for (i in seq_len(n)) {
        angle <- (2 * pi * (i - 1) / n) - pi / 2
        x <- cx + r * cos(angle); y <- cy + r * sin(angle)
        label <- satellites$label_text[i] %||% ""
        tooltip <- if (has_real_value(satellites$sub_text[i])) paste0(label, ": ", satellites$sub_text[i]) else label
        svg_edges <- c(svg_edges, sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#999" stroke-width="2" />', cx, cy, x, y))
        svg_nodes <- c(svg_nodes, sprintf(
          '<g><title>%s</title>
           <rect x="%.1f" y="%.1f" width="%d" height="%d" rx="10" fill="var(--diagram-accent-teal, #008A82)" />
           <foreignObject x="%.1f" y="%.1f" width="%d" height="%d"><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;align-items:center;justify-content:center;height:100%%;text-align:center;color:white;font-size:12px;font-weight:600;padding:6px;line-height:1.25;box-sizing:border-box;">%s</div></foreignObject></g>',
          htmltools::htmlEscape(tooltip),
          x - box_w / 2, y - box_h / 2, box_w, box_h,
          x - box_w / 2, y - box_h / 2, box_w, box_h,
          htmltools::htmlEscape(label)
        ))
        add_detail(label, satellites$sub_text[i])
      }
    }

    central <- nodes[nodes$sequence_order == 0, , drop = FALSE]
    central_label <- if (nrow(central) > 0) central$label_text[1] else title_text
    center_r <- 85
    svg <- sprintf(
      '<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">
         %s
         <circle cx="%.1f" cy="%.1f" r="%d" fill="var(--diagram-accent-dark, #002C3C)" />
         <foreignObject x="%.1f" y="%.1f" width="%d" height="%d"><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;align-items:center;justify-content:center;height:100%%;text-align:center;color:white;font-size:13px;font-weight:bold;padding:10px;line-height:1.3;box-sizing:border-box;">%s</div></foreignObject>
         %s
       </svg>',
      W, H, paste(svg_edges, collapse = ""), cx, cy, center_r,
      cx - center_r + 8, cy - center_r + 8, (center_r - 8) * 2, (center_r - 8) * 2,
      htmltools::htmlEscape(central_label), paste(svg_nodes, collapse = "")
    )
  }

  details_panel <- if (length(details_items) > 0) {
    tagList(
      tags$div(class = "chapter-title", style = "font-size: 1.05em; margin-top: 24px;",
               tags$i(class = "fa fa-list-ul"), " Details"),
      tags$div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 10px;",
               HTML(paste(details_items, collapse = "")))
    )
  } else NULL

  tagList(
    tags$div(class = "diagram-card",
      tags$div(class = "chapter-title", tags$i(class = "fa fa-project-diagram"), " ", title_text),
      HTML(svg),
      details_panel
    )
  )
}

# plotly family (line_chart, bar_chart, funnel, dual_axis_timeseries) -
# real numeric axes; plotly's own auto-scaling/legend/collision handling
# does the work here, matching Book Summary's existing visualizations tab.
render_diagram_plotly <- function(components_df, diagram_type) {
  title_row <- components_df[components_df$component_type == "title", , drop = FALSE]
  title_text <- if (nrow(title_row) > 0) title_row$label_text[1] else components_df$diagram_name[1]
  points <- components_df[components_df$component_type == "data_point", , drop = FALSE]

  p <- plotly::plot_ly()

  if (diagram_type == "line_chart" || diagram_type == "dual_axis_timeseries") {
    series_names <- unique(points$series_name)
    for (s in series_names) {
      sub <- points[points$series_name == s, , drop = FALSE]
      x_vals <- sub$value_numeric[sub$value_axis == "x"]
      y_vals <- sub$value_numeric[sub$value_axis == "y"]
      if (diagram_type == "dual_axis_timeseries" && length(x_vals) == 0) {
        # dual_axis_timeseries points carry only a y value + sequence_order as x
        x_vals <- sub$sequence_order[order(sub$sequence_order)]
        y_vals <- sub$value_numeric[order(sub$sequence_order)]
      }
      if (length(x_vals) == length(y_vals) && length(x_vals) > 0) {
        p <- plotly::add_trace(p, x = x_vals, y = y_vals, name = s, type = "scatter", mode = "lines+markers")
      }
    }
  } else if (diagram_type == "bar_chart") {
    p <- plotly::plot_ly(points, x = ~label_text, y = ~value_numeric, color = ~series_name, type = "bar")
  } else if (diagram_type == "funnel") {
    ordered <- points[order(points$sequence_order), , drop = FALSE]
    p <- plotly::plot_ly(ordered, y = ~label_text, x = ~value_numeric, type = "funnel")
  }

  p <- plotly::layout(p, title = title_text)

  tagList(
    tags$div(class = "chapter-title", tags$i(class = "fa fa-chart-line"), " ", title_text),
    p
  )
}

# ============================================================
# SIX SIGMA ANALYSIS (AI-generated Six Sigma diagrams)
# ============================================================
# Same architecture discipline as Strategic Analysis above (own table,
# own state/taxonomy/bulk-handoff scoping, own delimiter, 5-family
# renderer split by geometry, Claude never trusted with layout math),
# but with its OWN table (six_sigma_diagrams) because several Six Sigma
# tools need genuinely different geometry and fields that would either
# not fit or would overload Strategic Analysis's generic columns:
#   - Fishbone: a spine + angled category "bones", not a rectangular
#     grid, quadrant, or hub-and-spoke network.
#   - CTQ Tree: a top-down hierarchy (need -> CTQ driver -> metric),
#     needing parent/child edges - hence the component_ref/parent_ref
#     columns that Strategic Analysis's schema doesn't have.
#   - FMEA: needs Severity/Occurrence/Detection as first-class numeric
#     fields, with RPN (their product) computed at RENDER TIME, never
#     stored and never trusted as arithmetic Claude did itself.
#   - Pareto / Control Chart: need real derived statistics (cumulative
#     %, a running 80% line; a center line and +/-3-sigma control
#     limits) that are computed SERVER-SIDE from Claude's raw data
#     points, for exactly the same reason position is never trusted to
#     Claude in Strategic Analysis - arithmetic correctness matters and
#     LLMs are unreliable at it, so Claude supplies only the raw
#     frequency/measurement values and R does every calculation.
#
# Classification again reuses the SAME shared Category -> Domain ->
# Topic cascade as every other classified suite (its own taxonomy/
# state trigger). ON TOP of that, Six Sigma adds a second, independent
# "Diagram Group -> Diagram Type" cascade (Define/Measure/Analyse/
# Improve/Control -> the ~12 specific tools within that phase) since
# Six Sigma has meaningfully more distinct diagram types than Strategic
# Analysis and benefits from an extra narrowing level, mirroring DMAIC
# itself - this is what the person explicitly asked for: "group of
# diagram and specific kind of diagram filtering".

# ============================================================
# DELIMITER CONTRACT (items_packed field) - suite-scoped, own token
# ============================================================
SS_ITEM_SEP <- "|||SSITEM|||"

SIXSIGMA_FIELDS <- c(
  "component_type", "layout_role",
  "grid_row", "grid_col", "quadrant_position", "sequence_order",
  "label_text", "sub_text", "items_packed",
  "value_numeric", "value_axis", "series_name", "unit_label",
  "axis_type", "axis_min", "axis_max", "metric_name",
  "severity", "occurrence", "detection",
  "component_ref", "parent_ref",
  "color_hint", "icon_name"
)

# ---- Diagram Group -> Diagram Type taxonomy (DMAIC-organized) --------
SIXSIGMA_GROUPS <- c("framework_overview", "define", "measure", "analyse", "improve", "control", "data_analysis")
SIXSIGMA_GROUP_LABELS <- c(
  framework_overview = "Framework Overview",
  define = "Define", measure = "Measure", analyse = "Analyse",
  improve = "Improve", control = "Control", data_analysis = "Data Analysis"
)

SIXSIGMA_TYPES_BY_GROUP <- list(
  framework_overview = c("dmaic_process", "dmadv_process", "six_sigma_roles_hierarchy"),
  define  = c("sipoc", "ctq_tree", "stakeholder_analysis", "voice_of_customer", "cost_of_quality"),
  measure = c("process_map", "gage_rr", "house_of_quality", "check_sheet", "histogram", "scatter_plot"),
  analyse = c("fishbone", "five_whys", "pareto", "fmea_table", "current_reality_tree", "spaghetti_diagram"),
  improve = c("pugh_matrix", "doe_table", "five_s", "seven_wastes", "five_lean_principles",
              "poka_yoke_devices", "smed_analysis", "chaku_chaku_flow"),
  control = c("control_chart", "balanced_scorecard", "andon_board"),
  data_analysis = c("normal_distribution", "process_capability")
)

SIXSIGMA_TYPE_LABELS <- c(
  dmaic_process = "DMAIC Process Flow",
  dmadv_process = "DMADV Process Flow (Design for Six Sigma)",
  six_sigma_roles_hierarchy = "Six Sigma Roles Hierarchy",
  sipoc = "SIPOC Diagram (Suppliers-Inputs-Process-Outputs-Customers)",
  ctq_tree = "CTQ Tree (Critical-to-Quality)",
  stakeholder_analysis = "Stakeholder Analysis (Power/Interest Grid)",
  voice_of_customer = "Voice of the Customer Tree",
  cost_of_quality = "Cost of Quality",
  process_map = "Process Map / Flowchart",
  gage_rr = "Gage R&R (Measurement System Analysis)",
  house_of_quality = "House of Quality (QFD)",
  check_sheet = "Check Sheet",
  histogram = "Histogram",
  scatter_plot = "Scatter Plot (Correlation Analysis)",
  fishbone = "Fishbone / Ishikawa Diagram",
  five_whys = "Five Whys",
  pareto = "Pareto Chart",
  fmea_table = "FMEA (Failure Mode & Effects Analysis)",
  current_reality_tree = "Current Reality Tree",
  spaghetti_diagram = "Spaghetti Diagram (Movement Path)",
  pugh_matrix = "Pugh Decision Matrix",
  doe_table = "DOE Factorial Design Table",
  five_s = "5S Workplace Organisation",
  seven_wastes = "Seven Deadly Wastes",
  five_lean_principles = "Five Lean Principles",
  poka_yoke_devices = "Poka-Yoke Devices (Error Proofing)",
  smed_analysis = "SMED (Single-Minute Exchange of Dies)",
  chaku_chaku_flow = "Chaku-Chaku Flow",
  control_chart = "Control Chart (Individuals / X-bar / p)",
  balanced_scorecard = "Balanced Scorecard",
  andon_board = "Andon Status Board",
  normal_distribution = "Normal Distribution (Central Limit Theorem)",
  process_capability = "Process Capability (Cp/Cpk)"
)

SIXSIGMA_ALL_TYPES <- unlist(SIXSIGMA_TYPES_BY_GROUP, use.names = FALSE)

generate_new_sixsigma_id <- function(topic) {
  slug <- tolower(gsub("[^a-zA-Z0-9]+", "-", trimws(topic)))
  slug <- gsub("^-+|-+$", "", slug)
  if (nchar(slug) == 0) slug <- "sixsigma"
  if (nchar(slug) > 40) slug <- substr(slug, 1, 40)
  paste0(slug, "-", format(Sys.time(), "%Y%m%d%H%M%S"))
}

# ---- Per-diagram-type instruction blocks --------------------------------
# As with Strategic Analysis: preloaded, never typed by the user, always
# prepended to the free-text request. Each block is explicit about which
# fields to fill AND, critically, which values Claude must NEVER compute
# itself (cumulative %, control limits, RPN, Pugh totals) because those
# are calculated server-side from the raw values Claude supplies.
sixsigma_type_instructions <- function(diagram_type, title_hint) {
  sep <- SS_ITEM_SEP

  title_line <- if (nchar(trimws(title_hint %||% "")) > 0) {
    paste0('[', trimws(title_hint), ']')
  } else {
    '[<invent a concise, specific title for this diagram based on the user request>]'
  }

  type_block <- switch(diagram_type,

    "sipoc" = paste0(
      'DIAGRAM_TYPE = sipoc. Exactly 5 columns in this FIXED order: Suppliers, Inputs, Process, Outputs, ',
      'Customers. Output ONE block per column:\n',
      '[component_type]: shape_rectangle\n[layout_role]: grid_cell\n[grid_row]: 1\n[grid_col]: <1=Suppliers, 2=Inputs, 3=Process, 4=Outputs, 5=Customers>\n',
      '[sequence_order]: <same as grid_col>\n[label_text]: <"SUPPLIERS"|"INPUTS"|"PROCESS"|"OUTPUTS"|"CUSTOMERS" - matching grid_col>\n',
      '[items_packed]: <item 1>', sep, '<item 2>', sep, '<item 3> (3-5 items per column, specific to the request)\n',
      '[color_hint]: <accent_blue|accent_orange|accent_green|accent_purple|neutral_dark, one distinct hint per column>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    "ctq_tree" = paste0(
      'DIAGRAM_TYPE = ctq_tree. A 3-level top-down hierarchy: Customer Need (level 1, exactly one) -> CTQ ',
      'Drivers (level 2, 2-4 of them) -> Measurable Metrics (level 3, 1-2 per CTQ driver). Every node needs a ',
      'short unique [component_ref] (e.g. "NEED1", "CTQ1", "CTQ2", "M1", "M2") and, for levels 2-3, a ',
      '[parent_ref] pointing at the component_ref of the node directly above it - this is how the renderer ',
      'draws the connecting lines, so parent_ref values must exactly match a component_ref you defined earlier ',
      'in the response.\n\n',
      'Level 1 (exactly one):\n[component_type]: tree_node\n[layout_role]: node\n[grid_row]: 1\n',
      '[component_ref]: NEED1\n[parent_ref]: N/A\n[label_text]: <the customer need, in the customer\'s own words>\n\n',
      'Level 2 (2-4 blocks):\n[component_type]: tree_node\n[layout_role]: node\n[grid_row]: 2\n',
      '[component_ref]: <CTQ1, CTQ2, ...>\n[parent_ref]: NEED1\n[label_text]: <this CTQ driver>\n',
      '[sequence_order]: <left-to-right position among its siblings>\n\n',
      'Level 3 (1-2 blocks per level-2 node):\n[component_type]: tree_node\n[layout_role]: node\n[grid_row]: 3\n',
      '[component_ref]: <M1, M2, ...>\n[parent_ref]: <the CTQ_ref this metric measures>\n',
      '[label_text]: <the specific measurable target, e.g. "On-time delivery > 95%">\n',
      '[sequence_order]: <left-to-right position among its siblings>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    "process_map" = paste0(
      'DIAGRAM_TYPE = process_map. A left-to-right sequence of N steps, sequence_order = 1..N. Use ',
      '[component_type]: shape_rectangle for a normal process step, or [component_type]: shape_diamond for a ',
      'yes/no decision point - use at least one diamond if the process genuinely branches.\n\n',
      'For EACH step:\n[component_type]: <shape_rectangle|shape_diamond>\n[layout_role]: node\n',
      '[sequence_order]: <1..N>\n[label_text]: <step description, or the yes/no question for a diamond>\n',
      '[sub_text]: <owner/department responsible, else N/A>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    "fishbone" = paste0(
      'DIAGRAM_TYPE = fishbone (Ishikawa). One effect box (the problem statement, the "head" of the fish), ',
      'plus 4-6 category "bones" branching off the spine - use the standard categories that genuinely apply ',
      '(typically drawn from: Methods, Machines, Materials, Manpower/People, Measurement, Environment), each ',
      'carrying 2-4 specific candidate causes.\n\n',
      'Effect box (exactly one):\n[component_type]: effect_box\n[layout_role]: title\n',
      '[label_text]: <the problem/effect being investigated, stated precisely>\n\n',
      'For EACH category bone:\n[component_type]: bone_category\n[layout_role]: node\n',
      '[sequence_order]: <1..N, order along the spine>\n[label_text]: <category name, e.g. "Methods">\n',
      '[items_packed]: <candidate cause 1>', sep, '<candidate cause 2>', sep, '<candidate cause 3>\n',
      '[color_hint]: <distinct accent per bone>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    "five_whys" = paste0(
      'DIAGRAM_TYPE = five_whys. A chain of "Why" questions/answers, sequence_order = 1..N (typically 5, but ',
      'stop earlier if the true root cause is reached sooner, or continue further if genuinely needed).\n\n',
      'For EACH why in the chain:\n[component_type]: shape_rectangle\n[layout_role]: node\n',
      '[sequence_order]: <1..N>\n[label_text]: <the "Why...?" question>\n',
      '[sub_text]: <the answer, which becomes the next question\'s subject>\n',
      '[color_hint]: <"neutral_dark" for every box EXCEPT the final one, which gets "accent_green" to mark it as the identified root cause>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    "pareto" = paste0(
      'DIAGRAM_TYPE = pareto. Supply ONLY the raw category names and their raw frequency/count/cost values - ',
      'DO NOT sort them, DO NOT calculate percentages, and DO NOT calculate a cumulative total or cumulative ',
      'percentage. The renderer sorts by value descending and computes the cumulative % line itself from your ',
      'raw numbers, so it must receive genuinely unsorted, uncalculated raw values from you.\n\n',
      'For EACH category (4-8 of them):\n[component_type]: data_point\n[layout_role]: node\n',
      '[label_text]: <category/cause name>\n[value_numeric]: <raw frequency, count, or cost - a plain number>\n',
      '[unit_label]: <units, e.g. "occurrences" or "£">\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    "fmea_table" = paste0(
      'DIAGRAM_TYPE = fmea_table. Supply ONLY the three raw 1-10 ratings for each failure mode - DO NOT ',
      'calculate or state the Risk Priority Number (RPN). The renderer computes RPN = Severity x Occurrence x ',
      'Detection itself and sorts rows by it, so you must never multiply these numbers yourself.\n\n',
      'For EACH failure mode (3-6 of them):\n[component_type]: table_cell\n[layout_role]: grid_cell\n',
      '[label_text]: <the failure mode>\n[sub_text]: <the potential effect of this failure>\n',
      '[items_packed]: <potential cause 1>', sep, '<potential cause 2> (N/A if none)\n',
      '[severity]: <1-10, how severe is the effect on the customer>\n',
      '[occurrence]: <1-10, how likely is this failure to occur>\n',
      '[detection]: <1-10, how likely is the CURRENT process to detect it before it reaches the customer - 10 = very unlikely to detect>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    "pugh_matrix" = paste0(
      'DIAGRAM_TYPE = pugh_matrix. A grid of criteria (rows) x candidate concepts (columns), with the first ',
      'concept column always being the "Baseline" the others are scored against. Supply ONLY the individual ',
      'better/worse/same symbols per cell - DO NOT calculate or state column totals. The renderer sums each ',
      'concept column itself (+1 per "+", -1 per "-", 0 per "S").\n\n',
      'Header row (grid_row = 1, one block per concept column including Baseline):\n',
      '[component_type]: table_cell\n[layout_role]: grid_cell\n[grid_row]: 1\n[grid_col]: <1=Baseline, 2..N=other concepts>\n',
      '[label_text]: <concept name, column 1 must be "Baseline">\n\n',
      'Criteria rows (grid_row = 2..M, one block per criterion per concept column):\n',
      '[component_type]: table_cell\n[layout_role]: grid_cell\n[grid_row]: <2..M>\n[grid_col]: <1..N>\n',
      '[label_text]: <the criterion name IF grid_col = 1, else "N/A">\n',
      '[sub_text]: <"+" (better than baseline) | "-" (worse) | "S" (same); ALWAYS "S" for the Baseline column itself>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    "doe_table" = paste0(
      'DIAGRAM_TYPE = doe_table. A factorial design matrix: rows = experimental runs, columns = factors plus a ',
      'final Response column. Header row first, then one row per run.\n\n',
      'Header row (grid_row = 1):\n[component_type]: table_cell\n[layout_role]: grid_cell\n[grid_row]: 1\n',
      '[grid_col]: <1..N>\n[label_text]: <factor name, or "Response" for the last column>\n\n',
      'Run rows (grid_row = 2..M+1):\n[component_type]: table_cell\n[layout_role]: grid_cell\n',
      '[grid_row]: <2..M+1>\n[grid_col]: <1..N>\n',
      '[label_text]: <this run\'s level for that factor, e.g. "Low"/"High" or a number; for the Response column, the observed result>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    "five_s" = paste0(
      'DIAGRAM_TYPE = five_s. Exactly 5 sequential stages in this FIXED order: Sort, Set in Order, Shine, ',
      'Standardise, Sustain.\n\nFor EACH stage:\n[component_type]: bullet_list_item\n[layout_role]: list_item\n',
      '[sequence_order]: <1=Sort, 2=Set in Order, 3=Shine, 4=Standardise, 5=Sustain>\n',
      '[label_text]: <the stage name>\n[sub_text]: <one-line definition of this stage>\n',
      '[items_packed]: <specific action 1 for this request>', sep, '<specific action 2>\n',
      '[color_hint]: <distinct accent per stage>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    "control_chart" = paste0(
      'DIAGRAM_TYPE = control_chart. Supply ONLY the raw sequence of sample/subgroup measurements in the order ',
      'they were taken - DO NOT calculate or state a mean, center line, or control limits (UCL/LCL). The ',
      'renderer computes the center line and +/-3-sigma limits itself from your raw values, exactly as a real ',
      'control chart is built.\n\n',
      'For EACH sample point (10-20 of them, a realistic-looking but plausible sequence for this scenario, not ',
      'perfectly uniform):\n[component_type]: data_point\n[layout_role]: node\n',
      '[sequence_order]: <1..N, the sample/time order>\n[value_numeric]: <the raw measured value>\n',
      '[metric_name]: <what is being measured, e.g. "Cycle time (minutes)">\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    "balanced_scorecard" = paste0(
      'DIAGRAM_TYPE = balanced_scorecard. Exactly 4 quadrants in these FIXED positions: Financial (top_left), ',
      'Customer (top_right), Internal Process (bottom_left), Learning & Growth (bottom_right).\n\n',
      'For EACH quadrant:\n[component_type]: region_quadrant\n[layout_role]: quadrant_region\n',
      '[quadrant_position]: <top_left=Financial|top_right=Customer|bottom_left=Internal Process|bottom_right=Learning & Growth>\n',
      '[label_text]: <the perspective name, matching quadrant_position>\n',
      '[items_packed]: <objective/metric 1 with a target>', sep, '<objective/metric 2 with a target>\n',
      '[color_hint]: <distinct accent per quadrant>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    # ============================================================
    # NEW TOOLS - added to cover every tool named in the Lean Six Sigma
    # Green Belt Body of Knowledge dashboard (History/Roles/Benefits/
    # Disadvantages/References prose sections are NOT diagram-worthy and
    # are intentionally excluded - only tools with a genuine visual
    # structure get a diagram type here).
    # ============================================================

    # ---- Framework Overview group ----
    "dmaic_process" = paste0(
      'DIAGRAM_TYPE = dmaic_process. Exactly 5 boxes in this FIXED sequence: Define, Measure, Analyse, ',
      'Improve, Control.\n\nFor EACH box:\n[component_type]: shape_rectangle\n[layout_role]: node\n',
      '[sequence_order]: <1=Define, 2=Measure, 3=Analyse, 4=Improve, 5=Control>\n',
      '[label_text]: <the phase name exactly as given>\n',
      '[sub_text]: <what this phase means specifically for the topic\'s project, not the generic textbook definition>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "dmadv_process" = paste0(
      'DIAGRAM_TYPE = dmadv_process (Design for Six Sigma). Exactly 5 boxes in this FIXED sequence: Define, ',
      'Measure, Analyse, Design, Verify.\n\nFor EACH box:\n[component_type]: shape_rectangle\n[layout_role]: node\n',
      '[sequence_order]: <1=Define, 2=Measure, 3=Analyse, 4=Design, 5=Verify>\n',
      '[label_text]: <the phase name exactly as given>\n',
      '[sub_text]: <what this phase means specifically for designing this new product/process>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "six_sigma_roles_hierarchy" = paste0(
      'DIAGRAM_TYPE = six_sigma_roles_hierarchy. Exactly 5 levels in this FIXED order, top (most senior) to ',
      'bottom: Champions, Master Black Belts, Black Belts, Green Belts, Yellow Belts.\n\n',
      'For EACH level:\n[component_type]: bullet_list_item\n[layout_role]: list_item\n',
      '[sequence_order]: <1=Champions, 2=Master Black Belts, 3=Black Belts, 4=Green Belts, 5=Yellow Belts>\n',
      '[label_text]: <the role name>\n[sub_text]: <this role\'s specific responsibility for this topic/organization>\n',
      '[color_hint]: <distinct accent per level>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    # ---- Define group additions ----
    "stakeholder_analysis" = paste0(
      'DIAGRAM_TYPE = stakeholder_analysis (Power/Interest Grid). Exactly 4 quadrants in these FIXED ',
      'positions: Manage Closely (top_left = High Power, High Interest), Keep Satisfied (top_right = High ',
      'Power, Low Interest), Keep Informed (bottom_left = Low Power, High Interest), Monitor (bottom_right = ',
      'Low Power, Low Interest).\n\nFor EACH quadrant:\n[component_type]: region_quadrant\n[layout_role]: quadrant_region\n',
      '[quadrant_position]: <top_left|top_right|bottom_left|bottom_right>\n[label_text]: <quadrant name exactly as given>\n',
      '[items_packed]: <specific stakeholder 1 for this topic>', sep, '<specific stakeholder 2>\n',
      '[color_hint]: <distinct accent per quadrant>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "voice_of_customer" = paste0(
      'DIAGRAM_TYPE = voice_of_customer. A 2-level tree: raw Customer Statements (level 1, 2-4 of them, in the ',
      'customer\'s own words) each connecting down to its Translated Requirement (level 2, one per statement, ',
      'stated as a specific, measurable requirement).\n\n',
      'Every node needs a short unique [component_ref] and, for level 2, a [parent_ref] pointing at the ',
      'component_ref of the customer statement it translates.\n\n',
      'Level 1 nodes (2-4, use grid_row=1):\n[component_type]: tree_node\n[layout_role]: node\n[grid_row]: 1\n',
      '[component_ref]: <VOC1, VOC2, ...>\n[parent_ref]: N/A\n[sequence_order]: <left-to-right position>\n',
      '[label_text]: <the raw customer statement, in quotes>\n\n',
      'Level 2 nodes (one per level-1 node, use grid_row=2):\n[component_type]: tree_node\n[layout_role]: node\n[grid_row]: 2\n',
      '[component_ref]: <REQ1, REQ2, ...>\n[parent_ref]: <the VOC_ref this translates>\n[sequence_order]: <matches parent>\n',
      '[label_text]: <the specific, measurable translated requirement>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "cost_of_quality" = paste0(
      'DIAGRAM_TYPE = cost_of_quality. Exactly 4 cells in a SINGLE ROW (1 row x 4 columns), in this FIXED ',
      'order: Prevention Costs (col=1), Appraisal Costs (col=2), Internal Failure Costs (col=3), External ',
      'Failure Costs (col=4).\n\nFor EACH cell:\n[component_type]: shape_rectangle\n[layout_role]: grid_cell\n',
      '[grid_row]: 1\n[grid_col]: <1..4>\n[sequence_order]: <same as grid_col>\n',
      '[label_text]: <category name exactly as given>\n',
      '[items_packed]: <specific cost item 1 for this topic>', sep, '<specific cost item 2>\n',
      '[color_hint]: <accent_blue|accent_orange|accent_green|accent_purple, one per column>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    # ---- Measure group additions ----
    "gage_rr" = paste0(
      'DIAGRAM_TYPE = gage_rr (Measurement System Analysis). Supply ONLY the three raw variance-contribution ',
      'percentages - DO NOT calculate a total, a pass/fail verdict, or round them to make them sum exactly to ',
      '100; the renderer displays your raw numbers as given.\n\n',
      'Exactly 3 bars, in this FIXED order:\n[component_type]: data_point\n[layout_role]: node\n',
      '[label_text]: <"Repeatability"|"Reproducibility"|"Part-to-Part Variation", one bar each>\n',
      '[value_numeric]: <the percentage of total variation this component contributes, a plain number 0-100>\n',
      '[unit_label]: %\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "house_of_quality" = paste0(
      'DIAGRAM_TYPE = house_of_quality (QFD matrix). Row 1 = header row: a blank corner cell, then one cell ',
      'per technical/engineering characteristic (3-5 of them). Column 1 (rows 2+) = customer requirements (3-5 ',
      'of them). Interior cells = the correlation strength between that requirement and that technical ',
      'characteristic, as label_text: "Strong", "Medium", "Weak", or "N/A" for essentially no correlation.\n\n',
      'Output one block per cell using its ACTUAL grid_row/grid_col position:\n',
      '[component_type]: table_cell\n[layout_role]: grid_cell\n[grid_row]: <actual row>\n[grid_col]: <actual col>\n',
      '[label_text]: <header text if row 1 or col 1, else the correlation strength>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "check_sheet" = paste0(
      'DIAGRAM_TYPE = check_sheet. A tally table: row 1 = header row (blank corner, then one column per time ',
      'period/shift/location, 3-5 of them). Column 1 (rows 2+) = defect/event category names (3-6 of them). ',
      'Interior cells = the raw tally count for that category in that period, as label_text (a plain number, ',
      'as a string).\n\nOutput one block per cell using its ACTUAL grid_row/grid_col position:\n',
      '[component_type]: table_cell\n[layout_role]: grid_cell\n[grid_row]: <actual row>\n[grid_col]: <actual col>\n',
      '[label_text]: <header text if row 1 or col 1, else the tally count>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "histogram" = paste0(
      'DIAGRAM_TYPE = histogram. Supply ONLY raw bin labels and their raw frequency counts - DO NOT sort them ',
      'or calculate percentages; the renderer displays them in the order given (bins should already be in ',
      'ascending numeric order since that is how a histogram reads).\n\n',
      'For EACH bin (6-10 of them):\n[component_type]: data_point\n[layout_role]: node\n',
      '[sequence_order]: <bin order, ascending>\n[label_text]: <bin range, e.g. "10-15">\n',
      '[value_numeric]: <raw frequency count for this bin>\n[unit_label]: count\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "scatter_plot" = paste0(
      'DIAGRAM_TYPE = scatter_plot (correlation analysis). Supply ONLY the raw (x,y) coordinate pairs - DO NOT ',
      'calculate or state a correlation coefficient or a trend line; the renderer computes the linear trend ',
      'line and correlation coefficient itself from your raw points.\n\n',
      'For EACH point (8-15 of them):\n[component_type]: data_point\n[layout_role]: node\n',
      '[sequence_order]: <point index>\n[value_axis]: x\n[value_numeric]: <x value>\n\n',
      '(repeat the same sequence_order with [value_axis]: y and the y value as a SEPARATE block)\n\n',
      'Axis blocks (exactly 2):\n[component_type]: axis\n[layout_role]: axis\n[value_axis]: <x|y>\n',
      '[metric_name]: <what this axis measures, specific to the topic>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    # ---- Analyse group additions ----
    "current_reality_tree" = paste0(
      'DIAGRAM_TYPE = current_reality_tree (Theory of Constraints logic tree). A 3-level chain of cause and ',
      'effect: Undesirable Effects (level 1, the observed symptoms, 1-2 of them) <- Intermediate Causes (level ',
      '2, 2-3 of them) <- Root Cause (level 3, exactly one, the deepest underlying cause).\n\n',
      'Every node needs a short unique [component_ref] and a [parent_ref] pointing UP toward the effect it ',
      'causes (i.e. parent_ref on a level-3 root cause points at the level-2 cause it drives, which in turn ',
      'points at the level-1 effect it drives) - this is the reverse direction from CTQ Tree, since here you ',
      'are tracing effects back to causes, not needs down to metrics.\n\n',
      'Level 1 (grid_row=1, the symptoms):\n[component_type]: tree_node\n[layout_role]: node\n[grid_row]: 1\n',
      '[component_ref]: <EFFECT1, ...>\n[parent_ref]: N/A\n[label_text]: <the observed undesirable effect>\n\n',
      'Level 2 (grid_row=2, intermediate causes):\n[component_type]: tree_node\n[layout_role]: node\n[grid_row]: 2\n',
      '[component_ref]: <CAUSE1, CAUSE2, ...>\n[parent_ref]: <the EFFECT_ref this cause drives>\n',
      '[sequence_order]: <left-to-right position>\n[label_text]: <the intermediate cause>\n\n',
      'Level 3 (grid_row=3, exactly one root cause):\n[component_type]: tree_node\n[layout_role]: node\n[grid_row]: 3\n',
      '[component_ref]: ROOT1\n[parent_ref]: <one of the CAUSE_refs it drives>\n[label_text]: <the single root cause>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "spaghetti_diagram" = paste0(
      'DIAGRAM_TYPE = spaghetti_diagram (movement/travel path mapping). 5-8 locations that a person, material, ',
      'or information item visits in sequence within a workspace, plus the approximate distance travelled ',
      'between consecutive locations. Supply ONLY the raw distances between consecutive stops - DO NOT ',
      'calculate or state a total distance; the renderer sums it.\n\n',
      'For EACH location, in visit order:\n[component_type]: data_point\n[layout_role]: node\n',
      '[sequence_order]: <1..N, the actual visit order>\n[label_text]: <location name, e.g. "Supply Room A">\n',
      '[value_numeric]: <distance in metres from the PREVIOUS location to this one - use 0 for the first location>\n',
      '[unit_label]: m\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    # ---- Improve group additions ----
    "seven_wastes" = paste0(
      'DIAGRAM_TYPE = seven_wastes (Lean Muda). Exactly 7 cells in a SINGLE ROW (1 row x 7 columns), in this ',
      'FIXED order: Transport, Inventory, Motion, Waiting, Overproduction, Over-processing, Defects.\n\n',
      'For EACH waste:\n[component_type]: shape_rectangle\n[layout_role]: grid_cell\n',
      '[grid_row]: 1\n[grid_col]: <1..7, in the order given above>\n[sequence_order]: <same as grid_col>\n',
      '[label_text]: <the waste name exactly as given>\n',
      '[items_packed]: <specific example of this waste for this topic>', sep, '<another example>\n',
      '[color_hint]: <distinct accent, can repeat>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "five_lean_principles" = paste0(
      'DIAGRAM_TYPE = five_lean_principles. Exactly 5 boxes in this FIXED sequence: Value (identify what the ',
      'customer values), Value Stream (map the steps that create it), Flow (make those steps flow without ',
      'interruption), Pull (only produce what is pulled by demand), Perfection (pursue continuous improvement).\n\n',
      'For EACH box:\n[component_type]: shape_rectangle\n[layout_role]: node\n',
      '[sequence_order]: <1..5 in the order given above>\n[label_text]: <principle name exactly as given>\n',
      '[sub_text]: <what this principle means specifically for this topic>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "poka_yoke_devices" = paste0(
      'DIAGRAM_TYPE = poka_yoke_devices (error-proofing inventory). A table with header row 1: Prevention ',
      'Devices (col=1), Detection Devices (col=2). Column 1 rows 2+ list 3-5 specific prevention mechanisms ',
      'for this topic (devices that make the error physically impossible); column 2 rows 2+ list 3-5 specific ',
      'detection mechanisms (devices that catch the error immediately after it happens).\n\n',
      'Output one block per cell using its ACTUAL grid_row/grid_col position:\n',
      '[component_type]: table_cell\n[layout_role]: grid_cell\n[grid_row]: <actual row>\n[grid_col]: <1 or 2>\n',
      '[label_text]: <header text if row 1, else the specific device/mechanism>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "smed_analysis" = paste0(
      'DIAGRAM_TYPE = smed_analysis (Single-Minute Exchange of Dies - changeover reduction). A table with ',
      'header row 1: Activity (col=1), Classification (col=2, "Internal" if it requires the machine to be ',
      'stopped or "External" if it can be done while running), Action (col=3, "Keep As Internal", "Convert to ',
      'External", or "Eliminate"). 4-8 data rows, one per changeover activity for this topic.\n\n',
      'Output one block per cell using its ACTUAL grid_row/grid_col position:\n',
      '[component_type]: table_cell\n[layout_role]: grid_cell\n[grid_row]: <actual row>\n[grid_col]: <1, 2, or 3>\n',
      '[label_text]: <header text if row 1, else the activity name / classification / action for that row>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "chaku_chaku_flow" = paste0(
      'DIAGRAM_TYPE = chaku_chaku_flow (one-operator, multi-station continuous flow line). 4-8 stations in ',
      'sequence that a single operator moves through, loading and unloading parts.\n\n',
      'For EACH station:\n[component_type]: shape_rectangle\n[layout_role]: node\n',
      '[sequence_order]: <1..N, the station order the operator visits>\n[label_text]: <station name/operation>\n',
      '[sub_text]: <cycle time or specific task at this station for this topic>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    # ---- Control group additions ----
    "andon_board" = paste0(
      'DIAGRAM_TYPE = andon_board (visual status signal board). 4-8 stations/lines in a single row, each with ',
      'a current status.\n\nFor EACH station:\n[component_type]: shape_rectangle\n[layout_role]: grid_cell\n',
      '[grid_row]: 1\n[grid_col]: <1..N>\n[sequence_order]: <same as grid_col>\n',
      '[label_text]: <station/line name>\n[sub_text]: <brief current status description specific to this topic>\n',
      '[color_hint]: <"accent_green" for running normally, "accent_orange" for a minor issue/attention needed, "accent_red" for stopped/critical - vary these realistically, not all green>\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    # ---- Data Analysis group ----
    "normal_distribution" = paste0(
      'DIAGRAM_TYPE = normal_distribution (Central Limit Theorem illustration). Supply ONLY the raw mean and ',
      'standard deviation - DO NOT calculate or describe the bell curve shape, percentages under each region, ',
      'or draw the curve yourself in text; the renderer computes and draws the actual normal distribution ',
      'curve from these two numbers.\n\n',
      'Exactly one block:\n[component_type]: data_point\n[layout_role]: node\n',
      '[value_numeric]: <the mean, a plain number>\n[axis_min]: <the standard deviation, a plain positive number>\n',
      '[metric_name]: <what is being measured, e.g. "Cycle time (minutes)">\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),
    "process_capability" = paste0(
      'DIAGRAM_TYPE = process_capability (Cp/Cpk analysis). Supply ONLY the raw process mean, standard ',
      'deviation, and specification limits - DO NOT calculate Cp, Cpk, or a sigma level yourself; the renderer ',
      'computes all of these from your four raw numbers, exactly as a real capability study does.\n\n',
      'Exactly one block:\n[component_type]: data_point\n[layout_role]: node\n',
      '[value_numeric]: <the process mean, a plain number>\n[axis_min]: <the process standard deviation, a plain positive number>\n',
      '[axis_max]: <the Upper Specification Limit (USL), a plain number>\n[unit_label]: <the Lower Specification Limit (LSL), a plain number - reusing this text field to carry a 4th number since the schema has no dedicated LSL column>\n',
      '[metric_name]: <what is being measured, specific to this topic, e.g. "Shaft diameter (mm)">\n\n',
      'Title block:\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n'
    ),

    stop("Unknown Six Sigma diagram_type: ", diagram_type)
  )

  paste0(
    'You are generating the DATA for a Six Sigma diagram, not a picture. Output ONLY the metadata block ',
    'below followed by bracket-tag component rows in the exact format specified - no markdown, no prose ',
    'commentary, no code fences.\n\n',

    '1. Start with EXACTLY 6 metadata lines, each on its own line, each containing ONLY the actual value ',
    'wrapped in single square brackets - do NOT include a field name, label, or colon. Lines 1-5 are fixed by ',
    'the user\'s selection and must be EXACTLY as given; line 6 is the diagram title as instructed below:\n',
    '[', diagram_type, ']\n', title_line, '\n\n',

    '2. Leave exactly ONE blank line after the metadata block. Then output the component blocks. Every ',
    'component is its own block of "[field]: value" lines, separated by a single blank line from the next ',
    'component. Do not skip a field - if genuinely not applicable, write "N/A".\n\n',

    'CRITICAL: within [items_packed], separate multiple items with the EXACT literal token "', sep, '". ',
    'NEVER use "', sep, '" anywhere else. If you need a normal separator inside real text, use a comma or a ',
    'single hyphen instead.\n\n',

    'CRITICAL: never perform derived arithmetic yourself (cumulative percentages, RPN products, control ',
    'limits, Pugh column totals) even if it seems helpful - supply only the raw values the instructions below ',
    'ask for. The renderer calculates every derived statistic itself so the numbers are always correct.\n\n',

    type_block
  )
}

generate_sixsigma_prompt <- function(diagram_type, diagram_group, category, domain, topic, title_hint, user_request) {
  type_instructions <- sixsigma_type_instructions(diagram_type, title_hint)

  # The metadata block template inside sixsigma_type_instructions() only
  # hardcodes diagram_type and the title line (both type-specific); the
  # remaining 4 fixed metadata lines are injected here so the function
  # above stays reusable without repeating all 6 args in every switch arm.
  type_instructions <- sub(
    paste0('\\[', diagram_type, '\\]\\n'),
    paste0('[', diagram_type, ']\n[', diagram_group, ']\n[', category, ']\n[', domain, ']\n[', topic, ']\n'),
    type_instructions
  )

  paste0(
    'You are a Lean Six Sigma Master Black Belt building a "', SIXSIGMA_TYPE_LABELS[[diagram_type]],
    '" (', SIXSIGMA_GROUP_LABELS[[diagram_group]], ' phase tool). ',
    'Category: ', category, '. Domain: ', domain, '. Topic: ', topic, '.\n\n',
    'The user\'s specific request: "', user_request, '"\n\n',
    'Populate the diagram with content genuinely specific to this request (not generic placeholder text) - ',
    'reason about the actual process/problem described before writing labels, causes, and values.\n\n',
    type_instructions,
    '\n\nOutput format rules: one blank line between component blocks, no markdown headers, no numbering ',
    'outside the bracket fields, every field present on every block ("N/A" rather than omitting a line).\n\n',
    'Now generate the diagram, beginning with the 6 metadata lines.'
  )
}

# Force-overwrite the metadata block's first 5 positional bare-bracket
# lines (diagram_type/diagram_group/category/domain/topic - all fixed by
# the user's dropdown selections, never Claude's to change). The 6th line
# (title) is only forced when the user supplied an explicit title_hint.
overwrite_sixsigma_header <- function(text, diagram_type, diagram_group, category, domain, topic, title_override = NULL) {
  lines <- strsplit(text, "\n")[[1]]
  metadata_line_idx <- which(grepl("^\\[.+\\]$", trimws(lines)))
  metadata_line_idx <- head(metadata_line_idx, 6)

  values <- list(diagram_type, diagram_group, category, domain, topic, title_override)
  for (i in seq_along(metadata_line_idx)) {
    v <- values[[i]]
    if (!is.null(v) && !is.na(v) && nchar(trimws(v)) > 0) {
      lines[metadata_line_idx[i]] <- paste0("[", trimws(v), "]")
    }
  }
  paste(lines, collapse = "\n")
}

# Parser: same two-part structure as parse_diagram_text() (metadata block
# via a scan of the first N bare "[value]" lines, then component blocks
# via a single pass using plain `<-` in the loop and `<<-` reserved for
# flush_block()'s own reach-back into this function's `blocks`).
parse_sixsigma_text <- function(text, diagram_id, is_template = FALSE, source_diagram_id = NA, created_by = "claude_agent") {
  lines <- strsplit(text, "\n")[[1]]

  # ---- Part 1: metadata block (diagram_type, diagram_group, category, domain, topic, title) ----
  diagram_type <- NULL; diagram_group <- NULL; category <- NULL; domain <- NULL; topic <- NULL; title <- NULL
  metadata_count <- 0
  for (i in seq_len(min(20, length(lines)))) {
    line <- trimws(lines[i])
    if (grepl("^\\[.+\\]$", line)) {
      metadata_count <- metadata_count + 1
      value <- gsub("^\\[|\\]$", "", line)
      if (metadata_count == 1) diagram_type <- value
      else if (metadata_count == 2) diagram_group <- value
      else if (metadata_count == 3) category <- value
      else if (metadata_count == 4) domain <- value
      else if (metadata_count == 5) topic <- value
      else if (metadata_count == 6) title <- value
      else break
    }
  }
  if (is.null(diagram_type) || !diagram_type %in% SIXSIGMA_ALL_TYPES) {
    stop("Could not find a valid Six Sigma diagram type in the first metadata line of the generated text (expected one of: ",
         paste(SIXSIGMA_ALL_TYPES, collapse = ", "), ")")
  }
  if (is.null(diagram_group) || !diagram_group %in% SIXSIGMA_GROUPS) {
    stop("Could not find a valid diagram group in the second metadata line (expected one of: ",
         paste(SIXSIGMA_GROUPS, collapse = ", "), ")")
  }
  if (is.null(category) || is.null(domain) || is.null(topic)) {
    stop("Could not find Category, Domain, and Topic metadata in the generated diagram text")
  }
  if (is.null(title) || nchar(trimws(title)) == 0) title <- topic
  diagram_name <- SIXSIGMA_TYPE_LABELS[[diagram_type]]

  # ---- Part 2: component blocks ("[field]: value" tags) ----
  blocks <- list()
  current <- list()
  last_field <- NULL

  flush_block <- function() {
    if (length(current) > 0 && !is.null(current$component_type)) {
      blocks[[length(blocks) + 1]] <<- current
    }
  }

  for (line in lines) {
    line <- trimws(line)

    if (line == "" || grepl("^\\[.+\\]$", line)) {
      flush_block()
      current <- list()
      last_field <- NULL
      next
    }

    matched <- FALSE
    for (field in SIXSIGMA_FIELDS) {
      pat <- paste0("^\\[", field, "\\]:\\s*(.*)$")
      if (grepl(pat, line, ignore.case = TRUE)) {
        value <- trimws(sub(pat, "\\1", line, ignore.case = TRUE))
        if (field == "component_type" && !is.null(current$component_type)) {
          flush_block()
          current <- list()
        }
        current[[field]] <- value
        last_field <- field
        matched <- TRUE
        break
      }
    }
    if (!matched && length(current) > 0 && !is.null(last_field)) {
      current[[last_field]] <- paste(current[[last_field]], line)
    }
  }
  flush_block()

  if (length(blocks) == 0) stop("No valid Six Sigma component blocks found in text")

  df <- data.frame(
    diagram_id = character(), diagram_name = character(), diagram_type = character(), diagram_group = character(),
    category = character(), domain = character(), topic = character(), title = character(), is_template = logical(),
    source_diagram_id = character(),
    component_type = character(), layout_role = character(),
    grid_row = integer(), grid_col = integer(), quadrant_position = character(), sequence_order = integer(),
    z_index = integer(), pos_x = numeric(), pos_y = numeric(), width = numeric(), height = numeric(),
    label_text = character(), sub_text = character(), items_packed = character(),
    value_numeric = numeric(), value_axis = character(), series_name = character(), unit_label = character(),
    axis_type = character(), axis_min = numeric(), axis_max = numeric(), metric_name = character(),
    severity = integer(), occurrence = integer(), detection = integer(),
    component_ref = character(), parent_ref = character(),
    color_hint = character(), icon_name = character(), created_by = character(),
    stringsAsFactors = FALSE
  )

  na_int <- function(x) suppressWarnings(as.integer(x %||% NA))
  na_num <- function(x) suppressWarnings(as.numeric(x %||% NA))

  for (b in blocks) {
    df <- rbind(df, data.frame(
      diagram_id = diagram_id, diagram_name = diagram_name, diagram_type = diagram_type, diagram_group = diagram_group,
      category = category, domain = domain, topic = topic, title = title, is_template = is_template,
      source_diagram_id = as.character(source_diagram_id %||% NA),
      component_type = b$component_type %||% "", layout_role = b$layout_role %||% "",
      grid_row = na_int(b$grid_row), grid_col = na_int(b$grid_col),
      quadrant_position = b$quadrant_position %||% NA_character_, sequence_order = na_int(b$sequence_order),
      z_index = na_int(b$z_index), pos_x = NA_real_, pos_y = NA_real_, width = NA_real_, height = NA_real_,
      label_text = b$label_text %||% "", sub_text = b$sub_text %||% "", items_packed = b$items_packed %||% "",
      value_numeric = na_num(b$value_numeric), value_axis = b$value_axis %||% NA_character_,
      series_name = b$series_name %||% NA_character_, unit_label = b$unit_label %||% NA_character_,
      axis_type = b$axis_type %||% NA_character_, axis_min = na_num(b$axis_min), axis_max = na_num(b$axis_max),
      metric_name = b$metric_name %||% NA_character_,
      severity = na_int(b$severity), occurrence = na_int(b$occurrence), detection = na_int(b$detection),
      component_ref = b$component_ref %||% NA_character_, parent_ref = b$parent_ref %||% NA_character_,
      color_hint = b$color_hint %||% NA_character_, icon_name = b$icon_name %||% NA_character_,
      created_by = created_by,
      stringsAsFactors = FALSE
    ))
  }
  df
}

sixsigma_unpack_items <- function(items_packed) {
  if (!has_real_value(items_packed)) return(character(0))
  trimws(strsplit(items_packed, SS_ITEM_SEP, fixed = TRUE)[[1]])
}

# ============================================================
# SIX SIGMA DROPDOWNS
# ============================================================
# Category/Domain/Topic reuses the SAME shared cascade as Strategic
# Analysis/Mind Map/Knowledge Graph (own taxonomy method names below).
# The Diagram Group -> Diagram Type cascade is a SECOND, independent
# selector this suite adds on top - a short server-side cascade
# updating the Type dropdown's choices whenever Group changes.
sixsigma_group_dropdown_ui <- function(ns) {
  selectInput(ns("diagram_group_select"), "Diagram Group (DMAIC phase): *",
              choices = setNames(SIXSIGMA_GROUPS, SIXSIGMA_GROUP_LABELS[SIXSIGMA_GROUPS]))
}

sixsigma_type_dropdown_ui <- function(ns) {
  selectInput(ns("diagram_type_select"), "Diagram Type (specific tool): *", choices = NULL)
}

# Wires the Type dropdown's choices to whichever Group is currently
# selected. Called once per module that shows both dropdowns.
setup_sixsigma_group_type_cascade <- function(input, output, session) {
  observeEvent(input$diagram_group_select, {
    grp <- input$diagram_group_select
    types <- SIXSIGMA_TYPES_BY_GROUP[[grp]]
    if (is.null(types) || length(types) == 0) {
      updateSelectInput(session, "diagram_type_select", choices = c("(no tools in this group)" = ""))
    } else {
      updateSelectInput(session, "diagram_type_select",
                        choices = setNames(types, SIXSIGMA_TYPE_LABELS[types]))
    }
  }, ignoreNULL = FALSE)
}

# ============================================================
# SIX SIGMA - GENERIC RENDERERS
# ============================================================
# Three families, exactly as with Strategic Analysis, but Six Sigma's
# extra variety needs its own dedicated functions rather than reusing
# Strategic Analysis's (deliberate suite isolation - see the design note
# at the top of this section):
#   - HTML/CSS Grid family: sipoc, process_map, five_s, pugh_matrix,
#     doe_table, fmea_table, balanced_scorecard - browser layout engine,
#     no overlap possible.
#   - SVG family: fishbone, ctq_tree - server-computed geometry (bone
#     angles, tree levels), Claude never supplies a coordinate.
#   - Plotly family: pareto, control_chart - and this is where Six
#     Sigma's "never trust Claude with arithmetic" rule matters most:
#     cumulative %, the 80% reference line, and control limits (center
#     line, +/-3-sigma) are ALL computed here from Claude's raw values,
#     never read from anything Claude wrote.

render_sixsigma <- function(components_df, diagram_type) {
  cat(sprintf("🎨 [Six Sigma Analysis][DEBUG] Rendering diagram_type=%s with %d component row(s)\n",
              diagram_type, nrow(components_df)))

  if (nrow(components_df) == 0) {
    return(tags$div(class = "status-warning", "No components found for this diagram."))
  }

  html_family <- c("sipoc", "process_map", "five_s", "pugh_matrix", "doe_table", "fmea_table", "balanced_scorecard",
                    "seven_wastes", "andon_board", "cost_of_quality",
                    "dmaic_process", "dmadv_process", "chaku_chaku_flow", "five_lean_principles",
                    "six_sigma_roles_hierarchy",
                    "stakeholder_analysis",
                    "house_of_quality", "check_sheet", "poka_yoke_devices", "smed_analysis")
  svg_family <- c("fishbone", "ctq_tree", "voice_of_customer", "current_reality_tree", "spaghetti_diagram")
  plotly_family <- c("pareto", "control_chart", "gage_rr", "histogram", "scatter_plot",
                      "normal_distribution", "process_capability")

  if (diagram_type %in% html_family) {
    cat("🎨 [Six Sigma Analysis][DEBUG] Dispatching to render_sixsigma_html()\n")
    render_sixsigma_html(components_df, diagram_type)
  } else if (diagram_type %in% svg_family) {
    cat("🎨 [Six Sigma Analysis][DEBUG] Dispatching to render_sixsigma_svg()\n")
    render_sixsigma_svg(components_df, diagram_type)
  } else if (diagram_type %in% plotly_family) {
    cat("🎨 [Six Sigma Analysis][DEBUG] Dispatching to render_sixsigma_plotly()\n")
    render_sixsigma_plotly(components_df, diagram_type)
  } else {
    tags$div(class = "status-error", sprintf("Unknown Six Sigma diagram_type: %s", diagram_type))
  }
}

# ---- HTML/CSS Grid family: sipoc, process_map, five_s, balanced_scorecard,
#     pugh_matrix, doe_table, fmea_table. The first four reuse Strategic
#     Analysis's .diagram-grid/.diagram-cell/.diagram-stacked-list/
#     .diagram-quadrant-grid classes directly (same shared visual language
#     already established for "cards in a CSS grid" across this app); the
#     data-table trio (pugh_matrix/doe_table/fmea_table) use real <table>
#     markup with their own .ss-data-table styling since they need row
#     striping, a computed totals row (Pugh), and RPN color-coding (FMEA)
#     that a CSS-grid div layout doesn't suit.
render_sixsigma_html <- function(components_df, diagram_type) {
  title_row <- components_df[components_df$component_type == "title", , drop = FALSE]
  title_text <- if (nrow(title_row) > 0) title_row$label_text[1] else components_df$diagram_name[1]
  body_rows <- components_df[components_df$component_type != "title", , drop = FALSE]

  html_parts <- c(sprintf('<div class="diagram-card ss-card"><div class="chapter-title"><i class="fa fa-industry"></i> %s</div>', htmltools::htmlEscape(title_text)))

  if (diagram_type %in% c("sipoc", "seven_wastes", "andon_board", "cost_of_quality")) {
    n_cols <- max(body_rows$grid_col, 1, na.rm = TRUE)
    html_parts <- c(html_parts, sprintf('<div class="diagram-grid" style="grid-template-columns: repeat(%d, 1fr);">', n_cols))
    ordered <- body_rows[order(body_rows$grid_col), , drop = FALSE]
    for (i in seq_len(nrow(ordered))) {
      row <- ordered[i, ]
      items <- sixsigma_unpack_items(row$items_packed)
      items_html <- if (length(items) > 0) paste0('<ul class="diagram-item-list">', paste0('<li>', htmltools::htmlEscape(items), '</li>', collapse = ""), '</ul>') else ""
      color_style <- if (has_real_value(row$color_hint)) sprintf(' data-color-hint="%s"', row$color_hint) else ""
      html_parts <- c(html_parts, sprintf('<div class="diagram-cell"%s><div class="section-tag">%s</div>%s%s</div>',
        color_style, htmltools::htmlEscape(row$label_text %||% ""),
        if (has_real_value(row$sub_text)) sprintf('<div class="details-text">%s</div>', htmltools::htmlEscape(row$sub_text)) else "",
        items_html))
    }
    html_parts <- c(html_parts, '</div>')

  } else if (diagram_type %in% c("process_map", "dmaic_process", "dmadv_process", "chaku_chaku_flow", "five_lean_principles")) {
    ordered <- body_rows[order(body_rows$sequence_order), , drop = FALSE]
    html_parts <- c(html_parts, '<div class="ss-process-flow">')
    for (i in seq_len(nrow(ordered))) {
      row <- ordered[i, ]
      is_diamond <- identical(row$component_type, "shape_diamond")
      html_parts <- c(html_parts, '<div class="ss-flow-step">')
      if (is_diamond) {
        html_parts <- c(html_parts, sprintf(
          '<div class="ss-flow-diamond"><div class="ss-flow-diamond-inner"><span>%s</span></div></div>',
          htmltools::htmlEscape(row$label_text %||% "")
        ))
      } else {
        html_parts <- c(html_parts, sprintf('<div class="ss-flow-box"><span>%s</span></div>', htmltools::htmlEscape(row$label_text %||% "")))
      }
      if (has_real_value(row$sub_text)) {
        html_parts <- c(html_parts, sprintf('<div class="details-text" style="text-align:center; font-size:0.8em;">%s</div>', htmltools::htmlEscape(row$sub_text)))
      }
      html_parts <- c(html_parts, '</div>')
      if (i < nrow(ordered)) html_parts <- c(html_parts, '<div class="ss-flow-arrow">&#10142;</div>')
    }
    html_parts <- c(html_parts, '</div>')

  } else if (diagram_type %in% c("five_s", "six_sigma_roles_hierarchy")) {
    ordered <- body_rows[order(body_rows$sequence_order), , drop = FALSE]
    html_parts <- c(html_parts, '<div class="diagram-stacked-list">')
    for (i in seq_len(nrow(ordered))) {
      row <- ordered[i, ]
      items <- sixsigma_unpack_items(row$items_packed)
      items_html <- if (length(items) > 0) paste0('<ul class="diagram-item-list" style="color:rgba(255,255,255,0.92);">', paste0('<li>', htmltools::htmlEscape(items), '</li>', collapse = ""), '</ul>') else ""
      html_parts <- c(html_parts, sprintf(
        '<div class="diagram-list-bar" data-color-hint="%s"><span class="diagram-list-bar-label">%d. %s</span>%s%s</div>',
        row$color_hint %||% "neutral_dark", i, htmltools::htmlEscape(row$label_text %||% ""),
        if (has_real_value(row$sub_text)) sprintf('<div class="details-text">%s</div>', htmltools::htmlEscape(row$sub_text)) else "",
        items_html
      ))
    }
    html_parts <- c(html_parts, '</div>')

  } else if (diagram_type %in% c("balanced_scorecard", "stakeholder_analysis")) {
    quad_rows <- body_rows[body_rows$component_type == "region_quadrant", , drop = FALSE]
    html_parts <- c(html_parts, '<div class="diagram-quadrant-grid">')
    for (pos in c("top_left", "top_right", "bottom_left", "bottom_right")) {
      row <- quad_rows[quad_rows$quadrant_position == pos, , drop = FALSE]
      if (nrow(row) == 0) { html_parts <- c(html_parts, '<div class="diagram-quadrant-cell"></div>'); next }
      row <- row[1, ]
      items <- sixsigma_unpack_items(row$items_packed)
      items_html <- if (length(items) > 0) paste0('<ul class="diagram-item-list">', paste0('<li>', htmltools::htmlEscape(items), '</li>', collapse = ""), '</ul>') else ""
      html_parts <- c(html_parts, sprintf('<div class="diagram-quadrant-cell" data-quadrant="%s"><div class="section-tag">%s</div>%s</div>',
        pos, htmltools::htmlEscape(row$label_text %||% ""), items_html))
    }
    html_parts <- c(html_parts, '</div>')

  } else if (diagram_type %in% c("doe_table", "house_of_quality", "check_sheet", "poka_yoke_devices", "smed_analysis")) {
    n_rows <- max(body_rows$grid_row, 1, na.rm = TRUE)
    n_cols <- max(body_rows$grid_col, 1, na.rm = TRUE)
    mat <- matrix("", nrow = n_rows, ncol = n_cols)
    for (i in seq_len(nrow(body_rows))) {
      r <- body_rows[i, ]
      if (!is.na(r$grid_row) && !is.na(r$grid_col)) mat[r$grid_row, r$grid_col] <- htmltools::htmlEscape(r$label_text %||% "")
    }
    html_parts <- c(html_parts, '<table class="ss-data-table"><tbody>')
    for (rr in seq_len(n_rows)) {
      html_parts <- c(html_parts, if (rr == 1) '<tr class="ss-header-row">' else '<tr>')
      tag <- if (rr == 1) "th" else "td"
      for (cc in seq_len(n_cols)) html_parts <- c(html_parts, sprintf('<%s>%s</%s>', tag, mat[rr, cc], tag))
      html_parts <- c(html_parts, '</tr>')
    }
    html_parts <- c(html_parts, '</tbody></table>')

  } else if (diagram_type == "pugh_matrix") {
    # ---- Pugh totals are COMPUTED HERE, never trusted from Claude - see
    #     sixsigma_type_instructions("pugh_matrix") which explicitly tells
    #     Claude to supply only the raw +/-/S symbols. ----
    n_rows <- max(body_rows$grid_row, 1, na.rm = TRUE)
    n_cols <- max(body_rows$grid_col, 1, na.rm = TRUE)
    html_parts <- c(html_parts, '<table class="ss-data-table ss-pugh-table"><tbody>')
    for (rr in seq_len(n_rows)) {
      if (rr == 1) {
        html_parts <- c(html_parts, '<tr class="ss-header-row"><th>Criteria</th>')
        for (cc in seq_len(n_cols)) {
          cell <- body_rows[body_rows$grid_row == 1 & body_rows$grid_col == cc, , drop = FALSE]
          html_parts <- c(html_parts, sprintf('<th>%s</th>', htmltools::htmlEscape(if (nrow(cell) > 0) cell$label_text[1] %||% "" else "")))
        }
        html_parts <- c(html_parts, '</tr>')
      } else {
        criterion_cell <- body_rows[body_rows$grid_row == rr & body_rows$grid_col == 1, , drop = FALSE]
        criterion_name <- if (nrow(criterion_cell) > 0) criterion_cell$label_text[1] %||% "" else ""
        html_parts <- c(html_parts, sprintf('<tr><td class="ss-pugh-criterion">%s</td>', htmltools::htmlEscape(criterion_name)))
        for (cc in seq_len(n_cols)) {
          cell <- body_rows[body_rows$grid_row == rr & body_rows$grid_col == cc, , drop = FALSE]
          sym <- if (nrow(cell) > 0) toupper(trimws(cell$sub_text[1] %||% "S")) else "S"
          sym_class <- if (sym == "+") "ss-pugh-plus" else if (sym == "-") "ss-pugh-minus" else "ss-pugh-same"
          html_parts <- c(html_parts, sprintf('<td><span class="ss-pugh-symbol %s">%s</span></td>', sym_class, sym))
        }
        html_parts <- c(html_parts, '</tr>')
      }
    }
    # Computed totals row
    html_parts <- c(html_parts, '<tr class="ss-total-row"><td>TOTAL</td>')
    for (cc in seq_len(n_cols)) {
      total <- 0
      for (rr in 2:n_rows) {
        cell <- body_rows[body_rows$grid_row == rr & body_rows$grid_col == cc, , drop = FALSE]
        sym <- if (nrow(cell) > 0) toupper(trimws(cell$sub_text[1] %||% "S")) else "S"
        total <- total + (if (sym == "+") 1 else if (sym == "-") -1 else 0)
      }
      html_parts <- c(html_parts, sprintf('<td><strong>%+d</strong></td>', total))
    }
    html_parts <- c(html_parts, '</tr></tbody></table>')

  } else if (diagram_type == "fmea_table") {
    # ---- RPN is COMPUTED HERE (Severity x Occurrence x Detection), never
    #     trusted from Claude - see sixsigma_type_instructions("fmea_table").
    #     Rows are sorted by computed RPN descending (highest risk first),
    #     and color-banded using the standard FMEA convention: RPN >= 200
    #     high risk (red), 100-199 medium (amber), < 100 lower (green). ----
    fmea_rows <- body_rows[body_rows$component_type == "table_cell" & !is.na(body_rows$severity), , drop = FALSE]
    fmea_rows$rpn <- fmea_rows$severity * fmea_rows$occurrence * fmea_rows$detection
    fmea_rows <- fmea_rows[order(-fmea_rows$rpn), , drop = FALSE]

    html_parts <- c(html_parts, '<table class="ss-data-table ss-fmea-table"><thead><tr>',
                    '<th>Failure Mode</th><th>Potential Effect</th><th>Potential Causes</th>',
                    '<th>S</th><th>O</th><th>D</th><th>RPN</th></tr></thead><tbody>')
    for (i in seq_len(nrow(fmea_rows))) {
      row <- fmea_rows[i, ]
      items <- sixsigma_unpack_items(row$items_packed)
      causes_html <- if (length(items) > 0) paste(htmltools::htmlEscape(items), collapse = "; ") else "-"
      rpn_class <- if (row$rpn >= 200) "ss-rpn-high" else if (row$rpn >= 100) "ss-rpn-medium" else "ss-rpn-low"
      html_parts <- c(html_parts, sprintf(
        '<tr><td>%s</td><td>%s</td><td>%s</td><td>%d</td><td>%d</td><td>%d</td><td><span class="ss-rpn-badge %s">%d</span></td></tr>',
        htmltools::htmlEscape(row$label_text %||% ""), htmltools::htmlEscape(row$sub_text %||% ""), causes_html,
        row$severity, row$occurrence, row$detection, rpn_class, row$rpn
      ))
    }
    html_parts <- c(html_parts, '</tbody></table>',
                    '<p class="details-text" style="margin-top:10px;"><span class="ss-rpn-badge ss-rpn-high">RPN &ge; 200</span> High priority &nbsp; ',
                    '<span class="ss-rpn-badge ss-rpn-medium">100-199</span> Medium priority &nbsp; ',
                    '<span class="ss-rpn-badge ss-rpn-low">&lt; 100</span> Lower priority</p>')
  }

  html_parts <- c(html_parts, '</div>')
  HTML(paste(html_parts, collapse = ""))
}

# ---- SVG family: fishbone, ctq_tree - geometry (bone angles, tree
#     levels/positions) computed server-side in R. Claude never supplies
#     a coordinate for either.
render_sixsigma_svg <- function(components_df, diagram_type) {
  title_row <- components_df[components_df$component_type == "title", , drop = FALSE]
  title_text <- if (nrow(title_row) > 0) title_row$label_text[1] else components_df$diagram_name[1]

  if (diagram_type == "fishbone") {
    effect_row <- components_df[components_df$component_type == "effect_box", , drop = FALSE]
    effect_text <- if (nrow(effect_row) > 0) effect_row$label_text[1] else title_text
    bones <- components_df[components_df$component_type == "bone_category", , drop = FALSE]
    bones <- bones[order(bones$sequence_order), , drop = FALSE]
    n <- nrow(bones)

    W <- 900; H <- 480
    spine_y <- H / 2
    head_x <- W - 110
    tail_x <- 60
    box_w <- 190

    svg_parts <- character(0)
    # Spine (the fish's backbone)
    svg_parts <- c(svg_parts, sprintf('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="var(--ss-spine-color, #37474F)" stroke-width="4" />', tail_x, spine_y, head_x - 15, spine_y))
    # Head / effect box (arrow shape via polygon)
    svg_parts <- c(svg_parts, sprintf(
      '<polygon points="%d,%d %d,%d %d,%d %d,%d" fill="var(--ss-effect-color, #C0392B)" />',
      head_x - 15, spine_y - 55, head_x + 70, spine_y, head_x - 15, spine_y + 55, head_x - 15, spine_y - 55
    ))
    svg_parts <- c(svg_parts, sprintf(
      '<foreignObject x="%d" y="%d" width="230" height="110"><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;align-items:center;justify-content:center;height:100%%;text-align:center;font-size:13px;font-weight:bold;color:white;padding:4px;">%s</div></foreignObject>',
      head_x - 210, spine_y - 55, htmltools::htmlEscape(effect_text)
    ))

    if (n > 0) {
      spacing <- (head_x - 90 - tail_x) / n
      for (i in seq_len(n)) {
        bone <- bones[i, ]
        is_upper <- (i %% 2 == 1)
        attach_x <- tail_x + spacing * i
        tip_y <- if (is_upper) spine_y - 150 else spine_y + 150
        tip_x <- attach_x - 70

        # Angled bone line
        svg_parts <- c(svg_parts, sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%d" stroke="%s" stroke-width="2.5" />',
                                          attach_x, spine_y, tip_x, tip_y,
                                          "var(--ss-bone-color, #607D8B)"))
        # Category label box at the tip
        box_y <- if (is_upper) tip_y - 34 else tip_y
        svg_parts <- c(svg_parts, sprintf(
          '<rect x="%.1f" y="%.1f" width="%d" height="30" rx="5" fill="%s" />',
          tip_x - box_w / 2, box_y, box_w, bone$color_hint %||% "var(--ss-bone-color, #607D8B)"
        ))
        svg_parts <- c(svg_parts, sprintf(
          '<foreignObject x="%.1f" y="%.1f" width="%d" height="30"><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;align-items:center;justify-content:center;height:100%%;font-size:12px;font-weight:bold;color:white;">%s</div></foreignObject>',
          tip_x - box_w / 2, box_y, box_w, htmltools::htmlEscape(bone$label_text %||% "")
        ))
        # Causes listed along the bone
        items <- sixsigma_unpack_items(bone$items_packed)
        if (length(items) > 0) {
          list_y <- if (is_upper) box_y - (length(items) * 16) - 6 else box_y + 36
          items_html <- paste0(sprintf('<div style="font-size:11px; color:#2c3e50;">&bull; %s</div>', htmltools::htmlEscape(items)), collapse = "")
          svg_parts <- c(svg_parts, sprintf(
            '<foreignObject x="%.1f" y="%.1f" width="%d" height="%d"><div xmlns="http://www.w3.org/1999/xhtml">%s</div></foreignObject>',
            tip_x - box_w / 2, list_y, box_w, length(items) * 16 + 10, items_html
          ))
        }
      }
    }

    svg <- sprintf('<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">%s</svg>', W, H, paste(svg_parts, collapse = ""))

  } else if (diagram_type == "spaghetti_diagram") {
    # Movement path through N locations, visited in sequence_order. R lays
    # the locations out in a simple grid pattern (deterministic, not left
    # to Claude) and draws the path connecting them in visit order - the
    # distances Claude supplies are the raw distance FROM the previous
    # stop, and the TOTAL is computed here, never trusted from Claude.
    stops <- components_df[components_df$component_type == "data_point", , drop = FALSE]
    stops <- stops[order(stops$sequence_order), , drop = FALSE]
    n <- nrow(stops)

    W <- 800; H <- 600
    n_cols <- ceiling(sqrt(n))
    n_rows <- ceiling(n / n_cols)
    cell_w <- W / (n_cols + 1); cell_h <- (H - 60) / (n_rows + 1)

    node_x <- function(i) cell_w * (((i - 1) %% n_cols) + 1)
    node_y <- function(i) 40 + cell_h * (((i - 1) %/% n_cols) + 1)

    svg_parts <- character(0)
    if (n > 0) {
      # Path lines first (drawn under the nodes)
      for (i in seq_len(n)) {
        if (i > 1) {
          svg_parts <- c(svg_parts, sprintf(
            '<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="var(--ss-effect-color, #C0392B)" stroke-width="2.5" stroke-dasharray="6,4" />',
            node_x(i - 1), node_y(i - 1), node_x(i), node_y(i)
          ))
        }
      }
      for (i in seq_len(n)) {
        x <- node_x(i); y <- node_y(i)
        svg_parts <- c(svg_parts, sprintf(
          '<circle cx="%.1f" cy="%.1f" r="34" fill="var(--ss-ctq-color, #2C8C99)" />
           <foreignObject x="%.1f" y="%.1f" width="120" height="70"><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;align-items:center;justify-content:center;height:100%%;text-align:center;color:white;font-size:11px;font-weight:600;padding:4px;">%d. %s</div></foreignObject>',
          x, y, x - 60, y - 35, i, htmltools::htmlEscape(stops$label_text[i] %||% "")
        ))
      }
    }
    total_distance <- sum(stops$value_numeric, na.rm = TRUE)
    unit <- if (has_real_value(stops$unit_label[1])) stops$unit_label[1] else "m"
    svg_parts <- c(svg_parts, sprintf(
      '<text x="%d" y="20" font-size="14" font-weight="bold" fill="var(--ss-spine-color, #37474F)">Total distance travelled: %.1f %s (computed from the %d individual legs)</text>',
      10, total_distance, unit, n
    ))
    cat(sprintf("🔎 [Six Sigma Analysis][DEBUG] Spaghetti diagram: total distance computed as %.1f %s across %d stops (never trusted from Claude)\n", total_distance, unit, n))

    svg <- sprintf('<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">%s</svg>', W, H, paste(svg_parts, collapse = ""))

  } else { # ctq_tree, voice_of_customer, current_reality_tree - generic 3-level tree renderer
    nodes <- components_df[components_df$component_type == "tree_node", , drop = FALSE]
    level1 <- nodes[nodes$grid_row == 1, , drop = FALSE]
    level2 <- nodes[nodes$grid_row == 2, , drop = FALSE]
    level2 <- level2[order(level2$sequence_order), , drop = FALSE]
    level3 <- nodes[nodes$grid_row == 3, , drop = FALSE]
    level3 <- level3[order(level3$sequence_order), , drop = FALSE]

    W <- 960
    row_h <- 130
    H <- row_h * 3 + 60
    box_w <- 170; box_h <- 60

    node_x <- function(index, count, width) {
      slot_w <- width / count
      slot_w * (index - 0.5)
    }

    svg_parts <- character(0)
    positions <- list()  # component_ref -> list(x, y)

    if (nrow(level1) > 0) {
      x <- W / 2
      y <- 30
      positions[[level1$component_ref[1]]] <- list(x = x, y = y + box_h / 2)
      svg_parts <- c(svg_parts, sprintf(
        '<rect x="%.1f" y="%.1f" width="%d" height="%d" rx="8" fill="var(--ss-effect-color, #C0392B)" />
         <foreignObject x="%.1f" y="%.1f" width="%d" height="%d"><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;align-items:center;justify-content:center;height:100%%;text-align:center;color:white;font-weight:bold;font-size:13px;padding:6px;">%s</div></foreignObject>',
        x - box_w / 2, y, box_w, box_h, x - box_w / 2, y, box_w, box_h, htmltools::htmlEscape(level1$label_text[1] %||% "")
      ))
    }

    if (nrow(level2) > 0) {
      y <- row_h + 30
      n2 <- nrow(level2)
      for (i in seq_len(n2)) {
        x <- node_x(i, n2, W)
        positions[[level2$component_ref[i]]] <- list(x = x, y = y + box_h / 2)
        parent_pos <- positions[[level2$parent_ref[i]]]
        if (!is.null(parent_pos)) {
          svg_parts <- c(svg_parts, sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#999" stroke-width="2" />',
                                            parent_pos$x, parent_pos$y, x, y))
        }
        svg_parts <- c(svg_parts, sprintf(
          '<rect x="%.1f" y="%.1f" width="%d" height="%d" rx="8" fill="var(--ss-ctq-color, #2C8C99)" />
           <foreignObject x="%.1f" y="%.1f" width="%d" height="%d"><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;align-items:center;justify-content:center;height:100%%;text-align:center;color:white;font-weight:bold;font-size:12px;padding:5px;">%s</div></foreignObject>',
          x - box_w / 2, y, box_w, box_h, x - box_w / 2, y, box_w, box_h, htmltools::htmlEscape(level2$label_text[i] %||% "")
        ))
      }
    }

    if (nrow(level3) > 0) {
      y <- row_h * 2 + 30
      n3 <- nrow(level3)
      for (i in seq_len(n3)) {
        x <- node_x(i, n3, W)
        parent_pos <- positions[[level3$parent_ref[i]]]
        if (!is.null(parent_pos)) {
          svg_parts <- c(svg_parts, sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#ccc" stroke-width="1.5" />',
                                            parent_pos$x, parent_pos$y, x, y))
        }
        svg_parts <- c(svg_parts, sprintf(
          '<rect x="%.1f" y="%.1f" width="%d" height="%d" rx="6" fill="var(--ss-metric-color, #4CAF50)" />
           <foreignObject x="%.1f" y="%.1f" width="%d" height="%d"><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;align-items:center;justify-content:center;height:100%%;text-align:center;color:white;font-size:11px;padding:5px;">%s</div></foreignObject>',
          x - box_w / 2, y, box_w, box_h, x - box_w / 2, y, box_w, box_h, htmltools::htmlEscape(level3$label_text[i] %||% "")
        ))
      }
    }

    svg <- sprintf('<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">%s</svg>', W, H, paste(svg_parts, collapse = ""))
  }

  tagList(
    tags$div(class = "diagram-card ss-card",
      tags$div(class = "chapter-title", tags$i(class = "fa fa-industry"), " ", title_text),
      HTML(svg)
    )
  )
}

# ---- Plotly family: pareto, control_chart. This is where the "never
#     trust Claude with arithmetic" rule matters most - EVERY derived
#     statistic below (sort order, cumulative %, the 80% line, center
#     line, +/-3-sigma control limits) is computed here from Claude's
#     raw values, never read from anything Claude wrote (see
#     sixsigma_type_instructions() for the corresponding "supply only
#     raw values" instructions given to Claude).
render_sixsigma_plotly <- function(components_df, diagram_type) {
  title_row <- components_df[components_df$component_type == "title", , drop = FALSE]
  title_text <- if (nrow(title_row) > 0) title_row$label_text[1] else components_df$diagram_name[1]
  points <- components_df[components_df$component_type == "data_point", , drop = FALSE]

  if (diagram_type == "pareto") {
    # ---- Sort descending by raw value, compute cumulative % ourselves ----
    ordered <- points[order(-points$value_numeric), , drop = FALSE]
    ordered$cum_pct <- cumsum(ordered$value_numeric) / sum(ordered$value_numeric) * 100
    unit <- if (has_real_value(ordered$unit_label[1])) ordered$unit_label[1] else "count"

    p <- plotly::plot_ly()
    p <- plotly::add_trace(p, x = factor(ordered$label_text, levels = ordered$label_text), y = ordered$value_numeric,
                           type = "bar", name = unit, marker = list(color = "#2C8C99"),
                           yaxis = "y1")
    p <- plotly::add_trace(p, x = factor(ordered$label_text, levels = ordered$label_text), y = ordered$cum_pct,
                           type = "scatter", mode = "lines+markers", name = "Cumulative %",
                           line = list(color = "#C0392B", width = 2.5), marker = list(color = "#C0392B"),
                           yaxis = "y2")
    # 80% reference line - the whole point of a Pareto chart
    p <- plotly::add_trace(p, x = factor(ordered$label_text, levels = ordered$label_text),
                           y = rep(80, nrow(ordered)), type = "scatter", mode = "lines",
                           name = "80% threshold", line = list(color = "#999", width = 1.5, dash = "dash"),
                           yaxis = "y2")
    p <- plotly::layout(p,
      title = title_text,
      xaxis = list(title = ""),
      yaxis = list(title = unit, side = "left"),
      yaxis2 = list(title = "Cumulative %", side = "right", overlaying = "y", range = c(0, 105)),
      legend = list(orientation = "h", y = -0.2)
    )

  } else if (diagram_type == "control_chart") {
    ordered <- points[order(points$sequence_order), , drop = FALSE]
    values <- ordered$value_numeric
    metric_name <- if (has_real_value(ordered$metric_name[1])) ordered$metric_name[1] else "Measured value"

    center_line <- mean(values, na.rm = TRUE)
    sigma <- sd(values, na.rm = TRUE)
    ucl <- center_line + 3 * sigma
    lcl <- max(center_line - 3 * sigma, 0)  # a measured quantity is rarely meaningfully negative
    out_of_control <- values > ucl | values < lcl

    p <- plotly::plot_ly()
    p <- plotly::add_trace(p, x = ordered$sequence_order, y = values, type = "scatter", mode = "lines+markers",
                           name = metric_name,
                           marker = list(color = ifelse(out_of_control, "#C0392B", "#2C8C99"), size = 9),
                           line = list(color = "#2C8C99"))
    p <- plotly::add_trace(p, x = ordered$sequence_order, y = rep(center_line, nrow(ordered)),
                           type = "scatter", mode = "lines", name = sprintf("Center Line (%.2f)", center_line),
                           line = list(color = "#37474F", width = 1.5))
    p <- plotly::add_trace(p, x = ordered$sequence_order, y = rep(ucl, nrow(ordered)),
                           type = "scatter", mode = "lines", name = sprintf("UCL (%.2f)", ucl),
                           line = list(color = "#C0392B", width = 1.5, dash = "dash"))
    p <- plotly::add_trace(p, x = ordered$sequence_order, y = rep(lcl, nrow(ordered)),
                           type = "scatter", mode = "lines", name = sprintf("LCL (%.2f)", lcl),
                           line = list(color = "#C0392B", width = 1.5, dash = "dash"))
    p <- plotly::layout(p,
      title = sprintf("%s (center line and \u00b13\u03c3 limits computed from the %d points shown)", title_text, nrow(ordered)),
      xaxis = list(title = "Sample / Time Order"),
      yaxis = list(title = metric_name),
      legend = list(orientation = "h", y = -0.2)
    )

    if (any(out_of_control)) {
      cat(sprintf("⚠️  [Six Sigma Analysis][DEBUG] Control chart: %d point(s) OUT OF CONTROL (beyond \u00b13\u03c3)\n", sum(out_of_control)))
    }

  } else if (diagram_type == "gage_rr") {
    # Claude supplies the 3 raw variance-contribution percentages directly
    # (nothing derived to compute here) - displayed as a simple bar chart,
    # with the standard <10% "acceptable measurement system" reference line.
    unit <- if (has_real_value(points$unit_label[1])) points$unit_label[1] else "%"
    p <- plotly::plot_ly(points, x = ~label_text, y = ~value_numeric, type = "bar",
                         marker = list(color = c("#2C8C99", "#E08E45", "#4CAF50")[seq_len(nrow(points))]))
    p <- plotly::add_trace(p, x = points$label_text, y = rep(10, nrow(points)), type = "scatter", mode = "lines",
                           name = "10% acceptable threshold", line = list(color = "#C0392B", width = 1.5, dash = "dash"))
    p <- plotly::layout(p, title = title_text, xaxis = list(title = ""), yaxis = list(title = paste("Contribution to total variation (", unit, ")")))

  } else if (diagram_type == "histogram") {
    ordered <- points[order(points$sequence_order), , drop = FALSE]
    p <- plotly::plot_ly(ordered, x = ~factor(label_text, levels = label_text), y = ~value_numeric, type = "bar",
                         marker = list(color = "#2C8C99"))
    p <- plotly::layout(p, title = title_text, xaxis = list(title = "Bin"), yaxis = list(title = "Frequency"))

  } else if (diagram_type == "scatter_plot") {
    # Claude supplies only raw (x,y) points - the trend line AND the
    # correlation coefficient are both computed here via lm()/cor(),
    # never trusted from Claude.
    x_vals <- points$value_numeric[points$value_axis == "x"][order(points$sequence_order[points$value_axis == "x"])]
    y_vals <- points$value_numeric[points$value_axis == "y"][order(points$sequence_order[points$value_axis == "y"])]
    axis_rows <- components_df[components_df$component_type == "axis", , drop = FALSE]
    x_label <- axis_rows$metric_name[axis_rows$value_axis == "x"][1] %||% "X"
    y_label <- axis_rows$metric_name[axis_rows$value_axis == "y"][1] %||% "Y"

    p <- plotly::plot_ly(x = x_vals, y = y_vals, type = "scatter", mode = "markers",
                         marker = list(color = "#2C8C99", size = 10), name = "Observations")

    correlation_note <- ""
    if (length(x_vals) >= 3 && length(x_vals) == length(y_vals)) {
      fit <- tryCatch(lm(y_vals ~ x_vals), error = function(e) NULL)
      r <- tryCatch(cor(x_vals, y_vals), error = function(e) NA)
      if (!is.null(fit) && !is.na(r)) {
        x_range <- seq(min(x_vals), max(x_vals), length.out = 50)
        y_pred <- predict(fit, newdata = data.frame(x_vals = x_range))
        p <- plotly::add_trace(p, x = x_range, y = y_pred, type = "scatter", mode = "lines",
                               name = sprintf("Trend line (r = %.2f)", r),
                               line = list(color = "#C0392B", width = 2))
        correlation_note <- sprintf(" (correlation r = %.2f, computed from the %d points shown)", r, length(x_vals))
        cat(sprintf("🔎 [Six Sigma Analysis][DEBUG] Scatter plot: correlation r=%.3f computed from %d points (never trusted from Claude)\n", r, length(x_vals)))
      }
    }
    p <- plotly::layout(p, title = paste0(title_text, correlation_note), xaxis = list(title = x_label), yaxis = list(title = y_label))

  } else if (diagram_type == "normal_distribution") {
    # Claude supplies ONLY mean and standard deviation - the entire bell
    # curve is computed here via dnorm(), with +-1/2/3 sigma zones shaded,
    # never trusted from Claude as a drawn/described shape.
    mean_val <- points$value_numeric[1]
    sigma <- points$axis_min[1]
    metric_name <- if (has_real_value(points$metric_name[1])) points$metric_name[1] else "Value"
    x_range <- seq(mean_val - 4 * sigma, mean_val + 4 * sigma, length.out = 200)
    y_density <- dnorm(x_range, mean = mean_val, sd = sigma)

    cat(sprintf("🔎 [Six Sigma Analysis][DEBUG] Normal distribution: curve computed from mean=%.3f, sd=%.3f (never trusted from Claude)\n", mean_val, sigma))

    p <- plotly::plot_ly(x = x_range, y = y_density, type = "scatter", mode = "lines", fill = "tozeroy",
                         line = list(color = "#2C8C99", width = 2), fillcolor = "rgba(44,140,153,0.15)", name = "Distribution")
    for (k in 1:3) {
      p <- plotly::add_trace(p, x = c(mean_val - k * sigma, mean_val - k * sigma), y = c(0, max(y_density)),
                             type = "scatter", mode = "lines", line = list(color = "#999", width = 1, dash = "dot"),
                             showlegend = (k == 1), name = "\u00b1k\u03c3 boundaries")
      p <- plotly::add_trace(p, x = c(mean_val + k * sigma, mean_val + k * sigma), y = c(0, max(y_density)),
                             type = "scatter", mode = "lines", line = list(color = "#999", width = 1, dash = "dot"),
                             showlegend = FALSE)
    }
    p <- plotly::layout(p,
      title = sprintf("%s (mean=%.2f, \u03c3=%.2f - curve computed, not drawn by Claude)", title_text, mean_val, sigma),
      xaxis = list(title = metric_name), yaxis = list(title = "Probability Density"))

  } else { # process_capability
    mean_val <- points$value_numeric[1]
    sigma <- points$axis_min[1]
    usl <- points$axis_max[1]
    lsl <- suppressWarnings(as.numeric(points$unit_label[1]))
    metric_name <- if (has_real_value(points$metric_name[1])) points$metric_name[1] else "Value"

    # ---- Cp, Cpk, and an approximate sigma level are ALL computed here,
    #     never trusted from Claude - see sixsigma_type_instructions()
    #     which explicitly forbids Claude from doing this arithmetic. ----
    cp <- (usl - lsl) / (6 * sigma)
    cpk <- min((usl - mean_val) / (3 * sigma), (mean_val - lsl) / (3 * sigma))
    # Rough sigma-level approximation from Cpk (long-term, with the
    # standard 1.5-sigma shift) - a well-known approximation, not exact.
    sigma_level <- 3 * cpk + 1.5

    cat(sprintf("🔎 [Six Sigma Analysis][DEBUG] Process capability: Cp=%.3f, Cpk=%.3f, approx sigma level=%.2f (all computed, never trusted from Claude)\n", cp, cpk, sigma_level))

    x_range <- seq(min(lsl, mean_val - 4 * sigma), max(usl, mean_val + 4 * sigma), length.out = 200)
    y_density <- dnorm(x_range, mean = mean_val, sd = sigma)

    p <- plotly::plot_ly(x = x_range, y = y_density, type = "scatter", mode = "lines", fill = "tozeroy",
                         line = list(color = "#2C8C99", width = 2), fillcolor = "rgba(44,140,153,0.15)", name = "Process distribution")
    p <- plotly::add_trace(p, x = c(usl, usl), y = c(0, max(y_density)), type = "scatter", mode = "lines",
                           name = sprintf("USL (%.2f)", usl), line = list(color = "#C0392B", width = 2, dash = "dash"))
    p <- plotly::add_trace(p, x = c(lsl, lsl), y = c(0, max(y_density)), type = "scatter", mode = "lines",
                           name = sprintf("LSL (%.2f)", lsl), line = list(color = "#C0392B", width = 2, dash = "dash"))
    p <- plotly::layout(p,
      title = sprintf("%s | Cp = %.2f, Cpk = %.2f, approx. sigma level = %.1f\u03c3 (all computed from your mean/sd/USL/LSL, never Claude's arithmetic)",
                      title_text, cp, cpk, sigma_level),
      xaxis = list(title = metric_name), yaxis = list(title = "Probability Density"))
  }

  tagList(
    tags$div(class = "chapter-title", tags$i(class = "fa fa-chart-line"), " ", title_text),
    p
  )
}

# ============================================================
# SANKEY GRAPH (AI-generated Sankey flow diagrams)
# ============================================================
# A Sankey is fundamentally NODES (labeled boxes at a specific left-right
# column) plus WEIGHTED LINKS between them (source -> target, a flow
# magnitude) - genuinely different from Mind Map's tree or Knowledge
# Graph's general graph, so this suite gets its own table
# (sankey_graphs) with a row_kind = "node"/"link" split, mirroring
# Knowledge Graph's entity/relationship denormalization pattern but
# WITHOUT KG's versioning complexity (append-only, same simple pattern
# as Strategic Analysis/Six Sigma - this suite's Generate -> Bulk Import
# -> upload flow has no in-place editing).
#
# CRITICAL DESIGN PRINCIPLE, same one used throughout this app: node
# height and link curve width are NEVER computed by Claude or by R -
# the d3-sankey JS layout algorithm derives both directly from the raw
# value_numeric figures on each link, at render time, in the browser.
# Claude supplies only which nodes exist, which column each sits in,
# and the raw flow value of each link.
#
# Links may SKIP AHEAD any number of columns (e.g. column 1 straight to
# column 5) - only the constraint that a link's target column must be
# strictly greater than its source column is enforced (never backward,
# never same-column, matching how real Sankeys, e.g. energy-flow or
# budget diagrams, actually behave when a flow bypasses intermediate
# stages).

SANKEY_ITEM_SEP <- "|||SKYITEM|||"

SANKEY_FIELDS <- c(
  "row_kind", "component_ref", "column_index", "sequence_order",
  "label_text", "sub_text", "items_packed",
  "source_ref", "target_ref", "value_numeric", "unit_label",
  "color_hint"
)

generate_new_sankey_id <- function(topic) {
  slug <- tolower(gsub("[^a-zA-Z0-9]+", "-", trimws(topic)))
  slug <- gsub("^-+|-+$", "", slug)
  if (nchar(slug) == 0) slug <- "sankey"
  if (nchar(slug) > 40) slug <- substr(slug, 1, 40)
  paste0(slug, "-", format(Sys.time(), "%Y%m%d%H%M%S"))
}

# ---- Prompt construction ---------------------------------------------
# num_columns and num_initial_rows come from the Generate tab's sliders
# (2-12 and 2-20 respectively) - they are FIXED inputs to the prompt, not
# something Claude chooses, and are force-echoed into the metadata block
# by overwrite_sankey_header() afterwards exactly like every other fixed
# field in this app.
generate_sankey_prompt <- function(category, domain, topic, title_hint, num_columns, num_initial_rows, user_request) {
  sep <- SANKEY_ITEM_SEP

  title_line <- if (nchar(trimws(title_hint %||% "")) > 0) {
    paste0('[', trimws(title_hint), ']')
  } else {
    '[<invent a concise, specific title for this Sankey diagram based on the user request>]'
  }

  paste0(
    'You are a data visualization consultant building a professional Sankey flow diagram. A Sankey shows how ',
    'a quantity (money, energy, people, material, time - whatever fits the topic) flows and redistributes from ',
    'left to right through a sequence of stages, with the WIDTH of each flow proportional to its magnitude.\n\n',

    'Category: ', category, '. Domain: ', domain, '. Topic: ', topic, '.\n\n',
    'The user\'s specific request: "', user_request, '"\n\n',

    'Populate the diagram with content genuinely specific to this request (real node names, real plausible ',
    'magnitudes) - reason about the actual flow being described before inventing labels and values. Do not use ',
    'generic placeholders like "Node 1" or "Category A".\n\n',

    '=== STRUCTURE (mandatory) ===\n',
    'Exactly ', num_columns, ' columns, numbered 1 (leftmost) to ', num_columns, ' (rightmost).\n',
    'Column 1 must contain EXACTLY ', num_initial_rows, ' nodes - these are the starting streams the whole ',
    'diagram flows from.\n',
    'Columns 2 through ', num_columns, ' may each contain a DIFFERENT number of nodes than the column before ',
    'them, however many are needed as flows genuinely merge (several sources into one target) or split (one ',
    'source into several targets) on their way across the diagram - do not force every column to have the same ',
    'node count.\n\n',

    '=== LINKS (mandatory) ===\n',
    'Every link goes from a node in an EARLIER column to a node in a LATER column - a link\'s target column ',
    'number must always be strictly greater than its source column number. Links are allowed to SKIP AHEAD ',
    'past intermediate columns (e.g. a column-1 node linking directly to a column-4 node, bypassing columns 2 ',
    'and 3) whenever that reflects the real flow - use this deliberately where it makes sense (e.g. a source ',
    'that bypasses processing stages, a direct pass-through, a leak or loss straight to a final "Other/Unused" ',
    'node), not on every link.\n',
    'Every node in column 1 must have at least one OUTGOING link (it is a pure source). Every node in the ',
    'final column must have at least one INCOMING link (it is a pure sink) and no outgoing links. Every node ',
    'in between should have at least one incoming AND at least one outgoing link - a node with no connections ',
    'at all should not exist.\n',
    'Where a node has both incoming and outgoing links, its total outgoing flow should roughly match (not ',
    'necessarily exactly) its total incoming flow, the way a real conserved quantity would - do not calculate ',
    'this precisely, just keep the numbers plausible and in the right ballpark; the renderer does not validate ',
    'exact conservation.\n',
    'Give links genuinely varied values (not all equal) so the diagram\'s flow widths look meaningfully ',
    'different from each other - a professional Sankey has a visible mix of thick and thin flows.\n\n',

    '=== OUTPUT FORMAT ===\n',
    'Output ONLY the metadata block below followed by bracket-tag row blocks in the exact format specified - ',
    'no markdown, no prose commentary, no code fences.\n\n',

    '1. Start with EXACTLY 6 metadata lines, each on its own line, each containing ONLY the actual value ',
    'wrapped in single square brackets - no field name, no colon. Lines 1-5 are fixed by the user\'s selection ',
    '(do not change them); line 6 is the title as instructed below. The first 6 lines of your entire response ',
    'must be EXACTLY:\n',
    '[', num_columns, ']\n[', num_initial_rows, ']\n[', category, ']\n[', domain, ']\n[', topic, ']\n', title_line, '\n\n',

    '2. Leave exactly ONE blank line after the metadata block. Then output one block per row (a node OR a ',
    'link), separated by a single blank line from the next block. Do not skip a field - write "N/A" if genuinely ',
    'not applicable.\n\n',

    'CRITICAL: within [items_packed], separate multiple items with the EXACT literal token "', sep, '". ',
    'NEVER use "', sep, '" anywhere else.\n\n',

    'CRITICAL: every [component_ref] must be unique within this diagram. Use the naming convention c<column>n<index>, ',
    'e.g. c1n1, c1n2, c2n1, c3n1, c3n2, c3n3 - this makes it obvious which column a node belongs to and keeps ',
    'refs unambiguous when links reference them.\n\n',

    'For EACH node:\n',
    '[row_kind]: node\n[component_ref]: <e.g. c2n1 - unique, encodes its column>\n',
    '[column_index]: <1..', num_columns, ', matching the number in its component_ref>\n',
    '[sequence_order]: <top-to-bottom position within its column, 1 = topmost>\n',
    '[label_text]: <the node name - specific and real, not generic>\n',
    '[sub_text]: <a short one-line description of what this node represents for this specific topic, else N/A>\n',
    '[items_packed]: <an optional extra detail 1>', sep, '<optional extra detail 2> (N/A if none)\n',
    '[color_hint]: <accent_blue|accent_orange|accent_green|accent_purple|accent_teal|neutral_dark - vary these across columns/categories of node, not every node the same color>\n\n',

    'For EACH link:\n',
    '[row_kind]: link\n[source_ref]: <the component_ref of the source node>\n',
    '[target_ref]: <the component_ref of the target node, in a STRICTLY LATER column than the source>\n',
    '[value_numeric]: <the flow magnitude, a plain positive number, genuinely varied across links>\n',
    '[unit_label]: <the unit this value is measured in, specific to the topic, e.g. "$M", "MWh", "customers", "%">\n\n',

    'Title block: this is line 6 of the metadata above, not a separate row block - do not repeat it as a row.\n\n',

    'Now generate the Sankey diagram, beginning with the 6 metadata lines.'
  )
}

# Force-overwrite the metadata block's first 5 positional bare-bracket
# lines (num_columns/num_initial_rows/category/domain/topic - fixed by
# the user's slider/dropdown selections, never Claude's to change) back
# to the authoritative values. The 6th line (title) is only forced when
# the user supplied an explicit title_hint.
overwrite_sankey_header <- function(text, num_columns, num_initial_rows, category, domain, topic, title_override = NULL) {
  lines <- strsplit(text, "\n")[[1]]
  metadata_line_idx <- which(grepl("^\\[.+\\]$", trimws(lines)))
  metadata_line_idx <- head(metadata_line_idx, 6)

  values <- list(num_columns, num_initial_rows, category, domain, topic, title_override)
  for (i in seq_along(metadata_line_idx)) {
    v <- values[[i]]
    if (!is.null(v) && !is.na(v) && nchar(trimws(as.character(v))) > 0) {
      lines[metadata_line_idx[i]] <- paste0("[", trimws(as.character(v)), "]")
    }
  }
  paste(lines, collapse = "\n")
}

# Parser: mirrors parse_diagram_text()/parse_sixsigma_text()'s proven
# two-part structure exactly (same "for loop uses plain <-, only
# flush_block()'s own closure body uses <<-" scoping discipline that
# fixed the original "object 'current' not found" bug in this app).
#
# Part 1 - METADATA: 6 bare "[value]" lines give num_columns/
# num_initial_rows/category/domain/topic/title.
# Part 2 - ROWS: "[field]: value" tagged blocks (nodes and links mixed
# together, distinguished by their row_kind field), blank-line separated.
parse_sankey_text <- function(text, sankey_id, is_template = FALSE, source_sankey_id = NA, created_by = "claude_agent") {
  lines <- strsplit(text, "\n")[[1]]

  # ---- Part 1: metadata block ----
  num_columns <- NULL; num_initial_rows <- NULL; category <- NULL; domain <- NULL; topic <- NULL; title <- NULL
  metadata_count <- 0
  for (i in seq_len(min(20, length(lines)))) {
    line <- trimws(lines[i])
    if (grepl("^\\[.+\\]$", line)) {
      metadata_count <- metadata_count + 1
      value <- gsub("^\\[|\\]$", "", line)
      if (metadata_count == 1) num_columns <- value
      else if (metadata_count == 2) num_initial_rows <- value
      else if (metadata_count == 3) category <- value
      else if (metadata_count == 4) domain <- value
      else if (metadata_count == 5) topic <- value
      else if (metadata_count == 6) title <- value
      else break
    }
  }
  num_columns <- suppressWarnings(as.integer(num_columns))
  num_initial_rows <- suppressWarnings(as.integer(num_initial_rows))
  if (is.na(num_columns) || is.na(num_initial_rows)) {
    stop("Could not find valid numeric column/row counts in the first two metadata lines of the generated text")
  }
  if (is.null(category) || is.null(domain) || is.null(topic)) {
    stop("Could not find Category, Domain, and Topic metadata in the generated Sankey text")
  }
  if (is.null(title) || nchar(trimws(title)) == 0) title <- topic

  # ---- Part 2: row blocks ("[field]: value" tags) ----
  blocks <- list()
  current <- list()
  last_field <- NULL

  flush_block <- function() {
    if (length(current) > 0 && !is.null(current$row_kind)) {
      blocks[[length(blocks) + 1]] <<- current
    }
  }

  for (line in lines) {
    line <- trimws(line)

    if (line == "" || grepl("^\\[.+\\]$", line)) {
      flush_block()
      current <- list()
      last_field <- NULL
      next
    }

    matched <- FALSE
    for (field in SANKEY_FIELDS) {
      pat <- paste0("^\\[", field, "\\]:\\s*(.*)$")
      if (grepl(pat, line, ignore.case = TRUE)) {
        value <- trimws(sub(pat, "\\1", line, ignore.case = TRUE))
        if (field == "row_kind" && !is.null(current$row_kind)) {
          flush_block()
          current <- list()
        }
        current[[field]] <- value
        last_field <- field
        matched <- TRUE
        break
      }
    }
    if (!matched && length(current) > 0 && !is.null(last_field)) {
      current[[last_field]] <- paste(current[[last_field]], line)
    }
  }
  flush_block()

  if (length(blocks) == 0) stop("No valid node/link blocks found in the generated Sankey text")

  df <- data.frame(
    sankey_id = character(), title = character(), category = character(), domain = character(), topic = character(),
    is_template = logical(), source_sankey_id = character(),
    num_columns = integer(), num_initial_rows = integer(),
    row_kind = character(), component_ref = character(), column_index = integer(), sequence_order = integer(),
    label_text = character(), sub_text = character(), items_packed = character(),
    source_ref = character(), target_ref = character(), value_numeric = numeric(), unit_label = character(),
    color_hint = character(), created_by = character(),
    stringsAsFactors = FALSE
  )

  na_int <- function(x) suppressWarnings(as.integer(x %||% NA))
  na_num <- function(x) suppressWarnings(as.numeric(x %||% NA))

  for (b in blocks) {
    df <- rbind(df, data.frame(
      sankey_id = sankey_id, title = title, category = category, domain = domain, topic = topic,
      is_template = is_template, source_sankey_id = as.character(source_sankey_id %||% NA),
      num_columns = num_columns, num_initial_rows = num_initial_rows,
      row_kind = b$row_kind %||% "", component_ref = b$component_ref %||% NA_character_,
      column_index = na_int(b$column_index), sequence_order = na_int(b$sequence_order),
      label_text = b$label_text %||% "", sub_text = b$sub_text %||% "", items_packed = b$items_packed %||% "",
      source_ref = b$source_ref %||% NA_character_, target_ref = b$target_ref %||% NA_character_,
      value_numeric = na_num(b$value_numeric), unit_label = b$unit_label %||% NA_character_,
      color_hint = b$color_hint %||% NA_character_, created_by = created_by,
      stringsAsFactors = FALSE
    ))
  }

  # ---- Sanity checks (warnings only, never block upload - Claude's
  #     creative content isn't rejected for imperfections, but these are
  #     printed to the console so problems are visible during review) ----
  node_rows <- df[df$row_kind == "node", ]
  link_rows <- df[df$row_kind == "link", ]
  if (nrow(node_rows) > 0) {
    node_refs <- node_rows$component_ref
    if (any(duplicated(node_refs))) {
      cat("⚠️  [Sankey Graph][DEBUG] Duplicate component_ref values found among nodes:",
          paste(unique(node_refs[duplicated(node_refs)]), collapse = ", "), "\n")
    }
    col1_count <- sum(node_rows$column_index == 1, na.rm = TRUE)
    if (col1_count != num_initial_rows) {
      cat(sprintf("⚠️  [Sankey Graph][DEBUG] Column 1 has %d node(s) but num_initial_rows was %d\n", col1_count, num_initial_rows))
    }
  }
  if (nrow(link_rows) > 0) {
    bad_links <- link_rows[!(link_rows$source_ref %in% node_rows$component_ref) |
                            !(link_rows$target_ref %in% node_rows$component_ref), ]
    if (nrow(bad_links) > 0) {
      cat(sprintf("⚠️  [Sankey Graph][DEBUG] %d link(s) reference a component_ref that doesn't match any parsed node\n", nrow(bad_links)))
    }
  }

  df
}

sankey_unpack_items <- function(items_packed) {
  if (!has_real_value(items_packed)) return(character(0))
  trimws(strsplit(items_packed, SANKEY_ITEM_SEP, fixed = TRUE)[[1]])
}

# ---- D3 Sankey renderer ------------------------------------------------
# Same raw-D3-in-HTML technique used by Knowledge Graph's D3 tab (a
# container div + a <script> block built from an r"---( ... )---" raw
# string template with __TOKEN__ placeholders substituted via gsub,
# rather than an R htmlwidgets wrapper package) - kept consistent with
# the rest of this app's D3 usage.
#
# Uses the d3-sankey plugin's nodeAlign() hook to force each node into
# its EXPLICIT column_index from the data, rather than letting d3-sankey
# auto-assign columns from graph topology (its default behavior, which
# would place a node as early as possible and break skip-ahead links'
# intended positioning). d3-sankey then computes every node's vertical
# extent and every link's curve width purely from the supplied
# value_numeric figures - the actual "hard math" of a Sankey layout is
# never done by Claude or by R.
render_sankey <- function(components_df) {
  cat(sprintf("🎨 [Sankey Graph][DEBUG] Rendering with %d row(s) (%d nodes, %d links)\n",
              nrow(components_df),
              sum(components_df$row_kind == "node"), sum(components_df$row_kind == "link")))

  if (nrow(components_df) == 0) {
    return(tags$div(class = "status-warning", "No components found for this Sankey diagram."))
  }

  title_text <- if (has_real_value(components_df$title[1])) components_df$title[1] else "Sankey Diagram"
  node_rows <- components_df[components_df$row_kind == "node", , drop = FALSE]
  link_rows <- components_df[components_df$row_kind == "link", , drop = FALSE]
  num_columns <- suppressWarnings(as.integer(components_df$num_columns[1]))
  if (is.na(num_columns) || num_columns < 1) num_columns <- max(node_rows$column_index, 1, na.rm = TRUE)

  if (nrow(node_rows) == 0) {
    return(tags$div(class = "status-error", "This Sankey diagram has no node rows to render."))
  }

  color_map <- c(
    accent_blue = "#2C8C99", accent_orange = "#E08E45", accent_green = "#4CAF50",
    accent_purple = "#8E44AD", accent_teal = "#008A82", neutral_dark = "#37474F"
  )
  resolve_color <- function(hint) {
    if (!has_real_value(hint)) return(unname(color_map["accent_blue"]))
    if (hint %in% names(color_map)) return(unname(color_map[hint]))
    if (grepl("^#[0-9A-Fa-f]{3,8}$", hint)) return(hint)
    unname(color_map["accent_blue"])
  }

  nodes_list <- lapply(seq_len(nrow(node_rows)), function(i) {
    r <- node_rows[i, ]
    items <- sankey_unpack_items(r$items_packed)
    list(
      id = r$component_ref,
      name = r$label_text %||% r$component_ref,
      sub_text = if (has_real_value(r$sub_text)) r$sub_text else "",
      items = if (length(items) > 0) paste(items, collapse = " \u2022 ") else "",
      column = (suppressWarnings(as.integer(r$column_index)) %||% 1L) - 1L,  # 0-indexed for D3
      color = resolve_color(r$color_hint)
    )
  })

  links_list <- lapply(seq_len(nrow(link_rows)), function(i) {
    r <- link_rows[i, ]
    list(
      source = r$source_ref,
      target = r$target_ref,
      value = suppressWarnings(as.numeric(r$value_numeric)) %||% 1,
      unit = if (has_real_value(r$unit_label)) r$unit_label else ""
    )
  })

  nodes_json <- as.character(jsonlite::toJSON(nodes_list, auto_unbox = TRUE, null = "null"))
  links_json <- as.character(jsonlite::toJSON(links_list, auto_unbox = TRUE, null = "null"))
  nodes_json <- gsub("</script", "<\\/script", nodes_json, fixed = TRUE)
  links_json <- gsub("</script", "<\\/script", links_json, fixed = TRUE)

  widget_id <- paste0("sankey_", as.integer(Sys.time()), "_", sample(1000:9999, 1))

  js <- r"---(
(function() {
  var nodesData = __NODES_JSON__;
  var linksData = __LINKS_JSON__;
  var numColumns = __NUM_COLUMNS__;
  var containerId = "__CONTAINER_ID__";

  var container = document.getElementById(containerId);
  if (!container) return;
  container.innerHTML = "";

  if (typeof d3.sankey !== "function") {
    container.innerHTML = '<div class="status-error">d3-sankey plugin failed to load.</div>';
    return;
  }

  var nodeCountInWidestColumn = 1;
  var perColumn = {};
  nodesData.forEach(function(n) {
    perColumn[n.column] = (perColumn[n.column] || 0) + 1;
    nodeCountInWidestColumn = Math.max(nodeCountInWidestColumn, perColumn[n.column]);
  });

  var margin = { top: 50, right: 200, bottom: 20, left: 200 };
  var width = Math.max(container.clientWidth || 1000, numColumns * 220);
  var height = Math.max(560, nodeCountInWidestColumn * 68);
  var innerWidth = width - margin.left - margin.right;
  var innerHeight = height - margin.top - margin.bottom;

  var svg = d3.select(container).append("svg")
      .attr("width", width)
      .attr("height", height)
      .attr("viewBox", [0, 0, width, height])
      .style("font-family", "inherit")
      .style("max-width", "100%")
      .style("height", "auto");

  svg.call(d3.zoom().scaleExtent([0.5, 3]).on("zoom", function(event) {
    g.attr("transform", event.transform);
  }));

  var g = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  var sankeyGen = d3.sankey()
      .nodeId(function(d) { return d.id; })
      .nodeAlign(function(d) { return d.column; })
      .nodeWidth(22)
      .nodePadding(22)
      .extent([[0, 0], [innerWidth, innerHeight]]);

  var graph;
  try {
    graph = sankeyGen({
      nodes: nodesData.map(function(d) { return Object.assign({}, d); }),
      links: linksData.map(function(d) { return Object.assign({}, d); })
    });
  } catch (e) {
    container.innerHTML = '<div class="status-error">Could not lay out this Sankey - check that every link\'s source_ref/target_ref matches a real node, and that no link points backward or to its own column. (' + e.message + ')</div>';
    return;
  }

  var tooltip = d3.select(container).append("div")
      .attr("class", "sankey-tooltip")
      .style("opacity", 0);

  // ---- Links: gradient-filled flowing paths, thickness computed by
  //     d3-sankey itself from each link's raw value - never Claude/R math
  var defs = svg.append("defs");
  graph.links.forEach(function(l, i) {
    var gradId = "__CONTAINER_ID__-grad-" + i;
    var grad = defs.append("linearGradient")
        .attr("id", gradId)
        .attr("gradientUnits", "userSpaceOnUse")
        .attr("x1", l.source.x1).attr("x2", l.target.x0);
    grad.append("stop").attr("offset", "0%").attr("stop-color", l.source.color);
    grad.append("stop").attr("offset", "100%").attr("stop-color", l.target.color);
    l.gradId = gradId;
  });

  var linkGroup = g.append("g").attr("fill", "none");
  var linkPaths = linkGroup.selectAll("path")
    .data(graph.links)
    .join("path")
      .attr("d", d3.sankeyLinkHorizontal())
      .attr("stroke", function(d) { return "url(#" + d.gradId + ")"; })
      .attr("stroke-width", function(d) { return Math.max(1, d.width); })
      .attr("stroke-opacity", 0.42)
      .style("cursor", "pointer")
      .on("mouseover", function(event, d) {
        d3.select(this).attr("stroke-opacity", 0.75);
        tooltip.style("opacity", 1).html(
          "<strong>" + d.source.name + " \u2192 " + d.target.name + "</strong><br/>" +
          d.value.toLocaleString() + (d.unit ? (" " + d.unit) : "")
        );
      })
      .on("mousemove", function(event) {
        tooltip.style("left", (event.offsetX + 16) + "px").style("top", (event.offsetY + 8) + "px");
      })
      .on("mouseout", function() {
        d3.select(this).attr("stroke-opacity", 0.42);
        tooltip.style("opacity", 0);
      });

  // ---- Nodes: rounded rects, colored per node ----
  var nodeGroup = g.append("g");
  var nodeSel = nodeGroup.selectAll("rect")
    .data(graph.nodes)
    .join("rect")
      .attr("x", function(d) { return d.x0; })
      .attr("y", function(d) { return d.y0; })
      .attr("width", function(d) { return d.x1 - d.x0; })
      .attr("height", function(d) { return Math.max(1, d.y1 - d.y0); })
      .attr("rx", 4)
      .attr("fill", function(d) { return d.color; })
      .attr("stroke", "#fff")
      .attr("stroke-width", 1)
      .style("cursor", "pointer")
      .on("mouseover", function(event, d) {
        var totalIn = d3.sum(d.targetLinks, function(l) { return l.value; });
        var totalOut = d3.sum(d.sourceLinks, function(l) { return l.value; });
        var unit = (d.targetLinks[0] && d.targetLinks[0].unit) || (d.sourceLinks[0] && d.sourceLinks[0].unit) || "";
        var flowLine = "";
        if (totalIn > 0) flowLine += "In: " + totalIn.toLocaleString() + " " + unit + "<br/>";
        if (totalOut > 0) flowLine += "Out: " + totalOut.toLocaleString() + " " + unit;
        tooltip.style("opacity", 1).html(
          "<strong>" + d.name + "</strong>" +
          (d.sub_text ? ("<br/><span style='opacity:0.85'>" + d.sub_text + "</span>") : "") +
          "<br/>" + flowLine +
          (d.items ? ("<br/><span style='opacity:0.75;font-size:0.9em'>" + d.items + "</span>") : "")
        );
      })
      .on("mousemove", function(event) {
        tooltip.style("left", (event.offsetX + 16) + "px").style("top", (event.offsetY + 8) + "px");
      })
      .on("mouseout", function() { tooltip.style("opacity", 0); });

  // ---- Node labels: placed left of node if it's in the right half of
  //     the diagram (else its text would run off the edge), right
  //     otherwise - the standard Sankey labeling convention.
  nodeGroup.selectAll("text")
    .data(graph.nodes)
    .join("text")
      .attr("x", function(d) { return d.x0 < innerWidth / 2 ? d.x1 + 8 : d.x0 - 8; })
      .attr("y", function(d) { return (d.y0 + d.y1) / 2; })
      .attr("dy", "0.35em")
      .attr("text-anchor", function(d) { return d.x0 < innerWidth / 2 ? "start" : "end"; })
      .style("font-size", "12px")
      .style("font-weight", "600")
      .style("fill", "#2c3e50")
      .style("pointer-events", "none")
      .text(function(d) { return d.name; });

  // ---- Title ----
  svg.append("text")
      .attr("x", width / 2).attr("y", 26)
      .attr("text-anchor", "middle")
      .style("font-size", "16px").style("font-weight", "bold").style("fill", "#2c3e50")
      .text("__TITLE_TEXT__");
})();
)---"

  js <- gsub("__NODES_JSON__", nodes_json, js, fixed = TRUE)
  js <- gsub("__LINKS_JSON__", links_json, js, fixed = TRUE)
  js <- gsub("__NUM_COLUMNS__", as.character(num_columns), js, fixed = TRUE)
  js <- gsub("__CONTAINER_ID__", widget_id, js, fixed = TRUE)
  js <- gsub("__TITLE_TEXT__", gsub('"', '\\\\"', title_text), js, fixed = TRUE)

  tagList(
    tags$div(class = "chapter-title", tags$i(class = "fa fa-water"), " ", title_text),
    tags$div(id = widget_id, class = "sankey-widget-container",
             style = "width: 100%; overflow-x: auto; border: 1px solid #e6ecec; border-radius: 8px; background: #fff;"),
    tags$script(HTML(js))
  )
}

# ============================================================
# STRATEGY TOOL RECOMMENDER (Strategic Analysis only)
# ============================================================
# Given a free-text problem description, Claude picks the top N
# frameworks from the FULL 29-framework catalog that best fit the
# problem, with reasoning and drawbacks per pick. The critical design
# constraint: Claude must echo back the exact internal diagram_type id
# (e.g. "bcg_matrix"), never a free-text name it invents - this is what
# lets a click on a recommended tool deterministically auto-select the
# right Group + Framework dropdown on the Generate Diagram tab (see
# generate_diagram/server.R's observer on
# api_manager$pending_diagram_selection()). Any id Claude returns that
# isn't a real, current diagram_type is dropped by
# parse_diagram_recommendations() rather than trusted - the same
# "validate, don't assume Claude's output is well-formed" discipline
# used by every parser in this app.

# One-sentence description per framework, used to build the catalog
# index Claude reasons over - condensed from diagram_tool_guide's own
# "when to use" text so the two stay in sync in spirit if not verbatim.
DIAGRAM_TYPE_SHORT_DESC <- c(
  swot = "Broad first-pass assessment of internal strengths/weaknesses and external opportunities/threats.",
  pestel = "Macro-environment scan across political, economic, social, technological, environmental, legal factors.",
  five_forces = "Assesses competitive intensity and attractiveness of an industry.",
  vrio = "Assesses whether a specific resource/capability is a genuine source of sustained competitive advantage.",
  value_chain = "Maps where value is created or lost across a firm's primary and support activities.",
  bcg_matrix = "Prioritizes investment across a product/business-unit portfolio by market growth and relative share.",
  ge_mckinsey_matrix = "Nuanced portfolio view weighing industry attractiveness against business unit strength.",
  ansoff_matrix = "Chooses a growth strategy along the products/markets dimensions.",
  porters_generic_strategies = "Chooses the basis of competitive advantage: cost or differentiation, broad or narrow scope.",
  tows_matrix = "Turns a SWOT's raw analysis into concrete SO/WO/ST/WT action strategies.",
  blue_ocean_errc = "Rethinks which factors of competition to eliminate, reduce, raise, or create to escape head-to-head competition.",
  value_curve = "Visually compares a strategic profile against competitors across the industry's key competitive factors.",
  business_model_canvas = "Complete one-page view of how a business creates, delivers, and captures value.",
  lean_canvas = "Validates an early-stage startup idea, focused on problem/solution fit over infrastructure.",
  frame_diagnose_choose_act = "Structures a specific strategic decision step by step.",
  pdca_cycle = "Runs a continuous-improvement loop (Plan-Do-Check-Act).",
  weighted_decision_matrix = "Compares options against multiple weighted criteria with raw scores laid out clearly.",
  mckinsey_7s = "Assesses whether an organization's structure, systems, and culture align with its strategy.",
  raci_matrix = "Clarifies who is Responsible, Accountable, Consulted, and Informed across a set of tasks.",
  disruptive_innovation = "Shows how a disruptor's performance trajectory could overtake an incumbent's.",
  product_lifecycle = "Shows where a product sits in its Introduction/Growth/Maturity/Decline journey.",
  technology_adoption_lifecycle = "Segments a market by adoption behavior, Innovators through Laggards.",
  trend_to_commoditization = "Shows how price or margin erodes across successive product generations.",
  active_waiting = "Weighs the opportunity of waiting against the threat of delaying a strategic commitment.",
  economic_profit_mobility = "Shows how few companies sustain top-tier economic performance over time.",
  kano_model = "Classifies features by how they drive customer satisfaction: basic, performance, or delighter.",
  purpose_of_strategy = "Shows how a company's fundamental purpose cascades down into concrete initiatives.",
  strategic_planning_wheel = "Shows the phases of a recurring strategic planning cycle.",
  strategy_diamond = "Complete five-element view of a strategy: where to play, how to get there, how to win, sequencing, returns."
)

build_diagram_catalog_index <- function() {
  lines <- character(0)
  for (g in DIAGRAM_GROUPS) {
    lines <- c(lines, paste0("\n", DIAGRAM_GROUP_LABELS[[g]], ":"))
    for (t in DIAGRAM_TYPES_BY_GROUP[[g]]) {
      lines <- c(lines, sprintf("  - id=\"%s\" | %s | %s", t, DIAGRAM_TYPE_LABELS[[t]], DIAGRAM_TYPE_SHORT_DESC[[t]]))
    }
  }
  paste(lines, collapse = "\n")
}

generate_diagram_recommendation_prompt <- function(problem_description, num_recommendations) {
  catalog <- build_diagram_catalog_index()

  paste0(
    'You are a strategy consultant. A client has described a strategic problem below. From the FULL catalog of ',
    'available diagram/framework tools listed after it, recommend the top ', num_recommendations, ' tools that ',
    'would best help solve or frame this SPECIFIC problem - ranked from most to least aligned. Reason about the ',
    'actual problem, not generic popularity: a well-known framework that doesn\'t fit this problem should rank ',
    'below a less common one that does.\n\n',

    'THE PROBLEM:\n"', problem_description, '"\n\n',

    'THE FULL CATALOG (id | name | description) - you may ONLY recommend tools from this exact list, and you ',
    'MUST echo back the id EXACTLY as written (e.g. "bcg_matrix"), never the name or a paraphrase, since the id ',
    'is used to programmatically select the tool afterward:\n',
    catalog, '\n\n',

    'Output ONLY bracket-tag blocks in the exact format below - no markdown, no prose commentary, no code ',
    'fences, no numbering outside the bracket fields. One block per recommendation, most-aligned first, ',
    'separated by a single blank line. Output EXACTLY ', num_recommendations, ' blocks.\n\n',

    'For EACH recommendation:\n',
    '[rank]: <1..', num_recommendations, ', most aligned = 1>\n',
    '[diagram_type]: <the EXACT id from the catalog above, e.g. bcg_matrix - copy it character-for-character>\n',
    '[reasoning]: <2-3 sentences on specifically why this tool suits THIS problem - concrete, tied to the ',
    'problem\'s actual details, not a generic definition of what the tool does>\n',
    '[drawbacks]: <1-2 sentences on this tool\'s real limitations or blind spots FOR THIS SPECIFIC PROBLEM - ',
    'even the #1 recommendation should have an honest limitation noted, not "none">\n\n',

    'Now generate exactly ', num_recommendations, ' recommendations, beginning with rank 1.'
  )
}

# Parser: validates every diagram_type id against the CURRENT catalog
# (DIAGRAM_TYPES) before trusting it - an id Claude got wrong, invented,
# or that has since been removed from the catalog is dropped rather than
# passed through, since a broken id would silently fail to auto-select
# anything when a recommendation is clicked.
parse_diagram_recommendations <- function(text, num_recommendations) {
  lines <- strsplit(text, "\n")[[1]]
  blocks <- list()
  current <- list()
  last_field <- NULL
  fields <- c("rank", "diagram_type", "reasoning", "drawbacks")

  flush_block <- function() {
    if (length(current) > 0 && !is.null(current$diagram_type)) {
      blocks[[length(blocks) + 1]] <<- current
    }
  }

  for (line in lines) {
    line <- trimws(line)
    if (line == "") { flush_block(); current <- list(); last_field <- NULL; next }

    matched <- FALSE
    for (field in fields) {
      pat <- paste0("^\\[", field, "\\]:\\s*(.*)$")
      if (grepl(pat, line, ignore.case = TRUE)) {
        value <- trimws(sub(pat, "\\1", line, ignore.case = TRUE))
        if (field == "rank" && !is.null(current$rank)) { flush_block(); current <- list() }
        current[[field]] <- value
        last_field <- field
        matched <- TRUE
        break
      }
    }
    if (!matched && length(current) > 0 && !is.null(last_field)) {
      current[[last_field]] <- paste(current[[last_field]], line)
    }
  }
  flush_block()

  if (length(blocks) == 0) stop("No valid recommendation blocks found in Claude's response")

  df <- data.frame(
    rank = integer(), diagram_type = character(), diagram_label = character(), diagram_group = character(),
    diagram_group_label = character(), reasoning = character(), drawbacks = character(),
    stringsAsFactors = FALSE
  )

  dropped <- 0
  for (b in blocks) {
    dt <- b$diagram_type %||% ""
    if (!dt %in% DIAGRAM_TYPES) {
      cat(sprintf("⚠️  [Strategy Recommender][DEBUG] Dropping recommendation with unrecognized diagram_type '%s' (rank %s) - not in the current catalog\n", dt, b$rank %||% "?"))
      dropped <- dropped + 1
      next
    }
    grp <- names(which(sapply(DIAGRAM_TYPES_BY_GROUP, function(x) dt %in% x)))[1]
    df <- rbind(df, data.frame(
      rank = suppressWarnings(as.integer(b$rank %||% NA)),
      diagram_type = dt,
      diagram_label = DIAGRAM_TYPE_LABELS[[dt]],
      diagram_group = grp,
      diagram_group_label = DIAGRAM_GROUP_LABELS[[grp]],
      reasoning = b$reasoning %||% "",
      drawbacks = b$drawbacks %||% "",
      stringsAsFactors = FALSE
    ))
  }

  if (nrow(df) == 0) stop("Claude's response contained no recommendations with a valid, recognized diagram_type")
  df <- df[order(df$rank), ]

  if (dropped > 0) {
    cat(sprintf("⚠️  [Strategy Recommender][DEBUG] %d recommendation(s) dropped for invalid diagram_type; %d valid recommendation(s) remain (requested %d)\n",
                dropped, nrow(df), num_recommendations))
  }

  df
}

# ============================================================
# SIX SIGMA TOOL RECOMMENDER (Six Sigma Analysis only)
# ============================================================
# Identical design to the Strategic Analysis recommender above: given a
# free-text problem description, Claude picks the top N tools from the
# FULL 33-tool catalog, echoing back the exact internal diagram_type id
# (never a free-text name) so a click can deterministically auto-select
# the right Group + Type dropdown on the Generate Six Sigma Diagram tab.

# One-sentence description per tool, condensed from sixsigma_tool_guide's
# own "definition" text.
SIXSIGMA_TYPE_SHORT_DESC <- c(
  dmaic_process = "The core 5-phase methodology (Define-Measure-Analyse-Improve-Control) for improving an existing process.",
  dmadv_process = "Design for Six Sigma counterpart to DMAIC, used when designing a brand-new product or process.",
  six_sigma_roles_hierarchy = "The belt-based organizational structure of a Six Sigma program, Champions down to Yellow Belts.",
  sipoc = "High-level, single-page map of a process's boundaries: Suppliers, Inputs, Process, Outputs, Customers.",
  ctq_tree = "Translates a broad customer need into specific, measurable Critical-to-Quality requirements.",
  stakeholder_analysis = "Power/Interest grid for deciding how much engagement each stakeholder deserves.",
  voice_of_customer = "Captures raw customer statements and maps each to a specific translated requirement.",
  cost_of_quality = "Categorizes quality-related spending into Prevention, Appraisal, Internal Failure, External Failure.",
  process_map = "Documents the actual step-by-step flow of a process today, including decision points.",
  gage_rr = "Measurement System Analysis checking whether the measuring equipment itself is trustworthy.",
  house_of_quality = "QFD matrix correlating customer requirements against technical/engineering characteristics.",
  check_sheet = "Structured tally table for collecting raw frequency data by category over time.",
  histogram = "Shows the shape of a data distribution - central tendency, spread, and skew.",
  scatter_plot = "Tests and quantifies whether two variables are actually correlated.",
  fishbone = "Structured brainstorming tool organizing potential root causes into standard categories.",
  five_whys = "Fast root-cause technique, asking 'why' repeatedly to move past a symptom to its cause.",
  pareto = "Prioritizes which causes to fix first, based on frequency/cost/impact (the 80/20 rule).",
  fmea_table = "Proactively assesses and prioritizes the risk of potential failure modes before they occur.",
  current_reality_tree = "Theory of Constraints logic tool tracing layered intermediate causes back to one root cause.",
  spaghetti_diagram = "Tracks and quantifies the actual movement of people/materials/information through a space.",
  pugh_matrix = "Objectively compares several candidate solutions against a baseline across multiple criteria.",
  doe_table = "Plans an experiment testing multiple process factors simultaneously, rather than one at a time.",
  five_s = "5-stage workplace discipline (Sort, Set in Order, Shine, Standardise, Sustain) removing clutter.",
  seven_wastes = "Classic Lean taxonomy of non-value-added activity (Transport, Inventory, Motion, Waiting, etc.).",
  five_lean_principles = "Core Lean philosophy in sequence: Value, Value Stream, Flow, Pull, Perfection.",
  poka_yoke_devices = "Inventories concrete error-proofing mechanisms - prevention devices and detection devices.",
  smed_analysis = "Systematic method for reducing equipment changeover time by converting internal steps to external.",
  chaku_chaku_flow = "One-operator, multi-station continuous flow line design (load-load).",
  control_chart = "Monitors whether a process is statistically stable over time, detecting special-cause variation.",
  balanced_scorecard = "Tracks organizational performance across Financial, Customer, Process, Learning & Growth at once.",
  andon_board = "Visual management signal board showing real-time status across multiple stations/lines.",
  normal_distribution = "Illustrates the Central Limit Theorem and the bell-curve shape underlying most Six Sigma stats.",
  process_capability = "Formally assesses whether a process can reliably meet specification limits (Cp/Cpk)."
)

build_sixsigma_catalog_index <- function() {
  lines <- character(0)
  for (g in SIXSIGMA_GROUPS) {
    lines <- c(lines, paste0("\n", SIXSIGMA_GROUP_LABELS[[g]], ":"))
    for (t in SIXSIGMA_TYPES_BY_GROUP[[g]]) {
      lines <- c(lines, sprintf("  - id=\"%s\" | %s | %s", t, SIXSIGMA_TYPE_LABELS[[t]], SIXSIGMA_TYPE_SHORT_DESC[[t]]))
    }
  }
  paste(lines, collapse = "\n")
}

generate_sixsigma_recommendation_prompt <- function(problem_description, num_recommendations) {
  catalog <- build_sixsigma_catalog_index()

  paste0(
    'You are a Lean Six Sigma Master Black Belt. A client has described a problem below. From the FULL catalog ',
    'of available Six Sigma tools listed after it, recommend the top ', num_recommendations, ' tools that would ',
    'best help solve or frame this SPECIFIC problem - ranked from most to least aligned. Reason about the actual ',
    'problem, not generic popularity or which DMAIC phase "should" come first: a well-known tool that doesn\'t ',
    'fit this problem should rank below a less common one that does.\n\n',

    'THE PROBLEM:\n"', problem_description, '"\n\n',

    'THE FULL CATALOG (id | name | description) - you may ONLY recommend tools from this exact list, and you ',
    'MUST echo back the id EXACTLY as written (e.g. "fishbone"), never the name or a paraphrase, since the id ',
    'is used to programmatically select the tool afterward:\n',
    catalog, '\n\n',

    'Output ONLY bracket-tag blocks in the exact format below - no markdown, no prose commentary, no code ',
    'fences, no numbering outside the bracket fields. One block per recommendation, most-aligned first, ',
    'separated by a single blank line. Output EXACTLY ', num_recommendations, ' blocks.\n\n',

    'For EACH recommendation:\n',
    '[rank]: <1..', num_recommendations, ', most aligned = 1>\n',
    '[diagram_type]: <the EXACT id from the catalog above, e.g. fishbone - copy it character-for-character>\n',
    '[reasoning]: <2-3 sentences on specifically why this tool suits THIS problem - concrete, tied to the ',
    'problem\'s actual details, not a generic definition of what the tool does>\n',
    '[drawbacks]: <1-2 sentences on this tool\'s real limitations or blind spots FOR THIS SPECIFIC PROBLEM - ',
    'even the #1 recommendation should have an honest limitation noted, not "none">\n\n',

    'Now generate exactly ', num_recommendations, ' recommendations, beginning with rank 1.'
  )
}

# Parser: validates every diagram_type id against the CURRENT Six Sigma
# catalog (SIXSIGMA_ALL_TYPES) before trusting it, exactly mirroring
# parse_diagram_recommendations()'s discipline.
parse_sixsigma_recommendations <- function(text, num_recommendations) {
  lines <- strsplit(text, "\n")[[1]]
  blocks <- list()
  current <- list()
  last_field <- NULL
  fields <- c("rank", "diagram_type", "reasoning", "drawbacks")

  flush_block <- function() {
    if (length(current) > 0 && !is.null(current$diagram_type)) {
      blocks[[length(blocks) + 1]] <<- current
    }
  }

  for (line in lines) {
    line <- trimws(line)
    if (line == "") { flush_block(); current <- list(); last_field <- NULL; next }

    matched <- FALSE
    for (field in fields) {
      pat <- paste0("^\\[", field, "\\]:\\s*(.*)$")
      if (grepl(pat, line, ignore.case = TRUE)) {
        value <- trimws(sub(pat, "\\1", line, ignore.case = TRUE))
        if (field == "rank" && !is.null(current$rank)) { flush_block(); current <- list() }
        current[[field]] <- value
        last_field <- field
        matched <- TRUE
        break
      }
    }
    if (!matched && length(current) > 0 && !is.null(last_field)) {
      current[[last_field]] <- paste(current[[last_field]], line)
    }
  }
  flush_block()

  if (length(blocks) == 0) stop("No valid recommendation blocks found in Claude's response")

  df <- data.frame(
    rank = integer(), diagram_type = character(), diagram_label = character(), diagram_group = character(),
    diagram_group_label = character(), reasoning = character(), drawbacks = character(),
    stringsAsFactors = FALSE
  )

  dropped <- 0
  for (b in blocks) {
    dt <- b$diagram_type %||% ""
    if (!dt %in% SIXSIGMA_ALL_TYPES) {
      cat(sprintf("⚠️  [Six Sigma Recommender][DEBUG] Dropping recommendation with unrecognized diagram_type '%s' (rank %s) - not in the current catalog\n", dt, b$rank %||% "?"))
      dropped <- dropped + 1
      next
    }
    grp <- names(which(sapply(SIXSIGMA_TYPES_BY_GROUP, function(x) dt %in% x)))[1]
    df <- rbind(df, data.frame(
      rank = suppressWarnings(as.integer(b$rank %||% NA)),
      diagram_type = dt,
      diagram_label = SIXSIGMA_TYPE_LABELS[[dt]],
      diagram_group = grp,
      diagram_group_label = SIXSIGMA_GROUP_LABELS[[grp]],
      reasoning = b$reasoning %||% "",
      drawbacks = b$drawbacks %||% "",
      stringsAsFactors = FALSE
    ))
  }

  if (nrow(df) == 0) stop("Claude's response contained no recommendations with a valid, recognized diagram_type")
  df <- df[order(df$rank), ]

  if (dropped > 0) {
    cat(sprintf("⚠️  [Six Sigma Recommender][DEBUG] %d recommendation(s) dropped for invalid diagram_type; %d valid recommendation(s) remain (requested %d)\n",
                dropped, nrow(df), num_recommendations))
  }

  df
}

# ============================================================
# VISUALIZATION EXPORT (Strategic Analysis, Six Sigma, Flex Table)
# ============================================================
# Shared "download this rendered visualization" UI, used identically by
# diagram_visualizations, sixsigma_visualizations, and table_viewer. The
# actual export work happens entirely client-side (see
# www/js/diagram_export.js) - this just renders the format dropdown and
# download button and wires them to that JS, matching this app's existing
# pattern of loading shared client-side libraries (D3, Cytoscape) once
# globally and having individual modules use them.
#
# format_select_id and target_id are real DOM ids (already namespaced via
# ns()), not Shiny input/output names on their own - the dropdown is a
# plain HTML <select>, not selectInput(), since its value is only ever
# read by client-side JS and never needs to be a reactive Shiny input.
export_controls_ui <- function(ns, target_id, default_filename = "diagram") {
  format_select_id <- ns("export_format")
  tags$div(class = "export-controls-bar",
    tags$label("Download visualization as:", `for` = format_select_id, class = "export-controls-label"),
    tags$select(id = format_select_id, class = "form-control export-format-select",
      tags$option(value = "pdf", "PDF"),
      tags$option(value = "pptx", "PowerPoint (PPTX)"),
      tags$option(value = "html", "HTML"),
      tags$option(value = "jpeg", "JPEG Image")
    ),
    tags$button(
      type = "button", class = "btn btn-success export-download-btn",
      onclick = sprintf("window.exportVisualization('%s', '%s', '%s')", target_id, format_select_id, default_filename),
      tags$i(class = "fa fa-download"), " Download"
    )
  )
}

# Wraps already-rendered content (a tagList/HTML from render_diagram(),
# render_sixsigma(), or a plain HTML table) in the container html2canvas
# captures - carrying the export target's DOM id and a data-export-title
# attribute the JS reads for the downloaded file's name. Deliberately a
# SEPARATE wrapper (not baked into render_diagram()/render_sixsigma()
# themselves) so the export mechanism stays a concern of the
# Visualizations tab that's showing the content, not of the generic
# renderer functions, which have no reason to know about DOM export ids.
export_capture_wrapper <- function(ns, content, export_title) {
  tags$div(
    id = ns("export_target"), class = "export-capture-target",
    `data-export-title` = export_title %||% "diagram",
    content
  )
}
