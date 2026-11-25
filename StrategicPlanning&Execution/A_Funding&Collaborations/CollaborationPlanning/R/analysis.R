# R/analysis.R - suggestions and Claude analyses, shared by My suggestions, Analysis workbench, Analysis library
# and the Drive copies (R/drive.R).
#
#   * Claude answers as JSON: a title, a summary, a classification (country > category > topic > programme)
#     and one or more tables. British English, no long dashes (they are also replaced after the answer).
#   * Tables are shown with flextable when it is installed (the same look as the Books Networks app),
#     otherwise as a styled HTML table.
#   * Access: the owner sees everything; anyone else sees an analysis only when their email is in its
#     access list (the person who made the suggestion is always added). The word "everyone" in the list
#     shares it with every signed-in person (used by the example analysis).

SUGGESTION_KINDS <- c("Funding programme" = "programme", "Collaboration idea" = "collaboration")
HIERARCHY <- c(country = "Country", category = "Category", topic = "Topic", programme = "Programme")

# ---- text clean-up --------------------------------------------------------------------------
# No long dashes in anything Claude returns: " - " style breaks become commas, ranges get a hyphen
clean_dashes <- function(x) {
  if (!length(x)) return(x)
  x <- gsub("\\s*[\u2014\u2015]\\s*", ", ", x)          # em dash, horizontal bar
  x <- gsub("\\s+[\u2013\u2012]\\s+", ", ", x)          # spaced en dash used as a break
  x <- gsub("[\u2013\u2012\u2212]", "-", x)             # en dash in ranges, figure dash, minus sign
  x <- gsub(",\\s*,", ",", x)
  gsub("^,\\s*|\\s*,$", "", x)
}

# ---- the prompt -------------------------------------------------------------------------------
ANALYSIS_SYSTEM <- paste(
  "You are an analyst for a small UK technology company that bids for funding with partners.",
  "Write in plain British English (organisation, programme, analyse, licence).",
  "Never use the long dash characters (em dash or en dash); use commas, colons or a plain hyphen instead.",
  "Answer with JSON only, no words before or after it.")

analysis_prompt <- function(sug, instructions, company_profile = "") {
  paste0(
    "INSTRUCTIONS FROM OUR TEAM:\n", instructions, "\n\n",
    "THE SUGGESTION (", names(SUGGESTION_KINDS)[match(sug$kind, SUGGESTION_KINDS)] %|% "Suggestion", ", from ", sug$created_by, "):\n",
    "Title: ", sug$title, "\n", if (nzchar(sug$url)) paste0("Link for more information: ", sug$url, "\n"),
    "Description: ", sug$description, "\n",
    if (nzchar(sug$ideas)) paste0("Ideas to work together: ", sug$ideas, "\n"),
    if (nzchar(sug$funder)) paste0("Funder: ", sug$funder, "\n"),
    if (nzchar(sug$amount_text)) paste0("Amount: ", sug$amount_text, "\n"),
    if (nzchar(sug$deadline)) paste0("Deadline: ", sug$deadline, "\n"),
    if (nzchar(paste0(sug$country, sug$category, sug$topic))) paste0("Their classification: ", sug$country, " / ", sug$category, " / ", sug$topic, "\n"),
    if (nzchar(sug$notes)) paste0("Notes: ", sug$notes, "\n"),
    if (nzchar(company_profile)) paste0("\nABOUT US:\n", company_profile, "\n"),
    "\nReply with this JSON:\n",
    '{"title": "short title of the programme or idea",\n',
    ' "summary": "three or four plain sentences",\n',
    ' "classification": {"country": "", "category": "e.g. Grant, Accelerator, Collaboration, Competition", "topic": "main theme, e.g. Energy AI", "programme": "programme or idea name"},\n',
    ' "tables": [ {"title": "table title", "columns": ["Column 1", "Column 2"], "rows": [["cell", "cell"]]} ]}\n',
    "Use two to five tables, each with 2 to 6 columns and short cells (no line breaks inside cells). ",
    "Always include a table of key facts (item, detail, source) and a table of next steps (step, who, by when). ",
    "If a fact is not known, write 'not stated'. Do not invent figures.")
}

