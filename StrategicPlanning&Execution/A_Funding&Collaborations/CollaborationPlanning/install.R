# Install the packages Collaboration Planning needs (run once): source("install.R")
# Each package is installed on its own, so one failure does not stop the rest.
# On Windows only ready-made binary packages are used: a newer source version (for example officer 0.7.9 on R 4.4)
# can fail to build, while the binary (officer 0.7.3) works.

required <- c("shiny", "bslib", "DT", "R6", "yaml", "httr", "jsonlite", "openssl", "base64enc", "htmltools", "curl", "plotly")
optional <- c("officer", "pdftools", "readxl", "writexl",   # Word download, PDF reading, Excel Gantt
              "flextable",                                  # analysis tables (needs officer)
              "bigrquery")                                  # BigQuery (without it: Google Sheet or local CSV only)

pkg_type <- if (.Platform$OS.type == "windows") "binary" else getOption("pkgType")
ok_pkg <- function(p) requireNamespace(p, quietly = TRUE)

for (p in c(required, optional)) {
  if (ok_pkg(p)) next
  cat("Installing", p, "...\n")
  tryCatch(utils::install.packages(p, type = pkg_type, dependencies = c("Depends", "Imports", "LinkingTo")),
           error = function(e) cat("  could not install", p, ":", conditionMessage(e), "\n"),
           warning = function(w) cat("  warning for", p, ":", conditionMessage(w), "\n"))
}

missing_req <- required[!vapply(required, ok_pkg, TRUE)]
missing_opt <- optional[!vapply(optional, ok_pkg, TRUE)]
if (length(missing_req)) {
  cat("\nStill missing (the app needs these):", paste(missing_req, collapse = ", "), "\n")
} else {
  cat("\nReady. Run shiny::runApp()\n")
}
if (length(missing_opt))
  cat("Optional packages not installed:", paste(missing_opt, collapse = ", "),
      "\nThe app still runs; only the features that use them are switched off.\n")
