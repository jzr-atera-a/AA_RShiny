# tools/collab_sync_check.R - exchange with CollaborationPlanning through its Drive folder, tested against that
# app's OWN code (its R/drive.R, R/analysis.R, R/config.R, R/utils.R, R/programmes.R).
# Run from this app's folder:
#   python3 tools/fake_drive.py 8899 &
#   COLLAB_DIR=/path/to/CollaborationPlanning Rscript tools/collab_sync_check.R 8899 path/to/service_account.json
args <- commandArgs(trailingOnly = TRUE); port <- args[1]; sa_file <- args[2]
base <- paste0("http://127.0.0.1:", port)
options(bos.gdrive.api = paste0(base, "/drive/v3"), bos.gdrive.upload = paste0(base, "/upload/drive/v3"),
        bos.gdrive.token = paste0(base, "/token"))
suppressMessages({ library(shiny); library(htmltools) })
source("R/utils_gdrive.R"); source("R/utils_collab_sync.R")

# ---- CollaborationPlanning's own code, in its own environment
CP <- new.env()
cp_dir <- Sys.getenv("COLLAB_DIR")
for (f in c("config.R", "utils.R", "analysis.R", "programmes.R", "drive.R")) sys.source(file.path(cp_dir, "R", f), envir = CP)
take <- function(file, start) {                                 # one function from another file of that app
  src <- readLines(file.path(cp_dir, "R", file)); i <- grep(start, src)[1]; j <- i - 1 + which(grepl("^}", src[i:length(src)]))[1]
  eval(parse(text = src[i:j]), envir = CP)
}
take("collab.R", "^`%\\|%` <- function")                       # its `%|%` helper
take("mail.R", "^split_emails <- function")
CP$has_pkg <- function(p) FALSE                                  # plain HTML tables (no flextable here)
CP$DRIVE_API <- paste0(base, "/drive/v3/files"); CP$DRIVE_UPLOAD <- paste0(base, "/upload/drive/v3/files")
tok <- function() jsonlite::fromJSON(httr::content(httr::POST(paste0(base, "/token"), encode = "form",
                     body = list(grant_type = "refresh_token", client_id = "cid", refresh_token = "rt-good")), "text"))$access_token
CP$google_token <- function(...) tok()
CP$sa_key_available <- function() TRUE

pass <- 0; fail <- 0
check <- function(n, ok, d = NULL) { ok <- isTRUE(ok); cat(if (ok) "PASS " else "FAIL ", n, if (!ok && !is.null(d)) paste(" ->", paste(format(d), collapse = " | ")), "\n", sep = ""); if (ok) pass <<- pass + 1 else fail <<- fail + 1 }

# ---- sample content made the way CollaborationPlanning makes it
make_analysis <- function(id, title, tables, cls, deleted = "FALSE", updated = "2026-11-20 10:00:00") {
  a <- as.data.frame(as.list(setNames(rep("", length(CP$SCHEMAS$analyses)), CP$SCHEMAS$analyses)), stringsAsFactors = FALSE)
  a$analysis_id <- id; a$title <- title; a$summary <- paste("Summary of", title); a$status <- "saved"
  a$country <- cls[1]; a$category <- cls[2]; a$topic <- cls[3]; a$programme <- cls[4]
  a$tables_json <- CP$tables_to_json(tables); a$created_by <- "admin@team.org"; a$created_at <- updated; a$updated_at <- updated; a$deleted <- deleted
  a
}
grants <- data.frame(`Programme name` = c("Smart Energy Grant", "Net Zero Accelerator", "Smart Energy Grant"),
                     Funder = c("Innovate UK", "Carbon Trust", "Innovate UK"),
                     `Funding available` = c("Up to GBP 500,000", "GBP 50k", "Up to GBP 500,000"),
                     Deadline = c("2027-01-15", "Rolling", "2027-01-15"),
                     Link = c("https://apply.innovateuk.org/x", "https://carbontrust.com/y", "https://apply.innovateuk.org/x"),
                     `Why it fits` = c("Matches our AI grid work", "Mentoring + funding", "dup"), check.names = FALSE)
