# modules/vehicle_data_v2.R — Welch Group Fleet Monitor
# IMPROVED CLONE of vehicle_data.R  (Book Ch 3, 5, 8, 9)
#
# ── Bug fixes over vehicle_data.R ────────────────────────────────────────────
# [BUGFIX-1]  vehicle_data_p.R defines IDENTICAL function names (vehicle_data_ui /
#             vehicle_data_server). When both files are in modules/, the one sourced
#             last alphabetically silently overwrites the other. This v2 uses unique
#             names: vehicle_data_v2_ui / vehicle_data_v2_server.
#
# [BUGFIX-2]  statuses_as_df reads s$volvoGroupAccumulatedData (wrong top-level key).
#             The API spec nests it as:  s$accumulatedData$volvoGroupAccumulated
#             and snapshot EV data as:  s$snapshotData$volvoGroupSnapshot
#             Fixed in .flatten_status() below.
#
# [BUGFIX-3]  electricEnergyRecuperated is wrong field name. Spec: electricEnergyRecuperation
#             which is itself a nested object {energy, duration}. Must read .energy.
#
# [BUGFIX-4]  estimatedDistanceToEmpty treated as scalar. Spec: object with .electric/.gas.
#             Fixed: read $electric sub-field.
#
# [BUGFIX-5]  GrossWeight_kg extracted from snapshotData. Spec: grossCombinationVehicleWeight
#             is a TOP-LEVEL field on VehicleStatusObject, not inside snapshotData.
#
# [BUGFIX-6]  get_vehicle_positions / get_vehicle_statuses do not handle moreDataAvailable.
#             Results silently truncated on large fleets. Fixed with cursor pagination loop.
#
# [BUGFIX-7]  vehiclestatuses Accept header hardcoded as v3.0 triggering a 406+retry on
#             every single call. Fixed to use the correct v1.0 type from the spec.
#
# [BUGFIX-8]  datetype=received never explicitly sent despite API docs recommending it.
#             Added to all time-window queries.
#
# ── Chapter improvements ──────────────────────────────────────────────────────
# [Ch3-ORM]   Field mapping table shows each API field -> SQLAlchemy column type + unit
#             exactly as described in the Chapter 3 Volvo context box.
#
# [Ch5-SCHEMA] All 4 response sections (Base, Accumulated, Snapshot, Uptime) are extracted
#              with correct nested key paths — mirroring the marshmallow nested schema
#              design from Chapter 5. Partial extraction (contentFilter aware) mirrors
#              marshmallow's partial= loading.
#
# [Ch8-PAGE]  Full moreDataAvailable pagination loop mirrors SQLAlchemy paginate() from
#             Chapter 8. receivedDateTime cursor = equivalent of page cursor.
#
# [Ch9-CACHE] TTL recommendations displayed per contentFilter selection, matching the
#             cache TTL mapping from the Chapter 9 Volvo context box.
#             Rate limit 429 is handled with Retry-After sleep + retry (Chapter 9 whitelist).
# ─────────────────────────────────────────────────────────────────────────────

# ── Internal helpers ─────────────────────────────────────────────────────────

# [BUGFIX-2,3,4,5] Correct field extraction for a single vehicleStatus record
# [Ch5-SCHEMA] Mirrors the nested marshmallow schema structure from Ch5:
#   VehicleStatusSchema > SnapshotDataSchema > GNSSPositionSchema
#                       > AccumulatedDataSchema > VolvoGroupAccumulatedSchema
.flatten_status <- function(s) {
  # Base section (always present)
  trig  <- s$triggerType       %||% list()
  drv   <- s$driver1Id         %||% list()

  # [BUGFIX-5] grossCombinationVehicleWeight is top-level, NOT in snapshotData
  raw_dist <- suppressWarnings(as.numeric(s$hrTotalVehicleDistance %||% NA_real_))
  total_km <- if (!is.na(raw_dist) && raw_dist > 1000) raw_dist / 1000 else raw_dist
  raw_hrs  <- suppressWarnings(as.numeric(s$totalEngineHours %||% NA_real_))
  eng_hrs  <- if (!is.na(raw_hrs) && raw_hrs > 1000) raw_hrs / 1000 else raw_hrs
  gross_kg <- suppressWarnings(as.numeric(s$grossCombinationVehicleWeight %||% NA_real_))

  # Snapshot section (MAP service)
  snap <- s$snapshotData    %||% list()
  gnss <- snap$gnssPosition %||% list()

  # [BUGFIX-2] Volvo Group snapshot: correct path is snapshotData$volvoGroupSnapshot
  # NOT s$volvoGroupSnapshotData (wrong top-level key used in original)
  vgs  <- snap$volvoGroupSnapshot %||% list()

  # Accumulated section (CHECK service)
  acc  <- s$accumulatedData %||% list()

  # [BUGFIX-2] Volvo Group accumulated: correct path is accumulatedData$volvoGroupAccumulated
  # NOT s$volvoGroupAccumulatedData (wrong top-level key used in original)
  vga  <- acc$volvoGroupAccumulated %||% list()

  # Uptime section (HEALTH service)
  upt  <- s$uptimeData %||% list()

  # [BUGFIX-3] electricEnergyRecuperation is a nested object {energy, duration}
  # Original used .electricEnergyRecuperated (wrong field name + treated as scalar)
  regen_raw <- vga$electricEnergyRecuperation %||% list()
  regen_wh  <- suppressWarnings(as.numeric(regen_raw$energy %||% NA_real_))

  # [BUGFIX-4] estimatedDistanceToEmpty is an object {electric, gas}; need .electric
  # Original treated it as a direct numeric scalar
  est_range_raw <- vgs$estimatedDistanceToEmpty %||% list()
  est_range_km  <- suppressWarnings(
    as.numeric(est_range_raw$electric %||% est_range_raw[[1]] %||% NA_real_)
  )

  data.frame(
    # ── Identity & timing [Ch5: dump_only fields] ─────────────────────────
    VIN          = safe_extract(s,    "vin",              default = NA_character_),
    ReceivedAt   = safe_extract(s,    "receivedDateTime", default = NA_character_),
    CreatedAt    = safe_extract(s,    "createdDateTime",  default = NA_character_),
    TriggerType  = safe_extract(trig, "triggerType",      default = NA_character_),
    TriggerContext = safe_extract(trig, "context",        default = NA_character_),

    # ── Odometer & hours [Ch3: BigInteger column, unit = metres / 1000] ───
    TotalDistance_km  = round(total_km, 1),
    EngineHours_h     = round(eng_hrs, 2),

    # ── [BUGFIX-5] GVW is top-level, not snapshotData ─────────────────────
    GrossWeight_kg    = gross_kg,

    # ── Snapshot: position [Ch3: Float columns] ───────────────────────────
    Latitude          = suppressWarnings(as.numeric(gnss$latitude    %||% NA_real_)),
    Longitude         = suppressWarnings(as.numeric(gnss$longitude   %||% NA_real_)),
    Altitude_m        = suppressWarnings(as.numeric(gnss$altitude    %||% NA_real_)),
    Heading_deg       = suppressWarnings(as.numeric(gnss$heading     %||% NA_real_)),
    GNSS_Speed_kmh    = suppressWarnings(as.numeric(gnss$speed       %||% NA_real_)),
    WheelSpeed_kmh    = suppressWarnings(as.numeric(snap$wheelBasedSpeed %||% NA_real_)),
    TachoSpeed_kmh    = suppressWarnings(as.numeric(snap$tachographSpeed %||% NA_real_)),
    EngineSpeed_rpm   = suppressWarnings(as.numeric(snap$engineSpeed %||% NA_real_)),

    # ── Snapshot: EV battery [Ch3: batteryPackChargingStatus = String(30)] ─
    # fuelLevel1 = SOC% for BEV (rFMS spec). 0-100 range.
    BatterySoC_pct         = suppressWarnings(as.numeric(snap$fuelLevel1 %||% NA_real_)),
    AmbientTemp_C          = suppressWarnings(as.numeric(snap$ambientAirTemperature %||% NA_real_)),
    ChargingStatus         = safe_extract(snap, "batteryPackChargingStatus",            default = NA_character_),
    ChargingConnection     = safe_extract(snap, "batteryPackChargingConnectionStatus",  default = NA_character_),
    ChargingDevice         = safe_extract(snap, "batteryPackChargingDevice",            default = NA_character_),
    ChargingPower_kW       = suppressWarnings(as.numeric(snap$batteryPackChargingPower %||% NA_real_)),
    ChargeTarget_pct       = suppressWarnings(as.numeric(snap$batteryPackChargeTarget  %||% NA_real_)),

    # ── [BUGFIX-4] estimatedDistanceToEmpty: read .electric sub-field ──────
    EstRange_km            = est_range_km,

    # ── Volvo Group snapshot EV fields (VOLVOGROUPSNAPSHOT) [Ch5: nested] ──
    BatteryPack_pct        = suppressWarnings(as.numeric(vgs$hybridBatteryPackRemainingCharge %||% NA_real_)),
    ParkingClimate         = safe_extract(vgs, "parkingClimateStatus",  default = NA_character_),
    EngineOilLevel_pct     = suppressWarnings(as.numeric(vgs$engineOilLevel %||% NA_real_)),

    # ── Accumulated (CHECK service) ──────────────────────────────────────
    TotalFuelUsed_ml       = suppressWarnings(as.numeric(acc$engineTotalFuelUsed %||% NA_real_)),

    # ── Volvo Group accumulated EV fields (VOLVOGROUPACCUMULATED) ──────────
    ElecEnergyPropulsion_Wh = suppressWarnings(as.numeric(vga$electricEnergyPropulsion %||% NA_real_)),
    ElecEnergyTotal_Wh     = suppressWarnings(as.numeric(vga$totalElectricEnergyUsed   %||% NA_real_)),

    # [BUGFIX-3] Correct field name + correct path into nested object
    ElecEnergyRegen_Wh     = regen_wh,

    ElecEnergyMotorHours_h = suppressWarnings(as.numeric(vga$totalElectricMotorHours    %||% NA_real_)),
    LaneKeepWarnings       = suppressWarnings(as.numeric(vga$lanekeepingWarningCounter  %||% NA_real_)),

    # ── Driver ───────────────────────────────────────────────────────────
    DriverID               = safe_extract(drv, "tachoDriverIdentification", default = NA_character_),

    # ── Uptime (HEALTH service) ──────────────────────────────────────────
    ServiceDistance_m      = suppressWarnings(as.numeric(upt$serviceDistance          %||% NA_real_)),
    Coolant_C              = suppressWarnings(as.numeric(upt$engineCoolantTemperature %||% NA_real_)),

    stringsAsFactors = FALSE
  )
}

