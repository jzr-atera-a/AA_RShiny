# R/utils_data.R
# DataManager R6 Class - Manages asset data fetching and reactive state
# Extended from the reference architecture's DataManager to support:
#   - 5 asset classes (crypto, equity, commodity, forex, ig) vs. the reference's 3
#   - resolution-aware Yahoo Finance fetching (1m/5m/15m/30m/60m/1d), not just daily
#   - IG (CFD) fetching via the linked IGSessionManager (see R/utils_ig.R)
# All fetch paths produce the identical Date/Open/High/Low/Close/Volume/Adjusted/
# returns/returns_pct schema, so every module works unmodified regardless of source.
# ======================================================================

library(R6)
library(quantmod)
library(dplyr)
library(lubridate)
library(httr)
library(jsonlite)

DataManager <- R6::R6Class(
  "DataManager",
  
  public = list(
    # State
    current_asset = NULL,
    current_asset_class = NULL,
    resolution = "1d",          # Yahoo-sourced classes only; ignored for "ig"
    asset_data = NULL,
    data_loaded = FALSE,
    last_update = NULL,
    
    # Link to the IG session manager (set externally in global.R once both exist,
    # so IG-sourced fetches can check login state / call igfetchr).
    ig = NULL,
    
    # Reactive triggers
    state_trigger = NULL,
    refresh_trigger = NULL,
    
    # Initialize
    initialize = function() {
      self$state_trigger <- shiny::reactiveVal(0)
      self$refresh_trigger <- shiny::reactiveVal(0)
    },
    
    # Set current asset / asset class / resolution, and (re)fetch if anything changed
    set_current_asset = function(asset, asset_class, resolution = "1d") {
      if (is.null(asset) || asset == "") return()
      
      changed <- !identical(self$current_asset, asset) ||
                 !identical(self$current_asset_class, asset_class) ||
                 !identical(self$resolution, resolution)
      
      if (changed) {
        self$current_asset <- asset
        self$current_asset_class <- asset_class
        self$resolution <- resolution
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
    
    # Trigger state update (fires every module's observe() watchers)
    trigger_state_update = function() {
      current <- self$state_trigger()
      self$state_trigger(current + 1)
    },
    
    # ── Master dispatcher: routes to IG or Yahoo (daily/intraday) based on asset class ──
    fetch_data = function(months_back = 24) {
      if (is.null(self$current_asset)) return(NULL)
      
      if (self$current_asset_class == "ig") {
        if (is.null(self$ig) || !self$ig$is_logged_in()) {
          shiny::showNotification(
            "Please log in on the 'IG Login' tab before selecting an IG (CFD) instrument.",
            type = "warning", duration = 6
          )
          self$data_loaded <- FALSE
          self$asset_data <- NULL
          self$trigger_state_update()
          return(NULL)
        }
        shiny::showNotification("Fetching data from IG...", type = "message", duration = 2)
        df <- self$fetch_ig_data(self$current_asset)
      } else {
        shiny::showNotification(
          paste0("Fetching ", if (self$resolution == "1d") "daily" else paste0(self$resolution, "-resolution"), " data..."),
          type = "message", duration = 2
        )
        df <- self$fetch_yahoo_data(self$current_asset, self$resolution, months_back)
        if (is.null(df)) {
          Sys.sleep(2)
          df <- self$fetch_yahoo_data(self$current_asset, self$resolution, months_back)
        }
      }
      
      if (!is.null(df) && nrow(df) > 0) {
        self$asset_data <- df
        self$data_loaded <- TRUE
        self$last_update <- Sys.time()
        shiny::showNotification(paste("Loaded", nrow(df), "records for", self$current_asset),
                                 type = "message", duration = 3)
      } else {
        self$data_loaded <- FALSE
        self$asset_data <- NULL
        shiny::showNotification(
          paste0("Failed to load data for ", self$current_asset,
                 if (self$current_asset_class == "ig") ". Check your IG login and EPIC code."
                 else ". Try a coarser Data Resolution, or Yahoo Finance may be temporarily unavailable."),
          type = "error", duration = 8
        )
      }
      
      self$trigger_state_update()
      invisible(df)
    },
    
    # Resolution dispatcher for Yahoo-sourced classes
    fetch_yahoo_data = function(symbol, resolution = "1d", months_back = 24) {
      if (is.null(resolution) || resolution == "1d") {
        self$fetch_yahoo_daily(symbol, months_back)
      } else {
        self$fetch_yahoo_intraday(symbol, resolution)
      }
    },
    
    # Daily fetch via quantmod (proven path, unchanged from the original app's fetch_asset_data())
    fetch_yahoo_daily = function(symbol, months_back = 24) {
      tryCatch({
        start_date <- Sys.Date() - months(months_back)
        end_date <- Sys.Date()
        
        data <- getSymbols(symbol, src = "yahoo", from = start_date, to = end_date, auto.assign = FALSE)
        
        df <- data.frame(
          Date  = index(data),
          Open  = as.numeric(Op(data)),
          High  = as.numeric(Hi(data)),
          Low   = as.numeric(Lo(data)),
          Close = as.numeric(Cl(data))
        )
        
        vol <- tryCatch(as.numeric(Vo(data)), error = function(e) rep(NA_real_, nrow(df)))
        df$Volume <- ifelse(is.na(vol), 0, vol)
        
        adj <- tryCatch(as.numeric(Ad(data)), error = function(e) df$Close)
        df$Adjusted <- ifelse(is.na(adj), df$Close, adj)
        
        df <- df %>%
          arrange(Date) %>%
          mutate(
            returns     = c(NA, diff(log(Close))),
            returns_pct = c(NA, diff(Close) / head(Close, -1) * 100)
          )
        
        return(df)
        
      }, error = function(e) {
        shiny::showNotification(
          paste0("Error fetching ", symbol, ": ", conditionMessage(e), ". Try refreshing or switching assets."),
          type = "error", duration = 8
        )
        return(NULL)
      })
    },
    
    # Intraday fetch: calls Yahoo's public chart API directly via httr/jsonlite, bypassing
    # quantmod (whose intraday support varies by installed version). Yahoo's own lookback
    # limits per interval: 1m -> ~7 days, 5m/15m/30m -> ~60 days, 60m -> ~2 years.
    fetch_yahoo_intraday = function(symbol, interval = "1m") {
      tryCatch({
        range_map <- c("1m" = "7d", "5m" = "60d", "15m" = "60d", "30m" = "60d", "60m" = "730d")
        rng <- if (!is.na(range_map[interval])) range_map[[interval]] else "60d"
        
        url <- paste0(
          "https://query1.finance.yahoo.com/v8/finance/chart/", utils::URLencode(symbol, reserved = TRUE),
          "?range=", rng, "&interval=", interval, "&includePrePost=false"
        )
        
        resp <- httr::GET(url, httr::add_headers(`User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"))
        
        if (httr::status_code(resp) != 200) {
          shiny::showNotification(
            paste0("Yahoo intraday request failed (HTTP ", httr::status_code(resp), ") for ", symbol,
                   ". Try a coarser resolution."),
            type = "error", duration = 8
          )
          return(NULL)
        }
        
        parsed <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
        result <- parsed$chart$result
        
        if (is.null(result) || length(result) == 0) {
          err_msg <- parsed$chart$error$description
          shiny::showNotification(
            paste0("No intraday data for ", symbol,
                   if (!is.null(err_msg)) paste0(": ", err_msg) else ". Market may be closed or symbol unsupported."),
            type = "warning", duration = 8
          )
          return(NULL)
        }
        
        r1 <- result[[1]]
        ts <- unlist(r1$timestamp)
        quote <- r1$indicators$quote[[1]]
        
        if (is.null(ts) || length(ts) == 0) {
          shiny::showNotification(paste0("Empty intraday series for ", symbol, " at ", interval, " resolution."),
                                   type = "warning", duration = 6)
          return(NULL)
        }
        
        to_num_vec <- function(x, na_fill = NA_real_) {
          as.numeric(unlist(lapply(x, function(v) if (is.null(v)) na_fill else v)))
        }
        
        df <- data.frame(
          Date   = as.POSIXct(ts, origin = "1970-01-01", tz = "UTC"),
          Open   = to_num_vec(quote$open),
          High   = to_num_vec(quote$high),
          Low    = to_num_vec(quote$low),
          Close  = to_num_vec(quote$close),
          Volume = to_num_vec(quote$volume, na_fill = 0)
        )
        
        df$Adjusted <- df$Close
        df <- df[!is.na(df$Close) & !is.na(df$Date), ]
        
        if (nrow(df) < 2) {
          shiny::showNotification(
            paste0("Not enough intraday data points for ", symbol, " at this resolution — try a coarser one."),
            type = "warning", duration = 6
          )
          return(NULL)
        }
        
        df <- df %>%
          arrange(Date) %>%
          mutate(
            returns     = c(NA, diff(log(Close))),
            returns_pct = c(NA, diff(Close) / head(Close, -1) * 100)
          )
        
        return(df)
        
      }, error = function(e) {
        shiny::showNotification(paste0("Intraday fetch error for ", symbol, ": ", conditionMessage(e)),
                                 type = "error", duration = 8)
        return(NULL)
      })
    },
    
    # IG (CFD) fetch via the linked IGSessionManager / igfetchr. Column names are detected
    # defensively rather than hardcoded, since igfetchr's tibble output naming can evolve
    # between package versions — verify against a live pull.
    fetch_ig_data = function(epic, months_back = 24) {
      tryCatch({
        if (is.null(self$ig) || !self$ig$is_logged_in()) return(NULL)
        
        from_date <- format(Sys.Date() - months(months_back), "%Y-%m-%d")
        to_date   <- format(Sys.Date(), "%Y-%m-%d")
        
        raw <- igfetchr::ig_get_historical(
          epic = epic, from = from_date, to = to_date,
          resolution = "D", page_size = 20, auth = self$ig$auth
        )
        
        if (is.null(raw) || nrow(raw) == 0) {
          shiny::showNotification(paste("No IG data returned for", epic), type = "warning")
          return(NULL)
        }
        
        raw <- as.data.frame(raw)
        nm  <- names(raw)
        
        find_col <- function(patterns) {
          for (p in patterns) {
            hit <- grep(p, nm, ignore.case = TRUE, value = TRUE)
            if (length(hit) > 0) return(hit[1])
          }
          NA_character_
        }
        
        col_time  <- find_col(c("snapshotTime", "snapshot_time", "^date$", "^time$"))
        col_o_bid <- find_col(c("open.*bid", "open_bid"));   col_o_ask <- find_col(c("open.*ask", "open_ask"))
        col_o     <- find_col(c("^open$", "^openPrice$"))
        col_h_bid <- find_col(c("high.*bid", "high_bid"));   col_h_ask <- find_col(c("high.*ask", "high_ask"))
        col_h     <- find_col(c("^high$", "^highPrice$"))
        col_l_bid <- find_col(c("low.*bid", "low_bid"));     col_l_ask <- find_col(c("low.*ask", "low_ask"))
        col_l     <- find_col(c("^low$", "^lowPrice$"))
        col_c_bid <- find_col(c("close.*bid", "close_bid")); col_c_ask <- find_col(c("close.*ask", "close_ask"))
        col_c     <- find_col(c("^close$", "^closePrice$"))
        col_vol   <- find_col(c("lastTradedVolume", "^volume$"))
        
        mid_or_single <- function(bid_col, ask_col, single_col) {
          if (!is.na(bid_col) && !is.na(ask_col)) {
            (as.numeric(raw[[bid_col]]) + as.numeric(raw[[ask_col]])) / 2
          } else if (!is.na(single_col)) {
            as.numeric(raw[[single_col]])
          } else if (!is.na(bid_col)) {
            as.numeric(raw[[bid_col]])
          } else if (!is.na(ask_col)) {
            as.numeric(raw[[ask_col]])
          } else {
            rep(NA_real_, nrow(raw))
          }
        }
        
        dates <- if (!is.na(col_time)) {
          suppressWarnings(as.Date(raw[[col_time]]))
        } else {
          shiny::showNotification("Could not detect a date/time column in IG response — using row order.",
                                   type = "warning", duration = 6)
          Sys.Date() - rev(seq_len(nrow(raw))) + 1
        }
        
        df <- data.frame(
          Date  = dates,
          Open  = mid_or_single(col_o_bid, col_o_ask, col_o),
          High  = mid_or_single(col_h_bid, col_h_ask, col_h),
          Low   = mid_or_single(col_l_bid, col_l_ask, col_l),
          Close = mid_or_single(col_c_bid, col_c_ask, col_c)
        )
        
        df$Volume <- if (!is.na(col_vol)) as.numeric(raw[[col_vol]]) else 0
        df$Volume[is.na(df$Volume) | df$Volume < 0] <- 0
        df$Adjusted <- df$Close
        
        df <- df[!is.na(df$Close) & !is.na(df$Date), ]
        if (nrow(df) == 0) {
          shiny::showNotification(paste("Empty/unparseable IG dataset for", epic), type = "warning")
          return(NULL)
        }
        
        df <- df %>%
          arrange(Date) %>%
          mutate(
            returns     = c(NA, diff(log(Close))),
            returns_pct = c(NA, diff(Close) / head(Close, -1) * 100)
          )
        
        return(df)
        
      }, error = function(e) {
        shiny::showNotification(paste0("IG data error for ", epic, ": ", conditionMessage(e)),
                                 type = "error", duration = 8)
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
        resolution = self$resolution,
        records = nrow(data),
        start_date = min(data$Date),
        end_date = max(data$Date),
        current_price = tail(data$Close, 1),
        last_update = self$last_update
      )
    }
  )
)

cat("\u2713 Data utilities loaded\n")
