# worker/deploy_worker.R  —  ShinyDeployMaster v2
# ─────────────────────────────────────────────────────────────────────────────
# Runs in its own Rscript process (launched by modules/deploy/deploy_app.R).
# Usage:  Rscript deploy_worker.R <config.json>
# Credentials arrive ONLY via env vars RSDEPLOY_TOKEN / RSDEPLOY_SECRET.
#
# WHY THIS EXISTS
# rsconnect builds manifest.json by snapshotting the packages INSTALLED in
# the deploying R session. Anything the app uses that isn't installed is
# silently dropped, so shinyapps.io never installs it and the app dies with
# "there is no package called ...". RStudio works because your laptop has
# every package. This worker reproduces that condition for ANY app:
#   1. detect the app's packages with renv::dependencies() (same scanner
#      rsconnect uses),
#   2. resolve the full Depends/Imports/LinkingTo tree from CRAN metadata,
#   3. install whatever is missing/outdated into a private cache library
#      (Posit Package Manager Linux binaries = fast, no compiling),
#   4. call rsconnect::deployApp() so the manifest lists everything,
#   5. hit the deployed URL and read the server log to prove it STARTED.
# Nothing about any specific app is hard-coded here.
#
# Exit codes: 0 = deployed and started, 1 = failed before upload,
#             2 = deployApp() failed, 3 = deployed but failed to start.
# ─────────────────────────────────────────────────────────────────────────────

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x))) y else x

say  <- function(...) { cat(..., "\n", sep = ""); flush(stdout()) }
step <- function(n, msg) say(">>> [", n, "/6] ", msg)
ok   <- function(...) say("[OK] ", ...)
warn <- function(...) say("[WARN] ", ...)
info <- function(...) say("       ", ...)
die  <- function(msg, status = 1L) { say("[FAIL] ", msg); quit(save = "no", status = status) }

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1 || !file.exists(args[1])) die("No config file passed to worker.")
cfg <- jsonlite::fromJSON(args[1])

app_dir          <- normalizePath(cfg$app_dir, mustWork = FALSE)
app_name         <- cfg$app_name
account          <- cfg$account %||% ""
server           <- cfg$server %||% "shinyapps.io"
force_update     <- isTRUE(cfg$force_update %||% TRUE)
allow_unresolved <- isTRUE(cfg$allow_unresolved %||% FALSE)
dry_run          <- isTRUE(cfg$dry_run %||% FALSE)
lib_dir          <- cfg$lib_dir
manifest_repo    <- cfg$manifest_repo %||% "https://cloud.r-project.org"

if (!dir.exists(app_dir)) die(paste("App directory not found:", app_dir))

# ═════════════════════════════════════════════════════════════════════════════
step(1, "Preparing environment")
# ═════════════════════════════════════════════════════════════════════════════
dir.create(lib_dir, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib_dir, .libPaths()))
Sys.setenv(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep))
info("R ", as.character(getRversion()), " | rsconnect ", as.character(packageVersion("rsconnect")),
     " | renv ", as.character(packageVersion("renv")))
info("Cache library: ", lib_dir)

# Posit Package Manager serves pre-built Linux binaries when the URL names the
# distro and the user agent names the R version. Falls back to CRAN source.
detect_install_repo <- function() {
  if (nzchar(cfg$install_repo %||% "")) return(cfg$install_repo)
  if (.Platform$OS.type != "unix" || !file.exists("/etc/os-release")) return(manifest_repo)
  os <- readLines("/etc/os-release", warn = FALSE)
  cn <- sub('^VERSION_CODENAME="?([^"]*)"?$', "\\1", grep("^VERSION_CODENAME=", os, value = TRUE))
  if (length(cn) != 1 || !nzchar(cn)) return(manifest_repo)
  sprintf("https://packagemanager.posit.co/cran/__linux__/%s/latest", cn)
}
options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(),
        paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))
install_repo <- detect_install_repo()
info("Install repo : ", install_repo)
info("Manifest repo: ", manifest_repo)

