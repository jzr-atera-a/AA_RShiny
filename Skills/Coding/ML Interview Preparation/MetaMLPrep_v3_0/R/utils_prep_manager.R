# R/utils_prep_manager.R
# Shared Prep Manager - tracks progress, scores, notes across all tabs

library(R6)

PrepManager <- R6Class(
  "PrepManager",
  
  public = list(
    # Progress tracking per tab
    tab_progress    = list(),
    practice_scores = list(),
    notes           = list(),
    
    # Shared Python interpreter path (set by python_runner, read by maze_solver_tab)
    python_path = "python",

    # Reactive triggers
    progress_trigger = NULL,
    score_trigger    = NULL,
    
    # Candidate profile
    candidate = list(
      name        = "Candidate",
      role        = "Software Engineer (Leadership) - Machine Learning",
      company     = "Meta",
      interview_date = NULL,
      total_interviews = 5
    ),
    
    initialize = function() {
      self$progress_trigger <- reactiveVal(0)
      self$score_trigger    <- reactiveVal(0)
      
      # Initialise default progress
      tabs <- c("qualities","coding_interview","ml_design",
                "tech_project","cross_functional","career_interview",
                "intro_profile","qualities_profile","coding_profile",
                "ml_design_profile","tech_project_profile",
                "cross_functional_profile","career_profile",
                "python_runner","ml_design_whiteboard",
                "ml_design_excalidraw","ml_design_coderpad_wb",
                "intro_feedback","coding_feedback",
                "tech_project_feedback","cross_functional_feedback",
                "career_feedback","ml_design_feedback_1","ml_design_feedback_2",
                "ml_design_feedback_1","ml_design_feedback_2",
                "maze_solver_tab")
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
      entry <- list(
        score     = score,
        label     = label,
        timestamp = Sys.time()
      )
      if (is.null(self$practice_scores[[tab]])) {
        self$practice_scores[[tab]] <- list()
      }
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
