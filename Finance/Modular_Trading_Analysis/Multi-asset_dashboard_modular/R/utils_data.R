# R/utils_data.R
# DataManager R6 Class - Manages asset data fetching and reactive state
# ======================================================================

library(R6)
library(quantmod)
library(dplyr)
library(lubridate)

DataManager <- R6::R6Class(
  "DataManager",
  
  public = list(
    # State
    current_asset = NULL,
    current_asset_class = NULL,
    asset_data = NULL,
    data_loaded = FALSE,
    last_update = NULL,
    
    # Reactive triggers
    state_trigger = NULL,
    refresh_trigger = NULL,
    
    # Initialize
    initialize = function() {
      self$state_trigger <- shiny::reactiveVal(0)
      self$refresh_trigger <- shiny::reactiveVal(0)
    },
    
    # Set current asset
    set_current_asset = function(asset, asset_class) {
      if (is.null(asset) || asset == "") return()
      
      # Only fetch if changed
      if (!identical(self$current_asset, asset)) {
        self$current_asset <- asset
        self$current_asset_class <- asset_class
        self$fetch_data()
      }
    },
    
    # Trigger refresh
    trigger_refresh = function() {
      if (!is.null(self$current_asset)) {
        self$fetch_data()
      }
      current <- self$refresh_trigger()
      self$refresh_trigger(current + 1)
    },
    
    # Trigger state update
    trigger_state_update = function() {
      current <- self$state_trigger()
      self$state_trigger(current + 1)
    },
    
    # Fetch data from Yahoo Finance
    fetch_data = function(months_back = 24) {
      if (is.null(self$current_asset)) return(NULL)
      
      tryCatch({
        start_date <- Sys.Date() - months(months_back)
        end_date <- Sys.Date()
        
        # Fetch data using quantmod
        data <- getSymbols(self$current_asset, 
                          src = "yahoo", 
                          from = start_date, 
                          to = end_date, 
                          auto.assign = FALSE)
        
        # Convert to data frame
        df <- data.frame(
          Date = index(data),
          Open = as.numeric(Op(data)),
          High = as.numeric(Hi(data)),
          Low = as.numeric(Lo(data)),
          Close = as.numeric(Cl(data)),
          Volume = as.numeric(Vo(data)),
          Adjusted = as.numeric(Ad(data))
        )
        
        # Calculate returns
        df <- df %>%
          arrange(Date) %>%
          mutate(
            returns = c(NA, diff(log(Close))),
            returns_pct = c(NA, diff(Close) / head(Close, -1) * 100)
          )
        
        self$asset_data <- df
        self$data_loaded <- TRUE
        self$last_update <- Sys.time()
        
        # Notify all modules
        self$trigger_state_update()
        
        return(df)
        
      }, error = function(e) {
        warning("Error fetching data for ", self$current_asset, ": ", e$message)
        self$data_loaded <- FALSE
        self$asset_data <- NULL
        self$trigger_state_update()
        return(NULL)
      })
    },
    
    # Get current data
    get_data = function() {
      return(self$asset_data)
    },
    
    # Get data summary
    get_summary = function() {
      if (!self$data_loaded || is.null(self$asset_data)) {
        return(list(loaded = FALSE))
      }
      
      data <- self$asset_data
      
      list(
        loaded = TRUE,
        asset = self$current_asset,
        asset_class = self$current_asset_class,
        records = nrow(data),
        start_date = min(data$Date),
        end_date = max(data$Date),
        current_price = tail(data$Close, 1),
        last_update = self$last_update
      )
    },
    
    # Fetch hedge data
    fetch_hedge_data = function(hedge_symbol) {
      tryCatch({
        if (is.null(self$asset_data)) return(NULL)
        
        start_date <- min(self$asset_data$Date)
        end_date <- max(self$asset_data$Date)
        
        data <- getSymbols(hedge_symbol, 
                          src = "yahoo", 
                          from = start_date, 
                          to = end_date, 
                          auto.assign = FALSE)
        
        df <- data.frame(
          Date = index(data),
          Open = as.numeric(Op(data)),
          High = as.numeric(Hi(data)),
          Low = as.numeric(Lo(data)),
          Close = as.numeric(Cl(data)),
          Volume = as.numeric(Vo(data)),
          Adjusted = as.numeric(Ad(data))
        )
        
        df <- df %>%
          arrange(Date) %>%
          mutate(
            returns = c(NA, diff(log(Close))),
            returns_pct = c(NA, diff(Close) / head(Close, -1) * 100)
          )
        
        return(df)
        
      }, error = function(e) {
        warning("Error fetching hedge data for ", hedge_symbol, ": ", e$message)
        return(NULL)
      })
    },
    
    # Fetch composite data
    fetch_composite_data = function(symbols, start_date = NULL, end_date = NULL) {
      composite_list <- list()
      
      for (symbol in symbols) {
        tryCatch({
          data <- getSymbols(symbol, 
                            src = "yahoo", 
                            from = start_date %||% (Sys.Date() - months(12)), 
                            to = end_date %||% Sys.Date(), 
                            auto.assign = FALSE)
          
          df <- data.frame(
            Date = index(data),
            Close = as.numeric(Cl(data)),
            Volume = as.numeric(Vo(data))
          )
          
          df <- df %>%
            arrange(Date) %>%
            mutate(
              returns = c(NA, diff(log(Close))),
              asset = symbol
            )
          
          composite_list[[symbol]] <- df
          
        }, error = function(e) {
          warning("Error fetching ", symbol, ": ", e$message)
        })
      }
      
      if (length(composite_list) > 0) {
        return(bind_rows(composite_list))
      }
      
      return(NULL)
    }
  )
)

cat("✓ Data utilities loaded\n")