# A bundled .Rprofile that activates renv breaks startup on shinyapps.io
# (renv/ is stripped from the bundle). Neutralise it in this temp copy.
rp <- file.path(app_dir, ".Rprofile")
if (file.exists(rp)) {
  l <- readLines(rp, warn = FALSE)
  hit <- grepl("renv/activate.R", l, fixed = TRUE)
  if (any(hit)) {
    l[hit] <- paste("#", l[hit], " # disabled by ShinyDeployMaster")
    writeLines(l, rp)
    warn(".Rprofile renv activation disabled in the uploaded copy")
  }
}
ok("Environment ready")

# ═════════════════════════════════════════════════════════════════════════════
step(2, "Detecting the app's R packages (renv::dependencies - same scanner rsconnect uses)")
# ═════════════════════════════════════════════════════════════════════════════
deps <- tryCatch(
  renv::dependencies(app_dir, root = app_dir, progress = FALSE, quiet = TRUE),
  error = function(e) die(paste("Dependency scan failed:", conditionMessage(e)))
)
base_pkgs <- c(rownames(installed.packages(priority = "base")), "R")
direct    <- sort(setdiff(unique(deps$Package), base_pkgs))
if (!length(direct)) warn("No package references found in the app code")
ok(length(direct), " direct packages: ", paste(direct, collapse = ", "))

# Packages loaded by name at runtime (library(x, character.only = TRUE)) are
# invisible to every scanner, RStudio included. Flag it so it isn't a mystery.
r_files <- list.files(app_dir, pattern = "[.][Rr]$", recursive = TRUE, full.names = TRUE)
dyn <- r_files[vapply(r_files, function(f)
  any(grepl("character.only\\s*=\\s*TRUE", readLines(f, warn = FALSE))), logical(1))]
if (length(dyn)) {
  warn("Dynamic library(..., character.only = TRUE) found in: ",
       paste(sub(paste0(app_dir, "/"), "", dyn, fixed = TRUE), collapse = ", "))
  info("Any package loaded that way must ALSO appear as a literal library(pkg) or pkg:: call.")
}

# ═════════════════════════════════════════════════════════════════════════════
step(3, "Resolving the full dependency tree from the repository index")
# ═════════════════════════════════════════════════════════════════════════════
avail <- tryCatch(available.packages(repos = install_repo), error = function(e) NULL)
if (is.null(avail) || !nrow(avail)) {
  warn("Could not read ", install_repo, " - falling back to ", manifest_repo)
  install_repo <- manifest_repo
  avail <- tryCatch(available.packages(repos = install_repo), error = function(e) NULL)
}
if (is.null(avail) || !nrow(avail)) die("Cannot reach any package repository from this server.")

on_repo  <- intersect(direct, rownames(avail))
tree     <- tools::package_dependencies(on_repo, db = avail, recursive = TRUE,
                                        which = c("Depends", "Imports", "LinkingTo"))
all_pkgs <- sort(setdiff(unique(c(direct, unlist(tree, use.names = FALSE))), base_pkgs))

# Highest minimum version any package in the tree demands of each dependency
min_ver <- list()
for (p in intersect(all_pkgs, rownames(avail))) {
  for (fld in c("Depends", "Imports", "LinkingTo")) {
    x <- avail[p, fld]
    if (is.na(x)) next
    for (part in trimws(strsplit(x, ",")[[1]])) {
      m <- regmatches(part, regexec("^([A-Za-z][A-Za-z0-9.]*)\\s*\\(\\s*>=?\\s*([0-9][0-9.-]*)\\s*\\)", part))[[1]]
      if (length(m) == 3) {
        cur <- min_ver[[m[2]]]
        if (is.null(cur) || package_version(m[3]) > package_version(cur)) min_ver[[m[2]]] <- m[3]
      }
    }
  }
}

