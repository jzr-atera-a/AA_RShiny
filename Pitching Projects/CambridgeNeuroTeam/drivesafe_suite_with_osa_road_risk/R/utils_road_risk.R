# R/utils_road_risk.R
# ===============================================================================
# Shared data layer for the "OSA Road Risk & Interventions" module group
# (driver_road_risk_map, driver_road_risk_corridors, driver_road_risk_interventions)
#
# Provides a single source of truth for:
#   - the simulated UK road corridor network (17 corridors, real-world anchor
#     coordinates, no shapefiles / rasters / Terra dependency of any kind)
#   - the OSA road-risk scoring formula
#   - incident + rest-area/sleep-clinic point data
#   - shared colour scale + label helpers
#
# IMPORTANT: this file must never load {terra}, {raster}, {sp}-based raster
# tools, {leaflet}, or any package that pulls Terra/raster into the
# dependency tree (this includes {leaflet} itself, which Imports {raster}
# which Imports {terra} - that transitive chain is what broke
# `renv::snapshot()` on shinyapps.io). All spatial rendering downstream
# uses plotly::plot_ly(type = "scattermapbox") instead (see
# driver_road_risk_map/server.R), which depends on nothing beyond {plotly}.
# ===============================================================================

`%||%` <- function(x, y) if (is.null(x)) y else x

# ── OSA groups (kept consistent with the rest of the DriveSafe Suite) ─────────
OSA_GROUP_LABELS <- c(
  control       = "Control (No OSA)",
  osa_treated   = "OSA - CPAP Treated",
  osa_untreated = "OSA - Untreated"
)

OSA_GROUP_COLOURS <- c(
  control       = "#008A82",  # teal
  osa_treated   = "#27ae60",  # green
  osa_untreated = "#e74c3c"   # red
)

# ── Risk score colour scale (matches DriveSafe global scale) ──────────────────
# 0-25 Low | 25-50 Moderate | 50-75 High | 75-100 Critical
risk_colour <- function(score) {
  score <- as.numeric(score)
  out <- rep("#1a6b35", length(score))
  out[score >= 25 & score < 50] <- "#d4ac0d"
  out[score >= 50 & score < 75] <- "#e67e22"
  out[score >= 75]              <- "#c0392b"
  out[is.na(score)]             <- "#999999"
  out
}

risk_category <- function(score) {
  score <- as.numeric(score)
  out <- rep("Low", length(score))
  out[score >= 25 & score < 50] <- "Moderate"
  out[score >= 50 & score < 75] <- "High"
  out[score >= 75]              <- "Critical"
  out
}

RISK_SCALE_LABELS  <- c("Low (0-25)", "Moderate (25-50)", "High (50-75)", "Critical (75-100)")
RISK_SCALE_COLOURS <- c("#1a6b35", "#d4ac0d", "#e67e22", "#c0392b")

# ── Time-of-day windows ────────────────────────────────────────────────────────
TIME_WINDOWS <- c("00-06", "06-10", "10-14", "14-18", "18-24")
TIME_WINDOW_LABELS <- c(
  "00-06" = "Night / Early Morning (00:00-06:00)",
  "06-10" = "Morning Commute (06:00-10:00)",
  "10-14" = "Midday (10:00-14:00)",
  "14-18" = "Afternoon (14:00-18:00)",
  "18-24" = "Evening / Night (18:00-24:00)"
)
# Circadian alertness dips are the physiological reason OSA-related fatigue
# risk peaks in the early hours and again in the evening window.
TIME_WINDOW_MULT <- c("00-06" = 1.35, "06-10" = 0.85, "10-14" = 0.78,
                       "14-18" = 0.92, "18-24" = 1.15)

# ── Road types ─────────────────────────────────────────────────────────────────
ROAD_TYPE_LABELS <- c(
  motorway = "Motorway",
  a_road   = "A-Road",
  b_road   = "B-Road",
  urban    = "Urban"
)
ROAD_TYPE_BASE_RISK <- c(motorway = 18, a_road = 28, b_road = 38, urban = 32)