# ---- parsing ---------------------------------------------------------------------------------
# JSON first; if that fails, Markdown tables (| a | b |) in the text
parse_analysis <- function(text) {
  out <- tryCatch({
    j <- parse_json_loose(text, simplify = FALSE)
    tabs <- lapply(j$tables %||% list(), function(t) {
      cols <- clean_dashes(as.character(unlist(t$columns)))
      rows <- lapply(t$rows %||% list(), function(r) { v <- vapply(r, function(x) paste(as.character(unlist(x %||% "")), collapse = "; "), "")
                                                     length(v) <- length(cols); v[is.na(v)] <- ""; clean_dashes(v) })
      df <- if (length(rows)) as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE) else as.data.frame(matrix(character(0), 0, length(cols)))
      names(df) <- make.unique(ifelse(nzchar(cols), cols, paste("Column", seq_along(cols))))
      list(title = clean_dashes(as.character(t$title %||% "")), data = df)
    })
    cl <- j$classification %||% list()
    list(title = clean_dashes(as.character(j$title %||% "")), summary = clean_dashes(as.character(j$summary %||% "")),
         classification = lapply(setNames(names(HIERARCHY), names(HIERARCHY)), function(k) clean_dashes(as.character(cl[[k]] %||% ""))),
         tables = Filter(function(t) ncol(t$data) > 0, tabs))
  }, error = function(e) NULL)
  if (!is.null(out) && length(out$tables)) return(out)
  md <- parse_markdown_tables(text)
  if (!length(md)) stop("No tables found in Claude's answer. Edit the text into tables, or run the analysis again.", call. = FALSE)
  list(title = "", summary = "", classification = lapply(setNames(names(HIERARCHY), names(HIERARCHY)), function(k) ""), tables = md)
}

parse_markdown_tables <- function(text) {
  lines <- strsplit(gsub("\r", "", text %||% ""), "\n")[[1]]; tabs <- list(); i <- 1; title <- ""
  split_row <- function(l) clean_dashes(trimws(strsplit(sub("^\\s*\\|", "", sub("\\|\\s*$", "", l)), "\\|")[[1]]))
  while (i <= length(lines)) {
    l <- lines[i]
    if (grepl("^\\s*#+\\s+", l) || grepl("^\\s*\\*\\*.+\\*\\*\\s*$", l)) title <- clean_dashes(trimws(gsub("[#*]", "", l)))
    if (grepl("^\\s*\\|.*\\|\\s*$", l) && i < length(lines) && grepl("^\\s*\\|?\\s*:?-{3,}", lines[i + 1])) {
      head <- split_row(l); i <- i + 2; rows <- list()
      while (i <= length(lines) && grepl("^\\s*\\|.*\\|\\s*$", lines[i])) { r <- split_row(lines[i]); length(r) <- length(head); r[is.na(r)] <- ""; rows[[length(rows) + 1]] <- r; i <- i + 1 }
      df <- if (length(rows)) as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE) else as.data.frame(matrix(character(0), 0, length(head)))
      names(df) <- make.unique(ifelse(nzchar(head), head, paste("Column", seq_along(head))))
      tabs[[length(tabs) + 1]] <- list(title = title, data = df); title <- ""
      next
    }
    i <- i + 1
  }
  tabs
}

tables_to_json <- function(tabs) as.character(jsonlite::toJSON(lapply(tabs, function(t)
  list(title = t$title, columns = names(t$data), rows = unname(as.matrix(t$data)))), auto_unbox = TRUE))

