# tools/cp_tables_check.R - reading and writing CollaborationPlanning's tables (R/suite_cp.R) with that app's OWN
# storage code. BigQuery is replaced by an in-memory table store inside that code (bq_read / bq_append / bq_ensure_table);
# everything above it (store_read/store_append, add_programmes, latest_analyses, change log) is that app's real code.
# Its visibility rule (can_see_analysis) is checked with its own analysis.R + mail.R.  Run: COLLAB_DIR=<CollaborationPlanning> Rscript tools/cp_tables_check.R
suppressMessages({ library(shiny); library(R6); library(jsonlite) })
for (f in c("R/utils_gdrive.R", "R/utils_collab_sync.R", "R/suite_cp.R")) source(f)
for (f in c("R/utils_timezone.R", "R/api_manager.R")) source(f)     # bos_rbind_fill
pass <- 0; fail <- 0
check <- function(n, ok, d = NULL) { ok <- isTRUE(ok); cat(if (ok) "PASS " else "FAIL ", n, if (!ok && !is.null(d)) paste(" ->", paste(format(d), collapse = " ")), "\n", sep = ""); if (ok) pass <<- pass + 1 else fail <<- fail + 1 }

mem <- new.env()
assign("bq_ensure_table", function(tab) invisible(TRUE), envir = CP_ENV)
assign("bq_append", function(tab, df) { mem[[tab]] <- rbind(if (is.null(mem[[tab]])) CP_ENV$empty_table(tab) else mem[[tab]], df); invisible(nrow(df)) }, envir = CP_ENV)
assign("bq_read", function(tab) CP_ENV$conform(if (is.null(mem[[tab]])) CP_ENV$empty_table(tab) else mem[[tab]], tab), envir = CP_ENV)

api <- new.env(); api$bq_authenticated <- FALSE; api$bq_project_id <- "atera-2"; api$bq_credentials_path <- ""
s <- collab_settings_default(); s$share_with <- "partner@uni.ac.uk"; s$exported_by <- "joseph.zr@atera-analytics.co.uk"
e <- tryCatch(cp_connect(api, s), error = function(e) conditionMessage(e))
check("no BigQuery connection -> clear message", grepl("Connect to BigQuery first", e), e)
api$bq_authenticated <- TRUE
st <- cp_connect(api, s)
check("tables: write to BigQuery, read from BigQuery (no Sheet set)", identical(st$write_to, "BigQuery") && st$read_from == "BigQuery" &&
      st$dataset == "atera-2.business_strategy" && st$prefix == "cp_")
check("its code addresses cp_<table> in the same dataset", CP_ENV$bq_table_id("programmes") == "atera-2.business_strategy.cp_programmes")
s2 <- s; s2$sheet_id <- "https://docs.google.com/spreadsheets/d/1AbC_dEf-123/edit#gid=0"; s2$key_file <- "/nonexistent.json"
e <- tryCatch(cp_connect(api, s2), error = function(e) conditionMessage(e))
check("Sheet link -> id; Sheet without a usable key -> clear message (it reads from the Sheet)", cp_sheet_id(s2$sheet_id) == "1AbC_dEf-123" && grepl("no service-account key", e), e)
cp_connect(api, s)

# ---- that app adds programmes and an analysis, as its own tabs do
raw <- data.frame(programme_name = c("Smart Grants", "BridgeAI Feasibility", "Example Fund"), funder = c("Innovate UK", "Innovate UK", "X"),
                  country = "United Kingdom", category = "Grant", amount_of_money = c("Up to GBP 500,000", "GBP 50k - 100k", ""),
                  deadline = c("2026-12-10", "2027-01-20", ""), is_example = c("FALSE", "FALSE", "TRUE"), stringsAsFactors = FALSE)
CP_ENV$add_programmes(CP_ENV$programmes_from_parsed(raw, source = "live search"), "ali@x.com")
tabs <- list(list(title = "Shortlist", columns = list("Programme", "Funder", "Amount", "Deadline", "Link"),
                  rows = list(list("Eureka Globalstars", "Eureka", "EUR 300k", "2027-02-01", "https://eurekanetwork.org/x"))))
