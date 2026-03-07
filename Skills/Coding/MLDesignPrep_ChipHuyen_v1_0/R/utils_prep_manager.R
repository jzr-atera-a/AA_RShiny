# R/utils_prep_manager.R

library(R6)

PrepManager <- R6Class(
  "PrepManager",

  public = list(
    tab_progress    = list(),
    practice_scores = list(),
    notes           = list(),
    progress_trigger = NULL,
    score_trigger    = NULL,

    initialize = function() {
      self$progress_trigger <- reactiveVal(0)
      self$score_trigger    <- reactiveVal(0)

      tabs <- c("overview","framing","data_engineering","feature_engineering",
                "model_development","evaluation","deployment","monitoring",
                "design_questions","practice")
      for (t in tabs) {
        self$tab_progress[[t]]    <- 0
        self$practice_scores[[t]] <- list()
        self$notes[[t]]           <- ""
      }
      cat("PrepManager initialized\n")
    },

    update_progress = function(tab, pct) {
      self$tab_progress[[tab]] <- min(100, max(0, pct))
      self$trigger_progress()
    },

    get_progress = function(tab) {
      self$tab_progress[[tab]] %||% 0
    },

    get_overall_progress = function() {
      vals <- unlist(self$tab_progress)
      if (length(vals) == 0) return(0)
      round(mean(vals))
    },

    add_practice_score = function(tab, score, label = "") {
      entry <- list(score = score, label = label, timestamp = Sys.time())
      if (is.null(self$practice_scores[[tab]])) self$practice_scores[[tab]] <- list()
      n <- length(self$practice_scores[[tab]])
      self$practice_scores[[tab]][[n + 1]] <- entry
      self$trigger_score()
    },

    get_scores = function(tab) {
      self$practice_scores[[tab]] %||% list()
    },

    save_note = function(tab, text) {
      self$notes[[tab]] <- text
    },

    get_note = function(tab) {
      self$notes[[tab]] %||% ""
    },

    trigger_progress = function() {
      if (!is.null(self$progress_trigger)) {
        current <- isolate(self$progress_trigger())
        self$progress_trigger(current + 1)
      }
    },

    trigger_score = function() {
      if (!is.null(self$score_trigger)) {
        current <- isolate(self$score_trigger())
        self$score_trigger(current + 1)
      }
    }
  )
)
