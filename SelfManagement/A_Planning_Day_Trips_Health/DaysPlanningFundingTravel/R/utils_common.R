# R/utils_common.R
# Shared Utility Functions — Business Operations Suite
# =====================================================
# Three suites (Day Planner, Events Scheduling, Funding Programmes), each in
# its own clearly-commented section below. Every cascade-dropdown helper
# (function names AND their "+ Add New" sentinel constants) is suite-prefixed
# - Day Planner and Funding Programmes both originally had a generic
# `country_cityregion_dropdown_ui`/`setup_country_cityregion_cascade` pair,
# and Events Scheduling and Funding Programmes both originally had a generic
# `category_dropdown_ui`/`setup_category_cascade`/`CATEGORY_ADD_NEW_VALUE`
# pair. Merged into one R process unprefixed, the second-sourced suite would
# silently overwrite the first's - exactly the collision class this app's
# architecture guide warns about. Renamed here so all three suites keep
# fully independent, correct cascades.

# ============================================================
# SHARED GENERIC HELPERS (used by all three suites)
# ============================================================
safe_sql_escape <- function(x) {
  gsub("'", "\\'", x, fixed = TRUE)
}

has_real_value <- function(x) {
  if (is.null(x) || is.na(x)) return(FALSE)
  trimmed <- trimws(as.character(x))
  if (nchar(trimmed) == 0) return(FALSE)
  if (tolower(trimmed) %in% c("n/a", "na")) return(FALSE)
  TRUE
}

`%||%` <- function(x, y) if (is.null(x)) y else x


# =============================================================================
# ============================  DAY PLANNER  =================================
# =============================================================================
# Text format - 5-line bracketed header, then repeating row entries. See
# parse_schedule_text() below for the exact contract.

PROGRAMME_SCHEDULE_FIELDS <- c("row_type", "location_name", "location_details",
                               "opening_hours", "recommended_time", "observations")

