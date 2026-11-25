# tools/gdrive_check.R - checks R/utils_gdrive.R against a stand-in Drive server.
# Run from the app folder:  python3 tools/fake_drive.py 8899 &   Rscript tools/gdrive_check.R 8899 [path/to/service_account.json]
args <- commandArgs(trailingOnly = TRUE)
port <- args[1]; sa_file <- if (length(args) > 1) args[2] else NA
base <- paste0("http://127.0.0.1:", port)
options(bos.gdrive.api = paste0(base, "/drive/v3"), bos.gdrive.upload = paste0(base, "/upload/drive/v3"),
        bos.gdrive.token = paste0(base, "/token"), bos.gdrive.device = paste0(base, "/device/code"))
source("R/utils_gdrive.R")

pass <- 0; fail <- 0
check <- function(name, ok, detail = NULL) {
  ok <- isTRUE(ok)
  cat(if (ok) "PASS " else "FAIL ", name, if (!ok && !is.null(detail)) paste(" ->", paste(format(detail), collapse = " ")) else "", "\n", sep = "")
  if (ok) pass <<- pass + 1 else fail <<- fail + 1
}
st <- function(g) jsonlite::fromJSON(httr::content(httr::GET(paste0(base, "/_state"), httr::add_headers(Authorization = paste("Bearer", g$token()))), "text", encoding = "UTF-8"), simplifyVector = FALSE)
named <- function(s, n) Filter(function(f) identical(f$name, n), s$files)
control <- function(...) invisible(httr::POST(paste0(base, "/_control"), body = jsonlite::toJSON(list(...), auto_unbox = TRUE), httr::content_type_json()))

# ---- helpers
check("folder id from link", gd_folder_id("https://drive.google.com/drive/u/0/folders/1AbC_def-GHIJKLmnop?usp=sharing") == "1AbC_def-GHIJKLmnop")
check("folder id from ?id=", gd_folder_id("https://drive.google.com/open?id=1AbCdefGHIJKLmn") == "1AbCdefGHIJKLmn")
check("garbage rejected", gd_folder_id("my folder/please") == "")
check("safe names", gd_safe_name('AV/Dev: "Route*Map"?') == "AV Dev Route Map")
check("slug", gd_slug("Route Map (London -> Leeds)") == "route_map_london_leeds")
at <- as.POSIXct("2026-11-22 09:05:07")
p <- gd_placement("Audio Transcription", "Audio Transcription", "Analytics", "analytics", "Word Count Distribution", at)
s <- gd_settings_default()
check("scheme: app/group/tab/yyyy/yyyy-mm (section = group skipped)", paste(gd_folders(p, s, "html"), collapse = "/") == "BusinessOpsSuite/Audio Transcription/Analytics/2026/2026-11",
      gd_folders(p, s, "html"))
p2 <- gd_placement("Strategy Canvases", "Business Model Canvas", "View Canvas", "bm_canvas_view", "BM Canvas", at)
s2 <- s; s2$by_format <- TRUE
check("scheme: section + format folder", paste(gd_folders(p2, s2, "PDF"), collapse = "/") == "BusinessOpsSuite/Strategy Canvases/Business Model Canvas/View Canvas/2026/2026-11/pdf")
check("file name", gd_file_name(p, "html") == "analytics_word_count_distribution_20261122_090507.html", gd_file_name(p, "html"))
pr <- gd_properties(gd_placement("G", "S", "T", "t", strrep("x", 300), at), "png")
check("appProperties within 124 bytes", all(vapply(names(pr), function(k) nchar(k, "bytes") + nchar(pr[[k]], "bytes") <= 124, TRUE)))
check("csv quoting", gd_csv_line(c("a,b", 'q"x', "plain")) == '"a,b","q""x",plain')

# ---- settings file round trip (keeps other sections)
tmp <- tempfile(fileext = ".json"); writeLines('{"claude_model":"x","google_drive":{"client_id":"old"}}', tmp)
s3 <- gd_load_settings(tmp); s3$client_id <- "cid"; s3$default_formats <- c("gif"); s3$by_date <- FALSE
gd_save_settings(s3, tmp)
back <- gd_load_settings(tmp); raw <- jsonlite::fromJSON(tmp)
check("settings saved: other sections kept", identical(raw$claude_model, "x"))
check("settings round trip", back$client_id == "cid" && identical(back$default_formats, "gif") && identical(back$by_date, FALSE))
s1 <- s3; s1$default_formats <- c("gif", "png"); gd_save_settings(s1, tmp)
check("default_formats stays a list", identical(gd_load_settings(tmp)$default_formats, c("gif", "png")))

# ---- device sign-in
dev <- gd_device_start("cid")
check("device: user code + url", dev$user_code == "ABCD-EFGH" && grepl("google.com/device", dev$verification_url))
states <- character(0); res <- NULL
for (i in 1:5) { r <- gd_device_poll(dev, "cid", "secret"); states <- c(states, r$state); if (r$state == "ok") { res <- r; break } }
check("device: pending, slow_down, ok", identical(states, c("pending", "slow_down", "ok")), states)
check("device: refresh token + email", identical(res$refresh_token, "rt-device") && identical(res$email, "person@example.com"))

# ---- OAuth client
bad <- s; bad$client_id <- "cid"; bad$refresh_token <- "revoked"
e <- tryCatch({ GDrive$new(bad)$token(); NULL }, error = function(e) conditionMessage(e))
check("revoked token -> sign in again", grepl("invalid_grant", e) && grepl("sign in again", e), e)
s$client_id <- "cid"; s$client_secret <- "x"; s$refresh_token <- "rt-good"
g <- GDrive$new(s)
check("about(): user", g$about()$user$emailAddress == "person@example.com")
app_id <- g$app_folder()
S <- st(g)
check("app folder + README created once", length(named(S, "BusinessOpsSuite")) == 1 && length(named(S, GD_README)) == 1)
g2 <- GDrive$new(s)
check("new client reuses app folder (no duplicate)", g2$app_folder() == app_id && length(named(st(g), "BusinessOpsSuite")) == 1)
check("folder caches are per client", !identical(environment(g$save), environment(g2$save)))

