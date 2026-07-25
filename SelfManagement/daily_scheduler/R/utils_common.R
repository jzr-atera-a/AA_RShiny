# R/utils_common.R
# Shared Utility Functions
# ========================

# Safe SQL escape for preventing injection
safe_sql_escape <- function(input_value) {
  gsub("'", "''", input_value)
}

# Best-effort duration parser (minutes) for the visualizations time chart.
# Handles patterns like "2h 00m", "1.5h", "45 min", "15 minutes", "Total: 7h 20m".
# Returns NA when no recognisable duration is found - callers must handle NA.
parse_duration_minutes <- function(text) {
  if (is.null(text) || is.na(text) || trimws(as.character(text)) == "" ||
      tolower(trimws(as.character(text))) %in% c("n/a", "na")) return(NA_real_)
  
  t <- tolower(as.character(text))
  hrs <- 0
  mins <- 0
  
  h_match <- regmatches(t, regexpr("([0-9]+(\\.[0-9]+)?)\\s*h(r|our)?s?", t))
  if (length(h_match) > 0) {
    hrs <- as.numeric(regmatches(h_match, regexpr("[0-9]+(\\.[0-9]+)?", h_match)))
  }
  m_match <- regmatches(t, regexpr("([0-9]+)\\s*m(in|inute)?s?", t))
  if (length(m_match) > 0) {
    mins <- as.numeric(regmatches(m_match, regexpr("[0-9]+", m_match)))
  }
  
  total <- hrs * 60 + mins
  if (total == 0) return(NA_real_)
  total
}