parse_schedule_text <- function(text) {
  lines <- strsplit(text, "\n")[[1]]

  schedule_date <- NULL; day_type <- NULL; country <- NULL; city <- NULL; trip_details <- NULL
  metadata_count <- 0
  for (i in seq_len(min(15, length(lines)))) {
    line <- trimws(lines[i])
    if (grepl("^\\[.+\\]$", line)) {
      metadata_count <- metadata_count + 1
      value <- gsub("^\\[|\\]$", "", line)
      if (metadata_count == 1) schedule_date <- value
      else if (metadata_count == 2) day_type <- value
      else if (metadata_count == 3) country <- value
      else if (metadata_count == 4) city <- value
      else if (metadata_count == 5) trip_details <- value
      else break
    }
  }

  if (is.null(schedule_date) || is.null(day_type)) {
    stop("Could not find schedule date and day type in schedule text")
  }
  if (is.null(country)) country <- "N/A"
  if (is.null(city)) city <- "N/A"
  if (is.null(trip_details)) trip_details <- "N/A"

  entries <- list()
  current_entry <- list()

  for (line in lines) {
    line <- trimws(line)
    if (line == "" || grepl("^\\[.+\\]$", line)) {
      if (length(current_entry) >= 2 && !is.null(current_entry$row_type)) {
        entries[[length(entries) + 1]] <- current_entry
        current_entry <- list()
      }
      next
    }

    if (grepl("^\\[row_type\\]:", line, ignore.case = TRUE)) {
      current_entry$row_type <- trimws(sub("^\\[row_type\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[location_name\\]:", line, ignore.case = TRUE)) {
      current_entry$location_name <- trimws(sub("^\\[location_name\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[location_details\\]:", line, ignore.case = TRUE)) {
      current_entry$location_details <- trimws(sub("^\\[location_details\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[opening_hours\\]:", line, ignore.case = TRUE)) {
      current_entry$opening_hours <- trimws(sub("^\\[opening_hours\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[recommended_time\\]:", line, ignore.case = TRUE)) {
      current_entry$recommended_time <- trimws(sub("^\\[recommended_time\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[observations\\]:", line, ignore.case = TRUE)) {
      current_entry$observations <- trimws(sub("^\\[observations\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (length(current_entry) > 0 && !is.null(current_entry$observations)) {
      current_entry$observations <- paste(current_entry$observations, line)
    }
  }
  if (length(current_entry) >= 2 && !is.null(current_entry$row_type)) {
    entries[[length(entries) + 1]] <- current_entry
  }

  if (length(entries) == 0) stop("No valid location/transport/summary rows found in schedule text")

  parsed_df <- data.frame(
    schedule_date = character(), day_type = character(), country = character(), city = character(),
    trip_details = character(), row_type = character(), row_sequence = integer(),
    location_name = character(), location_details = character(), opening_hours = character(),
    recommended_time = character(), observations = character(), stringsAsFactors = FALSE
  )

  for (i in seq_along(entries)) {
    entry <- entries[[i]]
    parsed_df <- rbind(parsed_df, data.frame(
      schedule_date = schedule_date, day_type = day_type, country = country, city = city,
      trip_details = trip_details, row_type = entry$row_type, row_sequence = i,
      location_name = ifelse(is.null(entry$location_name), "", entry$location_name),
      location_details = ifelse(is.null(entry$location_details), "", entry$location_details),
      opening_hours = ifelse(is.null(entry$opening_hours), "N/A", entry$opening_hours),
      recommended_time = ifelse(is.null(entry$recommended_time), "", entry$recommended_time),
      observations = ifelse(is.null(entry$observations), "", entry$observations),
      stringsAsFactors = FALSE
    ))
  }
  parsed_df
}

generate_schedule_prompt <- function(schedule_date, day_type, country = "", city = "", trip_details = "") {
  is_travel <- identical(day_type, "Travel")
  is_real_loc <- function(x) nchar(trimws(x)) > 0 && !identical(tolower(trimws(x)), "n/a")
  has_location <- is_real_loc(country) || is_real_loc(city)
  place_text <- if (is_real_loc(country) && is_real_loc(city)) paste0(city, ", ", country)
                else if (is_real_loc(city)) city
                else if (is_real_loc(country)) country
                else "a location inferred from the details below"
  details_text <- if (nchar(trip_details) > 0) trip_details else "No further details provided - use your best judgement for a well-rounded day."

  weather_instruction <- if (has_location) {
    paste0(
      '\n0. WEATHER RESEARCH (do this FIRST, before planning):\n',
      '   Use your web search tool to find the actual weather forecast for ', place_text, ' on ', schedule_date, '. ',
      'Note the expected conditions, temperature range, and precipitation chance. Then plan the day around it: ',
      'prefer indoor locations or reschedule outdoor stops around any rain window, note what to wear/bring, ',
      'and mention the forecast explicitly in the Summary row (see rule 5) and in the observations of any ',
      'outdoor-relevant Location/Transport row. If you cannot find a specific forecast, say so honestly in the ',
      'Summary row instead of inventing one (e.g. "Forecast not found for this date - plan is weather-agnostic").\n'
    )
  } else {
    ''
  }

  weather_summary_line <- if (has_location) {
    'Start with a one-sentence "Weather Forecast: ..." statement (conditions, temperature range, rain chance), then the rest of the day insights.'
  } else {
    'No location was specified, so omit any weather statement here.'
  }

  paste0(
    'You are an expert day-planning assistant. Plan an optimal, realistic schedule for a single day: ',
    schedule_date, ' (day type: ', day_type, ') in ', place_text, ' following this EXACT format:
', weather_instruction, '
Format Requirements:
1. Start with day metadata in brackets (5 lines):
[', schedule_date, ']
[', day_type, ']
[', if (is_real_loc(country)) country else "N/A", ']
[', if (is_real_loc(city)) city else "N/A", ']
[One-line trip context summarising the day]

2. Additional details from the user (places to visit, start point, end point, preferences):
', details_text, '

3. For each stop, alternate Location and Transport rows using this EXACT pattern:

For a Location row:
[row_type]: Location
[location_name]: Name of the place
[location_details]: Address and a short description of what it is
[opening_hours]: Opening hours for this day (or "N/A" if not applicable)
[recommended_time]: Arrival-departure time window and duration, e.g. "9:00 AM - 11:00 AM (2h 00m)"
[observations]: What to expect, what to look for, and any practical tips for this location. If this is an
outdoor or weather-sensitive stop, include a brief weather-driven tip here (e.g. "Forecast shows light rain
around 2pm - bring a jacket or move indoors earlier").

For a Transport row (between two locations):
[row_type]: Transport
[location_name]: Short label for the transport leg, e.g. "Metro Line 6 to Trocadero"
[location_details]: The specific route/line/mode and how to catch it
[opening_hours]: N/A
[recommended_time]: Expected travel time, e.g. "15 min"
[observations]: Practical indications for taking this transport (frequency, ticket type, which exit, etc.)

4. CRITICAL PLANNING RULES:
   - Sequence stops to MINIMISE total travel time and distance, respecting any specified start/end point
   - Respect the OPENING HOURS of each location - never schedule a visit outside stated hours
   - Use the weather forecast from step 0 to inform indoor/outdoor choices and timing (e.g. schedule
     outdoor activities before or after a forecasted rain window, not during it)
   - Every Location row is immediately followed by a Transport row to the NEXT location, except the very
     last location, which is followed directly by the Summary row
   - Produce a realistic number of stops for one day (typically 3-7 locations) - do not pad with filler

5. Close with EXACTLY ONE Summary row for the whole day:
[row_type]: Summary
[location_name]: Day Summary
[location_details]: One-line title summarising the day
[opening_hours]: N/A
[recommended_time]: Total time for the day, e.g. "Total: 7h 20m" (sum of all location + transport durations)
[observations]: ', weather_summary_line, ' Then add key insights - why the route is efficient, any risks, what to expect overall.

6. FORMATTING RULES:
   - Separate each row entry with ONE blank line
   - NO extra markdown, NO headers with #, NO entry numbers
   - Use the exact bracket format shown above; every field must be present on every row (use "N/A" if it
     truly does not apply - never omit the line)

Now generate the complete day schedule for ', schedule_date, ' with ALL required fields for each row.'
  )
}

# Force-overwrites the 5-line bracketed metadata header with the exact
# strings the user selected in the UI, regardless of what Claude wrote.
overwrite_schedule_header <- function(text, schedule_date, day_type, country, city, trip_details) {
  lines <- strsplit(text, "\n")[[1]]
  bracket_idx <- c()
  for (i in seq_len(min(15, length(lines)))) {
    if (grepl("^\\[.+\\]$", trimws(lines[i]))) bracket_idx <- c(bracket_idx, i)
    if (length(bracket_idx) >= 5) break
  }
  if (length(bracket_idx) < 2) return(text)

  lines[bracket_idx[1]] <- paste0("[", schedule_date, "]")
  lines[bracket_idx[2]] <- paste0("[", day_type, "]")
  daytype_line <- bracket_idx[2]

  if (length(bracket_idx) >= 3) lines[bracket_idx[3]] <- paste0("[", country, "]")
  else { lines <- append(lines, paste0("[", country, "]"), after = daytype_line); bracket_idx <- c(bracket_idx, daytype_line + 1) }
  country_line <- bracket_idx[3]

  if (length(bracket_idx) >= 4) lines[bracket_idx[4]] <- paste0("[", city, "]")
  else { lines <- append(lines, paste0("[", city, "]"), after = country_line); bracket_idx <- c(bracket_idx, country_line + 1) }
  city_line <- bracket_idx[4]

  flat_details <- gsub("\\s*\n\\s*", " | ", trimws(trip_details %||% ""))
  if (nchar(flat_details) == 0) flat_details <- "N/A"

  if (length(bracket_idx) >= 5) lines[bracket_idx[5]] <- paste0("[", flat_details, "]")
  else lines <- append(lines, paste0("[", flat_details, "]"), after = city_line)

  paste(lines, collapse = "\n")
}

# Best-effort duration parser (minutes) for the Day Planner time-allocation
# chart. Suite-prefixed since "parse_duration" is a generic-sounding name.
schedule_parse_duration_minutes <- function(text) {
  if (is.null(text) || is.na(text) || trimws(as.character(text)) == "" ||
      tolower(trimws(as.character(text))) %in% c("n/a", "na")) return(NA_real_)
  t <- tolower(as.character(text))
  hrs <- 0; mins <- 0
  h_match <- regmatches(t, regexpr("([0-9]+(\\.[0-9]+)?)\\s*h(r|our)?s?", t))
  if (length(h_match) > 0) hrs <- as.numeric(regmatches(h_match, regexpr("[0-9]+(\\.[0-9]+)?", h_match)))
  m_match <- regmatches(t, regexpr("([0-9]+)\\s*m(in|inute)?s?", t))
  if (length(m_match) > 0) mins <- as.numeric(regmatches(m_match, regexpr("[0-9]+", m_match)))
  total <- hrs * 60 + mins
  if (total == 0) return(NA_real_)
  total
}

# ── Type of Day (single-level "Add New" pattern) ─────────────────────────────
SCHEDULE_DAYTYPE_ADD_NEW_VALUE <- "__ADD_NEW_DAYTYPE__"
SCHEDULE_DEFAULT_DAY_TYPES <- c("Travel", "Work", "Conference", "Research")

schedule_daytype_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("day_type_select"), "Type of Day: *",
                choices = c(setNames(SCHEDULE_DEFAULT_DAY_TYPES, SCHEDULE_DEFAULT_DAY_TYPES),
                            "+ Add New Type" = SCHEDULE_DAYTYPE_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("day_type_select"), SCHEDULE_DAYTYPE_ADD_NEW_VALUE),
      textInput(ns("new_day_type_text"), "New Type Name:", placeholder = "e.g., Family, Medical, Errands")
    )
  )
}

setup_schedule_daytype_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_schedule()
    if (!api_manager$bq_authenticated) return(data.frame(day_type = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_schedule_taxonomy(), error = function(e) data.frame(day_type = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored <- sort(unique(tax$day_type[nchar(trimws(tax$day_type)) > 0]))
    all_types <- sort(unique(c(SCHEDULE_DEFAULT_DAY_TYPES, stored)))
    choices <- c(setNames(all_types, all_types), "+ Add New Type" = SCHEDULE_DAYTYPE_ADD_NEW_VALUE)
    current <- isolate(input$day_type_select)
    selected <- if (!is.null(current) && current %in% choices) current else all_types[1]
    updateSelectInput(session, "day_type_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  reactive({
    if (identical(input$day_type_select, SCHEDULE_DAYTYPE_ADD_NEW_VALUE)) trimws(input$new_day_type_text %||% "")
    else input$day_type_select %||% ""
  })
}

# ── Country / City (Travel days) ─────────────────────────────────────────────
SCHEDULE_COUNTRY_ADD_NEW_VALUE <- "__ADD_NEW_COUNTRY_SCHED__"
SCHEDULE_CITY_ADD_NEW_VALUE <- "__ADD_NEW_CITY_SCHED__"

schedule_country_city_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("country_select"), "Country: *",
                choices = c("+ Add New Country" = SCHEDULE_COUNTRY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("country_select"), SCHEDULE_COUNTRY_ADD_NEW_VALUE),
      textInput(ns("new_country_text"), "New Country Name:", placeholder = "e.g., France")
    ),
    selectInput(ns("city_select"), "City: *",
                choices = c("+ Add New City" = SCHEDULE_CITY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("city_select"), SCHEDULE_CITY_ADD_NEW_VALUE),
      textInput(ns("new_city_text"), "New City Name:", placeholder = "e.g., Paris")
    )
  )
}

setup_schedule_country_city_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_schedule()
    if (!api_manager$bq_authenticated) return(data.frame(country = character(), city = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_schedule_taxonomy(), error = function(e) data.frame(country = character(), city = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    countries <- sort(unique(tax$country[nchar(trimws(tax$country)) > 0]))
    choices <- c("+ Add New Country" = SCHEDULE_COUNTRY_ADD_NEW_VALUE, setNames(countries, countries))
    current <- isolate(input$country_select)
    selected <- if (!is.null(current) && current %in% choices) current else SCHEDULE_COUNTRY_ADD_NEW_VALUE
    updateSelectInput(session, "country_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  observeEvent(input$country_select, {
    tax <- taxonomy()
    if (is.null(input$country_select) || input$country_select == SCHEDULE_COUNTRY_ADD_NEW_VALUE) {
      updateSelectInput(session, "city_select", choices = c("+ Add New City" = SCHEDULE_CITY_ADD_NEW_VALUE))
      return()
    }
    cities <- sort(unique(tax$city[tax$country == input$country_select & nchar(trimws(tax$city)) > 0]))
    if (length(cities) == 0) {
      updateSelectInput(session, "city_select", choices = c("+ Add New City" = SCHEDULE_CITY_ADD_NEW_VALUE))
    } else {
      updateSelectInput(session, "city_select",
                        choices = c("+ Add New City" = SCHEDULE_CITY_ADD_NEW_VALUE, setNames(cities, cities)))
    }
  }, ignoreInit = TRUE)

  reactive({
    country <- if (identical(input$country_select, SCHEDULE_COUNTRY_ADD_NEW_VALUE)) trimws(input$new_country_text %||% "") else input$country_select %||% ""
    city <- if (identical(input$city_select, SCHEDULE_CITY_ADD_NEW_VALUE)) trimws(input$new_city_text %||% "") else input$city_select %||% ""
    list(country = country, city = city)
  })
}

# ── Prep Checklist: a "night-before" motivational preparation checklist for
# a day already planned in day_scheduler. This is a genuinely different
# concept from the itinerary generation above (which plans WHAT happens
# that day) - this generates a short list of things to DO BEFOREHAND to be
# ready for it. Content shape is a flat numbered list of short strings
# (unlike the rest of this suite's multi-field bracket-tag rows), so it
# uses a lighter "N. text" format rather than the [field]: value convention
# - forcing a single-field list into that heavier convention would add
# nothing.

parse_prep_steps_text <- function(text) {
  lines <- strsplit(text, "\n")[[1]]
  steps <- c()

  for (line in lines) {
    line <- trimws(line)
    m <- regmatches(line, regexpr("^\\d+\\.\\s*(.+)$", line))
    if (length(m) > 0) {
      step_text <- trimws(sub("^\\d+\\.\\s*", "", m))
      if (nchar(step_text) > 0) steps <- c(steps, step_text)
    }
  }

  if (length(steps) == 0) stop("No numbered preparation steps found in the response")

  data.frame(step_sequence = seq_along(steps), step_text = steps, stringsAsFactors = FALSE)
}

generate_prep_steps_prompt <- function(schedule_date, plan_summary, schedule_text, category = "", location = "", additional_context = "") {
  context_line <- if (nchar(trimws(category)) > 0 && nchar(trimws(location)) > 0) {
    paste0("Category: ", category, ". Location: ", location, ".")
  } else if (nchar(trimws(category)) > 0) {
    paste0("Category: ", category, ".")
  } else if (nchar(trimws(location)) > 0) {
    paste0("Location: ", location, ".")
  } else ""

  details_line <- if (nchar(trimws(additional_context)) > 0) paste0("Additional details: ", additional_context, "\n") else ""

  paste0(
    'You are an enthusiastic and motivational preparation coach. Help me prepare for ', schedule_date, '.\n\n',
    'MY PLAN FOR THAT DAY:\n', plan_summary, '\n\n',
    if (nchar(trimws(schedule_text)) > 0) paste0('SCHEDULE FOR THAT DAY:\n', schedule_text, '\n\n') else '',
    context_line, if (nchar(context_line) > 0) '\n' else '',
    details_line, '\n',
    'Generate EXACTLY 4 to 8 numbered preparation steps to help me be fully ready for this day. Each step must be:\n',
    '- Specific and actionable\n',
    '- Optimistic and energizing in tone, with an emoji\n',
    '- One to two sentences, time-efficient to actually do\n',
    '- Ordered logically (e.g. the night before, then the morning of)\n\n',
    'Use power words like "powerful", "ready", "dominate", "excel", "accomplish". Make me WANT to follow these steps.\n\n',
    'Output ONLY a numbered list, nothing else, in exactly this format:\n',
    '1. [emoji] [Step text]\n',
    '2. [emoji] [Step text]\n',
    '... and so on for 4 to 8 steps total.'
  )
}

# ── Category (single-level "Add New", mirrors Diet Type / Session Type) ────
PREP_CATEGORY_ADD_NEW_VALUE <- "__ADD_NEW_PREPCATEGORY__"
PREP_DEFAULT_CATEGORIES <- c("Work", "Fitness", "Health", "Travel", "General")

prep_category_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("prep_category_select"), "Category:",
                choices = c("None" = "", setNames(PREP_DEFAULT_CATEGORIES, PREP_DEFAULT_CATEGORIES),
                            "+ Add New Category" = PREP_CATEGORY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("prep_category_select"), PREP_CATEGORY_ADD_NEW_VALUE),
      textInput(ns("new_prep_category_text"), "New Category Name:", placeholder = "e.g., Family, Social")
    )
  )
}

setup_prep_category_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_schedule()
    if (!api_manager$bq_authenticated) return(data.frame(category = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_prep_taxonomy(), error = function(e) data.frame(category = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
    all_cats <- sort(unique(c(PREP_DEFAULT_CATEGORIES, stored)))
    choices <- c("None" = "", setNames(all_cats, all_cats), "+ Add New Category" = PREP_CATEGORY_ADD_NEW_VALUE)
    current <- isolate(input$prep_category_select)
    selected <- if (!is.null(current) && current %in% choices) current else ""
    updateSelectInput(session, "prep_category_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  reactive({
    if (identical(input$prep_category_select, PREP_CATEGORY_ADD_NEW_VALUE)) trimws(input$new_prep_category_text %||% "")
    else input$prep_category_select %||% ""
  })
}

# ── Location (single-level "Add New") ───────────────────────────────────────
PREP_LOCATION_ADD_NEW_VALUE <- "__ADD_NEW_PREPLOCATION__"
PREP_DEFAULT_LOCATIONS <- c("Office", "Home", "Gym", "Client Site", "Travel")

prep_location_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("prep_location_select"), "Location:",
                choices = c("None" = "", setNames(PREP_DEFAULT_LOCATIONS, PREP_DEFAULT_LOCATIONS),
                            "+ Add New Location" = PREP_LOCATION_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("prep_location_select"), PREP_LOCATION_ADD_NEW_VALUE),
      textInput(ns("new_prep_location_text"), "New Location Name:", placeholder = "e.g., Conference Center")
    )
  )
}

