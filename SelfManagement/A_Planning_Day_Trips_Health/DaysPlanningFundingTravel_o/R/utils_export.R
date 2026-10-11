# R/utils_export.R
# Shared export utility: ICS + PDF + HTML for all modules
# Usage: api_manager$generate_calendar_export(data, format, filename_base)

# Add this method to APIManager class
# export_generator <- function(self, data_type, data, filename_base) {
#   self$generate_export(data_type, data, filename_base)
# }

# Standalone functions for each module to use:

# ============================================================================
# FUNCTION 1: Generate ICS Calendar File
# ============================================================================
generate_ics_file <- function(events_list, filename_base) {
  # events_list should be a list of events, each with:
  # - title (or name)
  # - start_time (datetime or character "YYYY-MM-DD HH:MM")
  # - end_time (datetime or character "YYYY-MM-DD HH:MM")
  # - description (optional)
  # - location (optional)
  
  tryCatch({
    ics_lines <- c(
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//Business Operations Suite//Export",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH"
    )
    
    for (idx in seq_along(events_list)) {
      event <- events_list[[idx]]
      
      # Parse times
      if (is.character(event$start_time)) {
        start_dt <- gsub("[^0-9]", "", event$start_time)
        if (nchar(start_dt) == 8) start_dt <- paste0(start_dt, "T000000")
      } else {
        start_dt <- format(event$start_time, "%Y%m%dT%H%M%S")
      }
      
      if (is.character(event$end_time)) {
        end_dt <- gsub("[^0-9]", "", event$end_time)
        if (nchar(end_dt) == 8) end_dt <- paste0(end_dt, "T235900")
      } else {
        end_dt <- format(event$end_time, "%Y%m%dT%H%M%S")
      }
      
      uid <- paste0("bos-", gsub(" ", "-", event$title %||% event$name), "-", idx)
      
      ics_lines <- c(ics_lines,
        "BEGIN:VEVENT",
        paste0("UID:", uid, "@businessops"),
        paste0("DTSTAMP:", format(Sys.time(), "%Y%m%dT%H%M%SZ")),
        paste0("DTSTART:", start_dt),
        paste0("DTEND:", end_dt),
        paste0("SUMMARY:", event$title %||% event$name),
        paste0("DESCRIPTION:", gsub("\n", "\\\\n", event$description %||% "")),
        if (!is.null(event$location)) paste0("LOCATION:", event$location),
        "STATUS:CONFIRMED",
        "END:VEVENT"
      )
    }
    
    ics_lines <- c(ics_lines, "END:VCALENDAR")
    
    return(list(
      success = TRUE,
      content = ics_lines,
      message = "ICS generated successfully"
    ))
    
  }, error = function(e) {
    return(list(
      success = FALSE,
      content = c("BEGIN:VCALENDAR", "VERSION:2.0", "END:VCALENDAR"),
      message = paste("ICS Error:", e$message)
    ))
  })
}

