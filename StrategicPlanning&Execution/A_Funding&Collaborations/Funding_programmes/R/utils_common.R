# R/utils_common.R
# Shared Utility Functions - Funding Programmes Suite
# ====================================================

# Safe SQL escape for preventing injection
safe_sql_escape <- function(input_value) {
  gsub("'", "''", input_value)
}

# The full set of fields in one programme record, in the order Claude should
# output them. "programme_name" is the field that starts a new record - when
# it reappears, the previous record is closed and pushed to the results list.
# This lets one paste contain several complete programme entries at once.
PROGRAMME_FIELDS <- c(
  "programme_name", "category", "country", "city_region",
  "amount_of_money", "conditions", "key_sponsors", "key_organiser_profiles",
  "areas_of_application", "start_date_for_applying", "deadline",
  "recommendations_for_applying", "verified_urls"
)

# Parse one or more programme records from text into a data frame.
#
# Expected format - one flat block per programme, blank line between blocks:
#
#   [programme_name]: Horizon Europe SME Instrument
#   [category]: Grant
#   [country]: European Union
#   [city_region]: All
#   [amount_of_money]: Up to EUR 2.5 million
#   [conditions]: Must be an SME registered in an EU member state...
#   [key_sponsors]: European Commission
#   [key_organiser_profiles]: Dr. Jane Smith, Programme Director...
#   [areas_of_application]: Deep tech, climate, health
#   [start_date_for_applying]: 2026-09-01
#   [deadline]: 2026-11-15
#   [recommendations_for_applying]: Prepare a strong TRL roadmap...
#   [verified_urls]: https://ec.europa.eu/..., https://example.com/apply
#
#   [programme_name]: (a second programme can follow immediately)
#   ...
#
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
        
        if (field == "programme_name") {
          flush_entry()
          current_entry <- list()
        }
        
        current_entry[[field]] <- value
        last_field <- field
        matched <- TRUE
        break
      }
    }
    
    # Multi-line accumulation onto whichever field was last set (handles
    # long free-text fields like conditions/recommendations wrapping lines)
    if (!matched && length(current_entry) > 0 && !is.null(last_field) &&
        !grepl("^\\[", line)) {
      current_entry[[last_field]] <- paste(current_entry[[last_field]], line)
    }
  }
  
  flush_entry()
  
  if (length(entries) == 0) {
    stop("No valid programme entries found in text")
  }
  
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
  
  return(parsed_df)
}

# Force-overwrites the category/country/city_region on every parsed record
# with the exact values selected in the UI, regardless of what Claude wrote -
# guarantees the saved data always matches the user's selection exactly.
overwrite_programme_taxonomy <- function(text, category, country, city_region) {
  lines <- strsplit(text, "\n")[[1]]
  
  for (i in seq_along(lines)) {
    if (grepl("^\\[category\\]:", lines[i], ignore.case = TRUE)) {
      lines[i] <- paste0("[category]: ", category)
    } else if (grepl("^\\[country\\]:", lines[i], ignore.case = TRUE)) {
      lines[i] <- paste0("[country]: ", country)
    } else if (grepl("^\\[city_region\\]:", lines[i], ignore.case = TRUE)) {
      lines[i] <- paste0("[city_region]: ", city_region)
    }
  }
  
  paste(lines, collapse = "\n")
}

# Generate Claude prompt to discover relevant funding programmes
generate_programme_prompt <- function(category, country, city_region, search_focus, n_results = 4) {
  
  region_text <- if (identical(city_region, "All") || nchar(trimws(city_region)) == 0) {
    country
  } else {
    paste0(city_region, ", ", country)
  }
  
  focus_text <- if (nchar(trimws(search_focus)) > 0) {
    search_focus
  } else {
    "No further focus provided - use your best judgement for relevant, well-known programmes."
  }
  
  prompt <- paste0(
    'You are a research assistant specializing in startup/business funding programmes. ',
    'Find up to ', n_results, ' real, well-known ', category, ' programmes relevant to ', region_text, '. ',
    'Focus area: ', focus_text, '\n\n',
    
    'CRITICAL ACCURACY RULES:\n',
    '- Only include programmes you have genuine knowledge of from training data. Do NOT invent fictional programmes.\n',
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
  
  return(prompt)
}

# ============================================================
# CATEGORY CLASSIFICATION (single-level, "Add New" pattern)
# ============================================================
CATEGORY_ADD_NEW_VALUE <- "__ADD_NEW_CATEGORY__"
DEFAULT_CATEGORIES <- c("Grant", "Incubator", "Accelerator", "Competition")

category_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("category_select"), "Category: *",
                choices = c(setNames(DEFAULT_CATEGORIES, DEFAULT_CATEGORIES),
                            "+ Add New Category" = CATEGORY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("category_select"), CATEGORY_ADD_NEW_VALUE),
      textInput(ns("new_category_text"), "New Category Name:", placeholder = "e.g., Fellowship, Award")
    )
  )
}

