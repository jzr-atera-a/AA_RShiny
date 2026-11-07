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
