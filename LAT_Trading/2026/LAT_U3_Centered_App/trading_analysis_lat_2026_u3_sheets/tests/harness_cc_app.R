# tests/harness_cc_app.R - the T Records C.C tab in a real browser against a FAKE Capital.com and an in-memory store.
# Used by tests/browser_cc.js (Playwright). Run: Rscript -e 'shiny::runApp(source("tests/harness_cc_app.R")$value, port = 8790)' from the app folder.
suppressMessages({ library(shiny); library(shinydashboard); library(TTR); library(zoo); library(DT); library(plotly) })
`%||%` <- function(x, y) if (is.null(x)) y else x
for (f in c("R/utils_cc_catalog.R", "R/utils_cc_api.R", "R/utils_cc_patterns.R", "R/utils_cc_chart.R", "R/utils_cc_records.R", "R/utils_cc_advice.R", "R/utils_cc_plan.R", "R/utils_unit3_rules.R", "R/utils_cc_course_full.R", "R/utils_cc_course_checks.R", "modules/cc_trading_records.R")) source(f)
src <- readLines("tests/test_cc_api_records.R"); eval(parse(text = src[grep("^js <- ", src):(grep("^cat\\(\"Credentials file", src) - 1)]))
cl <- cc_new_client(http_fn = fake$fn, sleep_fn = function(s) NULL)
cl$set_credentials(list(api_key = "KEY-123456789", identifier = "me@example.com", api_password = "pw", environment = "demo")); cl$login()
store <- cc_make_store(cc_mem_backend())
# a market like Brent on 30/10-02/11: a rally, a sharp fall, a small bounce (30-minute candles)
set.seed(1); kn <- c(108, 110.5, 109.5, 113, 114, 108.8, 109.3); ln <- c(250, 150, 125, 60, 30, 6); y <- kn[1]
for (k in seq_along(ln)) y <- c(y, seq(kn[k], kn[k + 1], length.out = ln[k] + 1)[-1]); nz <- 0.085; n <- length(y)
y <- y + cumsum(rnorm(n, 0, nz)) * 0.3 + rnorm(n, 0, nz); op <- c(y[1], head(y, -1))
bars <- data.frame(time = as.POSIXct("2026-10-10", tz = "UTC") + (0:(n - 1)) * 1800, open = op, high = pmax(op, y) + abs(rnorm(n, 0, nz)), low = pmin(op, y) - abs(rnorm(n, 0, nz)), close = y)
ui <- dashboardPage(dashboardHeader(title = "harness"), dashboardSidebar(disable = TRUE), dashboardBody(cc_trading_records_ui("cc")))
server <- function(input, output, session) cc_trading_records_server("cc", cl, store = store, fetch_bars = function(...) bars, vision_fn = function(p) list(text = if (grepl("propose up to 3 trades", p)) '{"summary":"Test suggestion.","morning_sheet_used":true,"suggestions":[{"side":"SELL","type":"LIMIT","entry":65.4567,"stop":66.1234,"target":63.9876,"probability_pct":41,"horizon_hours":5,"why":"Test.","main_risk":"Test risk."}],"scenario_estimates":[{"id":"BUY MARKET","probability_pct":52}]}' else if (grepl("COURSE CHECKS", p)) '{"checks":[],"additions":[],"course":[{"id":"htf","verdict":"supports","note":"Trend test note."}]}' else "{}"),
  morning_fn = function(day) list(ok = TRUE, sheet_id = "MS_T", saved_at = Sys.time(), text = "MORNING SHEET test"))
shinyApp(ui, server)