setup_prep_location_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_schedule()
    if (!api_manager$bq_authenticated) return(data.frame(location = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_prep_taxonomy(), error = function(e) data.frame(location = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored <- sort(unique(tax$location[nchar(trimws(tax$location)) > 0]))
    all_locs <- sort(unique(c(PREP_DEFAULT_LOCATIONS, stored)))
    choices <- c("None" = "", setNames(all_locs, all_locs), "+ Add New Location" = PREP_LOCATION_ADD_NEW_VALUE)
    current <- isolate(input$prep_location_select)
    selected <- if (!is.null(current) && current %in% choices) current else ""
    updateSelectInput(session, "prep_location_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  reactive({
    if (identical(input$prep_location_select, PREP_LOCATION_ADD_NEW_VALUE)) trimws(input$new_prep_location_text %||% "")
    else input$prep_location_select %||% ""
  })
}

# ── Monthly Commitments: three independent single-level "Add New" cascades
# (Category, Sector, Topic - no hierarchy between them, each stands alone).

COMMITMENT_CATEGORY_ADD_NEW_VALUE <- "__ADD_NEW_COMMITCATEGORY__"
COMMITMENT_DEFAULT_CATEGORIES <- c("Strategic", "Operational", "Financial", "Regulatory", "Partnership")

commitment_category_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("commitment_category_select"), "Category: *",
                choices = c(setNames(COMMITMENT_DEFAULT_CATEGORIES, COMMITMENT_DEFAULT_CATEGORIES),
                            "+ Add New Category" = COMMITMENT_CATEGORY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("commitment_category_select"), COMMITMENT_CATEGORY_ADD_NEW_VALUE),
      textInput(ns("new_commitment_category_text"), "New Category Name:")
    )
  )
}

setup_commitment_category_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_schedule()
    if (!api_manager$bq_authenticated) return(data.frame(category = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_commitments_taxonomy(), error = function(e) data.frame(category = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
    all_cats <- sort(unique(c(COMMITMENT_DEFAULT_CATEGORIES, stored)))
    choices <- c(setNames(all_cats, all_cats), "+ Add New Category" = COMMITMENT_CATEGORY_ADD_NEW_VALUE)
    current <- isolate(input$commitment_category_select)
    selected <- if (!is.null(current) && current %in% choices) current else all_cats[1]
    updateSelectInput(session, "commitment_category_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  reactive({
    if (identical(input$commitment_category_select, COMMITMENT_CATEGORY_ADD_NEW_VALUE)) trimws(input$new_commitment_category_text %||% "")
    else input$commitment_category_select %||% ""
  })
}

COMMITMENT_SECTOR_ADD_NEW_VALUE <- "__ADD_NEW_COMMITSECTOR__"
COMMITMENT_DEFAULT_SECTORS <- c("Technology", "Healthcare", "Finance", "Retail", "Manufacturing", "Public Sector")

commitment_sector_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("commitment_sector_select"), "Sector: *",
                choices = c(setNames(COMMITMENT_DEFAULT_SECTORS, COMMITMENT_DEFAULT_SECTORS),
                            "+ Add New Sector" = COMMITMENT_SECTOR_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("commitment_sector_select"), COMMITMENT_SECTOR_ADD_NEW_VALUE),
      textInput(ns("new_commitment_sector_text"), "New Sector Name:")
    )
  )
}

setup_commitment_sector_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_schedule()
    if (!api_manager$bq_authenticated) return(data.frame(sector = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_commitments_taxonomy(), error = function(e) data.frame(sector = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored <- sort(unique(tax$sector[nchar(trimws(tax$sector)) > 0]))
    all_sectors <- sort(unique(c(COMMITMENT_DEFAULT_SECTORS, stored)))
    choices <- c(setNames(all_sectors, all_sectors), "+ Add New Sector" = COMMITMENT_SECTOR_ADD_NEW_VALUE)
    current <- isolate(input$commitment_sector_select)
    selected <- if (!is.null(current) && current %in% choices) current else all_sectors[1]
    updateSelectInput(session, "commitment_sector_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  reactive({
    if (identical(input$commitment_sector_select, COMMITMENT_SECTOR_ADD_NEW_VALUE)) trimws(input$new_commitment_sector_text %||% "")
    else input$commitment_sector_select %||% ""
  })
}

# Topic has no sensible defaults (too open-ended) - "+ Add New" only, plus
# whatever's already been used, same mechanism as the other two.
COMMITMENT_TOPIC_ADD_NEW_VALUE <- "__ADD_NEW_COMMITTOPIC__"

commitment_topic_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("commitment_topic_select"), "Topic: *",
                choices = c("+ Add New Topic" = COMMITMENT_TOPIC_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("commitment_topic_select"), COMMITMENT_TOPIC_ADD_NEW_VALUE),
      textInput(ns("new_commitment_topic_text"), "New Topic Name:")
    )
  )
}

