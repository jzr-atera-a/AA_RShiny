# Stand-in app for tab H: synthetic candles, no broker. Run: shiny::runApp(source("tests/harness_ml_app.R")$value, port = 8843)
suppressMessages({ library(shiny); library(shinydashboard) }); `%||%` <- function(x, y) if (is.null(x)) y else x
for (f in c("R/utils_cc_catalog.R", "R/utils_cc_api.R", "R/utils_cc_patterns.R", "R/utils_cc_records.R", "R/utils_cc_markets.R", "R/utils_cc_advice.R", "R/utils_ml.R", "modules/cc_trading_records.R", "modules/ml_lab.R")) source(f)
fake_bars <- function(epic, res, from, to) { set.seed(sum(utf8ToInt(epic))); N <- 1800; tm <- as.POSIXct("2026-10-01 00:00", tz = "UTC") + (1:N) * 900; if (epic == "NOPE") return(NULL)
  r <- rnorm(N, 0, 0.1) + 0.03 * sin((1:N) / 40); c0 <- 90 + cumsum(r); b <- data.frame(time = tm, open = c(90, c0[-N]), close = c0)
  b$high <- pmax(b$open, b$close) + abs(rnorm(N, 0, 0.05)); b$low <- pmin(b$open, b$close) - abs(rnorm(N, 0, 0.05)); b }
store <- cc_make_store(cc_mem_backend())
t0 <- as.POSIXct("2026-10-01 00:00", tz = "UTC") + 1500 * 900
store$write("trades", data.frame(trade_id = paste0("T", 1:4), epic = "OIL_BRENT", status = "CLOSED", direction = c("BUY", "SELL", "BUY", "BUY"), entry_ts = t0 + c(0, 1, 8, 9) * 86400, exit_ts = t0 + c(0, 1, 8, 9) * 86400 + 7200,
  order_level = c(89.98, 90.02, 89.98, 89.98), entry_level = 90, exit_level = c(91, 90.5, 89.5, 90.75), exit_code = c("X", "SL", "SL", "T"), stop_initial = c(89.5, 90.5, 89.5, 89.5), target_level = c(90.75, 89.25, 90.75, 90.75), stringsAsFactors = FALSE))
client <- list(connected = function() TRUE, market = function(e) stop("no market in the stand-in"))
shinyApp(fluidPage(ml_lab_ui("ml"), tags$hr(), ml_risk_ui("ml")), function(input, output, session) ml_lab_server("ml", client, store, fetch_bars = fake_bars))
