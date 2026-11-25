# modules/Book Summary/books_browse.R
# ---- module --------------------------------------------------------------------------------------
# id:           books_browse
# name:         Browse Data
# icon:         table
# description:  Browse and download all book summaries
# packages:     shiny, shinydashboard, DT
# --------------------------------------------------------------------------------------------------

# The tab itself is shared with other suites: see raw_browse_ui / raw_browse_server in R/utils_suite_tabs.R.

BOOKS_BROWSE_CFG <- list(
  title = "Browse All Book Summaries",
  max_rows = c(100, 1000),          # shown at first, most allowed
  table = "bq_full_table_books",
  file_prefix = "book_summaries"
)

books_browse_ui <- function(id) raw_browse_ui(id, BOOKS_BROWSE_CFG)
books_browse_server <- function(id, api_manager) raw_browse_server(id, api_manager, BOOKS_BROWSE_CFG)