CP_ENV$store_append("analyses", data.frame(analysis_id = "an_1", title = "AI partners", tables_json = as.character(toJSON(tabs, auto_unbox = TRUE)),
  country = "United Kingdom", category = "Grant", topic = "AI", programme = "", access_emails = "everyone", status = "saved",
  created_by = "ali@x.com", created_at = CP_ENV$now_ts(), updated_at = CP_ENV$now_ts(), deleted = "FALSE", stringsAsFactors = FALSE), user = "ali@x.com")

p <- cp_programme_rows()
check("read its programmes list (example rows left out, its id kept as source_ref)", nrow(p) == 2 && all(p$source == COLLAB_SOURCE_TABLE) &&
      all(startsWith(p$source_ref, "prog")) && "Smart Grants" %in% p$programme_name, p$programme_name)
a <- cp_analysis_rows()
check("read programmes inside its analyses (table rows)", nrow(a$rows) == 1 && a$rows$programme_name == "Eureka Globalstars" && a$rows$source_ref == "an_1", a$rows)

# ---- import into our table, then the repeat check
ours <- data.frame(id = "17", programme_name = "Smart Grants", key_sponsors = "Innovate UK", source_ref = "", stringsAsFactors = FALSE)
m <- collab_mark_repeats(collab_conform(rbind(p, a$rows)), ours)
check("repeat marks: Smart Grants Repeated (already ours), others New", m$status[m$programme_name == "Smart Grants"] == "Repeated" &&
      all(m$status[m$programme_name != "Smart Grants"] == "New"), m[, c("programme_name", "status")])
loaded <- collab_rows_for_bq(m)
m2 <- collab_mark_repeats(collab_conform(rbind(p, a$rows)), rbind(ours, data.frame(id = "18", programme_name = loaded$programme_name,
       key_sponsors = loaded$key_sponsors, source_ref = loaded$source_ref, stringsAsFactors = FALSE)))
check("read again after loading: 'Already imported'", all(m2$status == "Already imported"), m2$status)

# ---- write: our programmes -> its list, and as analyses
d <- data.frame(id = c("31", "32"), programme_name = c("Horizon Europe Pathfinder", "Smart Grants"), key_sponsors = c("European Commission", "Innovate UK"),
                country = c("EU", "United Kingdom"), category = "Grant", amount_of_money = c("EUR 3m", "Up to GBP 500,000"),
                deadline = c("2027-03-05 17:00", "2026-12-10"), start_date_for_applying = "", areas_of_application = c("Deep tech", ""),
                conditions = "", verified_urls = c("https://ec.europa.eu/p", ""), recommendations_for_applying = "", key_organiser_profiles = "",
                city_region = "All", time_zone = "Europe/London", created_at = "2026-11-20 10:00:00", stringsAsFactors = FALSE)
r <- cp_write_programmes(d, s$exported_by)
check("programmes list: new one added, same funder + name skipped (its add_programmes)", r$added == 1 && r$skipped == 1, r)
pl <- cp_read("programmes"); hp <- pl[pl$programme_name == "Horizon Europe Pathfinder", ]
check("added in its own layout (funder, closes date, stage Discover, source, added_by)", nrow(hp) == 1 && hp$funder == "European Commission" &&
      hp$closes_date == "2027-03-05" && hp$stage == "Discover" && hp$source == CP_PROGRAMME_SOURCE && hp$added_by == s$exported_by, hp)
check("writing again adds nothing", cp_write_programmes(d, s$exported_by)$added == 0)
recs <- lapply(1:2, function(i) collab_export_record(d[i, , drop = FALSE], s, s$exported_by))
n <- cp_write_analyses(recs, s$exported_by)
la <- CP_ENV$latest_analyses(cp_read("analyses"))
check("analyses written to its table with bos_ ids", n == 2 && all(c("bos_31", "bos_32") %in% la$analysis_id))
V <- new.env(parent = globalenv()); for (f in c("config.R", "utils.R", "mail.R", "analysis.R")) sys.source(file.path(Sys.getenv("COLLAB_DIR"), "R", f), envir = V)
mine <- la[startsWith(la$analysis_id, "bos_"), ]
check("its own visibility rule: the share-with person sees them, others do not",
      all(V$can_see_analysis(mine, "partner@uni.ac.uk", FALSE)) && !any(V$can_see_analysis(mine, "someone@else.com", FALSE)))
