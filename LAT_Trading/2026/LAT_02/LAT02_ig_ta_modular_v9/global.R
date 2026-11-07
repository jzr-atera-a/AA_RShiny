# global.R - IG Trading & Technical Analysis Dashboard
# Minimal: constructs the shared R6 managers used across all modules.
# (No dynamic module loader/registry — app.R sources modules/*.R directly and
# wires up the sidebar/tabs/server calls explicitly, matching the simpler
# reference pattern.)

source("R/utils_data.R")
source("R/utils_ig.R")
source("R/utils_synthetic.R")

# Initialize managers. ig_manager is linked onto data_manager so any module can
# reach it via data_manager$ig without every module server needing its own
# extra constructor argument.
data_manager <- DataManager$new()
ig_manager   <- IGSessionManager$new()
data_manager$ig <- ig_manager

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("\u2713 Global configuration complete\n")