tables_from_json <- function(txt) {
  if (!nzchar(txt %||% "")) return(list())
  j <- tryCatch(jsonlite::fromJSON(txt, simplifyVector = FALSE), error = function(e) list())
  lapply(j, function(t) {
    cols <- as.character(unlist(t$columns))
    rows <- lapply(t$rows %||% list(), function(r) { v <- as.character(unlist(lapply(r, function(x) x %||% ""))); length(v) <- length(cols); v[is.na(v)] <- ""; v })
    df <- if (length(rows)) as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE) else as.data.frame(matrix(character(0), 0, length(cols)))
    names(df) <- make.unique(cols); list(title = t$title %||% "", data = df)
  })
}

# ---- rendering (flextable look) ---------------------------------------------------------------
render_table <- function(df) {
  if (has_pkg("flextable")) {
    ft <- tryCatch({
      f <- flextable::flextable(df)
      f <- flextable::theme_vanilla(f)
      f <- flextable::bg(f, bg = "#0f4a5c", part = "header")
      f <- flextable::color(f, color = "white", part = "header")
      f <- flextable::bold(f, part = "header")
      f <- flextable::bg(f, i = seq(2, max(2, nrow(df)), by = 2), bg = "#f2f8fa", part = "body")
      f <- flextable::fontsize(f, size = 10, part = "all")
      f <- flextable::border_outer(f, border = officer::fp_border(color = "#0b2a3c", width = 1))
      f <- flextable::valign(f, valign = "top", part = "body")
      f <- flextable::set_table_properties(f, layout = "autofit", width = 1)
      flextable::htmltools_value(f)
    }, error = function(e) NULL)
    if (!is.null(ft)) return(div(class = "ft-wrap", ft))
  }
  div(class = "ft-wrap", tags$table(class = "cp-ft",
    tags$thead(tags$tr(lapply(names(df), tags$th))),
    tags$tbody(lapply(seq_len(nrow(df)), function(i) tags$tr(lapply(df[i, ], function(v) tags$td(as.character(v))))))))
}

render_tables <- function(tabs) tagList(lapply(tabs, function(t) tagList(if (nzchar(t$title)) div(class = "ft-title", t$title), render_table(t$data))))

# ---- data and access --------------------------------------------------------------------------
latest_suggestions <- function(df = store_read("suggestions")) { d <- latest_by(df, "suggestion_id"); d[!is_true_vec(d$deleted), , drop = FALSE] }
latest_analyses <- function(df = store_read("analyses")) { d <- latest_by(df, "analysis_id"); d[!is_true_vec(d$deleted), , drop = FALSE] }

can_see_analysis <- function(a, email, is_owner) {
  if (isTRUE(is_owner)) return(rep(TRUE, nrow(a)))
  email <- tolower(trimws(email))
  vapply(a$access_emails, function(x) { e <- split_emails(x); "everyone" %in% e || email %in% e }, TRUE, USE.NAMES = FALSE)
}

# ---- the Country > Category > Topic > Programme tree ------------------------------------------
level_value <- function(x) ifelse(nzchar(trimws(x)), trimws(x), "(not classified)")

analysis_tree <- function(a, click_id, selected = "") {
  if (!nrow(a)) return(p(class = "small muted", "Nothing to show yet."))
  a$c1 <- level_value(a$country); a$c2 <- level_value(a$category); a$c3 <- level_value(a$topic); a$c4 <- level_value(a$programme %|% a$title)
  node <- function(df, depth) {
    if (depth > 3) return(lapply(seq_len(nrow(df)), function(i)
      tags$a(class = paste("leaf", if (df$analysis_id[i] == selected) "on"), onclick = js_click(click_id, df$analysis_id[i]),
             icon("table"), " ", df$c4[i], span(class = "small muted", " ", substr(df$updated_at[i], 1, 10)))))
    col <- c("c1", "c2", "c3")[depth]; lv <- c("country", "category", "topic")[depth]
    lapply(sort(unique(df[[col]])), function(v) {
      sub <- df[df[[col]] == v, , drop = FALSE]
      tags$details(class = paste0("lvl-", lv), open = NA,   # all levels open; each can be folded
                   tags$summary(v, span(class = "cnt", sprintf("(%d)", nrow(sub)))), node(sub, depth + 1))
    })
  }
  div(class = "tree", node(a, 1))
}