setup_commitment_topic_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_schedule()
    if (!api_manager$bq_authenticated) return(data.frame(topic = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_commitments_taxonomy(), error = function(e) data.frame(topic = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored <- sort(unique(tax$topic[nchar(trimws(tax$topic)) > 0]))
    choices <- c(setNames(stored, stored), "+ Add New Topic" = COMMITMENT_TOPIC_ADD_NEW_VALUE)
    current <- isolate(input$commitment_topic_select)
    selected <- if (!is.null(current) && current %in% choices) current else COMMITMENT_TOPIC_ADD_NEW_VALUE
    updateSelectInput(session, "commitment_topic_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  reactive({
    if (identical(input$commitment_topic_select, COMMITMENT_TOPIC_ADD_NEW_VALUE)) trimws(input$new_commitment_topic_text %||% "")
    else input$commitment_topic_select %||% ""
  })
}

# Formats one commitment row into a readable text block, used to inject a
# commitment's context into Generate Schedule's trip_details field so
# Claude can plan the day around delivering it - no day_scheduler schema
# change needed, same "reuse an existing field" pattern as the weather
# feature.
format_commitment_for_schedule_context <- function(commitment_row) {
  r <- commitment_row
  paste0(
    "COMMITMENT TO DELIVER: ", r$description, "\n",
    "- Category/Sector/Topic: ", r$category, " / ", r$sector, " / ", r$topic, "\n",
    "- Deadline: ", r$deadline, "\n",
    "- Stakeholders: ", r$stakeholders, "\n",
    "- Value of delivering: ", r$value_of_delivery, "\n",
    "- Consequences of NOT delivering: ", r$consequences_of_failure, "\n",
    "Please plan this day with concrete time allocated toward making progress on this commitment."
  )
}


# =============================================================================
# ========================  EVENTS SCHEDULING  ===============================
# =============================================================================
# Text format contract (unchanged from the standalone Events app):
#   Header (shared across all events in one scan): [city], [country], [scan_date]
#   Per-event block: [event_name], [organiser], [category], [subcategory],
#   [event_date], [event_time], [venue_name], [address], [latitude],
#   [longitude], [description], [ticket_url], [price_range], [source_url],
#   [extra_info]

parse_events_text <- function(text) {
  lines <- strsplit(text, "\n")[[1]]

  city      <- extract_event_field(lines, "city")
  country   <- extract_event_field(lines, "country")
  scan_date <- extract_event_field(lines, "scan_date")

  if (is.null(city))      city      <- ""
  if (is.null(country))   country   <- ""
  if (is.null(scan_date)) scan_date <- as.character(Sys.Date())

  entries  <- list()
  curr     <- list()
  in_event <- FALSE

  for (line in lines) {
    line <- trimws(line)
    if (grepl("^\\[event_name\\]:", line, ignore.case = TRUE)) {
      if (in_event && !is.null(curr$event_name)) entries[[length(entries) + 1]] <- curr
      curr     <- list()
      in_event <- TRUE
      curr$event_name <- trimws(sub("^\\[event_name\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (in_event) {
      curr <- parse_event_line(line, curr)
    }
  }
  if (in_event && !is.null(curr$event_name)) entries[[length(entries) + 1]] <- curr

  if (length(entries) == 0) stop("No valid event entries found in text")

  df <- do.call(rbind, lapply(entries, function(e) {
    data.frame(
      event_name  = e$event_name  %||% "",
      organiser   = e$organiser   %||% "N/A",
      city        = if (nchar(trimws(city)) > 0) city else e$city %||% "",
      country     = if (nchar(trimws(country)) > 0) country else e$country %||% "",
      category    = e$category    %||% "",
      subcategory = e$subcategory %||% "",
      event_date  = e$event_date  %||% "",
      event_time  = e$event_time  %||% "TBD",
      venue_name  = e$venue_name  %||% "",
      address     = e$address     %||% "",
      latitude    = e$latitude    %||% "N/A",
      longitude   = e$longitude   %||% "N/A",
      description = e$description %||% "",
      ticket_url  = e$ticket_url  %||% "N/A",
      price_range = e$price_range %||% "N/A",
      source_url  = e$source_url  %||% "N/A",
      scan_date   = scan_date,
      extra_info  = e$extra_info  %||% "",
      stringsAsFactors = FALSE
    )
  }))
  df
}

parse_event_line <- function(line, curr) {
  fields <- c("organiser", "category", "subcategory", "city", "country",
              "event_date", "event_time", "venue_name", "address",
              "latitude", "longitude", "description",
              "ticket_url", "price_range", "source_url", "extra_info")
  for (f in fields) {
    if (grepl(paste0("^\\[", f, "\\]:"), line, ignore.case = TRUE)) {
      curr[[f]] <- trimws(sub(paste0("^\\[", f, "\\]:\\s*"), "", line, ignore.case = TRUE))
      return(curr)
    }
  }
  curr
}

extract_event_field <- function(lines, field_name) {
  pat <- paste0("^\\[", field_name, "\\]:\\s*(.+)$")
  for (line in lines) {
    if (grepl(pat, line, ignore.case = TRUE, perl = TRUE)) {
      return(trimws(sub(paste0("^\\[", field_name, "\\]:\\s*"), "", line, ignore.case = TRUE)))
    }
  }
  NULL
}

overwrite_events_header <- function(text, city, country, scan_date) {
  lines     <- strsplit(text, "\n")[[1]]
  event_idx <- which(grepl("^\\s*\\[event_name\\]:", lines, ignore.case = TRUE))[1]
  if (is.na(event_idx)) return(text)
  remaining <- lines[event_idx:length(lines)]
  header    <- c(paste0("[city]: ", city), paste0("[country]: ", country), paste0("[scan_date]: ", scan_date), "")
  paste(c(header, remaining), collapse = "\n")
}

# ── Category / Subcategory (renamed from the standalone app's generic
#    category_dropdown_ui/setup_category_cascade/CATEGORY_ADD_NEW_VALUE,
#    which collided with Funding Programmes' own Category cascade) ──────────
EVENTS_CATEGORY_ADD_NEW_VALUE    <- "__ADD_NEW_CATEGORY_EVT__"
EVENTS_SUBCATEGORY_ADD_NEW_VALUE <- "__ADD_NEW_SUBCATEGORY_EVT__"

events_category_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("category_select"), "Category: *",
                choices = c("+ Add New Category" = EVENTS_CATEGORY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("category_select"), EVENTS_CATEGORY_ADD_NEW_VALUE),
      textInput(ns("new_category_text"), "New Category Name:", placeholder = "e.g., Music")
    ),
    selectInput(ns("subcategory_select"), "Subcategory: *",
                choices = c("+ Add New Subcategory" = EVENTS_SUBCATEGORY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("subcategory_select"), EVENTS_SUBCATEGORY_ADD_NEW_VALUE),
      textInput(ns("new_subcategory_text"), "New Subcategory Name:", placeholder = "e.g., Jazz")
    )
  )
}

