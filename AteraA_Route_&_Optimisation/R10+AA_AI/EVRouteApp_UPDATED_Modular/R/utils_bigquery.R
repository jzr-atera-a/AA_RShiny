# R/utils_bigquery.R
# R6 BigQueryManager Class with Reactive Triggers
# Version 3.0

library(R6)
library(bigrquery)
library(sf)
library(dplyr)

BigQueryManager <- R6Class(
  "BigQueryManager",
  
  public = list(
    bq_authenticated = FALSE,
    project_id = NULL,
    dataset_id = NULL,
    table_id = NULL,
    charging_points = NULL,
    network_data = NULL,  # Added for road network storage
    route_info = NULL,    # Added for route information storage
    state_trigger = NULL,  # Reactive trigger
    
    # Constructor
    initialize = function() {
      self$state_trigger <- reactiveVal(0)
      cat("BigQueryManager initialized\n")
    },
    
    # Authenticate with service account key
    authenticate = function(json_key_path, project_id, dataset_id, table_id) {
      tryCatch({
        # Set authentication
        bq_auth(path = json_key_path)
        
        # Test connection
        sql <- sprintf("SELECT * FROM `%s.%s.%s` LIMIT 10",
                       project_id, dataset_id, table_id)
        
        test_query <- bq_project_query(project_id, sql)
        test_data <- bq_table_download(test_query)
        
        self$bq_authenticated <- TRUE
        self$project_id <- project_id
        self$dataset_id <- dataset_id
        self$table_id <- table_id
        
        # Load full charging points data
        result <- self$load_charging_points()
        
        # Trigger state update
        self$trigger_state_update()
        
        list(success = TRUE, message = result$message)
        
      }, error = function(e) {
        self$bq_authenticated <- FALSE
        list(success = FALSE, message = as.character(e$message))
      })
    },
    
    # Load charging points from BigQuery
    load_charging_points = function() {
      if (!self$bq_authenticated) {
        stop("Not authenticated with BigQuery")
      }
      
      tryCatch({
        sql <- sprintf("SELECT * FROM `%s.%s.%s`",
                       self$project_id,
                       self$dataset_id,
                       self$table_id)
        
        query <- bq_project_query(self$project_id, sql)
        df_charging <- bq_table_download(query)
        
        # Clean and validate data
        df_charging <- df_charging %>%
          filter(!is.na(latitude) & !is.na(longitude)) %>%
          filter(is_valid_float(latitude) & is_valid_float(longitude)) %>%
          mutate(
            latitude = as.numeric(latitude),
            longitude = as.numeric(longitude)
          )
        
        # Convert to sf object
        self$charging_points <- st_as_sf(
          df_charging,
          coords = c("longitude", "latitude"),
          crs = 4326
        )
        
        list(
          success = TRUE,
          count = nrow(self$charging_points),
          message = paste("Loaded", nrow(self$charging_points), "charging points")
        )
        
      }, error = function(e) {
        list(success = FALSE, message = as.character(e$message))
      })
    },
    
    # Get charging points
    get_charging_points = function() {
      self$charging_points
    },
    
    # Clear authentication
    clear_auth = function() {
      self$bq_authenticated <- FALSE
      self$project_id <- NULL
      self$dataset_id <- NULL
      self$table_id <- NULL
      self$charging_points <- NULL
      
      # Trigger state update
      self$trigger_state_update()
      
      list(success = TRUE, message = "Authentication cleared")
    },
    
    # Get connection status
    get_status = function() {
      list(
        authenticated = self$bq_authenticated,
        project_id = self$project_id,
        dataset_id = self$dataset_id,
        table_id = self$table_id,
        charging_points_count = if (!is.null(self$charging_points)) nrow(self$charging_points) else 0
      )
    },
    
    # Trigger state update (for reactive cross-module updates)
    trigger_state_update = function() {
      if (!is.null(self$state_trigger)) {
        current <- isolate(self$state_trigger())
        self$state_trigger(current + 1)
      }
    }
  )
)