installed_version <- function(p) {
  d <- system.file("DESCRIPTION", package = p, lib.loc = .libPaths())
  if (!nzchar(d)) return(NA_character_)
  unname(read.dcf(d, fields = "Version")[1, 1])
}
status <- vapply(all_pkgs, function(p) {
  v <- installed_version(p)
  if (is.na(v)) return("missing")
  mv <- min_ver[[p]]
  if (!is.null(mv) && package_version(v) < package_version(mv)) return("outdated")
  "ok"
}, character(1))

need       <- names(status)[status != "ok"]
unresolved <- setdiff(need, rownames(avail))
to_install <- intersect(need, rownames(avail))

ok(length(all_pkgs), " packages in the full tree (", length(direct), " direct + ",
   length(all_pkgs) - length(direct), " transitive)")
info(sum(status == "ok"), " already installed, ", sum(status == "missing"), " missing, ",
     sum(status == "outdated"), " outdated")
if (length(unresolved)) {
  msg <- paste0("Not found on the repository (GitHub/Bioconductor/private/typo?): ",
                paste(unresolved, collapse = ", "))
  if (!allow_unresolved) die(paste(msg, "- the app would crash on startup. Fix the code or tick 'Deploy anyway'."))
  warn(msg)
}

# ═════════════════════════════════════════════════════════════════════════════
step(4, "Installing missing packages into the cache library")
# ═════════════════════════════════════════════════════════════════════════════
# --no-test-load: rsconnect only needs each package's DESCRIPTION to write the
# manifest. Binaries may need system libraries this server lacks, but
# shinyapps.io installs those itself ("Installing system dependencies").
do_install <- function(pkgs, repo, quiet) {
  if (!length(pkgs)) return(invisible())
  tryCatch(
    withCallingHandlers(
      utils::install.packages(pkgs, lib = lib_dir, repos = repo, dependencies = NA,
                              INSTALL_opts = "--no-test-load", quiet = quiet,
                              Ncpus = max(1L, min(4L, parallel::detectCores(), na.rm = TRUE))),
      warning = function(w) { warn("install.packages: ", conditionMessage(w)); invokeRestart("muffleWarning") }
    ),
    error = function(e) warn("install.packages: ", conditionMessage(e))
  )
}
still_needed <- function(pkgs) pkgs[vapply(pkgs, function(p) {
  v <- installed_version(p)
  is.na(v) || (!is.null(min_ver[[p]]) && package_version(v) < package_version(min_ver[[p]]))
}, logical(1))]

if (!length(to_install)) {
  ok("Nothing to install - every package is already available")
} else {
  info("Installing ", length(to_install), ": ", paste(to_install, collapse = ", "))
  t0 <- Sys.time()
  do_install(to_install, install_repo, quiet = TRUE)
  left <- still_needed(to_install)
  if (length(left) && !identical(install_repo, manifest_repo)) {
    warn("Retrying from ", manifest_repo, " (source build): ", paste(left, collapse = ", "))
    do_install(left, manifest_repo, quiet = FALSE)
    left <- still_needed(left)
  }
  if (length(left)) die(paste("Could not install:", paste(left, collapse = ", ")))
  ok(length(to_install), " packages installed in ", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "s")
}

# Final gate: every package in the tree must be visible, or the manifest will be short.
final_missing <- setdiff(all_pkgs[is.na(vapply(all_pkgs, installed_version, character(1)))], unresolved)
if (length(final_missing)) die(paste("Still missing after install:", paste(final_missing, collapse = ", ")))
ok("All ", length(all_pkgs) - length(unresolved), " packages visible to rsconnect - manifest will be complete")

# ═════════════════════════════════════════════════════════════════════════════
step(5, if (dry_run) "DRY RUN: building manifest.json only (no upload)" else paste("Deploying to", server))
# ═════════════════════════════════════════════════════════════════════════════
options(repos = c(CRAN = manifest_repo))   # manifest points shinyapps.io at CRAN

