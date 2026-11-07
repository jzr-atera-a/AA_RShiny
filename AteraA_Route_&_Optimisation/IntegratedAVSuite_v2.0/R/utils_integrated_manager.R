# R/utils_integrated_manager.R
# Integrated AV Manager - FIXED: Double filter for NAs after numeric conversion

library(R6)
library(bigrquery)
library(sf)
library(dplyr)
library(jsonlite)

IntegratedAVManager <- R6Class(
  "IntegratedAVManager",
  
  public = list(
    # BigQuery fields
    bq_authenticated = FALSE,
    project_id = NULL,
    dataset_id = NULL,
    table_id = NULL,
    charging_points = NULL,
    
    # Route Optimizer fields
    network_data = NULL,
    route_info = NULL,
    
    # Omniverse fields
    omniverse_scenarios = NULL,
    omniverse_connected = FALSE,
    selected_scenario = NULL,
    
    # Reactive triggers
    state_trigger = NULL,
    route_trigger = NULL,
    scenario_trigger = NULL,
    
    # Constructor
    initialize = function() {
      self$state_trigger <- reactiveVal(0)
      self$route_trigger <- reactiveVal(0)
      self$scenario_trigger <- reactiveVal(0)
      cat("IntegratedAVManager initialized\n")
    },
    
    # ========================================
    # BIGQUERY METHODS
    # ========================================
    
    authenticate = function(json_key_path, project_id, dataset_id, table_id) {
      tryCatch({
        bq_auth(path = json_key_path)
        
        sql <- sprintf("SELECT * FROM `%s.%s.%s` LIMIT 10",
                       project_id, dataset_id, table_id)
        
        test_query <- bq_project_query(project_id, sql)
        test_data <- bq_table_download(test_query)
        
        self$bq_authenticated <- TRUE
        self$project_id <- project_id
        self$dataset_id <- dataset_id
        self$table_id <- table_id
        
        result <- self$load_charging_points()
        self$trigger_state_update()
        
        if (!result$success) {
          return(list(success = FALSE, message = paste("Auth OK but data load failed:", result$message)))
        }
        
        list(success = TRUE, message = result$message)
        
      }, error = function(e) {
        self$bq_authenticated <- FALSE
        list(success = FALSE, message = as.character(e$message))
      })
    },
    
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
        
        # CRITICAL FIX: Filter for non-NA BEFORE conversion
        df_charging <- df_charging %>%
          filter(!is.na(latitude) & !is.na(longitude))
        
        # Convert to numeric
        df_charging <- df_charging %>%
          mutate(
            latitude = as.numeric(latitude),
            longitude = as.numeric(longitude)
          )
        
        # CRITICAL FIX: Filter AGAIN after conversion to remove any NAs created by coercion
        df_charging <- df_charging %>%
          filter(!is.na(latitude) & !is.na(longitude))
        
        cat("✓ Cleaned data:", nrow(df_charging), "valid charging points\n")
        
        # Now safe to convert to sf
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
        cat("ERROR in load_charging_points():", e$message, "\n")
        list(success = FALSE, message = as.character(e$message))
      })
    },
    
    get_charging_points = function() {
      self$charging_points
    },
    
    clear_auth = function() {
      self$bq_authenticated <- FALSE
      self$project_id <- NULL
      self$dataset_id <- NULL
      self$table_id <- NULL
      self$charging_points <- NULL
      self$trigger_state_update()
      list(success = TRUE, message = "Authentication cleared")
    },
    
    get_status = function() {
      list(
        authenticated = self$bq_authenticated,
        project_id = self$project_id,
        dataset_id = self$dataset_id,
        table_id = self$table_id,
        charging_points_count = if (!is.null(self$charging_points)) nrow(self$charging_points) else 0,
        omniverse_connected = self$omniverse_connected,
        scenario_count = if (!is.null(self$omniverse_scenarios)) length(self$omniverse_scenarios) else 0
      )
    },
    
    # ========================================
    # OMNIVERSE METHODS
    # ========================================
    
    load_omniverse_scenarios = function(scenarios_data) {
      self$omniverse_scenarios <- scenarios_data
      self$omniverse_connected <- TRUE
      self$trigger_scenario_update()
      
      list(
        success = TRUE,
        count = length(scenarios_data),
        message = paste("Loaded", length(scenarios_data), "scenarios")
      )
    },
    
    get_scenarios = function() {
      self$omniverse_scenarios
    },
    
    set_selected_scenario = function(scenario) {
      self$selected_scenario <- scenario
      self$trigger_scenario_update()
    },
    
    get_selected_scenario = function() {
      self$selected_scenario
    },
    
    # ========================================
    # CROSS-MODULE INTEGRATION
    # ========================================
    
    route_to_scenario = function(route_info, conditions = list()) {
      if (is.null(route_info)) {
        return(NULL)
      }
      
      origin_coords <- route_info$start_coords
      dest_coords <- route_info$end_coords
      origin_addr <- route_info$origin_address
      dest_addr <- route_info$destination_address
      
      scenario <- list(
        scenario_id = paste0("route_", format(Sys.time(), "%Y%m%d_%H%M%S")),
        route = paste(origin_addr, "to", dest_addr),
        origin = list(
          city = origin_addr,
          lat = origin_coords[2],
          lon = origin_coords[1]
        ),
        destination = list(
          city = dest_addr,
          lat = dest_coords[2],
          lon = dest_coords[1]
        ),
        road_type = conditions$road_type %||% "auto",
        traffic = conditions$traffic %||% "moderate_congestion",
        weather = conditions$weather %||% "clear",
        av_readiness = "PENDING",
        quality_score = 0,
        trajectories = list(),
        incidents = list()
      )
      
      return(scenario)
    },
    
    # ========================================
    # REACTIVE TRIGGERS
    # ========================================
    
    trigger_state_update = function() {
      if (!is.null(self$state_trigger)) {
        current <- isolate(self$state_trigger())
        self$state_trigger(current + 1)
      }
    },
    
    trigger_route_update = function() {
      if (!is.null(self$route_trigger)) {
        current <- isolate(self$route_trigger())
        self$route_trigger(current + 1)
      }
    },
    
    trigger_scenario_update = function() {
      if (!is.null(self$scenario_trigger)) {
        current <- isolate(self$scenario_trigger())
        self$scenario_trigger(current + 1)
      }
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
