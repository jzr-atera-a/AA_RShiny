# R/utils_prep_manager.R
library(R6)

PrepManager <- R6Class("PrepManager",
  public = list(
    notes = list(),

    initialize = function() {
      self$notes <- list()
    },

    save_note = function(tab, text) {
      self$notes[[tab]] <- text
    },

    get_note = function(tab) {
      self$notes[[tab]] %||% ""
    }
  )
)