an1 <- make_analysis("ana_1", "Energy grants for AI", list(list(title = "Grants found", data = grants), list(title = "Risks", data = data.frame(Risk = "x", Impact = "y"))),
                     c("United Kingdom", "Grant", "Energy AI", "Several"))
an2 <- make_analysis("ana_2", "EIC Pathfinder check", list(list(title = "Notes", data = data.frame(Point = "Consortium of 3", Detail = "Needed"))),
                     c("European Union", "Grant", "Deep tech", "EIC Pathfinder"))
an3 <- make_analysis("ana_3", "Old deleted one", list(), c("United Kingdom", "Grant", "x", "Deleted Prog"), deleted = "TRUE")
raw_prog <- data.frame(programme_name = c("Smart Energy Grant", "Example Fund", "AI Skills Prize"), funder = c("Innovate UK", "Demo", "DSIT"),
                       category = c("Grant", "Grant", "Prize"), country = "United Kingdom", summary = c("Grid flexibility projects", "x", "Skills"),
                       themes = c("Energy, AI", "x", "AI skills"), conditions = c("UK SMEs", "", "Open to all"), amount_text = c("", "x", "GBP 25k"),
                       min_gbp = c("100000", "", ""), max_gbp = c("500000", "", ""), funding_rate_pct = c("70", "", ""),
                       closes_date = c("2027-01-15", "", ""), deadline_text = c("", "", "Rolling"), opens_date = c("2026-11-01", "", ""),
                       source_url = c("https://apply.innovateuk.org/x", "", ""), is_example = c("FALSE", "TRUE", "FALSE"), stringsAsFactors = FALSE)
prog <- CP$map_programme_columns(raw_prog, "search"); prog$is_example <- raw_prog$is_example
old_prog <- prog[1, , drop = FALSE]; old_prog$programme_name <- "Older backup only"

# ---- our existing table (for the repeat check)
existing <- data.frame(id = c(7L, 8L), programme_name = c("Smart Energy Grant", "Something else"), key_sponsors = c("Innovate UK", ""),
                       source_ref = c("", ""), stringsAsFactors = FALSE)
ours <- data.frame(id = c(7L, 9L), created_at = c("2026-10-01 09:00:00", "2026-10-02 09:00:00"), category = c("Grant", "Loan"),
                   country = c("United Kingdom", "Mexico"), city_region = c("All", "CDMX"), programme_name = c("Smart Energy Grant", "Fondo Semilla"),
                   amount_of_money = c("GBP 500k", "MXN 1M"), conditions = c("UK SMEs", "Startups"), key_sponsors = c("Innovate UK", "NAFIN"),
                   key_organiser_profiles = "", areas_of_application = c("Energy, AI", ""), start_date_for_applying = c("2026-11-01", ""),
                   deadline = c("2027-01-15 17:00", "2027-03-01"), recommendations_for_applying = "", verified_urls = c("https://apply.innovateuk.org/x", ""),
                   time_zone = c("Europe/London", "America/Mexico_City"), stringsAsFactors = FALSE)

