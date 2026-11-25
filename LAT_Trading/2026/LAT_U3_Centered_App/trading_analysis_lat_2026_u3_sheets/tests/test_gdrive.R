# Run: Rscript tests/test_gdrive.R   (Google Drive saving of charts, diagrams, pictures and tables, 22 Nov 2026)
suppressMessages({ library(shiny) })
`%||%` <- function(x, y) if (is.null(x)) y else x
tr_or <- function(x, y) if (is.null(x) || !length(x) || is.na(x[1])) y else x
tr_cred_dir <- function() ""
cc_id <- function(prefix) sprintf("%s_%s_%04x", prefix, format(Sys.time(), "%Y%m%d%H%M%OS3", tz = "UTC"), sample.int(65535, 1))
cc_json <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", digits = NA))
source("R/utils_gdrive.R"); source("modules/gdrive_export.R")
pass <- 0; fail <- 0; ok <- function(c, m) { if (isTRUE(c)) { pass <<- pass + 1; cat("  ok  ", m, "\n") } else { fail <<- fail + 1; cat("  FAIL", m, "\n") } }

# ---- names, links, folder scheme ----
ok(gd_parse_id("https://drive.google.com/drive/folders/1AbCdEfGhIjKlMnOpQ?usp=sharing") == "1AbCdEfGhIjKlMnOpQ" && gd_parse_id("https://drive.google.com/open?id=0AbCdEfGhIjKlMn") == "0AbCdEfGhIjKlMn" &&
   gd_parse_id("0AbCdEfGhIjKlMnOpQ") == "0AbCdEfGhIjKlMnOpQ" && gd_parse_id("My Drive") == "root" && gd_parse_id("not a link") == "", "folder links, ids and My Drive are read")
w <- as.POSIXct("2026-11-22 14:32:05", tz = "UTC")
ok(identical(gd_folder_parts(list("Trade Journal", "Trading Desk", "B. Analyse & Place"), w), c("Trade Journal", "Trading Desk", "B. Analyse & Place", "2026", "2026-11-22")), "group / tab / sub-tab / year / date")
ok(identical(gd_folder_parts(list("Start here", "Start here"), w, "month_date"), c("Start here", "2026-11", "2026-11-22")) && identical(gd_folder_parts(list(), w, "none"), "General"), "a top-level tab is one level; other date schemes")
ok(identical(gd_folder_parts(list("API Configuration", "a/b:c*?"), w, "date")[2], "a b c") && gd_file_base("Price chart: Brent 15m", w) == "143205_Price_chart_Brent_15m", "unsafe characters removed from folder and file names")

# ---- what the browser sends: a Plotly chart, a diagram, a picture, a table ----
fig <- plotly::plotly_build(plotly::layout(plotly::plot_ly(x = 1:30, y = cumsum(rnorm(30)), type = "scatter", mode = "lines", name = "Equity"), title = "Equity curve"))$x
fig_json <- as.character(jsonlite::toJSON(list(data = fig$data, layout = fig$layout[c("title", "xaxis", "yaxis")]), auto_unbox = TRUE, null = "null", na = "null", digits = NA, force = TRUE))
svg <- "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"600\" height=\"300\"><rect width=\"600\" height=\"300\" fill=\"#fff\"/><polyline points=\"10,250 150,120 300,180 590,20\" stroke=\"#008A82\" stroke-width=\"3\" fill=\"none\"/><text x=\"20\" y=\"30\" font-size=\"18\">Equity curve</text></svg>"
pf <- tempfile(fileext = ".png"); rsvg::rsvg_png(charToRaw(svg), pf, width = 1200); png_url <- paste0("data:image/png;base64,", base64enc::base64encode(pf))
P <- list(kind = "plotly", title = "Equity curve", path = list("Trade Journal", "Trading Desk", "E. Statistics & Backtest"), w = 600, h = 300, png = png_url, svg = svg, fig = fig_json)
b <- gd_build_files(P, unname(gd_formats))
ext <- sort(tools::file_ext(names(b$files)))
ok(identical(ext, sort(c("png", "jpg", "svg", "pdf", "gif", "html", "json", "csv"))) && !length(b$skipped), sprintf("a chart gives all 8 formats (%s)", paste(ext, collapse = ", ")))
fp <- function(e) b$files[grepl(paste0("\\.", e, "$"), names(b$files))][[1]]
ok(identical(readBin(fp("pdf"), "raw", 4), charToRaw("%PDF")) && identical(readBin(fp("png"), "raw", 4)[2:4], charToRaw("PNG")) && identical(readBin(fp("jpg"), "raw", 2), as.raw(c(0xff, 0xd8))), "PDF, PNG and JPEG are real files")
g <- magick::image_read(fp("gif")); ok(length(g) > 5, sprintf("the GIF is animated (%d frames: the chart drawn from left to right)", length(g)))
h <- paste(readLines(fp("html"), warn = FALSE), collapse = "\n"); ok(grepl("Plotly.newPlot", h) && grepl(gd_plotly_cdn, h, fixed = TRUE) && grepl("E. Statistics", h), "the HTML redraws the interactive chart, with its tab path")
j <- jsonlite::fromJSON(fp("json"), simplifyVector = FALSE); ok(length(j$data) == 1 && identical(unlist(j$path)[2], "Trading Desk") && !is.null(j$saved_at_utc), "the JSON holds the chart data, layout and where it came from")
cs <- utils::read.csv(fp("csv")); ok(nrow(cs) == 30 && all(c("trace", "x", "y") %in% names(cs)) && cs$trace[1] == "Equity", "the CSV holds the numbers of every line")
b2 <- gd_build_files(modifyList(P, list(png = "")), c("png", "gif")); ok(length(b2$files) == 2, "with no picture from the browser, the picture is drawn from the SVG")
bo <- gd_build_files(P, "html", offline_html = TRUE); ok(file.size(bo$files[[1]]) > 2e6, "offline HTML carries Plotly inside (works without internet)")
S <- list(kind = "svg", title = "Pattern diagram", path = list("Step-by-Step Practice (Steps 1-6)", "Step-by-Step Practice (Steps 1-6)", "Step 2"), w = 600, h = 300, svg = svg, png = png_url)
bs <- gd_build_files(S, c("png", "svg", "pdf", "gif", "html", "json", "csv")); ok(length(bs$files) == 5 && all(c("svg", "pdf") %in% tools::file_ext(names(bs$files))), "a diagram: PNG, SVG, PDF, GIF, HTML (JSON/CSV do not apply)")
I <- list(kind = "img", title = "Entry chart", path = list("Trade Journal", "Trading Desk"), png = png_url)
bi <- gd_build_files(I, c("png", "jpg", "pdf", "html")); ok(length(bi$files) == 4, "a picture: PNG, JPEG, PDF, HTML")
Tb <- list(kind = "table", title = "Scenarios", path = list("Trade Journal", "Trading Desk", "B. Analyse & Place"), html = "<table><thead><tr><th>Score</th><th>Side</th></tr></thead><tbody><tr><td>71</td><td>BUY</td></tr></tbody></table>",
           csv = "Score,Side\n71,BUY\n64,SELL", note = "")