setup_events_category_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_events()
    if (!api_manager$bq_authenticated) return(data.frame(category = character(), subcategory = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_events_taxonomy(), error = function(e) data.frame(category = character(), subcategory = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax     <- taxonomy()
    cats    <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
    choices <- c("+ Add New Category" = EVENTS_CATEGORY_ADD_NEW_VALUE, setNames(cats, cats))
    current  <- isolate(input$category_select)
    selected <- if (!is.null(current) && current %in% choices) current else EVENTS_CATEGORY_ADD_NEW_VALUE
    updateSelectInput(session, "category_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  observeEvent(input$category_select, {
    tax <- taxonomy()
    if (is.null(input$category_select) || input$category_select == EVENTS_CATEGORY_ADD_NEW_VALUE) {
      updateSelectInput(session, "subcategory_select", choices = c("+ Add New Subcategory" = EVENTS_SUBCATEGORY_ADD_NEW_VALUE))
      return()
    }
    subs <- sort(unique(tax$subcategory[tax$category == input$category_select & nchar(trimws(tax$subcategory)) > 0]))
    if (length(subs) == 0) {
      updateSelectInput(session, "subcategory_select", choices = c("+ Add New Subcategory" = EVENTS_SUBCATEGORY_ADD_NEW_VALUE))
    } else {
      updateSelectInput(session, "subcategory_select",
                        choices = c("+ Add New Subcategory" = EVENTS_SUBCATEGORY_ADD_NEW_VALUE, setNames(subs, subs)))
    }
  }, ignoreInit = TRUE)

  reactive({
    category <- if (identical(input$category_select, EVENTS_CATEGORY_ADD_NEW_VALUE)) trimws(input$new_category_text %||% "") else input$category_select %||% ""
    subcategory <- if (identical(input$subcategory_select, EVENTS_SUBCATEGORY_ADD_NEW_VALUE)) trimws(input$new_subcategory_text %||% "") else input$subcategory_select %||% ""
    list(category = category, subcategory = subcategory)
  })
}

# ── Claude prompt - real events only, web search enabled via
#    call_claude(..., enable_web_search = TRUE) in scan_events/server.R ─────
generate_scan_prompt <- function(city            = "",
                                 country         = "",
                                 date_from       = NULL,
                                 date_to         = NULL,
                                 category        = "",
                                 subcategory     = "",
                                 top_n           = 10,
                                 extra_info      = "",
                                 optional_fields = "core") {

  location_str <- if (nchar(trimws(city)) > 0 && nchar(trimws(country)) > 0) paste0(city, ", ", country)
                  else if (nchar(trimws(city)) > 0) city
                  else if (nchar(trimws(country)) > 0) paste0(country, " (most relevant cities)")
                  else "worldwide (most notable events)"

  date_range_days <- if (!is.null(date_from) && !is.null(date_to)) as.integer(as.Date(date_to) - as.Date(date_from)) else 365
  date_str <- if (!is.null(date_from) && !is.null(date_to)) {
    if (date_range_days > 90) paste0(date_from, " to ", date_to, " (pick the ", top_n, " most significant)")
    else paste0(date_from, " to ", date_to)
  } else "next 3 months"

  cat_str <- if (nchar(trimws(subcategory)) > 0) paste0(category, " / ", subcategory)
             else if (nchar(trimws(category)) > 0) category else "any"

  extra_line <- if (nchar(trimws(extra_info)) > 0) paste0("\nExtra requirements: ", trimws(extra_info)) else ""

  core_fields <- paste0(
    "[event_name]: event name\n",
    "[organiser]: name or N/A\n",
    "[category]: Music/Tech/Art/Food/Sports/Family/Business/Health/Film/Comedy/Other\n",
    "[subcategory]: specific type\n",
    "[event_date]: YYYY-MM-DD\n",
    "[event_time]: HH:MM or All Day\n",
    "[venue_name]: name\n",
    "[address]: street address or N/A\n",
    "[description]: 2-3 sentences about the event\n",
    "[price_range]: Free or £10-£25 or N/A\n",
    "[source_url]: the real verified URL of the event page - do NOT write N/A, search the web to find it"
  )

  geo_fields    <- "\n[latitude]: decimal degrees or N/A\n[longitude]: decimal degrees or N/A"
  ticket_fields <- "\n[ticket_url]: URL or N/A\n[extra_info]: brief notes or N/A"

  optional_block <- switch(optional_fields %||% "core",
    "core"         = "",
    "core_geo"     = geo_fields,
    "core_tickets" = ticket_fields,
    "full"         = paste0(geo_fields, ticket_fields),
    ""
  )

  paste0(
    "Use your web search tool to find ", top_n, " REAL, confirmed, publicly announced events ",
    "in ", location_str, " between ", date_str, ".\n",
    "Category: ", cat_str, ".", extra_line, "\n\n",
    "IMPORTANT RULES:\n",
    "- Only include events that are real and publicly announced. Do NOT invent or guess events.\n",
    "- Search the web to verify each event exists and find its source URL.\n",
    "- source_url must be the real event page URL. Search for it - do not write N/A.\n",
    "- If you cannot find enough real events, return fewer than ", top_n, " rather than making events up.\n",
    "- Do not include events you are not confident actually exist.\n\n",
    "Output ONLY this block format. One blank line between events. No extra text before or after.\n\n",
    "[city]: ", if (nchar(trimws(city)) > 0) city else "Global", "\n",
    "[country]: ", if (nchar(trimws(country)) > 0) country else "Various", "\n",
    "[scan_date]: ", as.character(Sys.Date()), "\n\n",
    core_fields, optional_block
  )
}


# =============================================================================
# =======================  FUNDING PROGRAMMES  ===============================
# =============================================================================
# Flat multi-entry format - one block per programme, blank line between.
# Unlike Day Planner/Events, each programme is a complete standalone record
# (no shared header across entries): "programme_name" is the field that
# starts a new record.

PROGRAMME_FIELDS <- c(
  "programme_name", "category", "country", "city_region",
  "amount_of_money", "conditions", "key_sponsors", "key_organiser_profiles",
  "areas_of_application", "start_date_for_applying", "deadline",
  "recommendations_for_applying", "verified_urls"
)

parse_programme_text <- function(text) {
  lines <- strsplit(text, "\n")[[1]]
  entries <- list()
  current_entry <- list()
  last_field <- NULL

  flush_entry <- function() {
    if (length(current_entry) > 0 && !is.null(current_entry$programme_name)) {
      entries[[length(entries) + 1]] <<- current_entry
    }
  }

  for (line in lines) {
    line <- trimws(line)
    if (line == "") next
    matched <- FALSE

    for (field in PROGRAMME_FIELDS) {
      pat <- paste0("^\\[", field, "\\]:\\s*(.*)$")
      if (grepl(pat, line, ignore.case = TRUE)) {
        value <- trimws(sub(pat, "\\1", line, ignore.case = TRUE))
        if (field == "programme_name") { flush_entry(); current_entry <- list() }
        current_entry[[field]] <- value
        last_field <- field
        matched <- TRUE
        break
      }
    }

    if (!matched && length(current_entry) > 0 && !is.null(last_field) && !grepl("^\\[", line)) {
      current_entry[[last_field]] <- paste(current_entry[[last_field]], line)
    }
  }
  flush_entry()

  if (length(entries) == 0) stop("No valid programme entries found in text")

  parsed_df <- data.frame(
    category = character(), country = character(), city_region = character(),
    programme_name = character(), amount_of_money = character(), conditions = character(),
    key_sponsors = character(), key_organiser_profiles = character(),
    areas_of_application = character(), start_date_for_applying = character(),
    deadline = character(), recommendations_for_applying = character(),
    verified_urls = character(), stringsAsFactors = FALSE
  )

  for (entry in entries) {
    parsed_df <- rbind(parsed_df, data.frame(
      category = entry$category %||% "",
      country = entry$country %||% "",
      city_region = entry$city_region %||% "All",
      programme_name = entry$programme_name %||% "",
      amount_of_money = entry$amount_of_money %||% "",
      conditions = entry$conditions %||% "",
      key_sponsors = entry$key_sponsors %||% "",
      key_organiser_profiles = entry$key_organiser_profiles %||% "",
      areas_of_application = entry$areas_of_application %||% "",
      start_date_for_applying = entry$start_date_for_applying %||% "",
      deadline = entry$deadline %||% "",
      recommendations_for_applying = entry$recommendations_for_applying %||% "",
      verified_urls = entry$verified_urls %||% "",
      stringsAsFactors = FALSE
    ))
  }
  parsed_df
}

overwrite_programme_taxonomy <- function(text, category, country, city_region) {
  lines <- strsplit(text, "\n")[[1]]
  for (i in seq_along(lines)) {
    if (grepl("^\\[category\\]:", lines[i], ignore.case = TRUE)) lines[i] <- paste0("[category]: ", category)
    else if (grepl("^\\[country\\]:", lines[i], ignore.case = TRUE)) lines[i] <- paste0("[country]: ", country)
    else if (grepl("^\\[city_region\\]:", lines[i], ignore.case = TRUE)) lines[i] <- paste0("[city_region]: ", city_region)
  }
  paste(lines, collapse = "\n")
}

generate_programme_prompt <- function(category, country, city_region, search_focus, n_results = 4) {
  region_text <- if (identical(city_region, "All") || nchar(trimws(city_region)) == 0) country
                 else paste0(city_region, ", ", country)
  focus_text <- if (nchar(trimws(search_focus)) > 0) search_focus
                else "No further focus provided - use your best judgement for relevant, well-known programmes."

  paste0(
    'You are a research assistant specializing in startup/business funding programmes. ',
    'Find up to ', n_results, ' real, well-known ', category, ' programmes relevant to ', region_text, '. ',
    'Focus area: ', focus_text, '\n\n',
    'CRITICAL ACCURACY RULES:\n',
    '- Only include programmes you have genuine knowledge of. Do NOT invent fictional programmes.\n',
    '- If you are not confident about a specific date, amount, or URL, say so explicitly in that field ',
    '(e.g. "Check official site - exact deadline varies by year") rather than guessing a precise-looking but unverified value.\n',
    '- Dates should be in the format YYYY-MM-DD when known and confident.\n\n',
    'For EACH programme, output EXACTLY this format (no markdown, no extra commentary):\n\n',
    '[programme_name]: Full official name of the programme\n',
    '[category]: ', category, '\n',
    '[country]: ', country, '\n',
    '[city_region]: ', city_region, '\n',
    '[amount_of_money]: Funding amount or range offered (e.g. "Up to EUR 2.5 million" or "Equity-free grant, USD 50,000")\n',
    '[conditions]: Key eligibility conditions (company stage, sector, location requirements, etc.)\n',
    '[key_sponsors]: Who funds/sponsors this programme\n',
    '[key_organiser_profiles]: Names/roles of key people who run or represent the programme, if known\n',
    '[areas_of_application]: Sectors or fields this programme applies to\n',
    '[start_date_for_applying]: When applications open (YYYY-MM-DD if known, otherwise a description)\n',
    '[deadline]: Application deadline (YYYY-MM-DD if known, otherwise a description, e.g. "Rolling basis")\n',
    '[recommendations_for_applying]: Practical tips for a strong application\n',
    '[verified_urls]: Official URL(s) for this programme, comma-separated. Only include URLs you are ',
    'reasonably confident are correct.\n\n',
    'Separate each programme with a blank line. Every field must be present for every programme ',
    '(if something is genuinely unknown, write "Not confirmed - verify on official site").\n\n',
    'Now find and list the programmes.'
  )
}

# ── Category (single-level "Add New") - renamed from the generic
#    category_dropdown_ui/setup_category_cascade/CATEGORY_ADD_NEW_VALUE,
#    which collided with Events Scheduling's own Category cascade ──────────
FUNDING_CATEGORY_ADD_NEW_VALUE <- "__ADD_NEW_CATEGORY_FUND__"
FUNDING_DEFAULT_CATEGORIES <- c("Grant", "Incubator", "Accelerator", "Competition")

funding_category_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("category_select"), "Category: *",
                choices = c(setNames(FUNDING_DEFAULT_CATEGORIES, FUNDING_DEFAULT_CATEGORIES),
                            "+ Add New Category" = FUNDING_CATEGORY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("category_select"), FUNDING_CATEGORY_ADD_NEW_VALUE),
      textInput(ns("new_category_text"), "New Category Name:", placeholder = "e.g., Fellowship, Award")
    )
  )
}

setup_funding_category_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_funding()
    if (!api_manager$bq_authenticated) return(data.frame(category = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_funding_taxonomy(), error = function(e) data.frame(category = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
    all_categories <- sort(unique(c(FUNDING_DEFAULT_CATEGORIES, stored)))
    choices <- c(setNames(all_categories, all_categories), "+ Add New Category" = FUNDING_CATEGORY_ADD_NEW_VALUE)
    current <- isolate(input$category_select)
    selected <- if (!is.null(current) && current %in% choices) current else all_categories[1]
    updateSelectInput(session, "category_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  reactive({
    if (identical(input$category_select, FUNDING_CATEGORY_ADD_NEW_VALUE)) trimws(input$new_category_text %||% "")
    else input$category_select %||% ""
  })
}

# ── Country / City-Region (defaults to "All") - renamed from the generic
#    country_cityregion_dropdown_ui/setup_country_cityregion_cascade, which
#    collided with Day Planner's own Country/City cascade ──────────────────
FUNDING_COUNTRY_ADD_NEW_VALUE <- "__ADD_NEW_COUNTRY_FUND__"
FUNDING_CITYREGION_ADD_NEW_VALUE <- "__ADD_NEW_CITYREGION_FUND__"

funding_country_cityregion_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("country_select"), "Country: *",
                choices = c("+ Add New Country" = FUNDING_COUNTRY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("country_select"), FUNDING_COUNTRY_ADD_NEW_VALUE),
      textInput(ns("new_country_text"), "New Country Name:", placeholder = "e.g., Germany")
    ),
    selectInput(ns("cityregion_select"), "City / Region:",
                choices = c("All" = "All", "+ Add New City/Region" = FUNDING_CITYREGION_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("cityregion_select"), FUNDING_CITYREGION_ADD_NEW_VALUE),
      textInput(ns("new_cityregion_text"), "New City/Region Name:", placeholder = "e.g., Bavaria, Berlin")
    )
  )
}