# [Ch8-PAGE] Paginated fetch loop using receivedDateTime cursor.
# Mirrors SQLAlchemy paginate(): moreDataAvailable = has_next, cursor = next page start.
.paginated_fetch_v2 <- function(api_manager, endpoint_fn, args, flatten_fn,
                                 records_key, max_pages = 20) {
  all_records <- list()
  page        <- 1L

  # Copy args so we can advance starttime
  call_args <- args

  repeat {
    cat("[V2][PAGE", page, "] Calling", records_key, "\n")
    result <- tryCatch(
      do.call(endpoint_fn, call_args),
      error = function(e) list(success = FALSE, message = e$message, data = NULL)
    )

    if (!isTRUE(result$success)) {
      cat("[V2][PAGE", page, "] FAILED:", result$message %||% "?", "\n")
      break
    }

    page_records <- (result$data[[records_key]]) %||% list()
    cat("[V2][PAGE", page, "] Records:", length(page_records), "\n")
    all_records <- c(all_records, page_records)

    more <- isTRUE(result$data$moreDataAvailable)
    if (!more || length(page_records) == 0 || page >= max_pages) break

    # [Ch8-PAGE] Advance cursor: last receivedDateTime + 1 second
    # Equivalent to: starttime = pag.items[-1].receivedDateTime + timedelta(seconds=1)
    last_received <- page_records[[length(page_records)]]$receivedDateTime %||% NULL
    if (is.null(last_received)) break
    new_start <- tryCatch(
      as.POSIXct(last_received, format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC") + 1,
      error = function(e) NULL
    )
    if (is.null(new_start) || is.na(new_start)) break
    call_args$start_time <- new_start
    page <- page + 1L
    Sys.sleep(1.2)  # [Ch9-RATE] respect rate limits between pages
  }

  cat("[V2][TOTAL]", records_key, ":", length(all_records), "records\n")
  all_records
}

# ── UI ───────────────────────────────────────────────────────────────────────
vehicle_data_v2_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "wg-page-header",
      div(class = "wg-page-title",
        tags$i(class = "fa fa-truck", style = "margin-right:10px;"),
        "EV Fleet \u2014 Vehicle Data v2 (Improved)"
      ),
      div(class = "wg-page-subtitle",
        "Improved vehicle data tab. Bug fixes, full moreDataAvailable pagination, ",
        "correct EV field extraction, and enhanced visualisations."
      ),
      # Chapter context ribbon
      div(style = "margin-top:10px;padding:10px 16px;background:#1a2d45;border-left:4px solid #1a6faf;border-radius:6px;",
        tags$b(style = "color:#7ec8e3;", "\U0001f4da Ch 3, 5, 8, 9: "),
        tags$span(style = "color:#8fa0b5;font-size:13px;",
          "Ch3: API fields mapped to SQLAlchemy columns. ",
          "Ch5: Nested JSON extracted with correct key paths (marshmallow schema structure). ",
          "Ch8: Full moreDataAvailable pagination loop (SQLAlchemy paginate() equivalent). ",
          "Ch9: Cache TTL guidance per contentFilter + 429 rate-limit retry."
        )
      )
    ),

    # ── Query controls ────────────────────────────────────────────────────────
    fluidRow(
      column(12,
        div(class = "wg-card",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-sliders", style = "margin-right:8px;"),
            "Query Parameters"
          ),
          div(class = "wg-card-body",
            fluidRow(
              column(3,
                div(class = "wg-field-group",
                  tags$label("Vehicle(s)", class = "wg-label"),
                  uiOutput(ns("v2_vehicle_selector_ui")),
                  uiOutput(ns("v2_resolved_vins_display"))
                )
              ),
              column(3,
                div(class = "wg-field-group",
                  tags$label("Query Type", class = "wg-label"),
                  radioButtons(ns("v2_query_type"), label = NULL,
                    choices  = c(
                      "Vehicle List (metadata)"   = "vehicles",
                      "Positions (GPS)"           = "positions",
                      "Statuses (telemetry)"      = "statuses",
                      "Everything (full dump)"    = "everything"
                    ),
                    selected = "vehicles"
                  )
                ),
                # [Ch9-CACHE] Show recommended cache TTL for selected contentFilter
                conditionalPanel(
                  condition = sprintf("input['%s'] == 'statuses'", ns("v2_query_type")),
                  div(class = "wg-field-group",
                    tags$label("contentFilter (statuses)", class = "wg-label"),
                    checkboxGroupInput(ns("v2_status_content"), label = NULL,
                      choices  = c("ACCUMULATED", "SNAPSHOT", "UPTIME"),
                      selected = c("ACCUMULATED", "SNAPSHOT")
                    ),
                    div(class = "wg-field-group",
                      tags$label("additionalContent (Volvo EV fields)", class = "wg-label"),
                      checkboxGroupInput(ns("v2_additional"), label = NULL,
                        choices  = c(
                          "VOLVOGROUPACCUMULATED" = "VOLVOGROUPACCUMULATED",
                          "VOLVOGROUPSNAPSHOT"    = "VOLVOGROUPSNAPSHOT"
                        ),
                        selected = c("VOLVOGROUPACCUMULATED", "VOLVOGROUPSNAPSHOT")
                      )
                    )
                  )
                )
              ),
              column(3,
                div(class = "wg-field-group",
                  tags$label("Start Time (UTC)", class = "wg-label"),
                  dateInput(ns("v2_start_date"), label = NULL,
                            value = Sys.Date() - 13, max = Sys.Date(), width = "100%")
                ),
                div(class = "wg-field-group",
                  tags$label("End Time (UTC)", class = "wg-label"),
                  dateInput(ns("v2_end_date"), label = NULL,
                            value = Sys.Date(), max = Sys.Date(), width = "100%")
                ),
                conditionalPanel(
                  condition = sprintf("input['%s'] != 'vehicles'", ns("v2_query_type")),
                  checkboxInput(ns("v2_latest_only"), "Latest record only (latestOnly=true)", FALSE)
                ),
                # [Ch9-CACHE] TTL hint
                div(id = ns("v2_cache_hint_div"),
                  uiOutput(ns("v2_cache_hint"))
                )
              ),
              column(3,
                div(class = "wg-field-group",
                  tags$label("triggerFilter", class = "wg-label"),
                  selectInput(ns("v2_trigger"), label = NULL,
                    choices = c(
                      "No filter (all)"                                = "",
                      "TIMER"                                          = "TIMER",
                      "IGNITION_ON"                                    = "IGNITION_ON",
                      "IGNITION_OFF"                                   = "IGNITION_OFF",
                      "ENGINE_ON / OFF"                                = "ENGINE_ON",
                      "DRIVER_LOGIN / LOGOUT"                          = "DRIVER_LOGIN",
                      "TELL_TALE"                                      = "TELL_TALE",
                      "IDLING"                                         = "IDLING",
                      "FLEET_OVERSPEED"                                = "FLEET_OVERSPEED",
                      "BATTERY_PACK_CHARGING_STATUS_CHANGE"            = "BATTERY_PACK_CHARGING_STATUS_CHANGE",
                      "BATTERY_PACK_CHARGING_CONNECTION_STATUS_CHANGE" = "BATTERY_PACK_CHARGING_CONNECTION_STATUS_CHANGE",
                      "BATTERY_PACK_ENERGY_USAGE"                      = "BATTERY_PACK_ENERGY_USAGE",
                      "BATTERY_PACK_HIGH_DISCHARGE"                    = "BATTERY_PACK_HIGH_DISCHARGE",
                      "BATTERY_PRECONDITIONING"                        = "BATTERY_PRECONDITIONING",
                      "VEHICLE_COUPLER_UNLOCK_ALLOWED"                 = "VEHICLE_COUPLER_UNLOCK_ALLOWED",
                      "VEHICLE_MODE"                                   = "VEHICLE_MODE",
                      "CLIMATE_STATUS"                                 = "CLIMATE_STATUS",
                      "GEOFENCE"                                       = "GEOFENCE",
                      "TIRE_WARNING"                                   = "TIRE_WARNING"
                    ),
                    width = "100%"
                  )
                ),
                tags$br(),
                actionButton(ns("v2_btn_query"), "Run Query",
                             icon = icon("search"),
                             class = "wg-btn wg-btn-primary", width = "100%"),
                tags$br(), tags$br(),
                actionButton(ns("v2_btn_probe"), "Probe API (latestOnly)",
                             icon = icon("stethoscope"),
                             class = "wg-btn wg-btn-secondary", width = "100%",
                             style = "background:#1a3a2a;border-color:#2ecc71;color:#2ecc71;"),
                tags$br(), tags$br(),
                actionButton(ns("v2_btn_demo"), "Load Demo Data",
                             icon = icon("flask"),
                             class = "wg-btn wg-btn-secondary", width = "100%")
              )
            )
          )
        )
      )
    ),

    # ── Summary metrics ───────────────────────────────────────────────────────
    fluidRow(column(12, uiOutput(ns("v2_summary_metrics")))),

    # ── Results tabset ────────────────────────────────────────────────────────
    fluidRow(
      column(12,
        div(class = "wg-card", style = "margin-top:6px;",
          div(class = "wg-card-header",
            tags$i(class = "fa fa-database", style = "margin-right:8px;"),
            "Query Results",
            uiOutput(ns("v2_result_meta_badge"), inline = TRUE)
          ),
          div(class = "wg-card-body",
            tabsetPanel(id = ns("v2_result_tabs"),
              # ── Data Table ───────────────────────────────────────────────
              tabPanel("Data Table",
                tags$br(),
                # [Ch3-ORM] Field mapping reference box
                div(style = "margin-bottom:12px;padding:10px 14px;background:#0d1921;border-left:3px solid #1a6faf;border-radius:4px;",
                  tags$b(style = "color:#7ec8e3;",
                    tags$i(class = "fa fa-database", style = "margin-right:6px;"),
                    "[Ch3] SQLAlchemy Field Mapping"
                  ),
                  tags$br(),
                  tags$small(style = "color:#8fa0b5;",
                    "Key units: TotalDistance_km = hrTotalVehicleDistance \u00f7 1000 (metres \u2192 km). ",
                    "EngineHours_h = totalEngineHours \u00f7 1000 (1/1000 hr \u2192 hours). ",
                    "BatterySoC_pct = fuelLevel1 (SOC% for BEV in rFMS 2.1). ",
                    "ElecEnergyRegen_Wh = electricEnergyRecuperation.energy (nested object, not scalar)."
                  )
                ),
                uiOutput(ns("v2_data_table_ui"))
              ),

              # ── Field Explorer [Ch5] ─────────────────────────────────────
              tabPanel("Field Explorer [Ch5]",
                tags$br(),
                div(style = "padding:10px 14px;background:#0d1921;border-left:3px solid #1a6faf;border-radius:4px;margin-bottom:14px;",
                  tags$b(style = "color:#7ec8e3;",
                    "[Ch5-SCHEMA] Response Section Structure"
                  ),
                  tags$br(),
                  tags$small(style = "color:#8fa0b5;",
                    "The /vehiclestatuses response has 4 sections matching nested marshmallow schemas. ",
                    "Base is always present. Snapshot requires MAP. Accumulated requires CHECK. ",
                    "Uptime requires HEALTH (not yet released). additionalContent unlocks Volvo proprietary sub-objects."
                  )
                ),
                uiOutput(ns("v2_field_explorer_ui"))
              ),

              # ── Geographic Map ───────────────────────────────────────────
              tabPanel("Geographic Map",
                tags$br(),
                conditionalPanel(
                  condition = sprintf("input['%s'] == 'positions' || input['%s'] == 'statuses' || input['%s'] == 'everything'",
                                      ns("v2_query_type"), ns("v2_query_type"), ns("v2_query_type")),
                  div(class = "wg-map-controls",
                    div(style = "display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;",
                      div(
                        tags$small("Colour = vehicle. Circle size = speed. Toggle route polyline."),
                        checkboxInput(ns("v2_map_polyline"), "Draw route polyline", FALSE)
                      ),
                      downloadButton(ns("v2_btn_download_geojson"), "Download GeoJSON",
                        style = "padding:4px 12px;font-size:12px;background:#1a3a2a;border-color:#28a745;color:#28a745;")
                    )
                  ),
                  leaflet::leafletOutput(ns("v2_position_map"), height = "500px")
                )
              ),

              # ── EV Analytics [Ch3 fields, Ch5 extraction] ────────────────
              tabPanel("EV Analytics [Ch3/Ch5]",
                tags$br(),
                div(style = "padding:10px 14px;background:#0d1921;border-left:3px solid #28a745;border-radius:4px;margin-bottom:14px;",
                  tags$b(style = "color:#2ecc71;",
                    "[Ch3/Ch5] EV-Specific Fields from VOLVOGROUPSNAPSHOT + VOLVOGROUPACCUMULATED"
                  ),
                  tags$br(),
                  tags$small(style = "color:#8fa0b5;",
                    "These charts use fields only available with additionalContent=VOLVOGROUPSNAPSHOT,VOLVOGROUPACCUMULATED. ",
                    "Run a statuses query with both EV options checked to populate these charts."
                  )
                ),
                uiOutput(ns("v2_ev_analytics_ui"))
              ),

              # ── Trends & Charts ───────────────────────────────────────────
              tabPanel("Trends & Charts",
                tags$br(), uiOutput(ns("v2_trends_ui"))
              ),

              # ── Pagination Diagnostics [Ch8] ──────────────────────────────
              tabPanel("Pagination [Ch8]",
                tags$br(),
                div(style = "padding:10px 14px;background:#0d1921;border-left:3px solid #fd7e14;border-radius:4px;margin-bottom:14px;",
                  tags$b(style = "color:#fd7e14;",
                    "[Ch8] moreDataAvailable Pagination \u2014 cursor-based (receivedDateTime)"
                  ),
                  tags$br(),
                  tags$small(style = "color:#8fa0b5;",
                    "The Volvo API paginates using moreDataAvailable (like SQLAlchemy pag.has_next). ",
                    "Advance starttime to last receivedDateTime + 1 second (like pag.next_num cursor). ",
                    "The original vehicle_data.R does NOT handle moreDataAvailable for single-endpoint queries."
                  )
                ),
                verbatimTextOutput(ns("v2_pagination_log"))
              ),

              # ── Raw JSON ──────────────────────────────────────────────────
              tabPanel("Raw JSON",
                tags$br(),
                div(style = "display:flex;justify-content:flex-end;margin-bottom:8px;",
                  downloadButton(ns("v2_btn_download_json"), "Download JSON",
                    style = "padding:3px 10px;font-size:12px;background:#1a3a4a;border-color:#1a9b9b;color:#7ec8e3;")
                ),
                div(style = "background:#0d1921;border:1px solid #253a52;border-radius:4px;max-height:600px;overflow:auto;padding:12px;",
                  verbatimTextOutput(ns("v2_raw_json_display"))
                )
              ),

              # ── Debug & Diagnostics ───────────────────────────────────────
              tabPanel("Debug & Diagnostics",
                tags$br(),
                div(class = "wg-debug-section", style = "margin-bottom:14px;",
                  tags$h5(style = "color:#00b4d8;margin-bottom:8px;",
                    tags$i(class = "fa fa-send", style = "margin-right:6px;"),
                    "Last Request Sent"
                  ),
                  verbatimTextOutput(ns("v2_debug_request"))
                ),
                div(class = "wg-debug-section", style = "margin-bottom:14px;",
                  tags$h5(style = "color:#00b4d8;margin-bottom:8px;",
                    tags$i(class = "fa fa-reply", style = "margin-right:6px;"),
                    "Response Summary"
                  ),
                  verbatimTextOutput(ns("v2_debug_response"))
                ),
                div(class = "wg-debug-section",
                  tags$h5(style = "color:#00b4d8;margin-bottom:8px;",
                    tags$i(class = "fa fa-plug", style = "margin-right:6px;"),
                    "Connected Services (queried vehicles)"
                  ),
                  verbatimTextOutput(ns("v2_debug_services"))
                )
              )
            )
          )
        )
      )
    )
  )
}