check("classified as Country > Category > Topic in its tree", all(mine$country %in% c("EU", "United Kingdom")) && "Deep tech" %in% mine$topic &&
      all(grepl("/", mine$drive_path)))
Sys.sleep(1.1); d$amount_of_money[1] <- "EUR 3.5m"
cp_write_analyses(list(collab_export_record(d[1, , drop = FALSE], s, s$exported_by)), s$exported_by)
la2 <- CP_ENV$latest_analyses(cp_read("analyses"))
check("re-sharing updates (newest version wins there, still one per programme)", sum(la2$analysis_id == "bos_31") == 1 &&
      grepl("3.5m", la2$summary[la2$analysis_id == "bos_31"]))
check("its own reader skips what this app shared (no echo back)", cp_analysis_rows()$skipped_own == 2)
cl <- cp_read("changelog")
check("its change log records who wrote", any(cl$user == s$exported_by & cl$entity == "analyses") && any(cl$user == s$exported_by & cl$entity == "programmes"))
# ---- with its Google Sheet (it then reads from the Sheet): Sheets calls replaced by an in-memory sheet
sheet <- new.env()
for (nm in c("gs_list_tabs", "gs_tabs_cached")) assign(nm, function(...) { CP_ENV$.gs$tabs <- ls(sheet); ls(sheet) }, envir = CP_ENV)
assign("gs_ensure_tab", function(tab, existing = NULL) invisible(TRUE), envir = CP_ENV)
assign("gs_append", function(tab, df) sheet[[tab]] <- rbind(if (is.null(sheet[[tab]])) CP_ENV$empty_table(tab) else sheet[[tab]], df), envir = CP_ENV)
assign("gs_read", function(tab) CP_ENV$conform(sheet[[tab]], tab), envir = CP_ENV)
assign("gs_batch_read", function(tabs) sapply(tabs, function(t) CP_ENV$conform(sheet[[t]], t), simplify = FALSE), envir = CP_ENV)
kf <- tempfile(fileext = ".json"); writeLines('{"client_email":"sa@x.iam.gserviceaccount.com"}', kf)
s3 <- s; s3$sheet_id <- "1AbC"; s3$key_file <- kf
st <- cp_connect(api, s3)
check("with its Sheet: writes go to the Sheet and BigQuery, reads come from the Sheet", identical(st$write_to, c("Google Sheet", "BigQuery")) && st$read_from == "Google Sheet")
n_bq <- nrow(mem$programmes)
d2 <- d[1, ]; d2$programme_name <- "KTP"; d2$key_sponsors <- "Innovate UK"
cp_write_programmes(d2, s$exported_by)
check("a new programme lands in both copies", "KTP" %in% sheet$programmes$programme_name && nrow(mem$programmes) == n_bq + 1 &&
      "KTP" %in% cp_read("programmes")$programme_name)
# ---- people and messages (written by its own upsert_person and outreach code path) -> our Communications rows
cp_connect(api, s)
CP_ENV$upsert_person(list(email = "Ana@Uni.ac.uk", name = "Ana Ruiz", organisation = "Uni of X", role_title = "PI", interests = "AI, health",
                          country = "Spain"), "ali@x.com")
