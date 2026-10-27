# global.R — Shiny Deploy Master
# ─────────────────────────────────────────────────────────────

cat("\n╔══════════════════════════════════════════════════════════╗\n")
cat("║  SHINY DEPLOY MASTER — v1.0 — LOADING                  ║\n")
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

source("R/utils_academic.R",        local = .GlobalEnv)
source("R/utils_api_manager.R",     local = .GlobalEnv)
source("R/utils_deploy_manager.R",  local = .GlobalEnv)

# api_manager is session-independent (just holds credentials/state)
api_manager <- ApiManager$new()

cat("✓ Global configuration complete\n\n")