# ============================================================================
# FUNCTION 2: Generate High-Quality HTML File
# ============================================================================
generate_html_file <- function(title, data_rows, columns, filename_base) {
  # title: Document title
  # data_rows: List of rows or data frame
  # columns: List/vector of column names to display
  
  tryCatch({
    html_lines <- c(
      "<!DOCTYPE html>",
      "<html lang=\"en\">",
      "<head>",
      "  <meta charset=\"UTF-8\">",
      "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
      paste0("  <title>", title, "</title>"),
      "  <style>",
      "    * { margin: 0; padding: 0; box-sizing: border-box; }",
      "    body {",
      "      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;",
      "      line-height: 1.6;",
      "      color: #333;",
      "      background-color: #f5f5f5;",
      "      padding: 20px;",
      "    }",
      "    .container {",
      "      max-width: 1000px;",
      "      margin: 0 auto;",
      "      background-color: white;",
      "      padding: 40px;",
      "      border-radius: 8px;",
      "      box-shadow: 0 2px 10px rgba(0,0,0,0.1);",
      "    }",
      "    .header {",
      "      border-bottom: 3px solid #2196F3;",
      "      padding-bottom: 20px;",
      "      margin-bottom: 30px;",
      "    }",
      "    .header h1 {",
      "      color: #2196F3;",
      "      font-size: 2.2em;",
      "      margin-bottom: 10px;",
      "    }",
      "    .info-box {",
      "      background-color: #e3f2fd;",
      "      padding: 15px;",
      "      border-radius: 4px;",
      "      margin-bottom: 20px;",
      "    }",
      "    .info-box p {",
      "      margin: 5px 0;",
      "    }",
      "    table {",
      "      width: 100%;",
      "      border-collapse: collapse;",
      "      margin-bottom: 20px;",
      "    }",
      "    th {",
      "      background: linear-gradient(135deg, #2196F3, #1976D2);",
      "      color: white;",
      "      padding: 12px;",
      "      text-align: left;",
      "      font-weight: bold;",
      "    }",
      "    td {",
      "      padding: 12px;",
      "      border-bottom: 1px solid #ddd;",
      "    }",
      "    tr:hover {",
      "      background-color: #f5f5f5;",
      "    }",
      "    .footer {",
      "      border-top: 1px solid #ddd;",
      "      padding-top: 20px;",
      "      margin-top: 40px;",
      "      text-align: center;",
      "      color: #999;",
      "      font-size: 0.9em;",
      "    }",
      "    @media print {",
      "      body { background: white; }",
      "      .container { box-shadow: none; padding: 0; }",
      "    }",
      "  </style>",
      "</head>",
      "<body>",
      "  <div class=\"container\">",
      "    <div class=\"header\">",
      paste0("      <h1>", title, "</h1>"),
      "    </div>",
      "    <div class=\"info-box\">",
      paste0("      <p><strong>Generated:</strong> ", format(Sys.time(), "%A, %B %d, %Y at %H:%M"), "</p>"),
      "    </div>",
      "    <table>",
      "      <thead>",
      "        <tr>"
    )
    
    # Add table headers
    for (col in columns) {
      html_lines <- c(html_lines, paste0("          <th>", col, "</th>"))
    }
    
    html_lines <- c(html_lines,
      "        </tr>",
      "      </thead>",
      "      <tbody>"
    )
    
    # Add table rows
    if (is.data.frame(data_rows)) {
      for (i in 1:nrow(data_rows)) {
        html_lines <- c(html_lines, "        <tr>")
        for (col in columns) {
          val <- if (col %in% names(data_rows)) data_rows[[col]][i] else ""
          html_lines <- c(html_lines, paste0("          <td>", val, "</td>"))
        }
        html_lines <- c(html_lines, "        </tr>")
      }
    } else if (is.list(data_rows)) {
      for (row in data_rows) {
        html_lines <- c(html_lines, "        <tr>")
        for (col in columns) {
          val <- row[[col]] %||% ""
          html_lines <- c(html_lines, paste0("          <td>", val, "</td>"))
        }
        html_lines <- c(html_lines, "        </tr>")
      }
    }
    
    html_lines <- c(html_lines,
      "      </tbody>",
      "    </table>",
      "    <div class=\"footer\">",
      "      <p>Business Operations Suite - Exported Report</p>",
      "    </div>",
      "  </div>",
      "</body>",
      "</html>"
    )
    
    return(list(
      success = TRUE,
      content = html_lines,
      message = "HTML generated successfully"
    ))
    
  }, error = function(e) {
    return(list(
      success = FALSE,
      content = c("<html><body><p>Error generating HTML</p></body></html>"),
      message = paste("HTML Error:", e$message)
    ))
  })
}

