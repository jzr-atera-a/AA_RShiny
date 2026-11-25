# R/utils_timezone.R
# =============================================================================
# ONE time zone for every itinerary / schedule / plan the app generates.
#
#   * bos_tz_dropdown_ui()   - the dropdown (30 zones, Mexico City first, London second)
#   * bos_tz_wrap_prompt()   - tells Claude which zone every time must be written in
#   * bos_tz_set_header() /  - the generated text carries a first line
#     bos_tz_from_text()       "[time_zone]: America/Mexico_City", so the zone
#                              survives editing, "Copy to Bulk Import" and re-parsing
#   * the parsers add a time_zone column; BigQuery stores it (R/utils_api.R)
#   * ics_row_tz() (R/utils_ics.R) and the Titan hand-off use the SAVED zone.
#
# Rows saved before this feature have no zone: they are read as BOS_DEFAULT_TZ.
# Names are bos_-prefixed (Business Operations Suite) so nothing collides.
# =============================================================================

BOS_DEFAULT_TZ <- "America/Mexico_City"

# Exactly 30 zones: Mexico City first (default), London second, then the others.
BOS_TIMEZONES <- c(
  "Mexico City (CDMX), Mexico"      = "America/Mexico_City",
  "London, United Kingdom"          = "Europe/London",
  "Cancun, Mexico"                  = "America/Cancun",
  "Tijuana, Mexico"                 = "America/Tijuana",
  "New York, USA (Eastern)"         = "America/New_York",
  "Chicago, USA (Central)"          = "America/Chicago",
  "Denver, USA (Mountain)"          = "America/Denver",
  "Los Angeles, USA (Pacific)"      = "America/Los_Angeles",
  "Toronto, Canada"                 = "America/Toronto",
  "Bogota, Colombia"                = "America/Bogota",
  "Sao Paulo, Brazil"               = "America/Sao_Paulo",
  "Buenos Aires, Argentina"         = "America/Argentina/Buenos_Aires",
  "Madrid, Spain"                   = "Europe/Madrid",
  "Paris, France"                   = "Europe/Paris",
  "Berlin, Germany"                 = "Europe/Berlin",
  "Istanbul, Turkey"                = "Europe/Istanbul",
  "Moscow, Russia"                  = "Europe/Moscow",
  "Cairo, Egypt"                    = "Africa/Cairo",
  "Johannesburg, South Africa"      = "Africa/Johannesburg",
  "Dubai, UAE"                      = "Asia/Dubai",
  "Kolkata, India"                  = "Asia/Kolkata",
  "Bangkok, Thailand"               = "Asia/Bangkok",
  "Singapore"                       = "Asia/Singapore",
  "Shanghai, China"                 = "Asia/Shanghai",
  "Hong Kong"                       = "Asia/Hong_Kong",
  "Tokyo, Japan"                    = "Asia/Tokyo",
  "Seoul, South Korea"              = "Asia/Seoul",
  "Sydney, Australia"               = "Australia/Sydney",
  "Auckland, New Zealand"           = "Pacific/Auckland",
  "UTC"                             = "UTC"
)

# A valid Olson name, or BOS_DEFAULT_TZ. Accepts NULL / NA / "" / vectors (first element).
bos_tz_value <- function(x) {
  if (is.null(x) || length(x) == 0) return(BOS_DEFAULT_TZ)
  x <- trimws(as.character(x[1]))
  if (is.na(x) || !nzchar(x) || !x %in% OlsonNames()) BOS_DEFAULT_TZ else x
}

# Vectorised: valid zone per element, BOS_DEFAULT_TZ where missing/invalid.
bos_tz_vector <- function(x, n = length(x)) {
  if (is.null(x) || length(x) == 0) return(rep(BOS_DEFAULT_TZ, n))
  x <- trimws(as.character(x))
  x[is.na(x) | !nzchar(x) | !x %in% OlsonNames()] <- BOS_DEFAULT_TZ
  x
}

bos_tz_label <- function(tz) {
  tz <- bos_tz_value(tz)
  i <- match(tz, BOS_TIMEZONES)
  if (is.na(i)) tz else names(BOS_TIMEZONES)[i]
}

