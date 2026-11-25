# tools/merge_dpet_check.R - DaysPlanningExerciseTravel inside this app (R/suite_dpet.R):
# helper isolation, module entry points, one DPET manager per session, credentials handed over from API Settings,
# DPET table checks on first opening of a tab, Titan buttons on Funding/Gantt, registry order.
# BigQuery is replaced by recording stand-ins defined in the global environment (DPET helpers look there first).
suppressMessages({ library(shiny); library(shinydashboard); library(R6); library(yaml); library(purrr); library(httr); library(httr2)
                   library(jsonlite); library(DT); library(plotly); library(dplyr); library(stringr); library(tidyr); library(xml2); library(uuid) })
pass <- 0; fail <- 0
check <- function(n, ok, d = NULL) { ok <- isTRUE(ok); cat(if (ok) "PASS " else "FAIL ", n, if (!ok && !is.null(d)) paste(" ->", paste(format(d), collapse = " ")), "\n", sep = ""); if (ok) pass <<- pass + 1 else fail <<- fail + 1 }
source("global.R")

# --- isolation
check("DPET helpers live in DPET_ENV, ours stay global", !identical(body(DPET_ENV$generic_export_box_ui), body(generic_export_box_ui)) &&
      identical(environment(DPET_ENV$generic_export_box_ui), DPET_ENV))
check("a DPET tab's own code resolves DPET helpers", identical(environment(get("generate_schedule_server", DPET_ENV)), DPET_ENV))
check("our tabs keep our helpers (funding uses this app's generic_export_box_ui)", identical(environment(funding_visualizations_server), globalenv()))
ids <- loader$get_all_module_ids()
dp_ids <- names(Filter(function(m) identical(m$suite, "dpet"), loader$registry$modules))
check("all 37 DPET tabs (36 + Titan Calendar) registered with entry points in the global env", length(dp_ids) == 37 &&
      all(vapply(dp_ids, function(m) exists(paste0(m, "_ui"), globalenv()) && exists(paste0(m, "_server"), globalenv()), TRUE)), length(dp_ids))
check("DPET's own API tabs (BigQuery/Claude/Drive/Debug) not duplicated", !any(c("bigquery_auth", "claude_api_config", "gdrive_api_config") %in% ids) && "titan_auth" %in% ids)

# --- BigQuery stand-ins (global env: DPET's unqualified bq_* calls find these first)
rec <- new.env(); rec$sql <- character(); rec$auth <- character()
bq_deauth <- function() invisible(TRUE)
bq_auth <- function(path, ...) { rec$auth <- c(rec$auth, path); invisible(TRUE) }
bq_project_datasets <- function(...) list()
bq_project_query <- function(project, sql, ...) { rec$sql <- c(rec$sql, sql); structure(list(sql = sql), class = "fakejob") }
bq_table_download <- function(x, ...) {
  if (grepl("INFORMATION_SCHEMA", x$sql)) data.frame(table_name = character(), column_name = character()) else data.frame()
}
key <- tempfile(fileext = ".json")
writeLines(jsonlite::toJSON(list(type = "service_account", project_id = "atera-2", private_key = "x", client_email = "sa@x.iam.gserviceaccount.com"), auto_unbox = TRUE), key)