# ============================================================================
# FUNCTION 3: Generate Professional PDF via Markdown
# ============================================================================
generate_pdf_file <- function(title, summary_text, data_rows, columns) {
  # Generates markdown that will be rendered to PDF
  
  tryCatch({
    md_content <- c(
      "---",
      paste0("title: \"", title, "\""),
      "author: \"Business Operations Suite\"",
      paste0("date: \"", format(Sys.Date(), "%B %d, %Y"), "\""),
      "output: pdf_document",
      "---",
      "",
      paste0("# ", title),
      "",
      "## Summary",
      "",
      summary_text,
      "",
      "## Data",
      "",
      "| " , paste(columns, collapse = " | ") , " |",
      "| " , paste(rep("---", length(columns)), collapse = " | ") , " |"
    )
    
    # Add table rows
    if (is.data.frame(data_rows)) {
      for (i in 1:min(nrow(data_rows), 100)) {  # Limit to 100 rows for PDF
        row_vals <- sapply(columns, function(col) {
          if (col %in% names(data_rows)) as.character(data_rows[[col]][i]) else ""
        })
        md_content <- c(md_content, "| " , paste(row_vals, collapse = " | ") , " |")
      }
    } else if (is.list(data_rows)) {
      for (row in data_rows) {
        row_vals <- sapply(columns, function(col) as.character(row[[col]] %||% ""))
        md_content <- c(md_content, "| " , paste(row_vals, collapse = " | ") , " |")
      }
    }
    
    md_content <- c(md_content,
      "",
      "## Notes",
      "",
      "- This report was automatically generated",
      paste0("- Generated on ", format(Sys.time(), "%A, %B %d, %Y at %H:%M"), ""),
      "- Business Operations Suite",
      ""
    )
    
    return(list(
      success = TRUE,
      content = md_content,
      message = "PDF markdown generated successfully"
    ))
    
  }, error = function(e) {
    return(list(
      success = FALSE,
      content = c("# Error", "", "Could not generate PDF"),
      message = paste("PDF Error:", e$message)
    ))
  })
}

# ============================================================================
# HANDLER FUNCTIONS (use in downloadHandler)
# ============================================================================

# For ICS files
create_ics_download <- function(events_list, output_file) {
  result <- generate_ics_file(events_list, basename(output_file))
  if (result$success) {
    writeLines(result$content, output_file)
    cat("✅", result$message, "\n")
  } else {
    cat("❌", result$message, "\n")
    writeLines(result$content, output_file)
  }
}

# For HTML files
create_html_download <- function(title, data_rows, columns, output_file) {
  result <- generate_html_file(title, data_rows, columns, basename(output_file))
  if (result$success) {
    writeLines(result$content, output_file)
    cat("✅", result$message, "\n")
  } else {
    cat("❌", result$message, "\n")
    writeLines(result$content, output_file)
  }
}

# For PDF files (markdown → PDF)
create_pdf_download <- function(title, summary, data_rows, columns, output_file) {
  tryCatch({
    result <- generate_pdf_file(title, summary, data_rows, columns)
    
    if (result$success) {
      # Write temp markdown
      temp_md <- tempfile(fileext = ".md")
      writeLines(result$content, temp_md)
      
      # Render to PDF
      rmarkdown::render(
        temp_md,
        output_file = output_file,
        output_format = "pdf_document",
        quiet = TRUE
      )
      
      cat("✅ PDF generated\n")
      unlink(temp_md)
    } else {
      writeLines(result$content, output_file)
      cat("❌", result$message, "\n")
    }
  }, error = function(e) {
    cat("❌ PDF Error:", e$message, "\n")
  })
}

# ============================================================================
# GENERIC HTML + PDF EXPORT — shared by every suite's Visualizations tab
# ============================================================================
# Added to support "Save as HTML/PDF" on every suite's visualization view
# (Diet, Exercise, Events, Funding, Day Planner, and the closest equivalent
# in Gantt/Contacts). Deliberately does NOT use create_pdf_download() above
# (rmarkdown::render(..., pdf_document) needs a working LaTeX install, which
# shinyapps.io does not provide by default - almost certainly why that
# function was built but never actually wired into any module). Instead
# this mirrors Travel Planning's own PDF export, which already uses base-R
# grDevices::pdf() directly with no external dependency, proven working in
# this app already.

