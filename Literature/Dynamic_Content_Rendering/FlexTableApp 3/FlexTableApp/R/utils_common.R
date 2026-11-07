# R/utils_common.R
# Shared Utility Functions
# ========================
# Core innovation of this app: an EVER-CHANGING number of "columns" per
# generated table is stored as ONE delimited-text BigQuery column
# (columns_data), one physical BigQuery row per R Shiny table row
# (row_index). This file contains the delimiter constants and the
# pack/unpack logic shared by every module.

# Safe SQL escape for preventing injection
safe_sql_escape <- function(input_value) {
  gsub("'", "''", input_value)
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
# CATEGORY / TOPIC HIERARCHICAL CLASSIFICATION
# ============================================================
# Topic is a sub-category of Category (e.g. Category = "Finance",
# Topic = "ML Models for Asset Class Price Forecasting"). These
# sentinel values mark the "create a new one" option in the dropdowns.
CATEGORY_ADD_NEW_VALUE <- "__ADD_NEW_CATEGORY__"
TOPIC_ADD_NEW_VALUE <- "__ADD_NEW_TOPIC__"

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
    api_manager$state_trigger()
    if (!api_manager$bq_authenticated) {
      return(api_manager$empty_taxonomy())
    }
    tryCatch(api_manager$bq_get_taxonomy(), error = function(e) {
      api_manager$empty_taxonomy()
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

  observeEvent(input$category_select, {
    tax <- taxonomy()

    if (is.null(input$category_select) || input$category_select == CATEGORY_ADD_NEW_VALUE) {
      updateSelectInput(session, "topic_select",
                         choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE))
      return()
    }

    topics <- sort(unique(tax$topic[tax$category == input$category_select & nchar(trimws(tax$topic)) > 0]))

    if (length(topics) == 0) {
      updateSelectInput(session, "topic_select",
                         choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE))
    } else {
      updateSelectInput(session, "topic_select",
                         choices = c("+ Add New Topic" = TOPIC_ADD_NEW_VALUE,
                                     setNames(topics, topics)))
    }
  }, ignoreInit = TRUE)

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