run_mode <- function(mode) {
  cat(sprintf("\n==== %s mode ====\n", mode))
  if (mode == "folder") {
    root <- file.path(tempdir(), "collab_shared"); unlink(root, recursive = TRUE); dir.create(root)
    cps <- list(drive_mode = "folder", drive_local_path = root, drive_folder_id = "")
    s <- modifyList(collab_settings_default(), list(mode = "folder", local_path = root, share_with = "everyone", exported_by = "joseph@team.org"))
  } else {
    cps <- list(drive_mode = "api", drive_local_path = "", drive_folder_id = "sharedFolder01")
    s <- modifyList(collab_settings_default(), list(mode = "api", folder_id = "https://drive.google.com/drive/folders/sharedFolder01", key_file = sa_file,
                                                    share_with = "everyone", exported_by = "joseph@team.org"))
  }
  # CollaborationPlanning writes its analyses and two daily backups
  for (a in list(an1, an2, an3)) CP$drive_save_analysis(a, cps)
  CP$drive_save_file(c("Backups", "2026-11-20"), "programmes.csv", CP$csv_text(old_prog), "text/csv", cps)
  CP$drive_save_file(c("Backups", "2026-11-23"), "programmes.csv", CP$csv_text(prog), "text/csv", cps)

  fo <- collab_folder(s, sa_path = NA)
  # ---- IMPORT
  b <- fo$latest_backup("programmes")
  check(paste(mode, "- latest backup day picked"), identical(b$day, "2026-11-23"), b$day)
  bp <- collab_programmes_to_bos(collab_read_csv_text(b$text))
  check(paste(mode, "- backup: 2 programmes (example row skipped)"), nrow(bp) == 2, nrow(bp))
  sg <- bp[bp$programme_name == "Smart Energy Grant", ]
  check(paste(mode, "- backup mapping: deadline, opens, sponsors, amount, areas, summary, url"),
        sg$deadline == "2027-01-15" && sg$start_date_for_applying == "2026-11-01" && grepl("Innovate UK", sg$key_sponsors) &&
        sg$amount_of_money == "GBP 100000 to 500000 (70% funded)" && sg$areas_of_application == "Energy, AI" &&
        startsWith(sg$conditions, "Grid flexibility projects") && grepl("apply.innovateuk.org", sg$verified_urls), as.list(sg))
  check(paste(mode, "- backup: rolling deadline kept as text; source + id"), bp$deadline[bp$programme_name == "AI Skills Prize"] == "Rolling" &&
        all(bp$source == COLLAB_SOURCE_BACKUP) && all(startsWith(bp$source_ref, "prog_")))
  ra <- collab_read_analyses(fo$analyses())
  check(paste(mode, "- analyses: 2 read (deleted one skipped)"), ra$analyses == 2, ra$analyses)
  ar <- ra$rows
  check(paste(mode, "- analysis table -> 3 programme rows + 1 from a classification"), nrow(ar) == 4, ar$programme_name)
  ne <- ar[ar$programme_name == "Net Zero Accelerator", ]
  check(paste(mode, "- table columns mapped (funder, amount, deadline, link, why)"),
        ne$key_sponsors == "Carbon Trust" && ne$amount_of_money == "GBP 50k" && ne$deadline == "Rolling" && grepl("carbontrust", ne$verified_urls) &&
        grepl("Mentoring", ne$recommendations_for_applying) && ne$country == "United Kingdom" && ne$areas_of_application == "Energy AI", as.list(ne))
  check(paste(mode, "- classification-only analysis -> EIC Pathfinder row"), any(ar$programme_name == "EIC Pathfinder" & ar$country == "European Union"))
  check(paste(mode, "- risk table ignored (not programmes)"), !any(ar$programme_name == "x"))
  # ---- repeat marking
  all_in <- rbind(collab_conform(bp), collab_conform(ar))   # as the tab does
  existing2 <- existing; existing2$source_ref[2] <- bp$source_ref[bp$programme_name == "AI Skills Prize"]
  mk <- collab_mark_repeats(all_in, existing2)
  st <- setNames(mk$status, paste(mk$source, mk$programme_name, seq_len(nrow(mk))))
  check(paste(mode, "- Smart Energy Grant (already in our table) -> Repeated"), all(mk$status[mk$programme_name == "Smart Energy Grant"] == "Repeated"), st)
  check(paste(mode, "- same app record loaded before -> Already imported"), mk$status[mk$programme_name == "AI Skills Prize"] == "Already imported", st)
  check(paste(mode, "- new ones -> New"), all(mk$status[mk$programme_name %in% c("Net Zero Accelerator", "EIC Pathfinder")] == "New"), st)
  ld <- collab_rows_for_bq(mk)
  check(paste(mode, "- load set: Already imported left out, repeated flag TRUE/FALSE"), !any(ld$programme_name == "AI Skills Prize") &&
        all(ld$repeated[ld$programme_name == "Smart Energy Grant"] == "TRUE") && all(ld$repeated[ld$programme_name == "Net Zero Accelerator"] == "FALSE"))
  check(paste(mode, "- 'include already imported' loads it as repeated"), collab_rows_for_bq(mk, TRUE)$repeated[collab_rows_for_bq(mk, TRUE)$programme_name == "AI Skills Prize"] == "TRUE")

  # ---- EXPORT, then CollaborationPlanning's own reader
  paths <- vapply(seq_len(nrow(ours)), function(i) { e <- collab_export_record(ours[i, , drop = FALSE], s, "me@x.org")
    fo$write_analysis(e$levels, e$stem, e$json, e$html, e$analysis_id) }, "")
  check(paste(mode, "- exported to <Country>/<Category>/<Topic>/<programme>__bos_<id>"), identical(paths[1], "United Kingdom/Grant/Energy/Smart Energy Grant__bos_7"), paths)
  pulled <- CP$drive_pull_analyses(cps)
  mine <- pulled[startsWith(pulled$analysis_id, "bos_"), , drop = FALSE]
  check(paste(mode, "- CollaborationPlanning's drive_pull_analyses() reads our 2 programmes"), nrow(mine) == 2, pulled$analysis_id)
  m7 <- mine[mine$analysis_id == "bos_7", ]
  check(paste(mode, "- in its columns: title, classification, access, status, creator"),
        m7$title == "Smart Energy Grant" && m7$country == "United Kingdom" && m7$category == "Grant" && m7$topic == "Energy" &&
        m7$programme == "Smart Energy Grant" && m7$access_emails == "everyone" && m7$status == "saved" && m7$created_by == "joseph@team.org", as.list(m7))
  tb <- CP$tables_from_json(m7$tables_json)
  check(paste(mode, "- its tables_from_json(): Field/Value table with the deadline and zone"), length(tb) == 1 &&
        any(tb[[1]]$data$Field == "Deadline" & tb[[1]]$data$Value == "2027-01-15 17:00") && any(tb[[1]]$data$Value == "Europe/London"))
  check(paste(mode, "- its can_see_analysis(): shared with everyone"), isTRUE(CP$can_see_analysis(m7, "anyone@team.org", FALSE)))
  check(paste(mode, "- its analysis_html() renders our record"), grepl("Smart Energy Grant", CP$analysis_html(m7)))
  check(paste(mode, "- its analyses still there too"), all(c("ana_1", "ana_2") %in% pulled$analysis_id))
  # re-export after a change of category: moved, not copied; updated_at newer so that app takes it
  ours2 <- ours[1, , drop = FALSE]; ours2$category <- "Competition"; Sys.sleep(1.1)
  e <- collab_export_record(ours2, s); fo$write_analysis(e$levels, e$stem, e$json, e$html, e$analysis_id)
  p2 <- CP$drive_pull_analyses(cps)
  check(paste(mode, "- re-export after a category change: one copy, new place"), sum(p2$analysis_id == "bos_7") == 1 && p2$category[p2$analysis_id == "bos_7"] == "Competition" &&
        p2$updated_at[p2$analysis_id == "bos_7"] > m7$updated_at)
  # our import does not bring back our own exports
  ra2 <- collab_read_analyses(fo$analyses())
  check(paste(mode, "- our own exports are not imported back"), ra2$skipped_own == 2 && !any(grepl("^bos_", ra2$rows$source_ref)), ra2$skipped_own)
  invisible(TRUE)
}
run_mode("folder")
run_mode("api")

# ---- settings round trip
tmp <- tempfile(fileext = ".json"); writeLines('{"google_drive":{"client_id":"keep"}}', tmp)
s <- collab_settings_default(); s$mode <- "api"; s$folder_id <- "abc1234567890"; collab_save_settings(s, tmp)
check("settings: saved next to google_drive", collab_load_settings(tmp)$folder_id == "abc1234567890" && jsonlite::fromJSON(tmp)$google_drive$client_id == "keep")
check("ready: api needs folder + key; folder needs a path", !collab_ready(modifyList(s, list(folder_id = "")), NA) && collab_ready(s, "k.json") &&
      collab_ready(modifyList(s, list(mode = "folder", local_path = "/x")), NA))
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); quit(status = if (fail) 1 else 0)