# Builds a self-contained, styled HTML page: title, optional subtitle/summary
# paragraph, then a real HTML table. Returns list(success=, content=,
# message=) like the other generators in this file, for the same calling
# convention.
# Safe cell-value extraction for generate_generic_html/pdf below. The bug
# this fixes: `%||%` only substitutes when a value is NULL, but a missing
# BigQuery STRING cell comes back as NA (not NULL) once loaded into R - so
# `data_rows[[col]][i] %||% ""` silently let NA through unchanged, and
# `if (nchar(trimws(NA)) == 0)` then threw "missing value where TRUE/FALSE
# needed", an uncaught-looking error that produced Shiny's generic "An
# error has occurred!" page instead of a usable file.
safe_cell_value <- function(x, default = "") {
  if (is.null(x) || length(x) == 0) return(default)
  if (is.na(x)) return(default)
  val <- as.character(x)
  if (is.na(val)) return(default)
  val
}

generate_generic_html <- function(title, subtitle = NULL, data_rows, columns, column_labels = NULL) {
  if (is.null(column_labels)) column_labels <- columns

  tryCatch({
    esc <- function(x) {
      x <- safe_cell_value(x)
      x <- gsub("&", "&amp;", x, fixed = TRUE)
      x <- gsub("<", "&lt;", x, fixed = TRUE)
      x <- gsub(">", "&gt;", x, fixed = TRUE)
      x
    }

    html_lines <- c(
      "<!DOCTYPE html>", "<html lang=\"en\">", "<head>",
      "<meta charset=\"UTF-8\">",
      "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
      paste0("<title>", esc(title), "</title>"),
      "<style>",
      "*{margin:0;padding:0;box-sizing:border-box}",
      "body{font-family:'Segoe UI',Tahoma,Arial,sans-serif;line-height:1.6;color:#2c3e50;background:#f4f4f4;padding:20px}",
      ".container{max-width:1100px;margin:0 auto;background:#fff;padding:40px;border-radius:8px;box-shadow:0 2px 10px rgba(0,0,0,.1)}",
      ".header{border-bottom:3px solid #008A82;padding-bottom:20px;margin-bottom:20px}",
      ".header h1{color:#002C3C;font-size:2em;margin:0}",
      ".subtitle{background:#e8f5f4;padding:12px 16px;border-radius:4px;margin-bottom:24px;color:#444}",
      "table{width:100%;border-collapse:collapse;margin-top:10px}",
      "th{background:linear-gradient(135deg,#008A82 0%,#00A39A 100%);color:#fff;text-align:left;padding:10px 12px;font-size:.9em}",
      "td{padding:10px 12px;border-bottom:1px solid #eee;font-size:.9em;vertical-align:top}",
      "tr:nth-child(even){background:#f9f9f9}",
      ".footer{border-top:1px solid #ddd;padding-top:16px;margin-top:30px;text-align:center;color:#999;font-size:.85em}",
      "</style>", "</head>", "<body>",
      "<div class=\"container\">",
      "<div class=\"header\">", paste0("<h1>", esc(title), "</h1>"), "</div>"
    )

    if (!is.null(subtitle) && nchar(trimws(subtitle)) > 0) {
      html_lines <- c(html_lines, paste0("<div class=\"subtitle\">", esc(subtitle), "</div>"))
    }

    html_lines <- c(html_lines, "<table>", "<thead><tr>")
    for (lbl in column_labels) html_lines <- c(html_lines, paste0("<th>", esc(lbl), "</th>"))
    html_lines <- c(html_lines, "</tr></thead>", "<tbody>")

    n_rows <- if (is.data.frame(data_rows)) nrow(data_rows) else length(data_rows)
    for (i in seq_len(n_rows)) {
      html_lines <- c(html_lines, "<tr>")
      for (col in columns) {
        val <- if (is.data.frame(data_rows)) safe_cell_value(data_rows[[col]][i]) else safe_cell_value(data_rows[[i]][[col]])
        html_lines <- c(html_lines, paste0("<td>", esc(val), "</td>"))
      }
      html_lines <- c(html_lines, "</tr>")
    }

    html_lines <- c(html_lines, "</tbody>", "</table>",
      "<div class=\"footer\">",
      paste0("<p>Business Operations Suite - Exported ", format(Sys.time(), "%A, %B %d, %Y at %H:%M"), "</p>"),
      "</div>", "</div>", "</body>", "</html>")

    list(success = TRUE, content = html_lines, message = "HTML generated successfully")
  }, error = function(e) {
    list(success = FALSE, content = c("<html><body><p>Error generating HTML</p></body></html>"),
         message = paste("HTML Error:", e$message))
  })
}

