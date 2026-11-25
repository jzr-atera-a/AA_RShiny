# global.R - packages, sourcing order, start-up
# ============================================================
# DEPLOYMENT DEPENDENCIES - DO NOT REMOVE
# shinyapps.io only installs packages it can see as library() calls, so every package
# the app uses is listed here, including those only some tabs need.
# ============================================================
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(DT)
  library(R6)
  library(yaml)
  library(httr)
  library(jsonlite)
  library(openssl)
  library(base64enc)
  library(htmltools)
  library(curl)       # SMTP email (outreach, reminders)
  library(plotly)     # charts, Gantt
})
# Optional packages: only one or two tabs use each, so the app starts without them and those features say what is
# missing. They are attached here when installed so shinyapps.io bundles them.
#   officer  .docx download of answers, reading .docx files      pdftools  reading PDF CVs and emails
#   readxl   Excel Gantt upload                                   writexl   Gantt template download
#   flextable  analysis tables (falls back to a styled HTML table)
OPTIONAL_PACKAGES <- c("officer", "pdftools", "readxl", "writexl", "flextable")
if (requireNamespace("officer", quietly = TRUE)) suppressPackageStartupMessages(library(officer))
if (requireNamespace("pdftools", quietly = TRUE)) suppressPackageStartupMessages(library(pdftools))
if (requireNamespace("readxl", quietly = TRUE)) suppressPackageStartupMessages(library(readxl))
if (requireNamespace("writexl", quietly = TRUE)) suppressPackageStartupMessages(library(writexl))
if (requireNamespace("flextable", quietly = TRUE)) suppressPackageStartupMessages(library(flextable))
# bigrquery is optional: without it the app runs on the Google Sheet or local CSV only.
# It is attached here (when installed) so shinyapps.io bundles it.
if (requireNamespace("bigrquery", quietly = TRUE)) suppressPackageStartupMessages(library(bigrquery))

options(scipen = 999)   # write 900000, not 9e+05, wherever numbers are formatted
cat("\n== Collaboration Planning: starting ==\n")

# Load .Renviron from the app folder when running locally (shinyapps.io uses its own settings)
if (file.exists(".Renviron")) readRenviron(".Renviron")

# Sourcing order matters: config and helpers first, then storage, then UI builders.
for (f in c("R/config.R", "R/utils.R", "R/google_sheets.R", "R/bigquery.R", "R/store.R",
            "R/seed.R", "R/programmes.R", "R/integrations.R", "R/claude.R", "R/mail.R", "R/collab.R", "R/analysis.R", "R/drive.R", "R/auth.R", "R/module_loader.R", "R/nav.R")) source(f, local = .GlobalEnv)

loader <- ModuleLoader$new("modules")
loader$print()
for (p in OPTIONAL_PACKAGES) if (!has_pkg(p)) log_debug("[Start] optional package '", p, "' is not installed: ", PKG_NEEDED_FOR[[p]], " will not work")
store_init()
log_debug("[Start] running on ", if (IS_WINDOWS) "Windows (admin code not needed)" else "Linux/macOS (admin code needed)")