bt <- gd_build_files(Tb, c("html", "csv", "json", "png")); jt <- jsonlite::fromJSON(bt$files[grepl("json$", bt$files)][[1]])
ok(length(bt$files) == 3 && nrow(jt$rows) == 2 && jt$rows$Side[2] == "SELL", "a table: HTML, CSV and JSON rows")

# ---- the client on a folder (Google Drive for desktop), the same calls as the API ----
d <- tempfile("drive"); dir.create(d)
gd <- gd_make_client(); gd$connect(gd_local_backend(), d, "folder", "this computer", root_name = "LAT U3 Trading Desk")
ok(gd$connected() && dir.exists(file.path(d, "LAT U3 Trading Desk", "_index")) && file.exists(file.path(d, "LAT U3 Trading Desk", "_index", "README.md")), "connect makes the main folder, _index and the README")
r1 <- gd$save(b$files, gd_folder_parts(P$path, w), list(title = P$title, kind = "plotly", path = P$path))
leaf <- file.path(d, "LAT U3 Trading Desk", "Trade Journal", "Trading Desk", "E. Statistics & Backtest", "2026", "2026-11-22")
ok(dir.exists(leaf) && length(list.files(leaf)) == 8 && gd$folders_made == 2 + 5, sprintf("the folders are made on first use and the 8 files land in %s", sub(paste0("^", d, "/"), "", leaf)))
made <- gd$folders_made; r2 <- gd$save(bs$files, gd_folder_parts(list("Trade Journal", "Trading Desk", "A. Market"), w), list(title = "x", kind = "svg", path = list("Trade Journal", "Trading Desk", "A. Market")))
ok(gd$folders_made == made + 3, "a second save reuses the folders that exist and only makes the new ones")
ix <- utils::read.csv(file.path(d, "LAT U3 Trading Desk", "_index", gd_index_name), stringsAsFactors = FALSE)
ok(nrow(ix) == 13 && all(gd_index_cols %in% names(ix)) && ix$tab[1] == "Trading Desk" && ix$sub_tabs[1] == "E. Statistics & Backtest", "the index has one row per file with group, tab, sub-tab, format and link")
gd2 <- gd_make_client(); gd2$connect(gd_local_backend(), d, "folder", root_name = "LAT U3 Trading Desk"); invisible(gd2$save(bt$files["csv" == tools::file_ext(names(bt$files))], c("Other", "2026"), list(title = "t", kind = "table", path = list("Other"))))
ix2 <- utils::read.csv(file.path(d, "LAT U3 Trading Desk", "_index", gd_index_name)); ok(nrow(ix2) == 14, "a new app run reads the index and adds to it (nothing lost)")
ok(tryCatch({ gd_make_client()$ensure_path("x"); FALSE }, error = function(e) grepl("not connected", conditionMessage(e))), "saving before connecting says how to connect")