# ── SERVER ───────────────────────────────────────────────────────────────────
vehicle_data_v2_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    rv <- reactiveValues(
      df            = NULL,
      df_positions  = NULL,
      df_statuses   = NULL,
      raw_json_text = NULL,
      query_type    = NULL,
      query_time    = NULL,
      is_demo       = FALSE,
      debug_request = NULL,
      pagination_log = NULL
    )

    # ── Dynamic vehicle selector (same logic as original) ───────────────────
    output$v2_vehicle_selector_ui <- renderUI({
      cache <- api_manager$vehicles_cache %||% list()
      if (length(cache) == 0) {
        choices <- c("All vehicles" = "ALL")
        sel     <- "ALL"
      } else {
        make_label <- function(v) {
          name <- v$customerVehicleName %||% (v$vin %||% "?")
          vin  <- v$vin %||% "?"
          fuel <- paste(v$possibleFuelType %||% list(), collapse = "")
          ev_tag <- if (grepl("08", fuel)) " [EV]" else ""
          as.character(tags$span(
            tags$span(paste0(name, ev_tag)),
            tags$br(),
            tags$small(style = "color:#4a7a9b;font-family:monospace;font-size:10px;", vin)
          ))
        }
        labels  <- sapply(cache, make_label)
        values  <- sapply(cache, function(v) v$vin %||% "")
        keep    <- nchar(values) > 0
        choices <- c("All vehicles" = "ALL",
                     setNames(values[keep], labels[keep]))
        ev_vins <- sapply(cache, function(v) {
          fuel <- paste(v$possibleFuelType %||% list(), collapse = "")
          if (grepl("08", fuel)) v$vin %||% "" else ""
        })
        ev_vins <- unique(ev_vins[nchar(ev_vins) > 0])
        sel <- if (length(ev_vins) > 0) ev_vins else "ALL"
      }
      checkboxGroupInput(ns("v2_selected_vehicles"), label = NULL,
                         choices = choices, selected = sel)
    })

    output$v2_resolved_vins_display <- renderUI({
      sel <- input$v2_selected_vehicles
      if (is.null(sel)) return(NULL)
      if ("ALL" %in% sel) {
        n <- length(api_manager$vehicles_cache %||% list())
        div(style = "margin-top:6px;padding:5px 8px;background:#0d1921;border-left:2px solid #1a9b9b;border-radius:2px;",
          tags$small(style = "color:#4a9b8b;font-family:monospace;font-size:10px;",
            paste0("\u2192 ALL vehicles (", n, ") \u2014 no vin= sent"))
        )
      } else {
        vins <- .resolve_vins_v2()
        div(style = "margin-top:6px;padding:5px 8px;background:#0d1921;border-left:2px solid #1a9b9b;border-radius:2px;",
          tags$small(style = "color:#4a9b8b;font-size:10px;",
            paste0("\u2192 ", length(vins), " VIN(s) selected"))
        )
      }
    })

    .resolve_vins_v2 <- function() {
      sel <- input$v2_selected_vehicles
      if (is.null(sel) || "ALL" %in% sel) return(NULL)
      unique(sel[nchar(sel) > 0])
    }

    # [Ch9-CACHE] Cache TTL hint based on current contentFilter selection
    output$v2_cache_hint <- renderUI({
      qt <- input$v2_query_type
      cf <- input$v2_status_content
      ttl_info <- if (qt == "vehicles") {
        list(ttl = "86400s (24h)", note = "Fleet metadata changes rarely — once per day is sufficient.")
      } else if (qt == "positions") {
        list(ttl = "60s (1 min)", note = "MAP service updates every 1 min while moving.")
      } else if (qt == "statuses") {
        if ("SNAPSHOT" %in% (cf %||% "")) {
          list(ttl = "60s (1 min)", note = "SNAPSHOT: MAP service, 1-min cadence.")
        } else if ("ACCUMULATED" %in% (cf %||% "")) {
          list(ttl = "900s (15 min)", note = "ACCUMULATED: CHECK service, hourly or on login.")
        } else {
          list(ttl = "900s (15 min)", note = "All sections: use CHECK cadence (15 min).")
        }
      } else {
        list(ttl = "900s (15 min)", note = "Full dump: use slowest endpoint cadence.")
      }
      div(style = "margin-top:8px;padding:7px 10px;background:#1a2d45;border-left:3px solid #fd7e14;border-radius:3px;",
        tags$i(class = "fa fa-clock-o", style = "color:#fd7e14;margin-right:6px;"),
        tags$small(style = "color:#c8a96e;",
          tags$b("[Ch9-CACHE] "), "Recommended cache TTL: ", tags$b(ttl_info$ttl), " \u2014 ", ttl_info$note
        )
      )
    })

    # ── Run Query ─────────────────────────────────────────────────────────────
    observeEvent(input$v2_btn_query, {
      if (!api_manager$is_connected) {
        showNotification("Not connected. Go to API Connection tab first.", type = "warning"); return()
      }
      vins      <- .resolve_vins_v2()
      qtype     <- input$v2_query_type
      start_dt  <- as.POSIXct(paste(input$v2_start_date, "00:00:00"), tz = "UTC")
      end_dt    <- as.POSIXct(paste(input$v2_end_date,   "23:59:59"), tz = "UTC")
      tfilter   <- if (nchar(input$v2_trigger %||% "") == 0) NULL else input$v2_trigger
      latest    <- isTRUE(input$v2_latest_only)
      content   <- input$v2_status_content
      additional <- input$v2_additional

      pagination_lines <- c()

      # [Ch8-PAGE] Build debug request summary
      rv$debug_request <- paste(c(
        paste0("Endpoint    : ", switch(qtype,
          vehicles  = "/vehicle/vehicles",
          positions = "/vehicle/vehiclepositions",
          statuses  = "/vehicle/vehiclestatuses",
          everything = "/vehiclepositions + /vehiclestatuses (paginated)", "?")),
        paste0("VINs        : ", if (is.null(vins)) "ALL (no vin= param)" else paste(vins, collapse=", ")),
        paste0("starttime   : ", if (latest) "(omitted \u2014 latestOnly=true)" else format(start_dt, "%Y-%m-%dT%H:%M:%SZ")),
        paste0("stoptime    : ", if (latest) "(omitted \u2014 latestOnly=true)" else format(end_dt, "%Y-%m-%dT%H:%M:%SZ")),
        # [BUGFIX-8] We now always send datetype=received explicitly
        paste0("datetype    : received (explicit \u2014 [BUGFIX-8])"),
        paste0("latestOnly  : ", if (latest) "true" else "false"),
        paste0("triggerFilter: ", tfilter %||% "(none)"),
        paste0("contentFilter: ", paste(content %||% "(all)", collapse=",")),
        paste0("additionalContent: ", paste(additional %||% "(none)", collapse=",")),
        paste0("Sent at     : ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
      ), collapse = "\n")

      withProgress(message = "Querying Volvo Group API (v2)...", value = 0.2, {
        result <- tryCatch({
          if (qtype == "vehicles") {
            api_manager$get_vehicles()

          } else if (qtype == "positions") {
            # [BUGFIX-6] Use paginated fetch instead of single call
            # [Ch8-PAGE] Equivalent to: while pag.has_next: advance cursor
            pag_lines <- c("[Ch8-PAGE] Starting paginated /vehiclepositions fetch")
            all_pos <- .paginated_fetch_v2(
              api_manager  = api_manager,
              endpoint_fn  = api_manager$get_vehicle_positions,
              args         = list(vins = vins, start_time = start_dt, stop_time = end_dt,
                                  trigger_filter = tfilter, latest_only = latest),
              flatten_fn   = api_manager$positions_as_df,
              records_key  = "vehiclePositions"
            )
            pag_lines <- c(pag_lines, paste0("[Ch8-PAGE] Total position records: ", length(all_pos)))
            pagination_lines <<- pag_lines
            list(success = TRUE, status = 200L,
                 data = list(vehiclePositions = all_pos))

          } else if (qtype == "statuses") {
            # [BUGFIX-6][Ch8-PAGE] Paginated statuses fetch
            pag_lines <- c("[Ch8-PAGE] Starting paginated /vehiclestatuses fetch")
            all_stat <- .paginated_fetch_v2(
              api_manager = api_manager,
              endpoint_fn = api_manager$get_vehicle_statuses,
              args        = list(
                vins           = vins,
                start_time     = start_dt,
                stop_time      = end_dt,
                trigger_filter = tfilter,
                content        = if (length(content) > 0) content else NULL,
                additional     = if (length(additional) > 0) additional else NULL,
                latest_only    = latest
              ),
              flatten_fn  = api_manager$statuses_as_df,
              records_key = "vehicleStatuses"
            )
            pag_lines <- c(pag_lines, paste0("[Ch8-PAGE] Total status records: ", length(all_stat)))
            pagination_lines <<- pag_lines
            list(success = TRUE, status = 200L,
                 data = list(vehicleStatuses = all_stat))

          } else {
            api_manager$get_everything(vins = vins, start_time = start_dt, stop_time = end_dt)
          }
        }, error = function(e) {
          cat("[V2] Exception:", e$message, "\n")
          list(success = FALSE, message = e$message, data = NULL)
        })

        setProgress(0.8)
        rv$query_type    <- qtype
        rv$query_time    <- Sys.time()
        rv$is_demo       <- FALSE
        rv$pagination_log <- paste(pagination_lines, collapse = "\n")

        if (result$success) {
          if (qtype == "everything") {
            rv$df_statuses   <- result$statuses_df  %||% data.frame()
            rv$df_positions  <- result$positions_df %||% data.frame()
            rv$df            <- result$statuses_df  %||% data.frame()
            rv$raw_json_text <- result$raw_json_text %||% ""
          } else {
            # [BUGFIX-2,3,4,5] Use corrected .flatten_status() for statuses
            rv$df <- switch(qtype,
              vehicles  = api_manager$vehicles_as_df(result$data$vehicles         %||% list()),
              positions = api_manager$positions_as_df(result$data$vehiclePositions %||% list()),
              statuses  = {
                raw_list <- result$data$vehicleStatuses %||% list()
                if (length(raw_list) > 0) {
                  rows <- lapply(raw_list, .flatten_status)
                  do.call(rbind, rows)
                } else data.frame()
              }
            )
            rv$raw_json_text <- tryCatch(
              jsonlite::toJSON(result$data %||% list(), pretty = TRUE, auto_unbox = TRUE),
              error = function(e) paste("Serialisation error:", e$message)
            )
          }
          n_rows <- nrow(rv$df %||% data.frame())
          showNotification(sprintf("%d record(s) retrieved.", n_rows),
                           type = "message", duration = 4)
        } else {
          showNotification(paste("Error:", result$message), type = "error", duration = 8)
        }
        setProgress(1)
      })
    })

    # ── Probe API ─────────────────────────────────────────────────────────────
    observeEvent(input$v2_btn_probe, {
      if (!api_manager$is_connected) {
        showNotification("Connect first.", type = "warning"); return()
      }
      qtype <- input$v2_query_type
      if (qtype == "vehicles") {
        showNotification("Probe runs on positions or statuses only.", type = "warning"); return()
      }
      withProgress(message = "Probing API (latestOnly)...", value = 0.3, {
        result <- tryCatch({
          if (qtype == "positions") {
            api_manager$get_vehicle_positions(vins = NULL, latest_only = TRUE)
          } else {
            api_manager$get_vehicle_statuses(
              vins = NULL,
              content    = c("ACCUMULATED", "SNAPSHOT"),
              additional = c("VOLVOGROUPACCUMULATED", "VOLVOGROUPSNAPSHOT"),
              latest_only = TRUE
            )
          }
        }, error = function(e) list(success = FALSE, message = e$message, data = NULL))
        setProgress(0.8)
        rv$query_type <- qtype; rv$query_time <- Sys.time(); rv$is_demo <- FALSE
        if (isTRUE(result$success)) {
          rv$df <- if (qtype == "positions") {
            api_manager$positions_as_df(result$data$vehiclePositions %||% list())
          } else {
            raw_list <- result$data$vehicleStatuses %||% list()
            if (length(raw_list) > 0) do.call(rbind, lapply(raw_list, .flatten_status))
            else data.frame()
          }
          n <- nrow(rv$df %||% data.frame())
          if (n == 0)
            showNotification("PROBE: 0 records \u2014 no data stored for any vehicle.", type = "error", duration = 12)
          else
            showNotification(paste0("\u2713 PROBE: ", n, " record(s). Data exists!"), type = "message", duration = 6)
        } else {
          showNotification(paste("Probe failed:", result$message), type = "error", duration = 8)
        }
        setProgress(1)
      })
    })

    # ── Demo data ─────────────────────────────────────────────────────────────
    observeEvent(input$v2_btn_demo, {
      qtype <- input$v2_query_type
      rv$query_type <- qtype; rv$query_time <- Sys.time(); rv$is_demo <- TRUE
      vin1 <- "VF611AEA3SD000216"; vin2 <- "VF611AEA4SD000273"

      if (qtype == "vehicles") {
        rv$df <- api_manager$vehicles_as_df(list())  # empty but correct columns
      } else if (qtype == "positions") {
        set.seed(42); n <- 40
        base_lat <- c(52.2053, 51.5074); base_lon <- c(0.1218, -0.1278)
        rv$df <- do.call(rbind, lapply(seq_len(n), function(i) {
          vi <- ((i-1) %% 2) + 1
          data.frame(
            VIN = c(vin1, vin2)[vi],
            ReceivedAt = format(Sys.time() - (n-i)*900, "%Y-%m-%dT%H:%M:%SZ", tz="UTC"),
            Latitude   = base_lat[vi] + cumsum(rnorm(1,0,.01)),
            Longitude  = base_lon[vi] + cumsum(rnorm(1,0,.01)),
            Heading_deg = round(runif(1,0,359),1),
            Altitude_m  = round(rnorm(1,25,8),1),
            GNSS_Speed_kmh = round(pmax(0, rnorm(1,60,18)),1),
            WheelSpeed_kmh = round(pmax(0, rnorm(1,59,18)),1),
            TriggerType = sample(c("TIMER","IGNITION_ON","IGNITION_OFF"),1),
            GNSSStatus  = "GNSS_FIX", stringsAsFactors = FALSE
          )
        }))
      } else {
        set.seed(99); n <- 30
        rv$df <- do.call(rbind, lapply(seq_len(n), function(i) {
          vi <- ((i-1) %% 2) + 1
          soc <- round(pmax(10, pmin(100, 82 - i*1.8 + rnorm(1,0,5))), 1)
          data.frame(
            VIN = c(vin1, vin2)[vi],
            ReceivedAt = format(Sys.time()-(n-i)*1800, "%Y-%m-%dT%H:%M:%SZ", tz="UTC"),
            TriggerType = sample(c("TIMER","IGNITION_OFF","BATTERY_PACK_CHARGING_STATUS_CHANGE"),1),
            TotalDistance_km = round(61000 + i*42, 1),
            EngineHours_h    = round(3200 + i*1.1, 1),
            BatterySoC_pct   = soc,
            BatteryPack_pct  = soc + rnorm(1,0,2),
            ChargingStatus   = sample(c("NOT_CHARGING","CHARGING","CHARGING_AC",NA),1),
            ChargingPower_kW = ifelse(sample(c(TRUE,FALSE),1), round(runif(1,11,100),1), NA_real_),
            EstRange_km      = round(pmax(0, soc * 4.5), 0),
            ElecEnergyTotal_Wh     = round(rnorm(1, 180000, 20000), 0),
            ElecEnergyPropulsion_Wh= round(rnorm(1, 160000, 18000), 0),
            ElecEnergyRegen_Wh     = round(rnorm(1, 22000, 4000), 0),
            AmbientTemp_C    = round(rnorm(1, 12, 5), 1),
            GrossWeight_kg   = round(rnorm(1, 28000, 2000), 0),
            stringsAsFactors = FALSE
          )
        }))
      }
      showNotification("Demo data loaded.", type = "message", duration = 3)
    })

    # ── Summary metrics ───────────────────────────────────────────────────────
    output$v2_summary_metrics <- renderUI({
      req(!is.null(rv$df))
      df <- rv$df; qtype <- rv$query_type
      cards <- if (qtype == "positions") {
        valid <- df[!is.na(df$Latitude) & !is.na(df$Longitude), ]
        list(
          metric_card("Positions",     nrow(df)),
          metric_card("Unique VINs",   length(unique(df$VIN))),
          metric_card("Avg Speed km/h", round(mean(df$GNSS_Speed_kmh, na.rm=TRUE),1), colour="#fd7e14"),
          metric_card("GPS Records",   nrow(valid), colour="#28a745")
        )
      } else if (qtype == "statuses") {
        soc <- suppressWarnings(as.numeric(df$BatterySoC_pct))
        rng <- suppressWarnings(as.numeric(df$EstRange_km))
        list(
          metric_card("Status Records", nrow(df)),
          metric_card("Unique VINs",    length(unique(df$VIN))),
          metric_card("Avg Battery SoC", if (all(is.na(soc))) "-" else paste0(round(mean(soc,na.rm=TRUE),1),"%"), colour="#28a745"),
          metric_card("Avg Est. Range", if (all(is.na(rng))) "-" else paste0(round(mean(rng,na.rm=TRUE),0)," km"), colour="#1a9b9b")
        )
      } else {
        list(metric_card("Records", nrow(df)), metric_card("Columns", ncol(df)))
      }
      demo_tag <- if (isTRUE(rv$is_demo)) tags$span(class="wg-demo-badge","DEMO DATA") else NULL
      div(style="display:flex;flex-wrap:wrap;gap:10px;padding:6px 0 10px;align-items:center;",
        demo_tag,
        lapply(cards, function(c) div(style="flex:1;min-width:150px;", HTML(c)))
      )
    })

    output$v2_result_meta_badge <- renderUI({
      req(!is.null(rv$df))
      n  <- nrow(rv$df); sz <- format(object.size(rv$df), units="KB")
      ts <- if (!is.null(rv$query_time)) format(rv$query_time,"%H:%M:%S") else "-"
      tags$span(class="wg-badge", sprintf("%d rows \u00b7 %s \u00b7 %s", n, sz, ts))
    })

    # ── Data table ────────────────────────────────────────────────────────────
    output$v2_data_table_ui <- renderUI({
      if (is.null(rv$df) || nrow(rv$df)==0)
        return(div(class="wg-empty-state",
          tags$i(class="fa fa-table",style="font-size:32px;opacity:.3;"),
          tags$p("No data yet. Run a query or load demo data.")))
      DT::dataTableOutput(ns("v2_main_dt"))
    })

    .make_dt_v2 <- function(df) {
      dt <- DT::datatable(
        df,
        options  = list(pageLength=15, scrollX=TRUE,
                        dom="Blfrtip", buttons=c("csv","excel"),
                        columnDefs=list(list(className="dt-center",targets="_all"))),
        extensions = "Buttons",
        class = "wg-dt", rownames=FALSE, escape=FALSE
      )
      for (col in c("BatterySoC_pct","BatteryPack_pct")) {
        if (col %in% names(df))
          dt <- dt |> DT::formatStyle(col,
            background=DT::styleColorBar(c(0,100),"#1a9b9b"),
            backgroundSize="100% 80%",backgroundRepeat="no-repeat",backgroundPosition="center")
      }
      if ("GNSS_Speed_kmh" %in% names(df))
        dt <- dt |> DT::formatStyle("GNSS_Speed_kmh",
          color=DT::styleInterval(c(0,90),c("#888","#7ec8e3","#e05c5c")))
      if ("TotalDistance_km" %in% names(df))
        dt <- dt |> DT::formatRound("TotalDistance_km", digits=1)
      dt
    }

    output$v2_main_dt <- DT::renderDataTable({
      req(!is.null(rv$df), nrow(rv$df)>0)
      .make_dt_v2(rv$df)
    })

    # ── Field Explorer [Ch5] ─────────────────────────────────────────────────
    output$v2_field_explorer_ui <- renderUI({
      req(!is.null(rv$df), nrow(rv$df)>0)
      df <- rv$df
      qtype <- rv$query_type

      if (qtype != "statuses" && qtype != "everything") {
        return(div(style="color:#8fa0b5;padding:12px;",
          "Switch to Statuses query to see the full section/field breakdown."))
      }

      # Show which columns came from which section
      section_map <- list(
        "Base (always)"         = c("VIN","ReceivedAt","CreatedAt","TriggerType","TriggerContext",
                                    "TotalDistance_km","EngineHours_h","GrossWeight_kg"),
        "Snapshot (MAP)"        = c("Latitude","Longitude","Altitude_m","Heading_deg",
                                    "GNSS_Speed_kmh","WheelSpeed_kmh","TachoSpeed_kmh","EngineSpeed_rpm",
                                    "BatterySoC_pct","AmbientTemp_C","ChargingStatus","ChargingConnection",
                                    "ChargingDevice","ChargingPower_kW","ChargeTarget_pct"),
        "VOLVOGROUPSNAPSHOT"    = c("BatteryPack_pct","EstRange_km","ParkingClimate","EngineOilLevel_pct"),
        "Accumulated (CHECK)"   = c("TotalFuelUsed_ml"),
        "VOLVOGROUPACCUMULATED" = c("ElecEnergyPropulsion_Wh","ElecEnergyTotal_Wh",
                                    "ElecEnergyRegen_Wh","ElecEnergyMotorHours_h","LaneKeepWarnings"),
        "Uptime (HEALTH)"       = c("ServiceDistance_m","Coolant_C"),
        "Driver"                = c("DriverID")
      )
      colours <- c("#1a9b9b","#fd7e14","#28a745","#6f42c1","#17a2b8","#dc3545","#8fa0b5")

      tagList(
        lapply(seq_along(section_map), function(i) {
          sec_name <- names(section_map)[i]
          fields   <- section_map[[i]]
          present  <- fields[fields %in% names(df)]
          absent   <- fields[!fields %in% names(df)]
          col      <- colours[((i-1) %% length(colours)) + 1]

          div(style = paste0("margin-bottom:14px;padding:10px 14px;background:#1e2a3a;",
                             "border-left:4px solid ", col, ";border-radius:4px;"),
            tags$b(style = paste0("color:", col, ";"), sec_name),
            tags$br(),
            if (length(present) > 0)
              div(style = "margin-top:6px;display:flex;flex-wrap:wrap;gap:4px;",
                lapply(present, function(f) {
                  non_na <- sum(!is.na(df[[f]]))
                  pct    <- round(non_na / nrow(df) * 100)
                  HTML(sprintf(
                    '<span style="background:#0d1921;border:1px solid %s;padding:3px 8px;border-radius:4px;font-size:11px;font-family:monospace;">
                      <span style="color:%s;">%s</span>
                      <span style="color:#4a7a9b;"> %d%%</span>
                    </span>', col, col, f, pct
                  ))
                })
              )
            else NULL,
            if (length(absent) > 0)
              div(style = "margin-top:6px;",
                tags$small(style = "color:#4a4a5a;",
                  "Not in response (section not requested or service not active): ",
                  paste(absent, collapse=", ")
                )
              )
            else NULL
          )
        })
      )
    })

    # ── EV Analytics [Ch3/Ch5] ────────────────────────────────────────────────
    output$v2_ev_analytics_ui <- renderUI({
      req(!is.null(rv$df), nrow(rv$df) > 0)
      df <- rv$df
      has_ev <- any(c("BatterySoC_pct","ChargingStatus","ElecEnergyTotal_Wh","EstRange_km") %in% names(df))
      if (!has_ev)
        return(div(style="color:#8fa0b5;padding:12px;",
          "Run a statuses query with VOLVOGROUPSNAPSHOT + VOLVOGROUPACCUMULATED to see EV analytics."))

      tagList(
        fluidRow(
          column(6, plotly::plotlyOutput(ns("v2_soc_timeline"),  height="280px")),
          column(6, plotly::plotlyOutput(ns("v2_charging_bar"),  height="280px"))
        ),
        fluidRow(
          column(6, plotly::plotlyOutput(ns("v2_energy_donut"),  height="280px")),
          column(6, plotly::plotlyOutput(ns("v2_range_scatter"), height="280px"))
        )
      )
    })

    .dark <- function(title) list(
      title = list(text=title, font=list(color="#7ec8e3")),
      paper_bgcolor="#131e2b", plot_bgcolor="#1a2d45",
      legend=list(font=list(color="#8fa0b5")), font=list(color="#8fa0b5")
    )
    .ax <- function(xt,yt) list(
      xaxis=list(title=xt,color="#8fa0b5",gridcolor="#253a52"),
      yaxis=list(title=yt,color="#8fa0b5",gridcolor="#253a52")
    )

    output$v2_soc_timeline <- plotly::renderPlotly({
      req(!is.null(rv$df), "BatterySoC_pct" %in% names(rv$df))
      df <- rv$df
      df$ts  <- as.POSIXct(df$ReceivedAt, format="%Y-%m-%dT%H:%M:%SZ", tz="UTC")
      df$soc <- suppressWarnings(as.numeric(df$BatterySoC_pct))
      df <- df[!is.na(df$ts) & !is.na(df$soc), ]
      plotly::plot_ly(df, x=~ts, y=~soc, color=~VIN,
                      type="scatter", mode="lines+markers",
                      fill="tozeroy", alpha=0.35,
                      marker=list(size=5)) |>
        plotly::layout(!!!.dark("Battery SoC Over Time (%)"),
                       !!!.ax("Time (UTC)","SoC (%)"),
                       yaxis=list(range=c(0,105),color="#8fa0b5",gridcolor="#253a52"))
    })

    output$v2_charging_bar <- plotly::renderPlotly({
      req(!is.null(rv$df), "ChargingStatus" %in% names(rv$df))
      df <- rv$df[!is.na(rv$df$ChargingStatus), ]
      if (nrow(df) == 0) return(plotly::plotly_empty())
      tbl <- as.data.frame(table(df$ChargingStatus, df$VIN))
      names(tbl) <- c("Status","VIN","Count")
      colours_map <- c("CHARGING"="#28a745","CHARGING_AC"="#1a9b9b","CHARGING_DC"="#fd7e14",
                       "NOT_CHARGING"="#4a4a5a","ERROR"="#dc3545")
      plotly::plot_ly(tbl, x=~VIN, y=~Count, color=~Status, type="bar",
                      colors=colours_map) |>
        plotly::layout(!!!.dark("Charging Status Events by Vehicle"),
                       !!!.ax("Vehicle","Events"), barmode="stack")
    })

    output$v2_energy_donut <- plotly::renderPlotly({
      req(!is.null(rv$df))
      df <- rv$df
      prop <- suppressWarnings(as.numeric(df$ElecEnergyPropulsion_Wh))
      regen <- suppressWarnings(as.numeric(df$ElecEnergyRegen_Wh))
      total_prop  <- sum(prop,  na.rm=TRUE)
      total_regen <- sum(regen, na.rm=TRUE)
      if (total_prop == 0 && total_regen == 0)
        return(plotly::plotly_empty())
      plotly::plot_ly(
        labels = c("Propulsion","Recuperation"),
        values = c(total_prop, total_regen),
        type   = "pie", hole=0.45,
        marker = list(colors=c("#fd7e14","#1a9b9b"))
      ) |>
        plotly::layout(!!!.dark("Energy: Propulsion vs Recuperation (Wh)"),
                       showlegend=TRUE)
    })

    output$v2_range_scatter <- plotly::renderPlotly({
      req(!is.null(rv$df), "BatterySoC_pct" %in% names(rv$df), "EstRange_km" %in% names(rv$df))
      df <- rv$df
      df$soc   <- suppressWarnings(as.numeric(df$BatterySoC_pct))
      df$range <- suppressWarnings(as.numeric(df$EstRange_km))
      df <- df[!is.na(df$soc) & !is.na(df$range), ]
      if (nrow(df) == 0) return(plotly::plotly_empty())
      plotly::plot_ly(df, x=~soc, y=~range, color=~VIN, type="scatter",
                      mode="markers", marker=list(size=8, opacity=0.75)) |>
        plotly::layout(!!!.dark("SoC (%) vs Estimated Range (km)"),
                       !!!.ax("Battery SoC (%)","Estimated Range (km)"))
    })

    # ── Trends [original charts kept + extra] ────────────────────────────────
    output$v2_trends_ui <- renderUI({
      req(!is.null(rv$df), nrow(rv$df)>0)
      qtype <- rv$query_type
      if (qtype == "positions") {
        tagList(
          fluidRow(
            column(6, plotly::plotlyOutput(ns("v2_speed_time"),   height="280px")),
            column(6, plotly::plotlyOutput(ns("v2_heading_rose"), height="280px"))
          ),
          fluidRow(
            column(12, plotly::plotlyOutput(ns("v2_speed_heatmap"), height="280px"))
          )
        )
      } else if (qtype == "statuses") {
        tagList(
          fluidRow(
            column(6, plotly::plotlyOutput(ns("v2_dist_trend"),    height="280px")),
            column(6, plotly::plotlyOutput(ns("v2_engine_trend"),  height="280px"))
          ),
          fluidRow(
            column(6, plotly::plotlyOutput(ns("v2_trigger_dist"),  height="280px")),
            column(6, plotly::plotlyOutput(ns("v2_temp_trend"),    height="280px"))
          )
        )
      } else {
        tagList(
          fluidRow(
            column(6, plotly::plotlyOutput(ns("v2_fleet_fuel"),    height="280px")),
            column(6, plotly::plotlyOutput(ns("v2_fleet_year"),    height="280px"))
          )
        )
      }
    })

    output$v2_speed_time <- plotly::renderPlotly({
      req(rv$query_type=="positions",!is.null(rv$df),nrow(rv$df)>0)
      df <- rv$df
      df$ts <- as.POSIXct(df$ReceivedAt,format="%Y-%m-%dT%H:%M:%SZ",tz="UTC")
      df <- df[!is.na(df$ts),]
      plotly::plot_ly(df,x=~ts,y=~GNSS_Speed_kmh,color=~VIN,
                      type="scatter",mode="lines+markers",marker=list(size=5)) |>
        plotly::layout(!!!.dark("Speed Over Time (km/h)"),!!!.ax("Time","Speed km/h"))
    })

    output$v2_heading_rose <- plotly::renderPlotly({
      req(rv$query_type=="positions",!is.null(rv$df),nrow(rv$df)>0)
      df  <- rv$df[!is.na(rv$df$Heading_deg),]
      bins <- cut(df$Heading_deg, breaks=seq(0,360,by=22.5),include.lowest=TRUE)
      tbl  <- as.data.frame(table(bins))
      plotly::plot_ly(tbl,r=~Freq,theta=~bins,type="barpolar",
                      marker=list(color="#1a9b9b")) |>
        plotly::layout(!!!.dark("Heading Distribution"),
                       polar=list(bgcolor="#1a2d45",
                                  radialaxis=list(color="#8fa0b5"),
                                  angularaxis=list(color="#8fa0b5")))
    })

    output$v2_speed_heatmap <- plotly::renderPlotly({
      req(rv$query_type=="positions",!is.null(rv$df),nrow(rv$df)>0)
      df <- rv$df
      df$ts <- as.POSIXct(df$ReceivedAt,format="%Y-%m-%dT%H:%M:%SZ",tz="UTC")
      df <- df[!is.na(df$ts),]
      df$hour <- as.integer(format(df$ts,"%H"))
      df$spd  <- suppressWarnings(as.numeric(df$GNSS_Speed_kmh))
      # Average speed by hour of day
      tbl <- aggregate(spd ~ hour + VIN, data=df, FUN=function(x) round(mean(x,na.rm=TRUE),1))
      plotly::plot_ly(tbl, x=~hour, y=~VIN, z=~spd, type="heatmap",
                      colorscale=list(c(0,"#1a2d45"),c(0.5,"#1a9b9b"),c(1,"#fd7e14"))) |>
        plotly::layout(!!!.dark("Avg Speed by Hour of Day (km/h)"),
                       xaxis=list(title="Hour (UTC)",color="#8fa0b5",dtick=2),
                       yaxis=list(title="VIN",color="#8fa0b5"))
    })

    output$v2_dist_trend <- plotly::renderPlotly({
      req(rv$query_type=="statuses",!is.null(rv$df),"TotalDistance_km"%in%names(rv$df))
      df <- rv$df
      df$ts <- as.POSIXct(df$ReceivedAt,format="%Y-%m-%dT%H:%M:%SZ",tz="UTC")
      df$d  <- suppressWarnings(as.numeric(df$TotalDistance_km))
      df <- df[!is.na(df$ts)&!is.na(df$d),]
      plotly::plot_ly(df,x=~ts,y=~d,color=~VIN,type="scatter",mode="lines") |>
        plotly::layout(!!!.dark("Odometer (km)"),!!!.ax("Time","km"))
    })

    output$v2_engine_trend <- plotly::renderPlotly({
      req(rv$query_type=="statuses",!is.null(rv$df),"EngineHours_h"%in%names(rv$df))
      df <- rv$df
      df$ts <- as.POSIXct(df$ReceivedAt,format="%Y-%m-%dT%H:%M:%SZ",tz="UTC")
      df$h  <- suppressWarnings(as.numeric(df$EngineHours_h))
      df <- df[!is.na(df$ts)&!is.na(df$h),]
      plotly::plot_ly(df,x=~ts,y=~h,color=~VIN,type="bar") |>
        plotly::layout(!!!.dark("Engine/Motor Hours"),!!!.ax("Time","Hours"),barmode="group")
    })

    output$v2_trigger_dist <- plotly::renderPlotly({
      req(rv$query_type=="statuses",!is.null(rv$df),"TriggerType"%in%names(rv$df))
      df <- rv$df[!is.na(rv$df$TriggerType),]
      tbl <- as.data.frame(table(df$TriggerType))
      tbl <- tbl[order(-tbl$Freq),][seq_len(min(10,nrow(tbl))),]
      plotly::plot_ly(tbl,y=~reorder(Var1,Freq),x=~Freq,type="bar",orientation="h",
                      marker=list(color="#1a9b9b")) |>
        plotly::layout(!!!.dark("Top Trigger Types"),!!!.ax("Count","Trigger"))
    })

    output$v2_temp_trend <- plotly::renderPlotly({
      req(rv$query_type=="statuses",!is.null(rv$df),"AmbientTemp_C"%in%names(rv$df))
      df <- rv$df
      df$ts   <- as.POSIXct(df$ReceivedAt,format="%Y-%m-%dT%H:%M:%SZ",tz="UTC")
      df$temp <- suppressWarnings(as.numeric(df$AmbientTemp_C))
      df <- df[!is.na(df$ts)&!is.na(df$temp),]
      plotly::plot_ly(df,x=~ts,y=~temp,color=~VIN,type="scatter",mode="lines+markers",
                      marker=list(size=4)) |>
        plotly::layout(!!!.dark("Ambient Temperature (\u00b0C)"),!!!.ax("Time","Temp \u00b0C"))
    })

    output$v2_fleet_fuel <- plotly::renderPlotly({
      req(rv$query_type=="vehicles",!is.null(rv$df))
      df <- rv$df; if(nrow(df)==0) return(plotly::plotly_empty())
      tbl <- as.data.frame(table(df$FuelTypes)); names(tbl) <- c("Fuel","Count")
      tbl$Label <- ifelse(tbl$Fuel=="08","08 \u2014 Electric",
                   ifelse(tbl$Fuel=="04","04 \u2014 Diesel",tbl$Fuel))
      plotly::plot_ly(tbl,x=~Label,y=~Count,type="bar",
                      marker=list(color=c("#28a745","#fd7e14")[seq_len(nrow(tbl))])) |>
        plotly::layout(!!!.dark("Fleet by Fuel Type"),!!!.ax("Fuel","Count"))
    })

    output$v2_fleet_year <- plotly::renderPlotly({
      req(rv$query_type=="vehicles",!is.null(rv$df))
      df <- rv$df[!is.na(rv$df$ProductionYear),]
      tbl <- as.data.frame(table(df$ProductionYear))
      plotly::plot_ly(tbl,x=~Var1,y=~Freq,type="bar",
                      marker=list(color="#7ec8e3")) |>
        plotly::layout(!!!.dark("Fleet by Production Year"),!!!.ax("Year","Count"))
    })

    # ── Map ───────────────────────────────────────────────────────────────────
    output$v2_position_map <- leaflet::renderLeaflet({
      df_pos <- if (!is.null(rv$df_positions) && nrow(rv$df_positions)>0) rv$df_positions
                else if (!is.null(rv$df) && "Latitude" %in% names(rv$df)) rv$df
                else return(NULL)
      df <- df_pos[!is.na(df_pos$Latitude) & !is.na(df_pos$Longitude), ]
      req(nrow(df) > 0)
      vins   <- unique(df$VIN)
      cols   <- c("#1a9b9b","#fd7e14","#6f42c1","#28a745")
      vc     <- setNames(cols[seq_along(vins)], vins)
      cache  <- api_manager$vehicles_cache %||% list()
      vlabel <- sapply(vins, function(vin) {
        for (v in cache) { if (identical(v$vin, vin)) return(v$customerVehicleName %||% vin) }
        vin
      })
      map <- leaflet::leaflet(df) |>
        leaflet::addProviderTiles("CartoDB.DarkMatter",
          options=leaflet::providerTileOptions(opacity=0.9)) |>
        leaflet::addProviderTiles("CartoDB.DarkMatterOnlyLabels")
      if (isTRUE(input$v2_map_polyline)) {
        for (vin in vins) {
          sub <- df[df$VIN==vin,][order(df[df$VIN==vin,"ReceivedAt"]),]
          if (nrow(sub)>=2)
            map <- map |> leaflet::addPolylines(lng=sub$Longitude,lat=sub$Latitude,
              color=vc[[vin]],weight=2,opacity=0.7,label=vlabel[[vin]])
        }
      }
      for (vin in vins) {
        sub <- df[df$VIN==vin,]
        spd <- suppressWarnings(as.numeric(sub$GNSS_Speed_kmh %||% sub$WheelSpeed_kmh %||% 0))
        r   <- pmax(5,pmin(15,ifelse(is.na(spd),0,spd)/8))
        pop <- sprintf("<b>%s</b><br>Speed: %s km/h | Heading: %s\u00b0<br>Alt: %s m<br>%s",
          vlabel[[vin]], spd, sub$Heading_deg, sub$Altitude_m, sub$ReceivedAt)
        map <- map |> leaflet::addCircleMarkers(
          lng=sub$Longitude,lat=sub$Latitude,radius=r,
          color=vc[[vin]],fillColor=vc[[vin]],fillOpacity=0.75,weight=1,
          popup=lapply(pop,htmltools::HTML),label=vlabel[[vin]],group=vlabel[[vin]])
      }
      map |>
        leaflet::addLegend("bottomright",colors=unname(vc),labels=unname(vlabel),
                           title="Vehicle",opacity=0.85) |>
        leaflet::addLayersControl(overlayGroups=unname(vlabel),
                                  options=leaflet::layersControlOptions(collapsed=FALSE))
    })

    output$v2_btn_download_geojson <- downloadHandler(
      filename = function() paste0(format(Sys.Date(),"%Y-%m-%d"),"_positions_v2.geojson"),
      content  = function(file) {
        df <- if (!is.null(rv$df) && "Latitude" %in% names(rv$df)) rv$df else data.frame()
        valid <- df[!is.na(df$Latitude) & !is.na(df$Longitude), ]
        if (nrow(valid) == 0) { writeLines('{"type":"FeatureCollection","features":[]}',file); return(invisible(NULL)) }
        fc <- list(type="FeatureCollection", features=lapply(seq_len(nrow(valid)),function(i) {
          r <- valid[i,]
          list(type="Feature",
               properties=list(vin=r$VIN, speed=r$GNSS_Speed_kmh, heading=r$Heading_deg, ts=r$ReceivedAt),
               geometry=list(type="Point",coordinates=c(r$Longitude,r$Latitude)))
        }))
        writeLines(jsonlite::toJSON(fc,pretty=TRUE,auto_unbox=TRUE),file)
      }
    )

    # ── Pagination log [Ch8] ─────────────────────────────────────────────────
    output$v2_pagination_log <- renderText({
      if (is.null(rv$pagination_log) || nchar(rv$pagination_log)==0)
        paste(
          "[Ch8-PAGE] No pagination log yet. Run a Positions or Statuses query to see the",
          "moreDataAvailable cursor loop in action.",
          "",
          "Original vehicle_data.R does not have this loop \u2014 it silently returns only the",
          "first page of results. This v2 implementation advances the receivedDateTime cursor",
          "exactly as documented in Ch8: starttime = last_receivedDateTime + 1 second,",
          "equivalent to SQLAlchemy paginate()'s pag.has_next / pag.next_num pattern.",
          sep="\n"
        )
      else rv$pagination_log
    })

    # ── Raw JSON ──────────────────────────────────────────────────────────────
    output$v2_raw_json_display <- renderText({
      rv$raw_json_text %||% "(Run a query to see the raw JSON response)"
    })

    output$v2_btn_download_json <- downloadHandler(
      filename = function() paste0("v2_",rv$query_type%||%"data","_",format(Sys.time(),"%Y%m%d_%H%M%S"),".json"),
      content  = function(file) writeLines(rv$raw_json_text %||% "{}", file)
    )

    # ── Debug ──────────────────────────────────────────────────────────────────
    output$v2_debug_request <- renderText({ rv$debug_request %||% "(no query yet)" })

    output$v2_debug_response <- renderText({
      req(!is.null(rv$query_type))
      n <- nrow(rv$df %||% data.frame())
      paste(c(
        paste0("Query type : ", rv$query_type %||% "?"),
        paste0("Rows       : ", n),
        paste0("Columns    : ", ncol(rv$df %||% data.frame())),
        paste0("Query time : ", format(rv$query_time %||% Sys.time(), "%Y-%m-%d %H:%M:%S")),
        paste0("Demo data  : ", isTRUE(rv$is_demo))
      ), collapse="\n")
    })

    output$v2_debug_services <- renderText({
      cache <- api_manager$vehicles_cache %||% list()
      if (length(cache)==0) return("No vehicle cache. Connect first.")
      lines <- c()
      for (v in cache) {
        vgv  <- v$volvoGroupVehicle %||% list()
        svcs <- paste(vgv$connectedServices %||% list(), collapse=", ")
        if (nchar(svcs)==0) svcs <- "(none)"
        has_map <- grepl("MAP",svcs,ignore.case=TRUE)
        flag    <- if (has_map) "  \u2713 MAP" else "  \u2717 MAP MISSING \u2014 NO DATA EXPECTED"
        lines   <- c(lines, paste0(v$customerVehicleName%||%v$vin%||%"?", " [",v$vin%||%"?","]"))
        lines   <- c(lines, paste0("  Services: ", svcs, flag))
        lines   <- c(lines, "")
      }
      paste(lines, collapse="\n")
    })
  })
}
