# R/utils_study_manager.R — AI Agents in Action Study Suite

library(R6)

StudyManager <- R6Class(
  "StudyManager",

  public = list(
    tab_progress  = list(),
    quiz_scores   = list(),
    notes         = list(),
    bookmarks     = list(),
    progress_trigger = NULL,
    score_trigger    = NULL,

    initialize = function() {
      self$progress_trigger <- reactiveVal(0)
      self$score_trigger    <- reactiveVal(0)

      tabs <- c("overview", "llm_foundations", "local_agents", "autogen_crewai",
                "semantic_kernel", "behavior_trees", "chat_uis", "memory_rag",
                "prompt_flow", "prompting_techniques", "assistants_api",
                "deprecations", "quiz")

      for (t in tabs) {
        self$tab_progress[[t]] <- 0
        self$quiz_scores[[t]]  <- list()
        self$notes[[t]]        <- ""
        self$bookmarks[[t]]    <- FALSE
      }
      cat("StudyManager initialized\n")
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

    add_quiz_score = function(tab, score, total, label = "") {
      entry <- list(score = score, total = total, pct = round(100 * score / total),
                    label = label, timestamp = Sys.time())
      if (is.null(self$quiz_scores[[tab]])) self$quiz_scores[[tab]] <- list()
      n <- length(self$quiz_scores[[tab]])
      self$quiz_scores[[tab]][[n + 1]] <- entry
      self$trigger_score()
      pct <- round(100 * score / total)
      self$update_progress(tab, min(100, self$get_progress(tab) + pct %/% 2))
    },

    get_quiz_scores = function(tab) {
      self$quiz_scores[[tab]] %||% list()
    },

    save_note = function(tab, text) {
      self$notes[[tab]] <- text
    },

    get_note = function(tab) {
      self$notes[[tab]] %||% ""
    },

    toggle_bookmark = function(tab) {
      self$bookmarks[[tab]] <- !isTRUE(self$bookmarks[[tab]])
    },

    get_bookmarked = function() {
      names(Filter(isTRUE, self$bookmarks))
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
