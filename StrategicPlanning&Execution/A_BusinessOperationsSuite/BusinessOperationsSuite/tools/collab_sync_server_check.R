# tools/collab_sync_server_check.R - the Collaboration Sync tab's server (Read, Load, Share) with shiny::testServer,
# a stand-in API manager and a CollaborationPlanning folder on disk. Run: COLLAB_TEST_FOLDER=<folder> Rscript tools/collab_sync_server_check.R
suppressMessages({ library(shiny); library(htmltools) })
for (f in c("R/utils_gdrive.R", "R/utils_collab_sync.R", "modules/Funding Programmes/funding_collab_sync.R")) source(f)
folder <- Sys.getenv("COLLAB_TEST_FOLDER")
`%||%` <- function(a, b) if (is.null(a)) b else a
cfg <- tempfile(fileext = ".json")
gd_config_path <- function() cfg
collab_save_settings(modifyList(collab_settings_default(), list(mode = "folder", local_path = folder, share_with = "everyone", exported_by = "me@team.org")), cfg)
inserted <- list()
am <- list(bq_authenticated = TRUE, bq_full_table_funding = "p.d.funding_programmes", bq_time_zone_ready = list(funding = TRUE),
  state_trigger_funding = reactiveVal(0), bq_bump = function(...) NULL, bq_need = function(...) NULL, bq_ensure_time_zone_column = function(...) TRUE,
  bq_get_funding_taxonomy = function() data.frame(category = c("Grant", "Loan"), country = c("United Kingdom", "Mexico"), city_region = "All"),
  bq_funding_keys = function() data.frame(id = 7L, programme_name = "Smart Energy Grant", key_sponsors = "Innovate UK", source_ref = "", stringsAsFactors = FALSE),
  bq_insert_funding = function(df) { inserted[[length(inserted) + 1]] <<- df; nrow(df) },
  bq_query = function(q) data.frame(id = c(7L, 9L, 10L), programme_name = c("Smart Energy Grant", "Fondo Semilla", "Imported one"), category = c("Grant", "Loan", "Grant"),
                                    country = c("United Kingdom", "Mexico", "United Kingdom"), deadline = c("2027-01-15", "2027-03-01", ""),
                                    source = c(NA, NA, "CollaborationPlanning backup"), stringsAsFactors = FALSE))
pass <- 0; fail <- 0
check <- function(n, ok, d = NULL) { ok <- isTRUE(ok); cat(if (ok) "PASS " else "FAIL ", n, if (!ok && !is.null(d)) paste(" ->", paste(format(d), collapse = " | ")), "\n", sep = ""); if (ok) pass <<- pass + 1 else fail <<- fail + 1 }
txt <- function(x) paste(as.character(x$html %||% x), collapse = " ")
testServer(funding_collab_sync_server, args = list(api_manager = am), {
  session$setInputs(use_tables = FALSE, use_backup = TRUE, use_analyses = TRUE, to_programmes = FALSE, to_table_analyses = FALSE, to_drive = TRUE, include_already = FALSE, which = "ours", countries = NULL, categories = NULL)
  session$setInputs(read = 1)
  m <- marked()
  if (is.null(m)) cat("read status:", txt(output$read_status), "\n")
  check("Read: backup + analysis rows", nrow(m) == 3, m$programme_name)
  check("Read: Smart Energy Grant repeated, others new", m$status[m$programme_name == "Smart Energy Grant"] == "Repeated" && sum(m$status == "New") == 2, m$status)
  check("Read: summary line", grepl("New: 2, Repeated: 1, Already imported: 0", txt(output$read_status)), txt(output$read_status))
  session$setInputs(load = 1)
  d <- inserted[[1]]
  check("Load: 3 rows, repeated flag, source and ref, no preview columns", nrow(d) == 3 && sum(d$repeated == "TRUE") == 1 && all(startsWith(d$source, "CollaborationPlanning")) &&
        !any(c("status", "same_as_id") %in% names(d)), names(d))
  check("Load: message", grepl("Loaded 3 programme\\(s\\) into BigQuery: 2 new, 1 marked as repeated", txt(output$load_status)), txt(output$load_status))
  session$setInputs(share = 1)
  check("Share: 2 of ours written (the imported one left out)", grepl("Drive: 2 analysis file pair", txt(output$share_status)), txt(output$share_status))
  session$setInputs(which = "all", countries = "Mexico"); session$setInputs(preview_share = 1)
  check("Share preview: country filter", grepl("^.*1 programme\\(s\\) would be written as analyses: Fondo Semilla", txt(output$share_status)), txt(output$share_status))
})
f <- list.files(folder, pattern = "__bos_.*\\.json$", recursive = TRUE)
check("files in the folder: United Kingdom/Grant/... and Mexico/Loan/...", setequal(f, c("United Kingdom/Grant/Funding programme/Smart Energy Grant__bos_7.json", "Mexico/Loan/Funding programme/Fondo Semilla__bos_9.json")), f)
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); quit(status = if (fail) 1 else 0)
