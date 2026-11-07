# R/utils_ig.R
# IGSessionManager R6 Class - Manages IG REST API authentication/session state
# New addition (not present in the reference architecture, which has no broker
# integration) — mirrors the same R6 + reactiveVal trigger pattern used by
# DataManager (R/utils_data.R) for consistency with the rest of the app.
# Wraps the igfetchr CRAN package, which implements IG's CST / X-SECURITY-TOKEN
# session flow. install.packages("igfetchr") if not already installed.
# ======================================================================

library(R6)
library(igfetchr)

IGSessionManager <- R6::R6Class(
  "IGSessionManager",
  
  public = list(
    auth       = NULL,   # list returned by igfetchr::ig_auth() — cst, security, base_url, api_key, acc_number
    login_time = NULL,
    env        = "DEMO",
    
    # Reactive trigger so modules can observe() login/logout state changes
    state_trigger = NULL,
    
    initialize = function() {
      self$state_trigger <- shiny::reactiveVal(0)
    },
    
    trigger_state_update = function() {
      current <- self$state_trigger()
      self$state_trigger(current + 1)
    },
    
    is_logged_in = function() {
      !is.null(self$auth)
    },
    
    login = function(username, password, api_key, env = "DEMO", acc_number = NULL) {
      tryCatch({
        auth <- igfetchr::ig_auth(
          username   = username,
          password   = password,
          api_key    = api_key,
          acc_type   = env,
          acc_number = if (!is.null(acc_number) && nzchar(trimws(acc_number))) trimws(acc_number) else NULL
        )
        self$auth       <- auth
        self$env         <- env
        self$login_time <- Sys.time()
        self$trigger_state_update()
        shiny::showNotification("IG login successful.", type = "message", duration = 4)
        invisible(TRUE)
      }, error = function(e) {
        shiny::showNotification(paste("IG login failed:", conditionMessage(e)), type = "error", duration = 8)
        invisible(FALSE)
      })
    },
    
    logout = function() {
      if (is.null(self$auth)) return(invisible(FALSE))
      tryCatch(igfetchr::ig_close_session(self$auth), error = function(e) NULL)
      self$auth       <- NULL
      self$login_time <- NULL
      self$trigger_state_update()
      shiny::showNotification("Logged out of IG.", type = "message", duration = 3)
      invisible(TRUE)
    },
    
    get_accounts = function() {
      if (!self$is_logged_in()) return(NULL)
      tryCatch({
        igfetchr::ig_get_accounts(self$auth)
      }, error = function(e) {
        shiny::showNotification(paste("Could not fetch accounts:", conditionMessage(e)), type = "error", duration = 8)
        NULL
      })
    },
    
    search_markets = function(search_term) {
      if (!self$is_logged_in() || is.null(search_term) || search_term == "") return(NULL)
      tryCatch({
        igfetchr::ig_search_markets(search_term = search_term, auth = self$auth)
      }, error = function(e) {
        shiny::showNotification(paste("IG market search failed:", conditionMessage(e)), type = "error", duration = 8)
        NULL
      })
    }
  )
)

cat("\u2713 IG session utilities loaded\n")