# ── OSA group risk uplift (points added to base risk) ─────────────────────────
OSA_GROUP_UPLIFT <- c(control = 0, osa_treated = 10, osa_untreated = 22)

# ── 17 simulated UK corridors, anchored to real-world approximate coordinates ─
# geom_type: "line" (start->end path), "loop" (orbital), "cluster" (urban / B-road area)
uk_osa_corridors <- data.frame(
  corridor_id   = sprintf("C%02d", 1:17),
  corridor_name = c("M1", "M6", "M25", "M4", "M62", "M8", "M74", "A1",
                     "A30", "A14", "A55", "A57", "A406 North Circular",
                     "B-Roads West Midlands", "Urban Leeds",
                     "Urban Manchester", "Urban Birmingham"),
  road_type     = c("motorway","motorway","motorway","motorway","motorway",
                     "motorway","motorway","a_road","a_road","a_road","a_road",
                     "a_road","a_road","b_road","urban","urban","urban"),
  geom_type     = c("line","line","loop","line","line","line","line","line",
                     "line","line","line","line","loop","cluster","cluster",
                     "cluster","cluster"),
  lat1 = c(51.53, 52.37, 51.50, 51.49, 53.40, 55.86, 54.99, 51.53, 50.73,
           51.96, 53.19, 53.48, 51.57, 52.45, 53.80, 53.48, 52.48),
  lng1 = c(-0.13, -1.25, -0.25, -0.35, -2.90, -4.25, -3.05, -0.10, -3.53,
           1.35,  -2.89, -2.24, -0.15, -1.93, -1.55, -2.24, -1.90),
  lat2 = c(53.80, 54.89, NA,   51.62, 53.75, 55.95, 55.80, 55.95, 50.07,
           52.37, 53.31, 53.38, NA,   NA,    NA,    NA,    NA),
  lng2 = c(-1.55, -2.93, NA,   -3.94, -0.33, -3.19, -3.90, -3.19, -5.68,
           -1.25, -4.63, -1.47, NA,   NA,    NA,    NA,    NA),
  stringsAsFactors = FALSE
)

# ── Real intermediate waypoints for the 11 "line" corridors ───────────────────
# Straight start->end interpolation looked unrealistic (a UK motorway is never
# a straight line). Each of these follows real towns/cities the road actually
# passes through, so the simulated corridor traces something recognisable on
# the map. M25 and A406 stay as ellipse loops (geom_type "loop", unchanged).
uk_osa_corridor_waypoints <- list(
  C01 = data.frame(  # M1: London -> Leeds
    lat = c(51.53, 51.88, 52.24, 52.64, 52.95, 53.38, 53.80),
    lng = c(-0.13, -0.42, -0.90, -1.13, -1.15, -1.47, -1.55)),
  C02 = data.frame(  # M6: Rugby -> Carlisle
    lat = c(52.37, 52.55, 53.00, 53.39, 53.76, 54.05, 54.89),
    lng = c(-1.25, -1.85, -2.18, -2.60, -2.70, -2.80, -2.93)),
  C04 = data.frame(  # M4: London -> Swansea
    lat = c(51.49, 51.45, 51.56, 51.48, 51.58, 51.48, 51.62),
    lng = c(-0.35, -0.97, -1.78, -2.58, -2.99, -3.18, -3.94)),
  C05 = data.frame(  # M62: Liverpool -> Hull
    lat = c(53.40, 53.48, 53.65, 53.80, 53.70, 53.75),
    lng = c(-2.90, -2.24, -1.78, -1.55, -0.87, -0.33)),
  C06 = data.frame(  # M8: Glasgow -> Edinburgh
    lat = c(55.86, 55.88, 55.95),
    lng = c(-4.25, -3.52, -3.19)),
  C07 = data.frame(  # M74: Gretna -> Glasgow
    lat = c(54.99, 55.12, 55.48, 55.80),
    lng = c(-3.05, -3.36, -3.68, -3.90)),
  C08 = data.frame(  # A1: London -> Edinburgh
    lat = c(51.53, 52.57, 52.91, 53.52, 54.97, 55.95),
    lng = c(-0.10, -0.24, -0.64, -1.13, -1.61, -3.19)),
  C09 = data.frame(  # A30: Exeter -> Land's End
    lat = c(50.73, 50.74, 50.47, 50.12, 50.07),
    lng = c(-3.53, -4.01, -4.72, -5.54, -5.68)),
  C10 = data.frame(  # A14: Felixstowe -> Rugby
    lat = c(51.96, 52.06, 52.21, 52.33, 52.40, 52.37),
    lng = c(1.35,  1.15,  0.12, -0.18, -0.72, -1.25)),
  C11 = data.frame(  # A55: Chester -> Holyhead
    lat = c(53.19, 53.26, 53.29, 53.23, 53.31),
    lng = c(-2.89, -3.44, -3.73, -4.13, -4.63)),
  C12 = data.frame(  # A57: Manchester -> Sheffield (Snake Pass)
    lat = c(53.48, 53.44, 53.43, 53.38),
    lng = c(-2.24, -1.95, -1.85, -1.47))
)