if (dry_run) {
  wm_args <- list(appDir = app_dir)
  if ("dependencyResolution" %in% names(formals(rsconnect::writeManifest)))
    wm_args$dependencyResolution <- "library"          # same resolution as the real deploy
  res <- tryCatch(do.call(rsconnect::writeManifest, wm_args), error = function(e) e)
  if (inherits(res, "error")) die(paste("writeManifest failed:", conditionMessage(res)), 2L)
  mf <- jsonlite::fromJSON(file.path(app_dir, "manifest.json"))
  ok("manifest.json lists ", length(mf$packages), " packages")
  miss <- setdiff(direct, names(mf$packages))
  if (length(miss)) die(paste("Manifest is missing:", paste(miss, collapse = ", ")), 2L)
  ok("Every direct package is in the manifest")
  file.remove(file.path(app_dir, "manifest.json"))
  quit(save = "no", status = 0L)
}

token  <- Sys.getenv("RSDEPLOY_TOKEN")
secret <- Sys.getenv("RSDEPLOY_SECRET")
if (!nzchar(token) || !nzchar(secret)) die("Credentials not received by worker.")
tryCatch(
  rsconnect::setAccountInfo(name = account, token = token, secret = secret, server = server),
  error = function(e) die(paste("shinyapps.io rejected the credentials:", conditionMessage(e)))
)
ok("Authenticated as ", account)

deploy_args <- list(appDir = app_dir, appName = app_name, account = account, server = server,
                    forceUpdate = force_update, launch.browser = FALSE)
if ("dependencyResolution" %in% names(formals(rsconnect::deployApp))) {
  deploy_args$dependencyResolution <- "library"   # ignore any stale renv.lock in the zip
} else if (file.exists(file.path(app_dir, "renv.lock"))) {
  file.rename(file.path(app_dir, "renv.lock"), file.path(app_dir, "renv.lock.ignored"))
  warn("renv.lock in the upload was set aside (this rsconnect would require it to match exactly)")
}

res <- tryCatch(do.call(rsconnect::deployApp, deploy_args), error = function(e) e)
if (inherits(res, "error")) die(paste("deployApp failed:", conditionMessage(res)), 2L)
if (identical(res, FALSE)) die("deployApp reported failure", 2L)
ok("Upload and server build finished")

# ═════════════════════════════════════════════════════════════════════════════
step(6, "Verifying the app actually starts")
# ═════════════════════════════════════════════════════════════════════════════
url <- tryCatch({
  d <- rsconnect::deployments(app_dir)
  d <- d[d$name == app_name, , drop = FALSE]
  if (nrow(d)) d$url[nrow(d)] else NA_character_
}, error = function(e) NA_character_)
if (is.na(url) || !nzchar(url)) url <- sprintf("https://%s.shinyapps.io/%s/", account, app_name)
say("[URL] ", url)

code <- NA_integer_
for (i in 1:3) {                       # first request wakes the instance
  code <- tryCatch(curl::curl_fetch_memory(url, handle = curl::new_handle(timeout = 90))$status_code,
                   error = function(e) NA_integer_)
  if (!is.na(code) && code < 500) break
  Sys.sleep(10)
}
info("HTTP status: ", code)
Sys.sleep(5)

logs <- tryCatch(
  utils::capture.output(rsconnect::showLogs(appPath = app_dir, appName = app_name, account = account,
                                            server = server, entries = 150)),
  error = function(e) character(0)
)
bad <- grep("there is no package called|Error in |Execution halted|could not find function|failed to start",
            logs, value = TRUE, ignore.case = TRUE)
if (length(logs)) {
  say("------ last server log lines ------")
  for (l in tail(logs, 25)) say("  ", l)
  say("-----------------------------------")
}
if (length(bad) || (!is.na(code) && code >= 500)) {
  for (b in head(unique(bad), 10)) say("[FAIL] ", b)
  die("Deployed, but the app failed to start - see the log lines above.", 3L)
}
ok("App is up: ", url)
quit(save = "no", status = 0L)