reg <- loader$registry
layout <- nav_register(nav_layout(reg, ids))
testServer(function(input, output, session) {
  api <- APIManager$new()
  session$userData$api <- api
  dpet_bridge_wire(api, session, layout)
  for (m in c("schedule_visualizations", "events_to_calendar")) get(paste0(m, "_server"))(m, api)
}, {
  api <- session$userData$api; dp <- api$dpet
  check("one DPET manager per session, of DPET's own class", !is.null(dp) && inherits(dp, "R6") && !identical(dp, api) && is.null(api$titan_state) &&
        is.function(dp$titan_state))
  session$setInputs(sidebar_menu = "sec_dp_review", tabs_sec_dp_review = "schedule_visualizations"); session$elapse(100)
  check("tab opened before BigQuery: waits (not loaded)", !"schedule_visualizations" %in% session$userData$tabs_opened() &&
        any(vapply(dp$bq_unit_status, function(x) x$state %in% c("waiting", "offline"), TRUE)))
  # connect in API Settings (as bq_config does on success)
  api$bq_credentials_path <- key; api$bq_authenticated <- TRUE; api$bq_project_id <- "atera-2"; api$bq_dataset_id <- "business_strategy"
  api$claude_api_key <- "sk-ant-test"; api$claude_model <- "claude-sonnet-4-5"; api$claude_authenticated <- TRUE
  session$elapse(1600); session$flushReact()
  check("BigQuery handed over: DPET connected with the same key/project/dataset", isTRUE(dp$bq_authenticated) && identical(tail(rec$auth, 1), key) &&
        dp$bq_project_id == "atera-2" && dp$bq_dataset_id == "business_strategy")
  check("Claude handed over: same key and model", identical(dp$claude_api_key, "sk-ant-test") && identical(dp$claude_model, "claude-sonnet-4-5") && isTRUE(dp$claude_authenticated))
  session$elapse(1600); session$flushReact(); session$elapse(100)
  check("waiting tab checked its tables after connecting (day_scheduler created if missing)",
        any(grepl("CREATE TABLE IF NOT EXISTS `atera-2.business_strategy.day_scheduler`", rec$sql, fixed = TRUE)), tail(rec$sql, 3))
  check("tab then marked opened (its data loaders may run)", "schedule_visualizations" %in% session$userData$tabs_opened() &&
        "schedule" %in% session$userData$keys_opened())
  n0 <- length(rec$auth); session$elapse(3200)
  check("no repeated re-login while nothing changes", length(rec$auth) == n0)
  session$setInputs(sidebar_menu = "sec_ev_review", tabs_sec_ev_review = "browse_events"); session$elapse(100); session$flushReact()
  check("another DPET tab checks only its own table (city_events)", any(grepl("city_events", rec$sql)) && !any(grepl("diet_log", rec$sql)))
  api$claude_api_key <- "sk-ant-other"; session$elapse(1600)
  check("changing the Claude key in API Settings reaches DPET", identical(dp$claude_api_key, "sk-ant-other"))
  api$bq_authenticated <- FALSE; session$elapse(1600)
  check("disconnecting BigQuery in API Settings disconnects DPET", !isTRUE(dp$bq_authenticated))
  check("DPET table statuses feed the sidebar TABLES box", length(dpet_unit_status(api)) >= 2)
})

# --- Titan buttons on Funding / Gantt
testServer(funding_visualizations_server, args = list(api_manager = APIManager$new()), {
  out <- output$titan_buttons
  check("Funding Visualizations: Titan calendar box (asks to sign in)", grepl("Titan calendar: not signed in", out$html), out$html)
})
am <- APIManager$new()
am$gantt_data <- data.frame(Task_Name = c("Design", "Build"), Start_Date = c("2026-12-01", "2026-12-05"), End_Date = c("2026-12-03", "2026-12-09"),
                            stringsAsFactors = FALSE)
testServer(review_edit_server, args = list(api_manager = am), {
  check("Gantt Review & Edit: Titan calendar box", grepl("Titan", output$titan_buttons$html))
  dp <- dpet_manager(am)
  dp$titan_state(list(ok = TRUE, email = "me@company.com", server = "https://dav.titan.email"))
  session$flushReact()
  check("signed in to Titan: the two buttons appear", grepl("Load events into calendar", output$titan_buttons$html))
  session$setInputs(titan_load_events = 1)
  q <- dp$titan_queue()
  check("Gantt tasks reach Events to Calendar's 'Events to save' list as Due entries on their end dates",
        length(q) == 2 && all(grepl("^Due: ", vapply(q, `[[`, "", "title"))) && grepl("2026-12-09", format(q[[2]]$start)), lapply(q, `[[`, "when"))
})

# --- order
lab <- vapply(reg$groups, `[[`, "", "label")
check("sidebar order", identical(lab, c("API Settings", "Funding Programmes", "Project Application", "Strategy Canvases", "Communications",
  "Events Scheduling", "Day Planner", "Gantt to Tickets", "Health Tracker", "Media Processing")), lab)
sec_of <- function(g) vapply(reg$groups[[match(g, lab)]]$sections, `[[`, "", "label")
check("Online Collaboration last in Communications; Travel Planning last in Events Scheduling",
      tail(sec_of("Communications"), 1) == "Online Collaboration" && tail(sec_of("Events Scheduling"), 1) == "Travel Planning")
mp <- reg$groups[[match("Media Processing", lab)]]$sections
rc <- mp[[length(mp)]]
check("Receipt Processor: one sidebar item in Media Processing with its 6 tabs as horizontal tabs", rc$label == "Receipt Processor" && length(rc$modules) == 6)
tones <- function(g) vapply(reg$groups[[match(g, lab)]]$sections, function(s) s$tone %||% "", "")
check("green tones mark the former groups", identical(tones("Media Processing"), c("audio", "audio", "audio", "visual", "visual", "receipts")) &&
      identical(tones("Health Tracker"), c("exercise", "exercise", "exercise", "diet", "diet")))
cat(sprintf("%d passed, %d failed\n", pass, fail))