setup_funding_country_cityregion_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_funding()
    if (!api_manager$bq_authenticated) return(data.frame(country = character(), city_region = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_funding_taxonomy(), error = function(e) data.frame(country = character(), city_region = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    countries <- sort(unique(tax$country[nchar(trimws(tax$country)) > 0]))
    choices <- c("+ Add New Country" = FUNDING_COUNTRY_ADD_NEW_VALUE, setNames(countries, countries))
    current <- isolate(input$country_select)
    selected <- if (!is.null(current) && current %in% choices) current else FUNDING_COUNTRY_ADD_NEW_VALUE
    updateSelectInput(session, "country_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  observeEvent(input$country_select, {
    tax <- taxonomy()
    base_choices <- c("All" = "All", "+ Add New City/Region" = FUNDING_CITYREGION_ADD_NEW_VALUE)
    if (is.null(input$country_select) || input$country_select == FUNDING_COUNTRY_ADD_NEW_VALUE) {
      updateSelectInput(session, "cityregion_select", choices = base_choices)
      return()
    }
    regions <- sort(unique(tax$city_region[tax$country == input$country_select &
                                            nchar(trimws(tax$city_region)) > 0 & tax$city_region != "All"]))
    if (length(regions) == 0) {
      updateSelectInput(session, "cityregion_select", choices = base_choices)
    } else {
      updateSelectInput(session, "cityregion_select",
                        choices = c("All" = "All", setNames(regions, regions),
                                    "+ Add New City/Region" = FUNDING_CITYREGION_ADD_NEW_VALUE))
    }
  }, ignoreInit = TRUE)

  reactive({
    country <- if (identical(input$country_select, FUNDING_COUNTRY_ADD_NEW_VALUE)) trimws(input$new_country_text %||% "") else input$country_select %||% ""
    city_region <- if (identical(input$cityregion_select, FUNDING_CITYREGION_ADD_NEW_VALUE)) trimws(input$new_cityregion_text %||% "") else input$cityregion_select %||% "All"
    list(country = country, city_region = city_region)
  })
}

# =============================================================================
# =============================  DIET PLANNER  ================================
# =============================================================================
# Text format - 3-line bracketed header (log_date, diet_type,
# dietary_restrictions), then repeating meal entries + one Summary row.
# Mirrors the Day Planner's parse_schedule_text() architecture exactly, just
# with a shorter (3-line) header since diet has fewer day-level dimensions
# than a trip (no country/city equivalent).

parse_diet_text <- function(text) {
  lines <- strsplit(text, "\n")[[1]]

  log_date <- NULL; diet_type <- NULL; dietary_restrictions <- NULL
  metadata_count <- 0
  for (i in seq_len(min(10, length(lines)))) {
    line <- trimws(lines[i])
    if (grepl("^\\[.+\\]$", line)) {
      metadata_count <- metadata_count + 1
      value <- gsub("^\\[|\\]$", "", line)
      if (metadata_count == 1) log_date <- value
      else if (metadata_count == 2) diet_type <- value
      else if (metadata_count == 3) dietary_restrictions <- value
      else break
    }
  }

  if (is.null(log_date) || is.null(diet_type)) {
    stop("Could not find log date and diet type in diet text")
  }
  if (is.null(dietary_restrictions)) dietary_restrictions <- "N/A"

  entries <- list()
  current_entry <- list()

  for (line in lines) {
    line <- trimws(line)
    if (line == "" || grepl("^\\[.+\\]$", line)) {
      if (length(current_entry) >= 2 && !is.null(current_entry$row_type)) {
        entries[[length(entries) + 1]] <- current_entry
        current_entry <- list()
      }
      next
    }

    if (grepl("^\\[row_type\\]:", line, ignore.case = TRUE)) {
      current_entry$row_type <- trimws(sub("^\\[row_type\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[meal_name\\]:", line, ignore.case = TRUE)) {
      current_entry$meal_name <- trimws(sub("^\\[meal_name\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[meal_details\\]:", line, ignore.case = TRUE)) {
      current_entry$meal_details <- trimws(sub("^\\[meal_details\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[meal_time\\]:", line, ignore.case = TRUE)) {
      current_entry$meal_time <- trimws(sub("^\\[meal_time\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[calories_macros\\]:", line, ignore.case = TRUE)) {
      current_entry$calories_macros <- trimws(sub("^\\[calories_macros\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[observations\\]:", line, ignore.case = TRUE)) {
      current_entry$observations <- trimws(sub("^\\[observations\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (length(current_entry) > 0 && !is.null(current_entry$observations)) {
      current_entry$observations <- paste(current_entry$observations, line)
    }
  }
  if (length(current_entry) >= 2 && !is.null(current_entry$row_type)) {
    entries[[length(entries) + 1]] <- current_entry
  }

  if (length(entries) == 0) stop("No valid meal/summary rows found in diet text")

  parsed_df <- data.frame(
    log_date = character(), diet_type = character(), dietary_restrictions = character(),
    row_type = character(), row_sequence = integer(),
    meal_name = character(), meal_details = character(), meal_time = character(),
    calories_macros = character(), observations = character(), stringsAsFactors = FALSE
  )

  for (i in seq_along(entries)) {
    entry <- entries[[i]]
    parsed_df <- rbind(parsed_df, data.frame(
      log_date = log_date, diet_type = diet_type, dietary_restrictions = dietary_restrictions,
      row_type = entry$row_type, row_sequence = i,
      meal_name = ifelse(is.null(entry$meal_name), "", entry$meal_name),
      meal_details = ifelse(is.null(entry$meal_details), "", entry$meal_details),
      meal_time = ifelse(is.null(entry$meal_time), "N/A", entry$meal_time),
      calories_macros = ifelse(is.null(entry$calories_macros), "", entry$calories_macros),
      observations = ifelse(is.null(entry$observations), "", entry$observations),
      stringsAsFactors = FALSE
    ))
  }
  parsed_df
}

generate_diet_prompt <- function(log_date, diet_type, dietary_restrictions = "", preferences = "", target_calories = NULL) {
  restrictions_text <- if (nchar(trimws(dietary_restrictions)) > 0) dietary_restrictions else "None specified"
  preferences_text <- if (nchar(trimws(preferences)) > 0) preferences else "No further preferences provided - use your best judgement for a balanced day."
  calorie_text <- if (!is.null(target_calories) && !is.na(target_calories) && target_calories > 0) {
    paste0(target_calories, " kcal")
  } else {
    "not specified - use a sensible target for the diet type"
  }

  paste0(
    'You are an expert nutrition-planning assistant. Plan a realistic, balanced day of meals for ',
    log_date, ' following a "', diet_type, '" diet, in this EXACT format:

Context:
- Dietary restrictions/allergies: ', restrictions_text, '
- Daily calorie target: ', calorie_text, '
- Additional preferences: ', preferences_text, '

Format Requirements:
1. Start with day metadata in brackets (3 lines):
[', log_date, ']
[', diet_type, ']
[', restrictions_text, ']

2. For each meal, use this EXACT pattern (typically Breakfast, Lunch, Dinner, plus 1-2 Snacks):
[row_type]: Meal
[meal_name]: e.g. "Breakfast - Greek Yogurt Parfait"
[meal_details]: Ingredients and brief preparation notes
[meal_time]: Suggested time, e.g. "7:30 AM"
[calories_macros]: e.g. "420 kcal (P:32g / C:38g / F:14g)"
[observations]: Practical tips, substitutions, or why this meal fits the diet type/restrictions

3. CRITICAL RULES:
   - Respect the dietary restrictions/allergies STRICTLY - never suggest an excluded ingredient
   - Keep total daily calories close to the target (within about 10%)
   - Balance macros appropriately for the stated diet type (e.g. higher protein for Muscle Gain, ',
   'lower carb for Keto)
   - Produce a realistic number of meals for one day (typically 3-5) - do not pad with filler

4. Close with EXACTLY ONE Summary row for the whole day:
[row_type]: Summary
[meal_name]: Day Summary
[meal_details]: One-line title summarising the day\'s diet
[meal_time]: N/A
[calories_macros]: Total for the day, e.g. "Total: 1850 kcal (P:110g / C:180g / F:60g)"
[observations]: Key nutritional insights - how well it meets the target, hydration reminder, any risks or
gaps to watch for

5. FORMATTING RULES:
   - Separate each row entry with ONE blank line
   - NO extra markdown, NO headers with #, NO entry numbers
   - Use the exact bracket format shown above; every field must be present on every row (use "N/A" if it
     truly does not apply - never omit the line)

Now generate the complete day of meals for ', log_date, ' with ALL required fields for each row.'
  )
}

overwrite_diet_header <- function(text, log_date, diet_type, dietary_restrictions) {
  lines <- strsplit(text, "\n")[[1]]
  bracket_idx <- c()
  for (i in seq_len(min(10, length(lines)))) {
    if (grepl("^\\[.+\\]$", trimws(lines[i]))) bracket_idx <- c(bracket_idx, i)
    if (length(bracket_idx) >= 3) break
  }
  if (length(bracket_idx) < 2) return(text)

  lines[bracket_idx[1]] <- paste0("[", log_date, "]")
  lines[bracket_idx[2]] <- paste0("[", diet_type, "]")
  diettype_line <- bracket_idx[2]

  flat_restrictions <- gsub("\\s*\n\\s*", " | ", trimws(dietary_restrictions %||% ""))
  if (nchar(flat_restrictions) == 0) flat_restrictions <- "N/A"

  if (length(bracket_idx) >= 3) lines[bracket_idx[3]] <- paste0("[", flat_restrictions, "]")
  else lines <- append(lines, paste0("[", flat_restrictions, "]"), after = diettype_line)

  paste(lines, collapse = "\n")
}

# ── Diet Type (single-level "Add New" pattern) ───────────────────────────────
DIET_TYPE_ADD_NEW_VALUE <- "__ADD_NEW_DIETTYPE__"
DEFAULT_DIET_TYPES <- c("Balanced", "Weight Loss", "Muscle Gain", "Keto",
                        "Vegetarian", "Vegan", "Mediterranean", "Low Carb")

diet_type_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("diet_type_select"), "Diet Type: *",
                choices = c(setNames(DEFAULT_DIET_TYPES, DEFAULT_DIET_TYPES),
                            "+ Add New Diet Type" = DIET_TYPE_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("diet_type_select"), DIET_TYPE_ADD_NEW_VALUE),
      textInput(ns("new_diet_type_text"), "New Diet Type Name:", placeholder = "e.g., Paleo, Intermittent Fasting")
    )
  )
}

setup_diet_type_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_diet()
    if (!api_manager$bq_authenticated) return(data.frame(diet_type = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_diet_taxonomy(), error = function(e) data.frame(diet_type = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored <- sort(unique(tax$diet_type[nchar(trimws(tax$diet_type)) > 0]))
    all_types <- sort(unique(c(DEFAULT_DIET_TYPES, stored)))
    choices <- c(setNames(all_types, all_types), "+ Add New Diet Type" = DIET_TYPE_ADD_NEW_VALUE)
    current <- isolate(input$diet_type_select)
    selected <- if (!is.null(current) && current %in% choices) current else all_types[1]
    updateSelectInput(session, "diet_type_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  reactive({
    if (identical(input$diet_type_select, DIET_TYPE_ADD_NEW_VALUE)) trimws(input$new_diet_type_text %||% "")
    else input$diet_type_select %||% ""
  })
}

# =============================================================================
# ===========================  EXERCISE TRACKER  =============================
# =============================================================================
# Text format - 3-line bracketed header (workout_date, session_type,
# session_notes), then repeating exercise/activity entries + one Summary row.
# Same architecture as Day Planner / Diet Planner.

parse_exercise_text <- function(text) {
  lines <- strsplit(text, "\n")[[1]]

  workout_date <- NULL; session_type <- NULL; session_notes <- NULL
  metadata_count <- 0
  for (i in seq_len(min(10, length(lines)))) {
    line <- trimws(lines[i])
    if (grepl("^\\[.+\\]$", line)) {
      metadata_count <- metadata_count + 1
      value <- gsub("^\\[|\\]$", "", line)
      if (metadata_count == 1) workout_date <- value
      else if (metadata_count == 2) session_type <- value
      else if (metadata_count == 3) session_notes <- value
      else break
    }
  }

  if (is.null(workout_date) || is.null(session_type)) {
    stop("Could not find workout date and session type in exercise text")
  }
  if (is.null(session_notes)) session_notes <- "N/A"

  entries <- list()
  current_entry <- list()

  for (line in lines) {
    line <- trimws(line)
    if (line == "" || grepl("^\\[.+\\]$", line)) {
      if (length(current_entry) >= 2 && !is.null(current_entry$row_type)) {
        entries[[length(entries) + 1]] <- current_entry
        current_entry <- list()
      }
      next
    }

    if (grepl("^\\[row_type\\]:", line, ignore.case = TRUE)) {
      current_entry$row_type <- trimws(sub("^\\[row_type\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[exercise_category\\]:", line, ignore.case = TRUE)) {
      current_entry$exercise_category <- trimws(sub("^\\[exercise_category\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[exercise_name\\]:", line, ignore.case = TRUE)) {
      current_entry$exercise_name <- trimws(sub("^\\[exercise_name\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[exercise_details\\]:", line, ignore.case = TRUE)) {
      current_entry$exercise_details <- trimws(sub("^\\[exercise_details\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[metric_primary\\]:", line, ignore.case = TRUE)) {
      current_entry$metric_primary <- trimws(sub("^\\[metric_primary\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[metric_secondary\\]:", line, ignore.case = TRUE)) {
      current_entry$metric_secondary <- trimws(sub("^\\[metric_secondary\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[calories_burned\\]:", line, ignore.case = TRUE)) {
      current_entry$calories_burned <- trimws(sub("^\\[calories_burned\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (grepl("^\\[observations\\]:", line, ignore.case = TRUE)) {
      current_entry$observations <- trimws(sub("^\\[observations\\]:\\s*", "", line, ignore.case = TRUE))
    } else if (length(current_entry) > 0 && !is.null(current_entry$observations)) {
      current_entry$observations <- paste(current_entry$observations, line)
    }
  }
  if (length(current_entry) >= 2 && !is.null(current_entry$row_type)) {
    entries[[length(entries) + 1]] <- current_entry
  }

  if (length(entries) == 0) stop("No valid exercise/summary rows found in exercise text")

  parsed_df <- data.frame(
    workout_date = character(), session_type = character(), session_notes = character(),
    row_type = character(), row_sequence = integer(),
    exercise_category = character(), exercise_name = character(), exercise_details = character(),
    metric_primary = character(), metric_secondary = character(),
    calories_burned = character(), observations = character(), stringsAsFactors = FALSE
  )

  for (i in seq_along(entries)) {
    entry <- entries[[i]]
    parsed_df <- rbind(parsed_df, data.frame(
      workout_date = workout_date, session_type = session_type, session_notes = session_notes,
      row_type = entry$row_type, row_sequence = i,
      exercise_category = ifelse(is.null(entry$exercise_category), "", entry$exercise_category),
      exercise_name = ifelse(is.null(entry$exercise_name), "", entry$exercise_name),
      exercise_details = ifelse(is.null(entry$exercise_details), "", entry$exercise_details),
      metric_primary = ifelse(is.null(entry$metric_primary), "", entry$metric_primary),
      metric_secondary = ifelse(is.null(entry$metric_secondary), "N/A", entry$metric_secondary),
      calories_burned = ifelse(is.null(entry$calories_burned), "N/A", entry$calories_burned),
      observations = ifelse(is.null(entry$observations), "", entry$observations),
      stringsAsFactors = FALSE
    ))
  }
  parsed_df
}

generate_workout_prompt <- function(workout_date, session_type, session_notes = "", fitness_level = "Intermediate", duration_minutes = NULL) {
  notes_text <- if (nchar(trimws(session_notes)) > 0) session_notes else "No further preferences provided - use your best judgement."
  duration_text <- if (!is.null(duration_minutes) && !is.na(duration_minutes) && duration_minutes > 0) {
    paste0("~", duration_minutes, " minutes total")
  } else {
    "not specified - plan a realistic session length for this type"
  }

  paste0(
    'You are an expert fitness-planning assistant. Plan a realistic, well-structured "', session_type,
    '" workout session for ', workout_date, ' in this EXACT format:

Context:
- Fitness level: ', fitness_level, '
- Target session duration: ', duration_text, '
- Additional notes/goals: ', notes_text, '

Format Requirements:
1. Start with session metadata in brackets (3 lines):
[', workout_date, ']
[', session_type, ']
[', notes_text, ']

2. For each exercise or activity segment, use this EXACT pattern:
[row_type]: Exercise
[exercise_category]: Cardio | Weights | Swimming | Running | Yoga | Hiking | Sports | Other - pick the
one that best matches this specific entry (a session can mix categories, e.g. a warm-up Cardio entry
before a Weights session)
[exercise_name]: Specific exercise/activity name, e.g. "Barbell Back Squat" or "Freestyle Swim Laps"
[exercise_details]: For Weights, describe sets/reps/rest, e.g. "4 sets x 8 reps, 90s rest". For Cardio/
Swimming/Running, describe pace or effort. For Yoga/Hiking, describe the style/route.
[metric_primary]: The main quantifiable metric, e.g. "4 sets x 8 reps" or "5.2 km" or "45 min"
[metric_secondary]: A secondary metric, e.g. "70 kg" (weight used) or "Avg pace 5:30/km" or "320m elevation gain" or "N/A" if not applicable
[calories_burned]: Estimated calories for this entry, e.g. "180 kcal", or "N/A" for a pure strength set with no meaningful calorie burn
[observations]: Form cues, RPE/intensity, or practical tips for this entry

3. CRITICAL RULES:
   - Structure the session logically (warm-up, main work, cool-down where appropriate)
   - Match the exercise selection and volume to the stated fitness level
   - For Weights sessions, group related exercises sensibly (e.g. push/pull/legs) and respect realistic rest periods
   - Produce a realistic number of entries for the session (typically 4-8) - do not pad with filler

4. Close with EXACTLY ONE Summary row for the whole session:
[row_type]: Summary
[exercise_category]: N/A
[exercise_name]: Workout Summary
[exercise_details]: One-line title summarising the session
[metric_primary]: Total duration, e.g. "Total: 55 min"
[metric_secondary]: Total volume if relevant (e.g. "Total: 12,400 kg lifted") or "N/A"
[calories_burned]: Total estimated calories for the whole session, e.g. "Total: 480 kcal"
[observations]: Key insights - progress notes, recovery recommendations, what to focus on next time

5. FORMATTING RULES:
   - Separate each row entry with ONE blank line
   - NO extra markdown, NO headers with #, NO entry numbers
   - Use the exact bracket format shown above; every field must be present on every row (use "N/A" if it
     truly does not apply - never omit the line)

Now generate the complete workout session for ', workout_date, ' with ALL required fields for each row.'
  )
}

overwrite_workout_header <- function(text, workout_date, session_type, session_notes) {
  lines <- strsplit(text, "\n")[[1]]
  bracket_idx <- c()
  for (i in seq_len(min(10, length(lines)))) {
    if (grepl("^\\[.+\\]$", trimws(lines[i]))) bracket_idx <- c(bracket_idx, i)
    if (length(bracket_idx) >= 3) break
  }
  if (length(bracket_idx) < 2) return(text)

  lines[bracket_idx[1]] <- paste0("[", workout_date, "]")
  lines[bracket_idx[2]] <- paste0("[", session_type, "]")
  sessiontype_line <- bracket_idx[2]

  flat_notes <- gsub("\\s*\n\\s*", " | ", trimws(session_notes %||% ""))
  if (nchar(flat_notes) == 0) flat_notes <- "N/A"

  if (length(bracket_idx) >= 3) lines[bracket_idx[3]] <- paste0("[", flat_notes, "]")
  else lines <- append(lines, paste0("[", flat_notes, "]"), after = sessiontype_line)

  paste(lines, collapse = "\n")
}

# ── Session Type (day-level, single "Add New" pattern) ──────────────────────
SESSION_TYPE_ADD_NEW_VALUE <- "__ADD_NEW_SESSIONTYPE__"
DEFAULT_SESSION_TYPES <- c("Gym", "Cardio", "Swimming", "Running", "Yoga", "Hiking", "Mixed")

session_type_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("session_type_select"), "Session Type: *",
                choices = c(setNames(DEFAULT_SESSION_TYPES, DEFAULT_SESSION_TYPES),
                            "+ Add New Session Type" = SESSION_TYPE_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("session_type_select"), SESSION_TYPE_ADD_NEW_VALUE),
      textInput(ns("new_session_type_text"), "New Session Type Name:", placeholder = "e.g., CrossFit, Pilates")
    )
  )
}

setup_session_type_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_exercise()
    if (!api_manager$bq_authenticated) return(data.frame(session_type = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_exercise_taxonomy(), error = function(e) data.frame(session_type = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored <- sort(unique(tax$session_type[nchar(trimws(tax$session_type)) > 0]))
    all_types <- sort(unique(c(DEFAULT_SESSION_TYPES, stored)))
    choices <- c(setNames(all_types, all_types), "+ Add New Session Type" = SESSION_TYPE_ADD_NEW_VALUE)
    current <- isolate(input$session_type_select)
    selected <- if (!is.null(current) && current %in% choices) current else all_types[1]
    updateSelectInput(session, "session_type_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  reactive({
    if (identical(input$session_type_select, SESSION_TYPE_ADD_NEW_VALUE)) trimws(input$new_session_type_text %||% "")
    else input$session_type_select %||% ""
  })
}

# ── Exercise Category -> Exercise Name (row-level, 2-level "Add New" cascade,
#    seeded with real, common exercises per category so the dropdown is
#    immediately useful before any data has been logged) ────────────────────
EXERCISE_CATEGORY_ADD_NEW_VALUE <- "__ADD_NEW_EXCATEGORY__"
EXERCISE_NAME_ADD_NEW_VALUE     <- "__ADD_NEW_EXNAME__"
DEFAULT_EXERCISE_CATEGORIES <- c("Cardio", "Weights", "Swimming", "Running", "Yoga", "Hiking", "Sports", "Other")

DEFAULT_EXERCISE_NAMES_BY_CATEGORY <- list(
  "Cardio"   = c("Treadmill Run", "Stationary Bike", "Rowing Machine", "Elliptical", "Stair Climber", "Jump Rope"),
  "Weights"  = c("Bench Press", "Squat", "Deadlift", "Overhead Press", "Barbell Row", "Bicep Curl",
                "Tricep Extension", "Lat Pulldown", "Leg Press", "Leg Curl", "Shoulder Press",
                "Pull-Up", "Push-Up", "Plank"),
  "Swimming" = c("Freestyle", "Backstroke", "Breaststroke", "Butterfly", "Individual Medley"),
  "Running"  = c("Outdoor Run", "Treadmill Run", "Trail Run", "Interval Sprints"),
  "Yoga"     = c("Vinyasa Flow", "Hatha Yoga", "Power Yoga", "Yin Yoga", "Restorative Yoga"),
  "Hiking"   = c("Trail Hike", "Mountain Hike", "Nature Walk"),
  "Sports"   = c("Basketball", "Tennis", "Soccer", "Cycling", "Rock Climbing", "Boxing"),
  "Other"    = c()
)

exercise_category_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("exercise_category_select"), "Exercise Category: *",
                choices = c(setNames(DEFAULT_EXERCISE_CATEGORIES, DEFAULT_EXERCISE_CATEGORIES),
                            "+ Add New Category" = EXERCISE_CATEGORY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("exercise_category_select"), EXERCISE_CATEGORY_ADD_NEW_VALUE),
      textInput(ns("new_exercise_category_text"), "New Category Name:", placeholder = "e.g., Martial Arts")
    ),
    selectInput(ns("exercise_name_select"), "Exercise / Activity Name: *",
                choices = c("+ Add New Exercise" = EXERCISE_NAME_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("exercise_name_select"), EXERCISE_NAME_ADD_NEW_VALUE),
      textInput(ns("new_exercise_name_text"), "New Exercise/Activity Name:", placeholder = "e.g., Kettlebell Swing")
    )
  )
}

setup_exercise_category_cascade <- function(input, output, session, api_manager) {
  taxonomy <- reactive({
    api_manager$state_trigger_exercise()
    if (!api_manager$bq_authenticated) return(data.frame(exercise_category = character(), exercise_name = character(), stringsAsFactors = FALSE))
    tryCatch(api_manager$bq_get_exercise_taxonomy(), error = function(e) data.frame(exercise_category = character(), exercise_name = character(), stringsAsFactors = FALSE))
  })

  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored_cats <- sort(unique(tax$exercise_category[nchar(trimws(tax$exercise_category)) > 0]))
    all_cats <- sort(unique(c(DEFAULT_EXERCISE_CATEGORIES, stored_cats)))
    choices <- c(setNames(all_cats, all_cats), "+ Add New Category" = EXERCISE_CATEGORY_ADD_NEW_VALUE)
    current <- isolate(input$exercise_category_select)
    selected <- if (!is.null(current) && current %in% choices) current else all_cats[1]
    updateSelectInput(session, "exercise_category_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)

  observeEvent(input$exercise_category_select, {
    tax <- taxonomy()
    cat_sel <- input$exercise_category_select

    if (is.null(cat_sel) || cat_sel == EXERCISE_CATEGORY_ADD_NEW_VALUE) {
      updateSelectInput(session, "exercise_name_select", choices = c("+ Add New Exercise" = EXERCISE_NAME_ADD_NEW_VALUE))
      return()
    }

    stored_names <- sort(unique(tax$exercise_name[tax$exercise_category == cat_sel & nchar(trimws(tax$exercise_name)) > 0]))
    default_names <- DEFAULT_EXERCISE_NAMES_BY_CATEGORY[[cat_sel]] %||% character()
    all_names <- sort(unique(c(default_names, stored_names)))

    if (length(all_names) == 0) {
      updateSelectInput(session, "exercise_name_select", choices = c("+ Add New Exercise" = EXERCISE_NAME_ADD_NEW_VALUE))
    } else {
      updateSelectInput(session, "exercise_name_select",
                        choices = c(setNames(all_names, all_names), "+ Add New Exercise" = EXERCISE_NAME_ADD_NEW_VALUE))
    }
  }, ignoreInit = TRUE)

  reactive({
    category <- if (identical(input$exercise_category_select, EXERCISE_CATEGORY_ADD_NEW_VALUE)) trimws(input$new_exercise_category_text %||% "") else input$exercise_category_select %||% ""
    exercise_name <- if (identical(input$exercise_name_select, EXERCISE_NAME_ADD_NEW_VALUE)) trimws(input$new_exercise_name_text %||% "") else input$exercise_name_select %||% ""
    list(category = category, exercise_name = exercise_name)
  })
}

# Best-effort parser for the Diet Planner's calories_macros chart. Handles
# patterns like "420 kcal (P:32g / C:38g / F:14g)" or "Total: 1850 kcal
# (P:110g / C:180g / F:60g)". Returns a named list; any field not found is NA.
diet_parse_calories_macros <- function(text) {
  result <- list(calories = NA_real_, protein = NA_real_, carbs = NA_real_, fat = NA_real_)
  if (is.null(text) || is.na(text) || trimws(as.character(text)) == "") return(result)

  t <- as.character(text)

  cal_match <- regmatches(t, regexpr("([0-9]+)\\s*kcal", t, ignore.case = TRUE))
  if (length(cal_match) > 0) {
    result$calories <- as.numeric(regmatches(cal_match, regexpr("[0-9]+", cal_match)))
  }

  p_match <- regmatches(t, regexpr("P\\s*:\\s*([0-9]+)\\s*g", t, ignore.case = TRUE))
  if (length(p_match) > 0) result$protein <- as.numeric(regmatches(p_match, regexpr("[0-9]+", p_match)))

  c_match <- regmatches(t, regexpr("C\\s*:\\s*([0-9]+)\\s*g", t, ignore.case = TRUE))
  if (length(c_match) > 0) result$carbs <- as.numeric(regmatches(c_match, regexpr("[0-9]+", c_match)))

  f_match <- regmatches(t, regexpr("F\\s*:\\s*([0-9]+)\\s*g", t, ignore.case = TRUE))
  if (length(f_match) > 0) result$fat <- as.numeric(regmatches(f_match, regexpr("[0-9]+", f_match)))

  result
}

# Best-effort calorie parser for the Exercise Tracker's chart. Handles
# patterns like "180 kcal" or "Total: 480 kcal". Returns NA if not found.
exercise_parse_calories <- function(text) {
  if (is.null(text) || is.na(text) || trimws(as.character(text)) == "" ||
      tolower(trimws(as.character(text))) %in% c("n/a", "na")) return(NA_real_)
  t <- as.character(text)
  cal_match <- regmatches(t, regexpr("([0-9]+)\\s*kcal", t, ignore.case = TRUE))
  if (length(cal_match) == 0) return(NA_real_)
  as.numeric(regmatches(cal_match, regexpr("[0-9]+", cal_match)))
}