# Parse schedule text into data frame
#
# Expected format - 5-line bracketed header, then repeating row entries:
#
#   [2026-07-10]
#   [Travel]
#   [France]
#   [Paris]
#   [Museum day with an early start]
#
#   [row_type]: Location
#   [location_name]: Eiffel Tower
#   [location_details]: Champ de Mars - iconic iron lattice tower
#   [opening_hours]: 9:00 AM - 11:45 PM
#   [recommended_time]: 9:00 AM - 11:00 AM (2h 00m)
#   [observations]: Arrive early to avoid queues; buy tickets online
#
#   [row_type]: Transport
#   ...
#
#   [row_type]: Summary
#   [location_name]: Day Summary
#   [location_details]: Paris Day 1 - Eiffel Tower and Louvre highlights
#   [opening_hours]: N/A
#   [recommended_time]: Total: 7h 20m
#   [observations]: Efficient route minimizes backtracking
#
parse_schedule_text <- function(text) {
  
  lines <- strsplit(text, "\n")[[1]]
  
  # Extract metadata (first 5 bracketed lines)
  schedule_date <- NULL
  day_type <- NULL
  country <- NULL
  city <- NULL
  trip_details <- NULL
  
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
  
  # Parse entries
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
    }
    else if (grepl("^\\[location_name\\]:", line, ignore.case = TRUE)) {
      current_entry$location_name <- trimws(sub("^\\[location_name\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (grepl("^\\[location_details\\]:", line, ignore.case = TRUE)) {
      current_entry$location_details <- trimws(sub("^\\[location_details\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (grepl("^\\[opening_hours\\]:", line, ignore.case = TRUE)) {
      current_entry$opening_hours <- trimws(sub("^\\[opening_hours\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (grepl("^\\[recommended_time\\]:", line, ignore.case = TRUE)) {
      current_entry$recommended_time <- trimws(sub("^\\[recommended_time\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (grepl("^\\[observations\\]:", line, ignore.case = TRUE)) {
      current_entry$observations <- trimws(sub("^\\[observations\\]:\\s*", "", line, ignore.case = TRUE))
    }
    else if (length(current_entry) > 0 && !is.null(current_entry$observations)) {
      # Multi-line accumulation for observations (often the longest free text)
      current_entry$observations <- paste(current_entry$observations, line)
    }
  }
  
  # Add last entry if exists
  if (length(current_entry) >= 2 && !is.null(current_entry$row_type)) {
    entries[[length(entries) + 1]] <- current_entry
  }
  
  if (length(entries) == 0) {
    stop("No valid location/transport/summary rows found in schedule text")
  }
  
  # Convert to data frame
  parsed_df <- data.frame(
    schedule_date = character(),
    day_type = character(),
    country = character(),
    city = character(),
    trip_details = character(),
    row_type = character(),
    row_sequence = integer(),
    location_name = character(),
    location_details = character(),
    opening_hours = character(),
    recommended_time = character(),
    observations = character(),
    stringsAsFactors = FALSE
  )
  
  for (i in seq_along(entries)) {
    entry <- entries[[i]]
    parsed_df <- rbind(parsed_df, data.frame(
      schedule_date = schedule_date,
      day_type = day_type,
      country = country,
      city = city,
      trip_details = trip_details,
      row_type = entry$row_type,
      row_sequence = i,
      location_name = ifelse(is.null(entry$location_name), "", entry$location_name),
      location_details = ifelse(is.null(entry$location_details), "", entry$location_details),
      opening_hours = ifelse(is.null(entry$opening_hours), "N/A", entry$opening_hours),
      recommended_time = ifelse(is.null(entry$recommended_time), "", entry$recommended_time),
      observations = ifelse(is.null(entry$observations), "", entry$observations),
      stringsAsFactors = FALSE
    ))
  }
  
  return(parsed_df)
}

# Generate Claude prompt for a day schedule
generate_schedule_prompt <- function(schedule_date, day_type, country = "", city = "", trip_details = "") {
  
  is_travel <- identical(day_type, "Travel")
  
  place_text <- if (nchar(country) > 0 && nchar(city) > 0) {
    paste0(city, ", ", country)
  } else if (nchar(city) > 0) {
    city
  } else {
    "a location inferred from the details below"
  }
  
  details_text <- if (nchar(trip_details) > 0) {
    trip_details
  } else {
    "No further details provided - use your best judgement for a well-rounded day."
  }
  
  prompt <- paste0(
    'You are an expert day-planning assistant. Plan an optimal, realistic schedule for a single day: ',
    schedule_date, ' (day type: ', day_type, ') in ', place_text, ' following this EXACT format:

Format Requirements:
1. Start with day metadata in brackets (5 lines):
[', schedule_date, ']
[', day_type, ']
[', if (is_travel) country else "N/A", ']
[', if (is_travel) city else "N/A", ']
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
[observations]: What to expect, what to look for, and any practical tips for this location

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
   - Every Location row is immediately followed by a Transport row to the NEXT location, except the very
     last location, which is followed directly by the Summary row
   - Produce a realistic number of stops for one day (typically 3-7 locations) - do not pad with filler

5. Close with EXACTLY ONE Summary row for the whole day:
[row_type]: Summary
[location_name]: Day Summary
[location_details]: One-line title summarising the day
[opening_hours]: N/A
[recommended_time]: Total time for the day, e.g. "Total: 7h 20m" (sum of all location + transport durations)
[observations]: Key insights - why the route is efficient, any risks, what to expect overall

6. FORMATTING RULES:
   - Separate each row entry with ONE blank line
   - NO extra markdown, NO headers with #, NO entry numbers
   - Use the exact bracket format shown above; every field must be present on every row (use "N/A" if it
     truly does not apply - never omit the line)

Now generate the complete day schedule for ', schedule_date, ' with ALL required fields for each row.'
  )
  
  return(prompt)
}

# ============================================================
# TYPE OF DAY CLASSIFICATION (single-level, "Add New" pattern)
# ============================================================
DAYTYPE_ADD_NEW_VALUE <- "__ADD_NEW_DAYTYPE__"
DEFAULT_DAY_TYPES <- c("Travel", "Work", "Conference", "Research")

# Force-overwrites the 5-line bracketed metadata header in a Claude-generated
# schedule with the exact strings the user selected in the UI, regardless of
# what Claude actually wrote. This guarantees the saved data always matches
# the user's selection exactly (no paraphrasing, capitalization drift, etc.
# from the model).
overwrite_schedule_header <- function(text, schedule_date, day_type, country, city, trip_details) {
  lines <- strsplit(text, "\n")[[1]]
  
  bracket_idx <- c()
  for (i in seq_len(min(15, length(lines)))) {
    if (grepl("^\\[.+\\]$", trimws(lines[i]))) {
      bracket_idx <- c(bracket_idx, i)
    }
    if (length(bracket_idx) >= 5) break
  }
  
  # Need at least [date] and [day_type] to know where to anchor
  if (length(bracket_idx) < 2) {
    return(text)
  }
  
  lines[bracket_idx[1]] <- paste0("[", schedule_date, "]")
  lines[bracket_idx[2]] <- paste0("[", day_type, "]")
  
  daytype_line <- bracket_idx[2]
  
  if (length(bracket_idx) >= 3) {
    lines[bracket_idx[3]] <- paste0("[", country, "]")
  } else {
    lines <- append(lines, paste0("[", country, "]"), after = daytype_line)
    bracket_idx <- c(bracket_idx, daytype_line + 1)
  }
  
  country_line <- bracket_idx[3]
  
  if (length(bracket_idx) >= 4) {
    lines[bracket_idx[4]] <- paste0("[", city, "]")
  } else {
    lines <- append(lines, paste0("[", city, "]"), after = country_line)
    bracket_idx <- c(bracket_idx, country_line + 1)
  }
  
  city_line <- bracket_idx[4]
  
  flat_details <- gsub("\\s*\n\\s*", " | ", trimws(trip_details %||% ""))
  if (nchar(flat_details) == 0) flat_details <- "N/A"
  
  if (length(bracket_idx) >= 5) {
    lines[bracket_idx[5]] <- paste0("[", flat_details, "]")
  } else {
    lines <- append(lines, paste0("[", flat_details, "]"), after = city_line)
  }
  
  paste(lines, collapse = "\n")
}

# Reusable UI block: a Type of Day dropdown (with "+ Add New Type") and a
# conditional text box that appears when "add new" is selected. Used by
# generate_schedule and add_single. `ns` must be the calling module's own
# NS(id) function so the generated input IDs are correctly namespaced.
day_type_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("day_type_select"), "Type of Day: *",
                choices = c(setNames(DEFAULT_DAY_TYPES, DEFAULT_DAY_TYPES),
                            "+ Add New Type" = DAYTYPE_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("day_type_select"), DAYTYPE_ADD_NEW_VALUE),
      textInput(ns("new_day_type_text"), "New Type Name:", placeholder = "e.g., Family, Medical, Errands")
    )
  )
}

# Wires up the reactive cascade for a Type of Day dropdown block created by
# day_type_dropdown_ui(). Call once inside a module's moduleServer(), passing
# that module's own input/output/session and the shared api_manager. Returns
# a reactive() yielding the resolved day_type string (either the selected
# existing value, or the typed "new" value when "+ Add New Type" is chosen).
setup_day_type_cascade <- function(input, output, session, api_manager) {
  
  taxonomy <- reactive({
    api_manager$state_trigger()
    if (!api_manager$bq_authenticated) {
      return(data.frame(day_type = character(), stringsAsFactors = FALSE))
    }
    tryCatch(api_manager$bq_get_taxonomy(), error = function(e) {
      data.frame(day_type = character(), stringsAsFactors = FALSE)
    })
  })
  
  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored_types <- sort(unique(tax$day_type[nchar(trimws(tax$day_type)) > 0]))
    all_types <- sort(unique(c(DEFAULT_DAY_TYPES, stored_types)))
    choices <- c(setNames(all_types, all_types), "+ Add New Type" = DAYTYPE_ADD_NEW_VALUE)
    
    current <- isolate(input$day_type_select)
    selected <- if (!is.null(current) && current %in% choices) current else all_types[1]
    
    updateSelectInput(session, "day_type_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)
  
  reactive({
    if (identical(input$day_type_select, DAYTYPE_ADD_NEW_VALUE)) {
      trimws(input$new_day_type_text %||% "")
    } else {
      input$day_type_select %||% ""
    }
  })
}

# ============================================================
# COUNTRY / CITY HIERARCHICAL CLASSIFICATION (Travel days)
# ============================================================
# City is a sub-category of Country. Same "+ Add New" sentinel pattern as
# Genre/Topic in the book app.
COUNTRY_ADD_NEW_VALUE <- "__ADD_NEW_COUNTRY__"
CITY_ADD_NEW_VALUE <- "__ADD_NEW_CITY__"

# Reusable UI block: a Country dropdown (with "+ Add New Country") and a City
# dropdown (with "+ Add New City"), each with a conditional text box that
# appears when "add new" is selected. Used by generate_schedule and
# add_single for Travel-type days.
country_city_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("country_select"), "Country: *",
                choices = c("+ Add New Country" = COUNTRY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("country_select"), COUNTRY_ADD_NEW_VALUE),
      textInput(ns("new_country_text"), "New Country Name:", placeholder = "e.g., France")
    ),
    selectInput(ns("city_select"), "City: *",
                choices = c("+ Add New City" = CITY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("city_select"), CITY_ADD_NEW_VALUE),
      textInput(ns("new_city_text"), "New City Name:", placeholder = "e.g., Paris")
    )
  )
}

# Wires up the reactive cascade for a Country/City dropdown block created by
# country_city_dropdown_ui(). Returns a reactive() yielding
# list(country = ..., city = ...) with the resolved final values.
setup_country_city_cascade <- function(input, output, session, api_manager) {
  
  taxonomy <- reactive({
    api_manager$state_trigger()
    if (!api_manager$bq_authenticated) {
      return(data.frame(country = character(), city = character(), stringsAsFactors = FALSE))
    }
    tryCatch(api_manager$bq_get_taxonomy(), error = function(e) {
      data.frame(country = character(), city = character(), stringsAsFactors = FALSE)
    })
  })
  
  observeEvent(taxonomy(), {
    tax <- taxonomy()
    countries <- sort(unique(tax$country[nchar(trimws(tax$country)) > 0 &
                                          !tolower(trimws(tax$country)) %in% c("n/a", "na")]))
    choices <- c("+ Add New Country" = COUNTRY_ADD_NEW_VALUE, setNames(countries, countries))
    
    current <- isolate(input$country_select)
    selected <- if (!is.null(current) && current %in% choices) current else COUNTRY_ADD_NEW_VALUE
    
    updateSelectInput(session, "country_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)
  
  observeEvent(input$country_select, {
    tax <- taxonomy()
    
    if (is.null(input$country_select) || input$country_select == COUNTRY_ADD_NEW_VALUE) {
      updateSelectInput(session, "city_select",
                         choices = c("+ Add New City" = CITY_ADD_NEW_VALUE))
      return()
    }
    
    cities <- sort(unique(tax$city[tax$country == input$country_select & nchar(trimws(tax$city)) > 0]))
    
    if (length(cities) == 0) {
      updateSelectInput(session, "city_select",
                         choices = c("+ Add New City" = CITY_ADD_NEW_VALUE))
    } else {
      updateSelectInput(session, "city_select",
                         choices = c("+ Add New City" = CITY_ADD_NEW_VALUE,
                                     setNames(cities, cities)))
    }
  }, ignoreInit = TRUE)
  
  reactive({
    country <- if (identical(input$country_select, COUNTRY_ADD_NEW_VALUE)) {
      trimws(input$new_country_text %||% "")
    } else {
      input$country_select %||% ""
    }
    
    city <- if (identical(input$city_select, CITY_ADD_NEW_VALUE)) {
      trimws(input$new_city_text %||% "")
    } else {
      input$city_select %||% ""
    }
    
    list(country = country, city = city)
  })
}