# "UTC-06:00" on a given date (daylight saving aware)
bos_tz_offset <- function(tz, date = Sys.Date()) {
  tz <- bos_tz_value(tz)
  d <- suppressWarnings(as.Date(date))
  if (length(d) != 1 || is.na(d)) d <- Sys.Date()
  z <- format(as.POSIXct(paste(format(d), "12:00:00"), tz = tz), "%z")
  paste0("UTC", substr(z, 1, 3), ":", substr(z, 4, 5))
}

# date + minutes-after-midnight, as wall-clock time in tz -> POSIXct
bos_tz_local_posix <- function(date, minutes, tz = BOS_DEFAULT_TZ) {
  tz <- bos_tz_value(tz)
  d <- as.Date(date) + floor(minutes / 1440)
  m <- round(minutes %% 1440)
  mk <- function(mm) as.POSIXct(sprintf("%s %02d:%02d", format(d), as.integer(mm %/% 60), as.integer(mm %% 60)),
                                format = "%Y-%m-%d %H:%M", tz = tz)
  t <- mk(m)
  if (is.na(t)) t <- mk(m + 60)          # wall time skipped by a clock change
  t
}

bos_tz_utc_stamp <- function(date, minutes, tz = BOS_DEFAULT_TZ) {
  format(bos_tz_local_posix(date, minutes, tz), "%Y%m%dT%H%M%SZ", tz = "UTC")
}

# ---- text header ----------------------------------------------------------------

# Zone recorded in generated/pasted text ("[time_zone]: Europe/London" in the
# first lines), or `default` (NA unless given) when there is none / it is invalid.
bos_tz_from_text <- function(text, default = NA_character_) {
  if (is.null(text) || length(text) == 0 || is.na(text[1])) return(default)
  lines <- head(strsplit(as.character(text[1]), "\n", fixed = TRUE)[[1]], 40)
  hit <- grep("^\\s*\\[time_zone\\]\\s*:", lines, ignore.case = TRUE)
  if (!length(hit)) return(default)
  v <- trimws(sub("^\\s*\\[time_zone\\]\\s*:\\s*", "", lines[hit[1]], ignore.case = TRUE))
  v <- sub("\\s.*$", "", v)
  if (nzchar(v) && v %in% OlsonNames()) v else default
}

# Puts exactly one "[time_zone]: <zone>" line at the top of the text.
bos_tz_set_header <- function(text, tz) {
  lines <- strsplit(as.character(text %||% ""), "\n", fixed = TRUE)[[1]]
  lines <- lines[!grepl("^\\s*\\[time_zone\\]\\s*:", lines, ignore.case = TRUE)]
  paste(c(paste0("[time_zone]: ", bos_tz_value(tz)), lines), collapse = "\n")
}

# ---- Claude prompt --------------------------------------------------------------

bos_tz_prompt_block <- function(tz, date = Sys.Date()) {
  tz <- bos_tz_value(tz)
  paste0(
    "TIME ZONE REQUIREMENT (applies to the whole answer):\n",
    "The user plans in ", bos_tz_label(tz), " (", tz, ", ", bos_tz_offset(tz, date), " on ", as.character(date), ").\n",
    "- EVERY clock time you write (arrival/departure windows, meal times, session times, event times, ",
    "deadline times, opening of applications) MUST be local clock time in this zone.\n",
    "- If a source states a time in another zone (an event, deadline or session published in the venue's, ",
    "organiser's or country's local time), CONVERT it to ", tz, " before writing it, and mention the original ",
    "time and zone in the description/notes text when they differ.\n",
    "- Opening hours are facts about a venue: write them in the venue's local time and say so if that is not ",
    tz, ".\n",
    "- Never write zone abbreviations inside the time fields and never invent a time-zone field: the app ",
    "records the zone itself.\n",
    "- Use unambiguous clock times (e.g. 14:30 or 2:30 PM). If a time is genuinely unknown, say so instead of guessing.\n\n"
  )
}

bos_tz_wrap_prompt <- function(prompt, tz, date = Sys.Date()) {
  paste0(bos_tz_prompt_block(tz, date), prompt)
}

# ---- UI -------------------------------------------------------------------------

bos_tz_dropdown_ui <- function(ns, id = "time_zone", label = "Time zone for all times:",
                               help = "Claude is told to write every time in this zone, and it is saved with the data.") {
  tagList(
    selectInput(ns(id), label, choices = BOS_TIMEZONES, selected = BOS_DEFAULT_TZ),
    if (!is.null(help)) p(class = "text-muted", style = "margin-top: -8px; font-size: 0.85em;",
                          icon("globe"), " ", help)
  )
}
