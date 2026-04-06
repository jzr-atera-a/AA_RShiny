# R/utils_api_manager.R - Welch Group Fleet Monitor
# R6 API Manager for Volvo Group / Renault Trucks vehicle API
# Base URL: https://api.renault-trucks.com/vehicle  |  Spec: v1.0.6
#
# === ACCEPT HEADER PROBLEM & FIX ===
# httr automatically adds:  Accept: application/json, text/xml, application/xml, */*
# The Volvo API returns 406 for ANY Accept value except its own registered type.
# 
# For /vehicles the registered type is known:
#   application/x.volvogroup.com.vehicles.v1.0+json; UTF-8
#
# For /vehiclepositions and /vehiclestatuses we use curl::curl_fetch_memory()
# which lets us set EXACTLY the headers we want with no httr defaults injected.
# We try the Volvo pattern first, then fall back with verbose logging so we
# can identify the correct type from the 406 error body.
#
# All response bodies are parsed via rawToChar -> jsonlite (bypasses content-type).

VehicleAPIManager <- R6::R6Class("VehicleAPIManager",
  public = list(
    base_url          = "https://api.renault-trucks.com/vehicle",
    username          = NULL,
    password          = NULL,
    is_connected      = FALSE,
    last_error        = NULL,
    vehicles_cache    = NULL,
    last_connect_time = NULL,

    initialize = function() {
      cat("[API] VehicleAPIManager initialised\n")
      cat("[API] curl version:", curl::curl_version()$version, "\n")
    },

    set_credentials = function(username, password) {
      self$username     <- trimws(username)
      self$password     <- password
      self$is_connected <- FALSE
      cat("[API] Credentials set — user:", self$username, "\n")
      invisible(self)
    },

    # ── Test connection via httr (known Accept type for /vehicles) ──
    test_connection = function() {
      if (is.null(self$username) || nchar(self$username) == 0)
        return(list(success = FALSE, message = "Username is required.", status = 0))

      url   <- paste0(self$base_url, "/vehicles")
      reqid <- new_request_id()
      cat("[API] ── test_connection ──────────────────────\n")
      cat("[API] URL:", url, "\n")
      cat("[API] User:", self$username, "\n")
      cat("[API] RequestId:", reqid, "\n")

      tryCatch({
        resp <- httr::GET(
          url,
          httr::authenticate(self$username, self$password, "basic"),
          httr::add_headers(
            `Accept` = "application/x.volvogroup.com.vehicles.v1.0+json; UTF-8"
          ),
          httr::timeout(15),
          query = list(requestId = reqid, additionalContent = "VOLVOGROUPVEHICLE")
        )

        code    <- httr::status_code(resp)
        ct      <- httr::headers(resp)[["content-type"]] %||% "(none)"
        n_bytes <- length(httr::content(resp, "raw"))
        cat("[API] /vehicles -> HTTP", code, "| Content-Type:", ct, "| bytes:", n_bytes, "\n")

        body <- private$.parse_body(resp)

        if (code == 200) {
          self$is_connected     <- TRUE
          self$last_connect_time <- Sys.time()
          self$vehicles_cache   <- body$vehicleResponse$vehicles %||% list()
          n <- length(self$vehicles_cache)
          cat("[API] Connected OK —", n, "vehicles cached\n")
          return(list(
            success  = TRUE,
            message  = sprintf("Connected. %d vehicle(s) returned.", n),
            status   = code,
            vehicles = self$vehicles_cache
          ))
        } else {
          self$is_connected <- FALSE
          msg <- private$http_error_msg(code, body)
          self$last_error   <- msg
          cat("[API] Connection FAILED:", msg, "\n")
          return(list(success = FALSE, message = msg, status = code))
        }
      }, error = function(e) {
        self$is_connected <- FALSE
        self$last_error   <- e$message
        cat("[API] test_connection EXCEPTION:", e$message, "\n")
        list(success = FALSE, message = paste("Connection error:", e$message), status = 0)
      })
    },

    # ── GET /vehicles (httr — known Accept type) ──────────────────
    get_vehicles = function(additional_content = "VOLVOGROUPVEHICLE", last_vin = NULL) {
      private$.require_connection()
      q <- list(requestId = new_request_id(), additionalContent = additional_content)
      if (!is.null(last_vin)) q$lastVin <- last_vin

      url <- paste0(self$base_url, "/vehicles")
      cat("[API] GET /vehicles\n")
      cat("[API] Params:", paste(names(q), unlist(q), sep = "=", collapse = " | "), "\n")

      resp <- httr::GET(
        url,
        httr::authenticate(self$username, self$password, "basic"),
        httr::add_headers(`Accept` = "application/x.volvogroup.com.vehicles.v1.0+json; UTF-8"),
        httr::timeout(20),
        query = q
      )
      code <- httr::status_code(resp)
      cat("[API] /vehicles HTTP", code, "\n")
      private$.parse_httr(resp, "vehicleResponse", "/vehicles")
    },

    # ── GET /vehiclepositions (curl — full header control) ────────
    # IMPORTANT from rFMS docs: 'vin' is a STRING (single VIN, 17 chars).
    # It is NOT an array — comma-separated VINs cause a 400 error.
    # Strategy:
    #   - vins == NULL  → omit vin param → API returns ALL vehicles
    #   - length(vins) == 1 → pass single vin param
    #   - length(vins) > 1  → loop one call per VIN, combine results
    # Also: when latestOnly=TRUE, starttime/stoptime are NOT required per spec.
    get_vehicle_positions = function(vins = NULL, start_time = NULL, stop_time = NULL,
                                     trigger_filter = NULL, latest_only = FALSE) {
      private$.require_connection()

      .single_call <- function(vin_single = NULL) {
        q <- list(requestId = new_request_id())
        if (!is.null(vin_single))        q$vin           <- vin_single
        # Only add time params when NOT using latestOnly (per rFMS spec)
        if (!latest_only) {
          if (!is.null(start_time))      q$starttime     <- format(start_time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
          if (!is.null(stop_time))       q$stoptime      <- format(stop_time,  "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
        }
        if (!is.null(trigger_filter))    q$triggerFilter <- trigger_filter
        if (latest_only)                 q$latestOnly    <- "true"

        cat("[API] GET /vehiclepositions (via curl, controlled headers)\n")
        cat("[API] Params:", paste(names(q), unlist(q), sep = "=", collapse = " | "), "\n")

        private$.curl_get(
          endpoint    = "/vehiclepositions",
          query       = q,
          accept_type = "application/x.volvogroup.com.vehiclepositions.v1.0+json; UTF-8",
          root_key    = "vehiclePositionResponse"
        )
      }

      # No VINs or "ALL" → single call without vin param (returns all vehicles)
      if (is.null(vins) || length(vins) == 0) {
        return(.single_call(NULL))
      }

      # Single VIN → direct call
      if (length(vins) == 1) {
        return(.single_call(vins[[1]]))
      }

      # Multiple VINs → loop one call per VIN, merge vehiclePositions lists.
      # The API rate limit is 1 request/second per endpoint — sleep 1.2s between calls.
      cat("[API] Multiple VINs (", length(vins), ") — issuing", length(vins),
          "sequential calls (1.2s gap each)\n")
      all_positions <- list()
      last_status   <- 200L
      last_msg      <- ""
      for (i in seq_along(vins)) {
        if (i > 1) Sys.sleep(1.2)   # respect 1-second rate limit
        res <- .single_call(vins[[i]])
        if (isTRUE(res$success) && !is.null(res$data$vehiclePositions)) {
          all_positions <- c(all_positions, res$data$vehiclePositions)
        } else if (!isTRUE(res$success)) {
          last_status <- res$status %||% 400L
          last_msg    <- res$message %||% "unknown error"
          cat("[API] VIN", vins[[i]], "failed:", last_msg, "\n")
        }
      }
      cat("[API] Combined positions:", length(all_positions), "records\n")
      list(
        success = TRUE,
        status  = 200L,
        data    = list(vehiclePositions = all_positions),
        message = if (length(all_positions) == 0 && nchar(last_msg) > 0) last_msg else NULL
      )
    },

    # ── GET /vehiclestatuses (curl — full header control) ─────────
    # Same single-VIN-per-call constraint as vehiclepositions (rFMS spec).
    get_vehicle_statuses = function(vins = NULL, start_time = NULL, stop_time = NULL,
                                    trigger_filter = NULL, content = NULL,
                                    additional = NULL, latest_only = FALSE) {
      private$.require_connection()

      .single_call <- function(vin_single = NULL) {
        q <- list(requestId = new_request_id())
        if (!is.null(vin_single))        q$vin           <- vin_single
        if (!latest_only) {
          if (!is.null(start_time))      q$starttime     <- format(start_time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
          if (!is.null(stop_time))       q$stoptime      <- format(stop_time,  "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
        }
        if (!is.null(trigger_filter))    q$triggerFilter <- trigger_filter
        if (!is.null(content))           q$contentFilter    <- paste(toupper(content), collapse = ",")
        # additionalContent returns Volvo Group proprietary EV sections
        # (VOLVOGROUPACCUMULATED = lifetime energy/charging; VOLVOGROUPSNAPSHOT = event data)
        if (!is.null(additional))        q$additionalContent <- paste(additional, collapse = ",")
        if (latest_only)                 q$latestOnly    <- "true"

        cat("[API] GET /vehiclestatuses (via curl, controlled headers)\n")
        cat("[API] Params:", paste(names(q), unlist(q), sep = "=", collapse = " | "), "\n")

        # Auto-discover correct version via 406 handler in .curl_get
        private$.curl_get(
          endpoint    = "/vehiclestatuses",
          query       = q,
          accept_type = "application/x.volvogroup.com.vehiclestatuses.v3.0+json; UTF-8",
          root_key    = "vehicleStatusResponse"
        )
      }

      if (is.null(vins) || length(vins) == 0) {
        return(.single_call(NULL))
      }
      if (length(vins) == 1) {
        return(.single_call(vins[[1]]))
      }

      cat("[API] Multiple VINs (", length(vins), ") — issuing", length(vins),
          "sequential calls (1.2s gap each)\n")
      all_statuses <- list()
      last_msg     <- ""
      for (i in seq_along(vins)) {
        if (i > 1) Sys.sleep(1.2)
        res <- .single_call(vins[[i]])
        if (isTRUE(res$success) && !is.null(res$data$vehicleStatuses)) {
          all_statuses <- c(all_statuses, res$data$vehicleStatuses)
        } else if (!isTRUE(res$success)) {
          last_msg <- res$message %||% "unknown error"
          cat("[API] VIN", vins[[i]], "failed:", last_msg, "\n")
        }
      }
      cat("[API] Combined statuses:", length(all_statuses), "records\n")
      list(
        success = TRUE,
        status  = 200L,
        data    = list(vehicleStatuses = all_statuses),
        message = if (length(all_statuses) == 0 && nchar(last_msg) > 0) last_msg else NULL
      )
    },

    # ── GET everything — positions + statuses, all fields, paginated ──
    # Fires both endpoints with zero filters and all Volvo EV additional content.
    # Paginates using the receivedDateTime cursor until moreDataAvailable=false.
    # Returns a list: positions_raw, statuses_raw, raw_json_text, positions_df, statuses_df.
    get_everything = function(vins = NULL, start_time = NULL, stop_time = NULL) {
      private$.require_connection()

      # ── inner: paginated fetch for one endpoint, one VIN ─────────
      .fetch_paginated <- function(endpoint, accept_type, root_key,
                                   records_key, vin_single,
                                   start_t, stop_t, extra_q = list()) {
        all_records <- list()
        cursor_start <- start_t
        page <- 1L

        repeat {
          q <- list(requestId = new_request_id())
          if (!is.null(vin_single)) q$vin       <- vin_single
          q$starttime <- format(cursor_start, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
          q$stoptime  <- format(stop_t,       "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
          q$datetype  <- "received"
          for (nm in names(extra_q)) q[[nm]] <- extra_q[[nm]]

          cat("[API][ALL] Page", page, endpoint,
              if (!is.null(vin_single)) paste("VIN", vin_single) else "ALL VINs", "\n")

          res <- private$.curl_get(
            endpoint    = endpoint,
            query       = q,
            accept_type = accept_type,
            root_key    = root_key
          )

          if (!isTRUE(res$success)) {
            cat("[API][ALL] Page", page, "FAILED:", res$message %||% "?", "\n")
            break
          }

          page_records <- res$data[[records_key]] %||% list()
          cat("[API][ALL] Page", page, "records:", length(page_records), "\n")
          all_records <- c(all_records, page_records)

          more <- isTRUE(res$data$moreDataAvailable)
          if (!more || length(page_records) == 0) break

          # Advance cursor: receivedDateTime of last record + 1 second
          last_received <- page_records[[length(page_records)]]$receivedDateTime %||% NULL
          if (is.null(last_received)) break
          new_cursor <- tryCatch(
            as.POSIXct(last_received, format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC") + 1,
            error = function(e) NULL
          )
          if (is.null(new_cursor) || is.na(new_cursor)) break
          cursor_start <- new_cursor
          page <- page + 1L
          Sys.sleep(1.2)   # respect rate limit between pages
        }
        all_records
      }

      # ── Build VIN list (NULL = all vehicles, no vin param) ───────
      vin_list <- if (is.null(vins) || length(vins) == 0) list(NULL) else as.list(vins)

      # ── statuses: no content filter = all sections, all EV data ──
      statuses_extra <- list(
        additionalContent = "VOLVOGROUPACCUMULATED,VOLVOGROUPSNAPSHOT"
        # no contentFilter → API returns ACCUMULATED + SNAPSHOT + UPTIME
        # no triggerFilter → every trigger type is included
      )
      positions_extra <- list()  # no trigger filter

      all_statuses  <- list()
      all_positions <- list()

      for (i in seq_along(vin_list)) {
        vin <- vin_list[[i]]
        if (i > 1) Sys.sleep(1.2)

        cat("[API][ALL] ── VIN", if (is.null(vin)) "ALL" else vin, "──\n")

        # Statuses
        s_recs <- .fetch_paginated(
          endpoint    = "/vehiclestatuses",
          accept_type = "application/x.volvogroup.com.vehiclestatuses.v3.0+json; UTF-8",
          root_key    = "vehicleStatusResponse",
          records_key = "vehicleStatuses",
          vin_single  = vin,
          start_t     = start_time,
          stop_t      = stop_time,
          extra_q     = statuses_extra
        )
        all_statuses <- c(all_statuses, s_recs)
        Sys.sleep(1.2)

        # Positions
        p_recs <- .fetch_paginated(
          endpoint    = "/vehiclepositions",
          accept_type = "application/x.volvogroup.com.vehiclepositions.v1.0+json; UTF-8",
          root_key    = "vehiclePositionResponse",
          records_key = "vehiclePositions",
          vin_single  = vin,
          start_t     = start_time,
          stop_t      = stop_time,
          extra_q     = positions_extra
        )
        all_positions <- c(all_positions, p_recs)
      }

      cat("[API][ALL] Total statuses:", length(all_statuses),
          "| Total positions:", length(all_positions), "\n")

      # ── Serialise raw JSON for display ────────────────────────────
      raw_json_text <- tryCatch(
        jsonlite::toJSON(
          list(
            statuses  = all_statuses,
            positions = all_positions
          ),
          pretty = TRUE, auto_unbox = TRUE
        ),
        error = function(e) paste("JSON serialisation error:", e$message)
      )

      list(
        success       = TRUE,
        status        = 200L,
        statuses_raw  = all_statuses,
        positions_raw = all_positions,
        statuses_df   = self$statuses_as_df(all_statuses),
        positions_df  = self$positions_as_df(all_positions),
        raw_json_text = raw_json_text,
        data          = list(
          vehicleStatuses   = all_statuses,
          vehiclePositions  = all_positions
        )
      )
    },

    # ── Flatten vehicle list ──────────────────────────────────────
    vehicles_as_df = function(vlist = NULL) {
      vlist <- vlist %||% self$vehicles_cache %||% list()
      cat("[API] vehicles_as_df: flattening", length(vlist), "vehicles\n")
      if (length(vlist) == 0) return(data.frame())
      rows <- lapply(vlist, function(v) {
        vgv <- v$volvoGroupVehicle %||% list()
        data.frame(
          VIN               = safe_extract(v,   "vin",                 default = "-"),
          Name              = safe_extract(v,   "customerVehicleName", default = "-"),
          Registration      = safe_extract(vgv, "registrationNumber",  default = "-"),
          Brand             = safe_extract(v,   "brand",               default = "-"),
          Type              = safe_extract(v,   "type",                default = "-"),
          Model             = safe_extract(v,   "model",               default = "-"),
          EmissionLevel     = safe_extract(v,   "emissionLevel",       default = "-"),
          FuelTypes         = paste(safe_extract(v, "possibleFuelType", default = list()) %||% list(), collapse = ", "),
          ProductionYear    = as.integer(safe_extract(v,   "productionDate", "year",  default = NA_integer_)),
          ProductionMonth   = as.integer(safe_extract(v,   "productionDate", "month", default = NA_integer_)),
          DeliveryDate      = safe_extract(vgv, "deliveryDate",        default = "-"),
          Country           = safe_extract(vgv, "countryOfOperation",  default = "-"),
          TransportCycle    = safe_extract(vgv, "transportCycle",      default = "-"),
          RoadCondition     = safe_extract(vgv, "roadCondition",       default = "-"),
          SpeedLimit_kmh    = as.numeric(safe_extract(vgv, "vehicleReportSettings", "roadOverspeedLimit", default = NA_real_)),
          ConnectedServices = paste(safe_extract(vgv, "connectedServices", default = list()) %||% list(), collapse = ", "),
          stringsAsFactors  = FALSE
        )
      })
      df <- do.call(rbind, rows)
      cat("[API] vehicles_as_df:", nrow(df), "rows\n")
      df
    },

    # ── Flatten positions ─────────────────────────────────────────
    positions_as_df = function(pos_list) {
      cat("[API] positions_as_df: flattening", length(pos_list), "records\n")
      if (length(pos_list) == 0) return(data.frame())
      rows <- lapply(pos_list, function(p) {
        gnss <- p$gnssPosition %||% list()
        data.frame(
          VIN            = safe_extract(p,    "vin",              default = NA_character_),
          ReceivedAt     = safe_extract(p,    "receivedDateTime", default = NA_character_),
          CreatedAt      = safe_extract(p,    "createdDateTime",  default = NA_character_),
          Latitude       = as.numeric(safe_extract(gnss, "latitude",         default = NA_real_)),
          Longitude      = as.numeric(safe_extract(gnss, "longitude",        default = NA_real_)),
          Heading_deg    = as.numeric(safe_extract(gnss, "heading",          default = NA_real_)),
          Altitude_m     = as.numeric(safe_extract(gnss, "altitude",         default = NA_real_)),
          GNSS_Speed_kmh = as.numeric(safe_extract(gnss, "speed",            default = NA_real_)),
          GNSSStatus     = safe_extract(gnss, "gnssStatus",                   default = NA_character_),
          WheelSpeed_kmh = as.numeric(safe_extract(p,    "wheelBasedSpeed",  default = NA_real_)),
          TachoSpeed_kmh = as.numeric(safe_extract(p,    "tachographSpeed",  default = NA_real_)),
          TriggerType    = safe_extract(p,    "triggerType", "triggerType",   default = NA_character_),
          stringsAsFactors = FALSE
        )
      })
      df <- do.call(rbind, rows)
      cat("[API] positions_as_df:", nrow(df), "rows |",
          sum(!is.na(df$Latitude) & !is.na(df$Longitude)), "with GPS\n")
      df
    },

    # ── Flatten statuses ──────────────────────────────────────────
    # Unit notes (rFMS 2.1 spec):
    #   hrTotalVehicleDistance : stored in metres → divide by 1000 for km
    #   totalEngineHours       : 1/1000 hours → divide by 1000 for hours
    #   fuelLevel1             : for BEV = battery SOC % (0-100)
    #   fuelConsumption        : irrelevant for BEV; electricEnergyUsed in volvoGroupAccumulated
    statuses_as_df = function(status_list) {
      cat("[API] statuses_as_df: flattening", length(status_list), "records\n")
      if (length(status_list) == 0) return(data.frame())

      # Log raw structure of first record so we can see all available fields
      if (length(status_list) >= 1) {
        cat("[API] First record keys (top level):", paste(names(status_list[[1]]), collapse=", "), "\n")
        acc1  <- status_list[[1]]$accumulatedData %||% list()
        snap1 <- status_list[[1]]$snapshotData    %||% list()
        vga1  <- status_list[[1]]$volvoGroupAccumulatedData %||% list()
        vgs1  <- status_list[[1]]$volvoGroupSnapshotData    %||% list()
        cat("[API] accumulatedData keys:", paste(names(acc1),  collapse=", "), "\n")
        cat("[API] snapshotData keys:   ", paste(names(snap1), collapse=", "), "\n")
        cat("[API] volvoGroupAccumulated:", paste(names(vga1),  collapse=", "), "\n")
        cat("[API] volvoGroupSnapshot:   ", paste(names(vgs1),  collapse=", "), "\n")
      }

      rows <- lapply(status_list, function(s) {
        acc  <- s$accumulatedData          %||% list()
        snap <- s$snapshotData             %||% list()
        vga  <- s$volvoGroupAccumulatedData %||% list()
        vgs  <- s$volvoGroupSnapshotData    %||% list()
        drv  <- s$driver1Id                %||% list()
        gnss <- snap$gnssPosition          %||% list()  # position embedded in snapshot
        trig <- s$triggerType              %||% list()

        # hrTotalVehicleDistance: rFMS stores in metres (not 1/100 km)
        # 61,210,715 m = 61,211 km — consistent with ~17 months of operation
        raw_dist <- as.numeric(safe_extract(s, "hrTotalVehicleDistance", default = NA_real_))
        total_km <- if (!is.na(raw_dist) && raw_dist > 1000) raw_dist / 1000 else raw_dist

        # totalEngineHours: rFMS stores in 1/1000 hours
        raw_hrs <- as.numeric(safe_extract(s, "totalEngineHours", default = NA_real_))
        eng_hrs <- if (!is.na(raw_hrs) && raw_hrs > 1000) raw_hrs / 1000 else raw_hrs

        data.frame(
          # ── Identity & timing ─────────────────────────────────
          VIN         = safe_extract(s, "vin",             default = NA_character_),
          ReceivedAt  = safe_extract(s, "receivedDateTime", default = NA_character_),
          CreatedAt   = safe_extract(s, "createdDateTime",  default = NA_character_),
          TriggerType = safe_extract(trig, "triggerType",   default = NA_character_),

          # ── Odometer & hours ──────────────────────────────────
          TotalDistance_km = round(total_km, 1),
          EngineHours_h    = round(eng_hrs,  2),

          # ── Position embedded in snapshot ─────────────────────
          Latitude    = as.numeric(safe_extract(gnss, "latitude",  default = NA_real_)),
          Longitude   = as.numeric(safe_extract(gnss, "longitude", default = NA_real_)),
          Speed_kmh   = as.numeric(safe_extract(snap, "wheelBasedSpeed", default = NA_real_)),
          PosDateTime = safe_extract(gnss, "positionDateTime", default = NA_character_),

          # ── EV Battery (fuelLevel1 = SOC% for BEV in rFMS) ───
          BatterySoC_pct       = as.numeric(safe_extract(snap, "fuelLevel1",         default = NA_real_)),
          CatalystLevel_pct    = as.numeric(safe_extract(snap, "catalystFuelLevel",   default = NA_real_)),

          # ── EV Charging status ────────────────────────────────
          ChargingStatus     = safe_extract(snap, "batteryPackChargingStatus",           default = NA_character_),
          ChargingConnection = safe_extract(snap, "batteryPackChargingConnectionStatus", default = NA_character_),

          # ── Accumulated (rFMS standard) ───────────────────────
          FuelConsumption_l    = as.numeric(safe_extract(acc, "fuelConsumption",  default = NA_real_)),
          HRFuelConsumption_ml = as.numeric(safe_extract(acc, "hrFuelConsumption", default = NA_real_)),
          Distance_km          = as.numeric(safe_extract(acc, "distance",          default = NA_real_)),
          GrossWeight_kg       = as.numeric(safe_extract(snap, "grossCombinationVehicleWeight", default = NA_real_)),

          # ── Volvo Group EV Accumulated (additionalContent=VOLVOGROUPACCUMULATED)
          ElecEnergyUsed_kWh   = as.numeric(safe_extract(vga, "electricEnergyUsed",    default = NA_real_)),
          ElecEnergyRegen_kWh  = as.numeric(safe_extract(vga, "electricEnergyRecuperated", default = NA_real_)),
          ElecCharged_kWh      = as.numeric(safe_extract(vga, "electricEnergyCharged", default = NA_real_)),

          # ── Volvo Group EV Snapshot (additionalContent=VOLVOGROUPSNAPSHOT)
          BatteryPack_pct      = as.numeric(safe_extract(vgs, "batteryPackLevelPercent", default = NA_real_)),
          EstRange_km          = as.numeric(safe_extract(vgs, "estimatedDistanceToEmpty", default = NA_real_)),

          # ── Driver ───────────────────────────────────────────
          DriverID             = safe_extract(drv, "tachoDriverIdentification", default = NA_character_),

          stringsAsFactors = FALSE
        )
      })
      df <- do.call(rbind, rows)
      cat("[API] statuses_as_df:", nrow(df), "rows | cols:", paste(names(df), collapse=", "), "\n")
      df
    }
  ),

  private = list(
    .require_connection = function() {
      if (!self$is_connected)
        stop("Not connected. Please authenticate in the API Connection tab first.")
    },

    # ── Raw curl GET — gives FULL control over every header ───────
    # httr wraps libcurl and injects Accept/User-Agent automatically.
    # curl::curl_fetch_memory() sends ONLY what we explicitly specify.
    .curl_get = function(endpoint, query, accept_type, root_key) {
      base_url <- paste0(self$base_url, endpoint)

      # Build query string.
      # Use a light encoder NOT curl_escape — curl_escape encodes colons as %3A
      # which breaks ISO8601 timestamps (server then sees startTime as blank).
      # We only encode chars that truly need it; colons/dashes/T/Z are safe in
      # query values and must be left as-is for the Volvo API to parse dates.
      safe_encode <- function(v) {
        v <- as.character(v)
        v <- gsub(" ",  "%20", v)
        v <- gsub("\\+", "%2B", v)
        v <- gsub("#",  "%23", v)
        v <- gsub("\\[", "%5B", v)
        v <- gsub("\\]", "%5D", v)
        v
      }
      qs <- paste(
        mapply(function(k, v) paste0(k, "=", safe_encode(v)),
               names(query), unlist(query)),
        collapse = "&"
      )
      url <- paste0(base_url, "?", qs)

      cat("[API] curl GET:", url, "\n")
      cat("[API] Accept:", accept_type, "\n")

      # Build curl handle with explicit headers only
      h <- curl::new_handle()
      curl::handle_setopt(h,
        userpwd    = paste0(self$username, ":", self$password),
        httpauth   = 1L,           # CURLAUTH_BASIC
        timeout    = 30L,
        httpheader = c(
          paste0("Accept: ", accept_type)
          # No other headers — curl's defaults (Host, Content-Length etc) are fine
          # but we deliberately omit any default Accept that httr would add
        )
      )

      resp_raw <- tryCatch(
        curl::curl_fetch_memory(url, handle = h),
        error = function(e) {
          cat("[API] curl EXCEPTION:", e$message, "\n")
          list(status_code = 0L, content = raw(0),
               headers = raw(0), error = e$message)
        }
      )

      code <- resp_raw$status_code %||% 0L
      cat("[API]", endpoint, "-> HTTP", code, "\n")

      # Parse response headers for Content-Type (for debugging)
      raw_headers <- rawToChar(resp_raw$headers %||% raw(0))
      ct_line <- grep("^content-type", strsplit(raw_headers, "\r\n")[[1]],
                      ignore.case = TRUE, value = TRUE)
      cat("[API] Response Content-Type:", if (length(ct_line) > 0) ct_line[1] else "(none)", "\n")

      # If 406: parse the error body which lists acceptable types, then auto-retry
      if (code == 406L) {
        body_txt <- tryCatch(rawToChar(resp_raw$content %||% raw(0)), error = function(e) "")
        cat("[API] 406 received. Error body:", substr(body_txt, 1, 600), "\n")

        # Parse acceptable types from the detail field:
        # "Acceptable representations: [type1, type2, ...]"
        acceptable <- tryCatch({
          err_json <- jsonlite::fromJSON(body_txt, simplifyVector = FALSE)
          detail   <- err_json$detail %||% ""
          m        <- regmatches(detail, gregexpr(
            "application/x\\.volvogroup\\.com\\.[^,\\]]+",
            detail, perl = TRUE))[[1]]
          trimws(m)
        }, error = function(e) character(0))

        if (length(acceptable) == 0) {
          cat("[API] Could not parse acceptable types from 406 body\n")
          return(list(
            success = FALSE, status = 406L,
            message = paste0("Not acceptable (406). Server said: ", substr(body_txt, 1, 300)),
            data    = NULL
          ))
        }

        cat("[API] Server acceptable types:", paste(acceptable, collapse = " | "), "\n")
        cat("[API] Retrying with first acceptable type:", acceptable[1], "\n")

        # Retry with each acceptable type until one works
        for (try_type in acceptable) {
          h_retry <- curl::new_handle()
          curl::handle_setopt(h_retry,
            userpwd    = paste0(self$username, ":", self$password),
            httpauth   = 1L,
            timeout    = 30L,
            httpheader = c(paste0("Accept: ", try_type, "; UTF-8"))
          )
          resp_retry <- tryCatch(
            curl::curl_fetch_memory(url, handle = h_retry),
            error = function(e) list(status_code = 0L, content = raw(0), headers = raw(0))
          )
          code_retry <- resp_retry$status_code %||% 0L
          cat("[API] Retry Accept:", try_type, "-> HTTP", code_retry, "\n")
          if (code_retry == 200L) {
            cat("[API] SUCCESS with:", try_type, "\n")
            cat("[API] *** UPDATE utils_api_manager.R: set accept_type for", endpoint,
                "to '", try_type, "; UTF-8' ***\n")
            resp_raw <- resp_retry
            code     <- code_retry
            break
          }
        }

        if (code != 200L) {
          return(list(
            success = FALSE, status = 406L,
            message = paste0(
              "Not acceptable (406). Tried: ", paste(acceptable, collapse = ", "),
              ". None succeeded — check credentials have access to this endpoint."
            ),
            data = NULL
          ))
        }
      }

      # Parse body
      body <- tryCatch({
        txt <- rawToChar(resp_raw$content %||% raw(0))
        Encoding(txt) <- "UTF-8"
        preview <- substr(txt, 1, 300)
        cat("[API] Body preview:", gsub("\n", " ", preview), "\n")
        if (nchar(trimws(txt)) == 0) return(list())
        # Try JSON; if plain text (e.g. "Only last 14 days available.") wrap as message
        tryCatch(
          jsonlite::fromJSON(txt, simplifyVector = FALSE),
          error = function(e) {
            cat("[API] Body is plain text:", trimws(txt), "\n")
            list(message = trimws(txt))
          }
        )
      }, error = function(e) {
        cat("[API] Body parse error:", e$message, "\n")
        list()
      })

      # 429: API rate limit is 1 second per endpoint per user.
      # Auto-retry once after sleeping the indicated wait time (default 1.5s).
      if (code == 429L) {
        body_txt <- tryCatch(rawToChar(resp_raw$content %||% raw(0)), error = function(e) "")
        # Extract suggested wait from body e.g. "Try again in 0 seconds.551"
        wait_secs <- tryCatch({
          m <- regmatches(body_txt, regexpr("Try again in ([0-9.]+) seconds", body_txt))
          if (length(m) > 0) as.numeric(sub("Try again in ([0-9.]+) seconds", "\\1", m)) + 1.5
          else 1.5
        }, error = function(e) 1.5)
        wait_secs <- max(wait_secs, 1.2)  # always wait at least 1.2s
        cat("[API] 429 rate limit — sleeping", round(wait_secs, 2), "s then retrying\n")
        Sys.sleep(wait_secs)

        h_retry <- curl::new_handle()
        curl::handle_setopt(h_retry,
          userpwd    = paste0(self$username, ":", self$password),
          httpauth   = 1L, timeout = 30L,
          httpheader = c(paste0("Accept: ", accept_type))
        )
        resp_raw <- tryCatch(
          curl::curl_fetch_memory(url, handle = h_retry),
          error = function(e) list(status_code = 0L, content = raw(0), headers = raw(0))
        )
        code <- resp_raw$status_code %||% 0L
        cat("[API] Retry after 429 -> HTTP", code, "\n")

        if (code == 429L) {
          return(list(success = FALSE, status = 429L,
            message = "Rate limit (429) — still hit after retry. Wait a few seconds and try again.",
            data = NULL))
        }

        # Re-parse body after retry
        body <- tryCatch({
          txt <- rawToChar(resp_raw$content %||% raw(0))
          Encoding(txt) <- "UTF-8"
          tryCatch(jsonlite::fromJSON(txt, simplifyVector = FALSE),
                   error = function(e) list(message = trimws(txt)))
        }, error = function(e) list())
      }

      if (code == 200L) {
        data <- body[[root_key]] %||% body
        cat("[API] Extracted root_key '", root_key, "' — type:", class(data)[1],
            "| length:", length(data), "\n")
        list(success = TRUE, status = code, data = data, raw = body,
             size = length(resp_raw$content %||% raw(0)))
      } else {
        msg <- private$http_error_msg(code, body)
        cat("[API] FAILED:", msg, "\n")
        list(success = FALSE, status = code, message = msg, data = NULL)
      }
    },

    # ── httr body parser (for /vehicles only) ────────────────────
    .parse_body = function(resp) {
      tryCatch({
        raw_bytes <- httr::content(resp, "raw")
        n <- length(raw_bytes %||% raw(0))
        cat("[API] parse_body: raw bytes:", n, "\n")
        if (is.null(raw_bytes) || n == 0) return(list())
        txt <- rawToChar(raw_bytes)
        Encoding(txt) <- "UTF-8"
        if (nchar(trimws(txt)) == 0) return(list())
        cat("[API] Body preview:", substr(gsub("\n", " ", txt), 1, 300), "\n")
        # Try JSON first; if it fails (plain-text error body) return as message
        tryCatch(
          jsonlite::fromJSON(txt, simplifyVector = FALSE),
          error = function(e) {
            cat("[API] Body is plain text, not JSON:", trimws(txt), "\n")
            list(message = trimws(txt))
          }
        )
      }, error = function(e) {
        cat("[API] parse_body ERROR:", e$message, "\n")
        list()
      })
    },

    .parse_httr = function(resp, root_key, endpoint = "?") {
      code <- httr::status_code(resp)
      body <- private$.parse_body(resp)
      cat("[API] parse_httr", endpoint, "HTTP", code, "| keys:", paste(names(body), collapse = ", "), "\n")
      if (code == 200) {
        data <- body[[root_key]] %||% body
        cat("[API] root_key '", root_key, "' length:", length(data), "\n")
        list(success = TRUE,  status = code, data = data, raw = body,
             size = length(httr::content(resp, "raw")))
      } else {
        msg <- private$http_error_msg(code, body)
        cat("[API] FAILED:", msg, "\n")
        list(success = FALSE, status = code, message = msg, data = NULL)
      }
    },

    http_error_msg = function(code, body) {
      base <- switch(as.character(code),
        "400" = "Bad request (400) - check parameters",
        "401" = "Unauthorised (401) - wrong credentials or expired",
        "403" = "Forbidden (403) - insufficient rights or response too large",
        "404" = "Not found (404) - vehicle/endpoint unknown",
        "406" = "Not acceptable (406) - unsupported Accept header",
        "429" = "Too many requests (429) - rate limit hit, retry later",
        paste("HTTP error", code)
      )
      detail <- safe_extract(body, "message", default = NULL)
      result <- if (!is.null(detail)) paste0(base, " — ", detail) else base
      cat("[API] Error:", result, "\n")
      result
    }
  )
)

cat("[API] VehicleAPIManager class loaded\n")