# ── Generate stable (seeded) sample points along every corridor ───────────────
# Each point carries a fixed spatial-noise offset so that repeated reactive
# re-renders never jitter the map, while risk *level* still varies
# realistically point-to-point (junctions, gradients, local conditions).
.generate_corridor_points <- function(corridors, n_per_line = 24, n_per_cluster = 30) {
  all_pts <- lapply(seq_len(nrow(corridors)), function(i) {
    row <- corridors[i, ]
    set.seed(1000 + i)  # stable per-corridor seed

    if (row$geom_type == "line") {
      wp <- uk_osa_corridor_waypoints[[row$corridor_id]]
      if (is.null(wp)) wp <- data.frame(lat = c(row$lat1, row$lat2), lng = c(row$lng1, row$lng2))

      # Distribute n_per_line points along the piecewise route, weighted by
      # each segment's share of total path length (approximate degrees
      # distance - good enough for a stylised UK overview map).
      seg_len <- sqrt(diff(wp$lat)^2 + diff(wp$lng)^2)
      cum_len <- c(0, cumsum(seg_len))
      total_len <- cum_len[length(cum_len)]
      target_d  <- seq(0, total_len, length.out = n_per_line)

      lat <- numeric(n_per_line); lng <- numeric(n_per_line)
      for (j in seq_along(target_d)) {
        d <- target_d[j]
        seg <- max(1, min(length(seg_len), findInterval(d, cum_len, all.inside = TRUE)))
        seg_frac <- if (seg_len[seg] > 0) (d - cum_len[seg]) / seg_len[seg] else 0
        lat[j] <- wp$lat[seg] + (wp$lat[seg + 1] - wp$lat[seg]) * seg_frac
        lng[j] <- wp$lng[seg] + (wp$lng[seg + 1] - wp$lng[seg]) * seg_frac
      }
      # small residual wiggle so it doesn't look like ruler-straight segments
      frac <- seq(0, 1, length.out = n_per_line)
      wiggle <- sin(frac * pi * 8) * 0.008
      lat <- lat + wiggle
      lng <- lng - wiggle

    } else if (row$geom_type == "loop") {
      theta <- seq(0, 2 * pi, length.out = n_per_line)
      r_lat <- 0.22; r_lng <- 0.45
      lat <- row$lat1 + r_lat * sin(theta)
      lng <- row$lng1 + r_lng * cos(theta)

    } else { # cluster
      theta <- runif(n_per_cluster, 0, 2 * pi)
      r     <- sqrt(runif(n_per_cluster, 0, 1)) * 0.055
      lat   <- row$lat1 + r * sin(theta)
      lng   <- row$lng1 + r * cos(theta)
    }

    data.frame(
      corridor_id   = row$corridor_id,
      corridor_name = row$corridor_name,
      road_type     = row$road_type,
      point_index   = seq_along(lat),
      lat           = round(lat, 5),
      lng           = round(lng, 5),
      # Wider per-point spread than before, so risk visibly varies along a
      # single corridor (junctions/gradients/local conditions) instead of
      # rendering as one uniform colour block.
      point_noise   = round(rnorm(length(lat), 0, 14), 2),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, all_pts)
}

# Built once at source-time (fixed seeds => deterministic, no per-session cost)
uk_osa_corridor_points <- .generate_corridor_points(uk_osa_corridors)

# Corridor midpoint (for click-marker placement / labels)
uk_osa_corridor_midpoints <- do.call(rbind, lapply(split(uk_osa_corridor_points,
                                                          uk_osa_corridor_points$corridor_id), function(d) {
  data.frame(
    corridor_id   = d$corridor_id[1],
    corridor_name = d$corridor_name[1],
    road_type     = d$road_type[1],
    lat           = mean(d$lat),
    lng           = mean(d$lng),
    stringsAsFactors = FALSE
  )
}))
uk_osa_corridor_midpoints <- uk_osa_corridor_midpoints[match(uk_osa_corridors$corridor_id,
                                                               uk_osa_corridor_midpoints$corridor_id), ]

# ── Core OSA road-risk scoring formula ─────────────────────────────────────────
# score = base_risk[road_type]
#         + (osa_uplift[group] + duration_hours * 2.4) * time_window_multiplier
#         + point_noise
# Clamped to [2, 99]. Only the fatigue-related term (OSA uplift + duration)
# is scaled by time-of-day - the structural road-type risk is not.
osa_risk_score <- function(road_type, osa_group, time_window, duration_hours,
                            point_noise = 0) {
  base <- ROAD_TYPE_BASE_RISK[road_type]
  up   <- OSA_GROUP_UPLIFT[osa_group]
  mult <- TIME_WINDOW_MULT[time_window]
  dur  <- pmin(pmax(duration_hours, 0), 8) * 2.4

  # The circadian time-of-day effect is a driver-alertness phenomenon, so it
  # only scales the fatigue-related component (OSA treatment uplift +
  # accumulated journey duration) - NOT the static, structural road-type
  # risk, which doesn't change because it's 3am. Multiplying the whole sum
  # (as an earlier version did) compounded everything and pushed nearly
  # every point to the 99 ceiling under worst-case filters.
  fatigue <- (up + dur) * mult
  score <- base + fatigue + point_noise
  pmin(pmax(score, 2), 99)
}

# Single-scenario breakdown (not vectorised) used to explain a risk score in
# hover text / side panels - "why is this point 62/100?"
osa_risk_breakdown <- function(road_type, osa_group, time_window, duration_hours,
                                point_noise = 0) {
  base <- unname(ROAD_TYPE_BASE_RISK[road_type])
  up   <- unname(OSA_GROUP_UPLIFT[osa_group])
  mult <- unname(TIME_WINDOW_MULT[time_window])
  dur  <- pmin(pmax(duration_hours, 0), 8) * 2.4

  fatigue_raw    <- up + dur
  fatigue_scaled <- fatigue_raw * mult
  total          <- pmin(pmax(base + fatigue_scaled + point_noise, 2), 99)

  list(
    base_risk           = round(base, 1),
    osa_uplift          = round(up, 1),
    duration_component  = round(dur, 1),
    fatigue_raw         = round(fatigue_raw, 1),
    time_multiplier     = mult,
    fatigue_scaled      = round(fatigue_scaled, 1),
    point_noise         = round(point_noise, 1),
    total               = round(total, 1),
    category            = risk_category(total)
  )
}

# ── 8 fictional OSA-related near-miss incident points ─────────────────────────
osa_incident_points <- data.frame(
  incident_id = paste0("INC-", sprintf("%03d", 1:8)),
  corridor_name = c("M1", "M6", "A1", "M62", "A14", "M25", "A57", "Urban Manchester"),
  lat = c(52.63, 53.10, 54.20, 53.58, 52.10, 51.48, 53.43, 53.47),
  lng = c(-1.15, -2.30, -1.55, -1.65, 0.35,  0.05,  -1.85, -2.23),
  severity = c("High","Critical","Moderate","High","Moderate","High","Critical","High"),
  description = c(
    "Lane-departure near-miss; driver reported severe daytime sleepiness (ESS 18), untreated OSA suspected.",
    "Micro-sleep event detected via telematics at 03:40; driver later diagnosed with severe OSA.",
    "Delayed braking response on approach to queue; fatigue flagged in post-trip review.",
    "Drift into hard shoulder corrected by lane-keep assist; driver had skipped CPAP the prior 2 nights.",
    "Following-distance violation cluster during a 5h continuous drive without a break.",
    "Near-collision at low-speed queue; driver reported 'zoning out', consistent with OSA mind-wandering profile.",
    "Missed exit + erratic steering on a demanding route (Snake Pass); driver un-treated, high ESS score.",
    "Red-light response delay flagged by dashcam AI; driver awaiting CPAP titration appointment."
  ),
  stringsAsFactors = FALSE
)

# ── Rest areas + OSA/CPAP-relevant sleep clinics ───────────────────────────────
osa_rest_areas <- data.frame(
  name = c("Watford Gap Services (M1)", "Tibshelf Services (M1)",
           "Hilton Park Services (M6)", "Keele Services (M6)",
           "Sandbach Services (M6)", "Cobham Services (M25)",
           "South Mimms Services (M25)", "Membury Services (M4)",
           "Leigh Delamere Services (M4)", "Burtonwood Services (M62)",
           "Hartshead Moor Services (M62)", "Southwaite Services (M6)"),
  type = "rest_area",
  lat = c(52.33, 53.16, 52.60, 53.00, 53.14, 51.33, 51.69, 51.48,
          51.48, 53.42, 53.72, 54.80),
  lng = c(-1.10, -1.32, -2.06, -2.27, -2.36, -0.40, -0.20, -1.46,
          -2.19, -2.65, -1.70, -2.80),
  stringsAsFactors = FALSE
)

osa_sleep_clinics <- data.frame(
  name = c("Royal Papworth Hospital Sleep Centre", "Addenbrooke's Sleep Service",
           "Guy's & St Thomas' Sleep Disorders Centre", "Manchester Sleep Centre (Wythenshawe)"),
  type = "sleep_clinic",
  lat = c(52.16, 52.17, 51.50, 53.38),
  lng = c(0.16,  0.14,  -0.12, -2.29),
  stringsAsFactors = FALSE
)

osa_service_points <- rbind(
  osa_rest_areas[, c("name","type","lat","lng")],
  osa_sleep_clinics[, c("name","type","lat","lng")]
)

# ── Duration-category helper (used by the corridor comparison module) ─────────
duration_category <- function(hours) {
  out <- ifelse(hours < 2, "Short (<2h)",
         ifelse(hours <= 4, "Medium (2-4h)", "Long (>4h)"))
  factor(out, levels = c("Short (<2h)", "Medium (2-4h)", "Long (>4h)"))
}

# ── Convenience: full corridor x group x time-window summary table ────────────
# One row per corridor per OSA group per time window, using a representative
# 4-hour journey duration. Used by the corridors module for ranking / heatmap.
build_corridor_risk_summary <- function(duration_hours = 4) {
  base <- expand.grid(
    corridor_id = uk_osa_corridors$corridor_id,
    osa_group   = names(OSA_GROUP_UPLIFT),
    time_window = TIME_WINDOWS,
    stringsAsFactors = FALSE
  )
  base <- merge(base, uk_osa_corridors[, c("corridor_id","corridor_name","road_type")],
                by = "corridor_id")
  base$risk_score <- osa_risk_score(base$road_type, base$osa_group,
                                     base$time_window, duration_hours)
  base
}