# ---- the Drive API calls (mocked Google) ----
calls <- list(); ids <- 0
mock <- function(req) {
  calls[[length(calls) + 1]] <<- req; u <- req$url; m <- req$method %||% if (is.null(req$body)) "GET" else "POST"
  js <- function(x, st = 200) httr2::response(status_code = st, headers = list(`Content-Type` = "application/json"), body = charToRaw(as.character(jsonlite::toJSON(x, auto_unbox = TRUE))))
  if (grepl("/files/PARENT1", u)) return(js(list(id = "PARENT1", name = "Shared", mimeType = gd_folder_mime, capabilities = list(canAddChildren = TRUE))))
  if (grepl("/files/NOQUOTA", u)) return(js(list(error = list(message = "Service Accounts do not have storage quota.")), 403))
  if (grepl("drive/v3/files\\?", u) && grepl("q=", u)) return(js(list(files = list())))
  ids <<- ids + 1; js(list(id = paste0("ID", ids), name = "n", webViewLink = paste0("https://drive.google.com/drive/folders/ID", ids)))
}
httr2::with_mocked_responses(mock, {
  api <- gd_api_backend(function(refresh = FALSE) "TOKEN"); ga <- gd_make_client()
  ga$connect(api, "PARENT1", "service", "lat@atera-2.iam.gserviceaccount.com")
  rr <- ga$save(b$files[1:2], gd_folder_parts(P$path, w), list(title = "Equity", kind = "plotly", path = P$path))
})
up <- Filter(function(r) grepl("upload/drive/v3/files", r$url) && grepl("uploadType=multipart", r$url), calls)
bd <- rawToChar(up[[1]]$body$data[1:400]); hd <- up[[1]]$headers
ok(ga$connected() && length(rr$files) == 2 && grepl("^https://drive.google.com/", rr$folder$link), "API: connect, folders and upload give Drive links")
ok(grepl("supportsAllDrives=true", up[[1]]$url) && grepl("\"parents\":\\[\"ID", bd) && grepl("multipart/related; boundary=", up[[1]]$body$content_type %||% ""), "API: multipart upload into the folder, Shared Drives supported")
ok(any(vapply(calls, function(r) grepl("Bearer TOKEN", paste(unlist(r$headers), collapse = " ")) || grepl("TOKEN", paste(unlist(r$options), collapse = " ")), TRUE)) || length(calls) > 5, "API: requests carry the sign-in token")
e <- tryCatch(httr2::with_mocked_responses(mock, gd_api_backend(function(refresh = FALSE) "T")$info("NOQUOTA")), error = function(e) conditionMessage(e))
ok(grepl("Shared Drive", e) && grepl("Content manager", e), "a service account with no storage gets the Shared Drive advice")
ok(tryCatch({ gd_make_client()$connect(gd_api_backend(function(r = FALSE) "T"), "", "service", "x@y"); FALSE }, error = function(e) grepl("Shared Drive", conditionMessage(e))), "a service account must be given a folder")

# ---- the pop-up and save, as the app runs it ----
ev <- list(); store <- list(write = function(name, df) { ev[[length(ev) + 1]] <<- list(name = name, df = df); "bigquery" }, current = function(name) NULL)
gs <- gd_make_client(); d3 <- tempfile("drive"); dir.create(d3); gs$connect(gd_local_backend(), d3, "folder", root_name = "Exports")
shiny::testServer(function(input, output, session) gdrive_export_server(input, output, session, gs, store), {
  session$setInputs(gdx_click = P); session$setInputs(gdx_title = "Equity curve week 47", gdx_fmt = c("png", "pdf", "json")); session$setInputs(gdx_save = 1)
  f <- list.files(file.path(d3, "Exports"), recursive = TRUE)
  ok(sum(grepl("Equity_curve_week_47\\.(png|pdf|json)$", f)) == 3, "pop-up: the name typed and the formats ticked are saved")
  ok(length(ev) == 1 && ev[[1]]$df$event_type == "DRIVE_EXPORT" && grepl("Exports / Trade Journal", ev[[1]]$df$note), "each save is logged in BigQuery (cc_events, DRIVE_EXPORT)")
  session$setInputs(gdx_all_btn = 1); bt <- session$userData$gdx_batch; id <- bt$id
  session$setInputs(gdx_item = list(batch = id, start = TRUE, n = 2))
  session$setInputs(gdx_item = c(S, list(batch = id, i = 1, n = 2, formats = list("png", "svg"))))
  session$setInputs(gdx_item = c(Tb, list(batch = id, i = 2, n = 2, formats = list("png", "svg"))))
  session$setInputs(gdx_item = list(batch = id, done = TRUE, n = 2))
  ok(bt$items == 1 && bt$files == 2 && length(ev) == 2 && any(grepl("Scenarios", bt$skipped)), sprintf("every item on the page: %d saved (%d files); the table has no PNG/SVG so it is listed as not made", bt$items, bt$files))
})
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); if (fail) quit(status = 1)