CP_ENV$upsert_person(list(email = "ben@corp.com", name = "Ben Ode", organisation = "Corp"), "ali@x.com")
CP_ENV$upsert_person(list(email = "ana@uni.ac.uk", name = "Ana Ruiz", role_title = "Professor"), "ali@x.com")    # an update, same person
CP_ENV$store_append("messages", data.frame(message_id = c("msg_1", "msg_2", "msg_3"), email = c("ana@uni.ac.uk", "ben@corp.com", "nobody@x.com"),
  channel = "email", purpose = "Partner invite", content = c("Hi Ana", "Hi Ben", "?"), subject = c("BridgeAI", "", ""), direction = "out",
  status = "sent", created_by = "ali@x.com", created_at = "2026-11-24 09:00:00", stringsAsFactors = FALSE), user = "ali@x.com")
ppl <- cp_people()
cc <- collab_people_to_contacts(ppl)
check("its people -> contacts (latest version, cp_ ids, email lower-case, its fields mapped)", nrow(cc) == 2 &&
      all(startsWith(cc$contact_id, "cp_per")) && cc$job_title[cc$email == "ana@uni.ac.uk"] == "Professor" &&
      cc$company[cc$email == "ana@uni.ac.uk"] == "Uni of X" && grepl("From CollaborationPlanning", cc$user_notes[1]), cc[, c("full_name", "email", "job_title")])
ours_c <- data.frame(contact_id = "u-1", full_name = "Benjamin Ode", company = "Corp", email = "BEN@corp.com", source_ref = NA, stringsAsFactors = FALSE)
mk <- collab_mark_contact_repeats(cc, ours_c)
check("contacts: Ben (same email as ours) Repeated, Ana New", mk$status[mk$email == "ben@corp.com"] == "Repeated" && mk$same_as_id[mk$email == "ben@corp.com"] == "u-1" &&
      mk$status[mk$email == "ana@uni.ac.uk"] == "New", mk[, c("email", "status")])
all_c <- bos_rbind_fill(ours_c, cc)
check("after import: 'Already imported'", all(collab_mark_contact_repeats(cc, all_c)$status == "Already imported"))
cm <- collab_messages_to_comms(cp_messages(), all_c)
check("messages: linked to OUR contact when the email matches, else the imported one; unknown people left out",
      nrow(cm) == 2 && cm$contact_id[cm$source_ref == "msg_2"] == "u-1" && startsWith(cm$contact_id[cm$source_ref == "msg_1"], "cp_per") &&
      grepl("^Subject: BridgeAI", cm$message_content[cm$source_ref == "msg_1"]) && grepl("(out sent)", cm$communication_purpose[1], fixed = TRUE), cm)
check("messages imported before are skipped", nrow(collab_messages_to_comms(cp_messages(), all_c, cm$message_id)) == 0)

# ---- funding outputs into its Country/Category/Topic folders (folder mode), invisible to its analysis reader
root <- tempfile("cpfolder"); dir.create(root)
sf <- s; sf$mode <- "folder"; sf$local_path <- root
lv <- collab_output_levels("United Kingdom", "all", sf)
p1 <- collab_write_outputs(lv, "funding_programmes_by_category", list(list(ext = "png", bytes = as.raw(1:5)), list(ext = "csv", bytes = charToRaw("a,b"))), sf)
check("outputs land in Country/Category/Topic (all categories named)", identical(lv, c("United Kingdom", "All categories", "Funding programme")) &&
      length(p1) == 2 && all(file.exists(file.path(root, p1))), p1)
D <- new.env(parent = globalenv()); for (f in c("config.R", "utils.R", "drive.R")) sys.source(file.path(Sys.getenv("COLLAB_DIR"), "R", f), envir = D)
dset <- list(drive_mode = "folder", drive_local_path = root)
check("its own Drive reader does not take them for analyses", nrow(D$drive_pull_analyses(dset)) == 0)
e1 <- collab_export_record(d[1, , drop = FALSE], sf, s$exported_by); collab_folder(sf)$write_analysis(e1$levels, e1$stem, e1$json, e1$html, e1$analysis_id)
check("...while our shared analysis next to them is read by it", nrow(D$drive_pull_analyses(dset)) == 1)
check("not set up -> nothing written, no error", is.null(collab_write_outputs(lv, "x", list(list(ext = "csv", bytes = raw(1))), collab_settings_default())))

cat(sprintf("%d passed, %d failed\n", pass, fail))