# ---- uploads
png <- as.raw(c(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1:40))
f1 <- g$save(p, "html", charToRaw("<html>chart</html>"))
f2 <- g$save(p, "png", png)
S <- st(g)
check("every folder level exists once", all(vapply(c("Audio Transcription", "Analytics", "2026", "2026-11"), function(n) length(named(S, n)) == 1, TRUE)))
month <- named(S, "2026-11")[[1]]
mid <- names(Filter(function(f) identical(f$name, "2026-11"), S$files))
inm <- Filter(function(f) mid %in% unlist(f$parents), S$files)
check("files land in <tab>/2026/2026-11", length(inm) == 2)
h <- Filter(function(f) grepl("\\.html$", f$name), inm)[[1]]
check("multipart: content intact", rawToChar(openssl::base64_decode(h$content)) == "<html>chart</html>")
check("multipart: mime + appProperties", h$mimeType == "text/html" && h$appProperties$bos_tab_id == "analytics" && h$appProperties$bos_format == "html")
pn <- Filter(function(f) grepl("\\.png$", f$name), inm)[[1]]
check("binary bytes intact", identical(openssl::base64_decode(pn$content), png))
check("result has path + link", f1$path == "BusinessOpsSuite/Audio Transcription/Analytics/2026/2026-11" && startsWith(f1$link, "https://"))

# ---- manifest
g$append_manifest(list(gd_manifest_row(p, "html", f1), gd_manifest_row(p, "png", f2, note = 'desk, "A"')))
g$append_manifest(list(gd_manifest_row(p, "png", f2)))
man <- named(st(g), GD_MANIFEST)
lines <- strsplit(rawToChar(openssl::base64_decode(man[[1]]$content)), "\n")[[1]]
check("one manifest, header + 3 rows", length(man) == 1 && length(lines) == 4 && lines[1] == paste(GD_MANIFEST_COLS, collapse = ","), length(lines))
check("manifest quotes cells", endsWith(lines[3], '"desk, ""A"""'), lines[3])

# ---- resumable
g$resumable_above <- 1000
big <- as.raw(rep(0:250, length.out = 5000))
fb <- g$save(p, "tiff", big)
S <- st(g)
check("resumable used, bytes intact", S$resumable_starts == 1 && identical(openssl::base64_decode(S$files[[fb$id]]$content), big))
g$resumable_above <- 5 * 1024^2

# ---- retries / recovery
n0 <- st(g)$tokens_issued
control(expire_next = 1); invisible(g$save(p, "png", png))
check("401 -> one token refresh, retried", st(g)$tokens_issued == n0 + 1)
control(fail_next_upload_500 = 1)
check("503 -> retried", !is.null(g$save(p, "png", png)$id))
S <- st(g); mid <- names(Filter(function(f) identical(f$name, "2026-11"), S$files))
invisible(httr::DELETE(paste0(base, "/drive/v3/files/", mid), httr::add_headers(Authorization = paste("Bearer", g$token()))))
again <- g$save(p, "png", png)
S <- st(g)
check("deleted folder -> recreated, upload ok", length(named(S, "2026-11")) == 1 && !is.null(S$files[[again$id]]))

# ---- shared drive + errors
sd <- s; sd$root_folder <- "https://drive.google.com/drive/folders/sharedFolder01"
gs <- GDrive$new(sd); invisible(gs$save(p, "png", png))
L <- Filter(function(l) identical(l$path, "/drive/v3/files") && identical(l$method, "GET") && grepl("'sharedFolder01' in parents", l$q$q %|g|% ""), st(g)$log)
check("shared drive: corpora=drive + driveId", length(L) > 0 && all(vapply(L, function(l) identical(l$q$corpora, "drive") && identical(l$q$driveId, "drv1"), TRUE)))
pf <- s; pf$root_folder <- "plainfile"
check("file as root refused", grepl("not a folder", tryCatch({ GDrive$new(pf)$resolve_root(); "" }, error = conditionMessage)))
mf <- s; mf$root_folder <- "missingFolderId123"
e <- tryCatch({ GDrive$new(mf)$resolve_root(); "" }, error = conditionMessage)
check("missing root -> 404 with hint", grepl("404", e) && grepl("check the folder id", e), e)
control(quota_error = TRUE)
e <- tryCatch({ g$save(p, "png", png); "" }, error = conditionMessage)
check("storageQuotaExceeded -> Shared Drive hint", grepl("Shared Drive", e), e)
control(quota_error = FALSE)

# ---- service account
if (!is.na(sa_file)) {
  ss <- gd_settings_default(); ss$auth_mode <- "service_account"; ss$impersonate <- "boss@example.com"
  ga <- GDrive$new(ss, sa_path = sa_file)
  t1 <- ga$token(); t2 <- ga$token()
  check("service account: JWT token fetched and cached", identical(t1, t2) && startsWith(t1, "tok"))
}
e <- tryCatch({ GDrive$new(modifyList(gd_settings_default(), list(auth_mode = "service_account"))); "" }, error = conditionMessage)
check("service account without key -> clear message", grepl("No service-account key", e))

cat(sprintf("\n%d passed, %d failed\n", pass, fail))
quit(status = if (fail == 0) 0 else 1)
