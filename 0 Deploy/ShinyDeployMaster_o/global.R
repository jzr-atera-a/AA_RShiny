# global.R — Shiny Deploy Master
# ─────────────────────────────────────────────────────────────

cat("\n╔══════════════════════════════════════════════════════════╗\n")
cat("║  SHINY DEPLOY MASTER — v2.0 — LOADING                  ║\n")
cat("║  APIs (BigQuery · Claude · Auth · Debug) · Deploy       ║\n")
cat("╚══════════════════════════════════════════════════════════╝\n\n")

suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(DT)
  library(jsonlite)
  library(httr)
  library(bigrquery)
  library(curl)
  library(processx)
  library(rsconnect)
})

`%||%` <- function(x, y) if (is.null(x)) y else x

# ── Deploy settings (v2) ─────────────────────────────────────
# Zip uploads up to 200 MB (Shiny's default is only 5 MB)
options(shiny.maxRequestSize = 200 * 1024^2)
# Standalone worker that performs every deployment in its own R process
SDM_WORKER  <- normalizePath("worker/deploy_worker.R", mustWork = FALSE)
# Shared cache library for packages installed on demand for deployments.
# Lives outside tempdir() so it survives across sessions on this instance.
SDM_LIB_DIR <- file.path(dirname(tempdir()), "sdm_deploy_lib", paste0("R-", getRversion()))

source("R/utils_academic.R",        local = .GlobalEnv)
source("R/utils_api_manager.R",     local = .GlobalEnv)
source("R/utils_deploy_manager.R",  local = .GlobalEnv)

# api_manager is session-independent (just holds credentials/state)
api_manager <- ApiManager$new()

cat("✓ Global configuration complete\n\n")