setup_category_cascade <- function(input, output, session, api_manager) {
  
  taxonomy <- reactive({
    api_manager$state_trigger()
    if (!api_manager$bq_authenticated) {
      return(data.frame(category = character(), stringsAsFactors = FALSE))
    }
    tryCatch(api_manager$bq_get_taxonomy(), error = function(e) {
      data.frame(category = character(), stringsAsFactors = FALSE)
    })
  })
  
  observeEvent(taxonomy(), {
    tax <- taxonomy()
    stored <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
    all_categories <- sort(unique(c(DEFAULT_CATEGORIES, stored)))
    choices <- c(setNames(all_categories, all_categories), "+ Add New Category" = CATEGORY_ADD_NEW_VALUE)
    
    current <- isolate(input$category_select)
    selected <- if (!is.null(current) && current %in% choices) current else all_categories[1]
    
    updateSelectInput(session, "category_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)
  
  reactive({
    if (identical(input$category_select, CATEGORY_ADD_NEW_VALUE)) {
      trimws(input$new_category_text %||% "")
    } else {
      input$category_select %||% ""
    }
  })
}

# ============================================================
# COUNTRY / CITY-REGION HIERARCHICAL CLASSIFICATION
# ============================================================
# City/Region defaults to "All" (programmes are frequently nationwide or
# supranational) but can cascade to specific regions stored per country.
COUNTRY_ADD_NEW_VALUE <- "__ADD_NEW_COUNTRY_FP__"
CITYREGION_ADD_NEW_VALUE <- "__ADD_NEW_CITYREGION_FP__"

country_cityregion_dropdown_ui <- function(ns) {
  tagList(
    selectInput(ns("country_select"), "Country: *",
                choices = c("+ Add New Country" = COUNTRY_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("country_select"), COUNTRY_ADD_NEW_VALUE),
      textInput(ns("new_country_text"), "New Country Name:", placeholder = "e.g., Germany")
    ),
    selectInput(ns("cityregion_select"), "City / Region:",
                choices = c("All" = "All", "+ Add New City/Region" = CITYREGION_ADD_NEW_VALUE)),
    conditionalPanel(
      condition = sprintf("input['%s'] == '%s'", ns("cityregion_select"), CITYREGION_ADD_NEW_VALUE),
      textInput(ns("new_cityregion_text"), "New City/Region Name:", placeholder = "e.g., Bavaria, Berlin")
    )
  )
}

setup_country_cityregion_cascade <- function(input, output, session, api_manager) {
  
  taxonomy <- reactive({
    api_manager$state_trigger()
    if (!api_manager$bq_authenticated) {
      return(data.frame(country = character(), city_region = character(), stringsAsFactors = FALSE))
    }
    tryCatch(api_manager$bq_get_taxonomy(), error = function(e) {
      data.frame(country = character(), city_region = character(), stringsAsFactors = FALSE)
    })
  })
  
  observeEvent(taxonomy(), {
    tax <- taxonomy()
    countries <- sort(unique(tax$country[nchar(trimws(tax$country)) > 0]))
    choices <- c("+ Add New Country" = COUNTRY_ADD_NEW_VALUE, setNames(countries, countries))
    
    current <- isolate(input$country_select)
    selected <- if (!is.null(current) && current %in% choices) current else COUNTRY_ADD_NEW_VALUE
    
    updateSelectInput(session, "country_select", choices = choices, selected = selected)
  }, ignoreNULL = FALSE)
  
  observeEvent(input$country_select, {
    tax <- taxonomy()
    
    base_choices <- c("All" = "All", "+ Add New City/Region" = CITYREGION_ADD_NEW_VALUE)
    
    if (is.null(input$country_select) || input$country_select == COUNTRY_ADD_NEW_VALUE) {
      updateSelectInput(session, "cityregion_select", choices = base_choices)
      return()
    }
    
    regions <- sort(unique(tax$city_region[tax$country == input$country_select &
                                            nchar(trimws(tax$city_region)) > 0 &
                                            tax$city_region != "All"]))
    
    if (length(regions) == 0) {
      updateSelectInput(session, "cityregion_select", choices = base_choices)
    } else {
      updateSelectInput(session, "cityregion_select",
                        choices = c("All" = "All", setNames(regions, regions),
                                    "+ Add New City/Region" = CITYREGION_ADD_NEW_VALUE))
    }
  }, ignoreInit = TRUE)
  
  reactive({
    country <- if (identical(input$country_select, COUNTRY_ADD_NEW_VALUE)) {
      trimws(input$new_country_text %||% "")
    } else {
      input$country_select %||% ""
    }
    
    city_region <- if (identical(input$cityregion_select, CITYREGION_ADD_NEW_VALUE)) {
      trimws(input$new_cityregion_text %||% "")
    } else {
      input$cityregion_select %||% "All"
    }
    
    list(country = country, city_region = city_region)
  })
}