# Writes a PDF directly to output_file using base-R graphics (no LaTeX/
# pandoc dependency) - one "record block" per row (label: value for each
# selected column), word-wrapped and paginated. Mirrors Travel Planning's
# own proven PDF export approach. Returns TRUE/FALSE.
generate_generic_pdf <- function(output_file, title, subtitle = NULL, data_rows, columns, column_labels = NULL, max_rows = 150) {
  if (is.null(column_labels)) column_labels <- columns

  pdf_ok <- tryCatch({
    grDevices::pdf(output_file, width = 8.27, height = 11.69, onefile = TRUE)
    on.exit(if (!is.null(grDevices::dev.list())) grDevices::dev.off(), add = TRUE)

    margin_left <- 0.07; margin_right <- 0.95; line_height <- 0.022
    y <- NULL

    new_page <- function() {
      plot.new()
      plot.window(xlim = c(0, 1), ylim = c(0, 1))
      0.97
    }

    draw_header <- function(y) {
      text(margin_left, y, title, cex = 1.6, font = 2, col = "#002C3C", adj = c(0, 1))
      y <- y - 0.035
      if (!is.null(subtitle) && nchar(trimws(subtitle)) > 0) {
        wrapped <- strwrap(subtitle, width = 95)
        for (ln in wrapped) { text(margin_left, y, ln, cex = 0.95, col = "#555555", adj = c(0, 1)); y <- y - line_height }
        y <- y - 0.012
      }
      text(margin_left, y, paste0("Generated ", format(Sys.time(), "%B %d, %Y at %H:%M")), cex = 0.8, col = "#999999", adj = c(0, 1))
      y - 0.04
    }

    y <- new_page()
    y <- draw_header(y)

    n_rows <- if (is.data.frame(data_rows)) nrow(data_rows) else length(data_rows)
    n_rows <- min(n_rows, max_rows)

    for (i in seq_len(n_rows)) {
      row_lines <- c()
      for (j in seq_along(columns)) {
        col <- columns[j]; lbl <- column_labels[j]
        val <- if (is.data.frame(data_rows)) safe_cell_value(data_rows[[col]][i]) else safe_cell_value(data_rows[[i]][[col]])
        if (nchar(trimws(val)) == 0) next
        wrapped <- strwrap(paste0(lbl, ": ", val), width = 98, exdent = 2)
        row_lines <- c(row_lines, wrapped)
      }
      block_height <- (length(row_lines) + 1.5) * line_height

      if (y - block_height < 0.04) { y <- new_page() }

      text(margin_left, y, paste0(i, "."), cex = 0.95, font = 2, col = "#008A82", adj = c(0, 1))
      y <- y - line_height * 1.3
      for (ln in row_lines) { text(margin_left + 0.02, y, ln, cex = 0.85, col = "#2c3e50", adj = c(0, 1)); y <- y - line_height }
      y <- y - line_height * 0.6
    }

    if (n_rows < (if (is.data.frame(data_rows)) nrow(data_rows) else length(data_rows))) {
      if (y - 0.03 < 0.04) y <- new_page()
      text(margin_left, y, paste0("... truncated at ", max_rows, " rows for PDF export ..."), cex = 0.85, font = 3, col = "#e67e22", adj = c(0, 1))
    }

    TRUE
  }, error = function(e) {
    cat("\u274c [generate_generic_pdf] Error:", e$message, "\n")
    FALSE
  })

  pdf_ok
}
