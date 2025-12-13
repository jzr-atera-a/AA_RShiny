# ============================================================================
# GOOGLE ANALYTICS 4 - COMPREHENSIVE DATA EXPLORER
# ============================================================================
# Purpose: Pull ALL available data from GA4 to understand what's accessible
# Property ID: 515710306
# Website: www.atera-analytics.co.uk
# ============================================================================

# Load required libraries
library(googleAnalyticsR)
library(dplyr)
library(tidyr)
library(lubridate)

# ============================================================================
# CONFIGURATION
# ============================================================================

# **MODIFY THIS PATH** to point to your service account JSON file
JSON_FILE_PATH <- "C:/111_SecA/atera_gcp/atera-analytics-service for google analytics/atera-2-50bf5c013456.json"
# Property ID (numeric only - googleAnalyticsR adds 'properties/' prefix)
PROPERTY_ID <- "515710306"

# Date range for data pull
START_DATE <- Sys.Date() - 90  # Last 90 days
END_DATE <- Sys.Date()

# ============================================================================
# AUTHENTICATION
# ============================================================================

cat("============================================================================\n")
cat("GOOGLE ANALYTICS 4 - COMPREHENSIVE DATA EXPLORER\n")
cat("============================================================================\n\n")

cat("Step 1: Authenticating with Google Analytics...\n")
tryCatch({
  ga_auth(json_file = JSON_FILE_PATH)
  cat("✓ Authentication successful!\n\n")
}, error = function(e) {
  cat("✗ Authentication failed:", e$message, "\n")
  cat("Please check your JSON file path and try again.\n")
  stop("Authentication failed")
})

# ============================================================================
# VERIFY PROPERTY ACCESS
# ============================================================================

cat("Step 2: Verifying property access...\n")
account_list <- ga_account_list(type = "ga4")

if (nrow(account_list) == 0) {
  stop("No GA4 properties found. Check service account permissions.")
}

cat("✓ Found", nrow(account_list), "GA4 properties\n")
cat("\nAvailable Properties:\n")
cat("Column names in account_list:", paste(names(account_list), collapse = ", "), "\n\n")
print(account_list)
cat("\n")

# Check if our property is in the list - try different possible column names
property_id_column <- NULL
if ("propertyId" %in% names(account_list)) {
  property_id_column <- "propertyId"
} else if ("property_id" %in% names(account_list)) {
  property_id_column <- "property_id"
} else if ("id" %in% names(account_list)) {
  property_id_column <- "id"
}

if (is.null(property_id_column)) {
  cat("\n✗ Cannot find property ID column in account list!\n")
  cat("Available columns:", paste(names(account_list), collapse = ", "), "\n")
  stop("Cannot verify property access")
}

if (!(PROPERTY_ID %in% account_list[[property_id_column]])) {
  cat("\n✗ Property", PROPERTY_ID, "not found in accessible properties!\n")
  cat("Available Property IDs:", paste(account_list[[property_id_column]], collapse = ", "), "\n")
  stop("Property not accessible")
}

cat("\n✓ Property", PROPERTY_ID, "is accessible\n\n")

# ============================================================================
# DATA EXPLORATION PARAMETERS
# ============================================================================

cat("============================================================================\n")
cat("DATA PULL CONFIGURATION\n")
cat("============================================================================\n")
cat("Property ID:", PROPERTY_ID, "\n")
cat("Date Range:", START_DATE, "to", END_DATE, "\n")
cat("Days:", as.numeric(END_DATE - START_DATE), "days\n\n")

# ============================================================================
# SECTION 1: CORE OVERVIEW METRICS
# ============================================================================

cat("============================================================================\n")
cat("SECTION 1: CORE OVERVIEW METRICS\n")
cat("============================================================================\n\n")

cat("Pulling daily overview data...\n")
overview_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c(
    "activeUsers",
    "newUsers",
    "sessions",
    "screenPageViews",
    "userEngagementDuration",
    "averageSessionDuration",
    "bounceRate",
    "sessionsPerUser",
    "screenPageViewsPerSession",
    "eventCount"
  ),
  dimensions = c("date"),
  limit = -1
)

cat("✓ Retrieved", nrow(overview_data), "days of data\n\n")
cat("OVERVIEW DATA SUMMARY:\n")
cat("----------------------------------------\n")
cat("Total Active Users:", formatC(sum(overview_data$activeUsers, na.rm = TRUE), format = "d", big.mark = ","), "\n")
cat("Total New Users:", formatC(sum(overview_data$newUsers, na.rm = TRUE), format = "d", big.mark = ","), "\n")
cat("Total Sessions:", formatC(sum(overview_data$sessions, na.rm = TRUE), format = "d", big.mark = ","), "\n")
cat("Total Page Views:", formatC(sum(overview_data$screenPageViews, na.rm = TRUE), format = "d", big.mark = ","), "\n")
cat("Total Events:", formatC(sum(overview_data$eventCount, na.rm = TRUE), format = "d", big.mark = ","), "\n")
cat("Avg Session Duration:", round(mean(overview_data$averageSessionDuration, na.rm = TRUE), 1), "seconds\n")
cat("Avg Bounce Rate:", round(mean(overview_data$bounceRate, na.rm = TRUE) * 100, 1), "%\n\n")

cat("First 10 rows of overview data:\n")
print(head(overview_data, 10))
cat("\n")

# ============================================================================
# SECTION 2: USER DEMOGRAPHICS & TECHNOLOGY
# ============================================================================

cat("============================================================================\n")
cat("SECTION 2: USER DEMOGRAPHICS & TECHNOLOGY\n")
cat("============================================================================\n\n")

# Geographic data
cat("2.1: Geographic Distribution...\n")
geo_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("activeUsers", "sessions", "screenPageViews"),
  dimensions = c("country", "city", "region"),
  limit = 100
)
cat("✓ Retrieved", nrow(geo_data), "locations\n")
cat("Top 5 countries by users:\n")
print(head(geo_data[order(-geo_data$activeUsers), c("country", "activeUsers", "sessions")], 5))
cat("\n")

# Device data
cat("2.2: Device Information...\n")
device_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("activeUsers", "sessions", "screenPageViews", "averageSessionDuration"),
  dimensions = c("deviceCategory", "operatingSystem", "browser"),
  limit = 100
)
cat("✓ Retrieved", nrow(device_data), "device combinations\n")
cat("Device breakdown:\n")
device_summary <- device_data %>%
  group_by(deviceCategory) %>%
  summarise(
    users = sum(activeUsers),
    sessions = sum(sessions),
    .groups = "drop"
  ) %>%
  arrange(desc(users))
print(device_summary)
cat("\n")

# Browser data
cat("Top 5 browsers:\n")
browser_summary <- device_data %>%
  group_by(browser) %>%
  summarise(users = sum(activeUsers), .groups = "drop") %>%
  arrange(desc(users)) %>%
  head(5)
print(browser_summary)
cat("\n")

# ============================================================================
# SECTION 3: TRAFFIC SOURCES & ACQUISITION
# ============================================================================

cat("============================================================================\n")
cat("SECTION 3: TRAFFIC SOURCES & ACQUISITION\n")
cat("============================================================================\n\n")

cat("3.1: Traffic Source / Medium...\n")
source_medium_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("activeUsers", "newUsers", "sessions", "screenPageViews"),
  dimensions = c("sessionSource", "sessionMedium", "sessionCampaignName"),
  limit = 100
)
cat("✓ Retrieved", nrow(source_medium_data), "source/medium combinations\n")
cat("Top 10 traffic sources:\n")
print(head(source_medium_data[order(-source_medium_data$sessions), ], 10))
cat("\n")

# Default channel grouping
cat("3.2: Default Channel Grouping...\n")
channel_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("activeUsers", "sessions", "screenPageViews", "averageSessionDuration"),
  dimensions = c("sessionDefaultChannelGroup"),
  limit = -1
)
cat("✓ Retrieved", nrow(channel_data), "channels\n")
print(channel_data[order(-channel_data$sessions), ])
cat("\n")

# ============================================================================
# SECTION 4: PAGE PERFORMANCE
# ============================================================================

cat("============================================================================\n")
cat("SECTION 4: PAGE PERFORMANCE\n")
cat("============================================================================\n\n")

cat("4.1: Page Views by Page Path...\n")
page_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c(
    "screenPageViews",
    "activeUsers",
    "averageSessionDuration",
    "bounceRate"
  ),
  dimensions = c("pagePath", "pageTitle"),
  limit = 50
)
cat("✓ Retrieved", nrow(page_data), "pages\n")
cat("Top 10 pages by views:\n")
print(head(page_data[order(-page_data$screenPageViews), ], 10))
cat("\n")

# Landing pages
cat("4.2: Landing Pages...\n")
landing_page_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("sessions", "activeUsers", "bounceRate"),
  dimensions = c("landingPage"),
  limit = 20
)
cat("✓ Retrieved", nrow(landing_page_data), "landing pages\n")
cat("Top 5 landing pages:\n")
print(head(landing_page_data[order(-landing_page_data$sessions), ], 5))
cat("\n")

# ============================================================================
# SECTION 5: USER BEHAVIOR & ENGAGEMENT
# ============================================================================

cat("============================================================================\n")
cat("SECTION 5: USER BEHAVIOR & ENGAGEMENT\n")
cat("============================================================================\n\n")

# New vs Returning
cat("5.1: New vs Returning Users...\n")
user_type_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("activeUsers", "newUsers", "sessions", "screenPageViews"),
  dimensions = c("newVsReturning"),
  limit = -1
)
cat("✓ Retrieved user type data\n")
print(user_type_data)
cat("\n")

# Hourly traffic patterns
cat("5.2: Hourly Traffic Patterns...\n")
hourly_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("activeUsers", "sessions"),
  dimensions = c("hour"),
  limit = -1
)
cat("✓ Retrieved", nrow(hourly_data), "hours of data\n")
cat("Traffic by hour of day:\n")
print(hourly_data[order(as.numeric(hourly_data$hour)), ])
cat("\n")

# Day of week patterns
cat("5.3: Day of Week Patterns...\n")
dow_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("activeUsers", "sessions", "screenPageViews"),
  dimensions = c("dayOfWeek", "dayOfWeekName"),
  limit = -1
)
cat("✓ Retrieved day of week data\n")
print(dow_data[order(as.numeric(dow_data$dayOfWeek)), ])
cat("\n")

# ============================================================================
# SECTION 6: EVENTS
# ============================================================================

cat("============================================================================\n")
cat("SECTION 6: EVENT TRACKING\n")
cat("============================================================================\n\n")

cat("6.1: Event Names and Counts...\n")
event_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("eventCount", "eventCountPerUser"),
  dimensions = c("eventName"),
  limit = 100
)
cat("✓ Retrieved", nrow(event_data), "event types\n")
cat("Top 20 events:\n")
print(head(event_data[order(-event_data$eventCount), ], 20))
cat("\n")

# Event details with parameters
cat("6.2: Events with Parameters...\n")
event_params_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("eventCount"),
  dimensions = c("eventName", "pagePath"),
  limit = 100
)
cat("✓ Retrieved", nrow(event_params_data), "event-page combinations\n")
cat("Sample of events by page:\n")
print(head(event_params_data[order(-event_params_data$eventCount), ], 10))
cat("\n")

# ============================================================================
# SECTION 7: CONVERSIONS & GOALS
# ============================================================================

cat("============================================================================\n")
cat("SECTION 7: CONVERSIONS & GOALS\n")
cat("============================================================================\n\n")

cat("7.1: Conversion Events...\n")
conversion_data <- tryCatch({
  ga_data(
    propertyId = PROPERTY_ID,
    date_range = c(START_DATE, END_DATE),
    metrics = c("conversions", "eventCount"),
    dimensions = c("eventName"),
    limit = 50
  )
}, error = function(e) {
  cat("Note: No conversion events configured or accessible\n")
  NULL
})

if (!is.null(conversion_data) && nrow(conversion_data) > 0) {
  cat("✓ Retrieved", nrow(conversion_data), "conversion events\n")
  print(conversion_data[order(-conversion_data$conversions), ])
} else {
  cat("No conversion data available\n")
}
cat("\n")

# ============================================================================
# SECTION 8: CONTACT PAGE SPECIFIC DATA
# ============================================================================

cat("============================================================================\n")
cat("SECTION 8: CONTACT PAGE SPECIFIC DATA\n")
cat("============================================================================\n\n")

cat("8.1: Contact Page Traffic...\n")
contact_page_data <- tryCatch({
  ga_data(
    propertyId = PROPERTY_ID,
    date_range = c(START_DATE, END_DATE),
    metrics = c("screenPageViews", "activeUsers", "sessions", "averageSessionDuration"),
    dimensions = c("pagePath", "pageTitle"),
    dim_filters = ga_data_filter(
      pagePath %contains% "contact"
    ),
    limit = 20
  )
}, error = function(e) {
  cat("Note: No contact pages found with 'contact' in path\n")
  NULL
})

if (!is.null(contact_page_data) && nrow(contact_page_data) > 0) {
  cat("✓ Retrieved", nrow(contact_page_data), "contact-related pages\n")
  print(contact_page_data)
  cat("\nTotal contact page views:", sum(contact_page_data$screenPageViews), "\n")
  cat("Total users:", sum(contact_page_data$activeUsers), "\n")
} else {
  cat("No contact page data found\n")
}
cat("\n")

# Contact-related events
cat("8.2: Contact-Related Events...\n")
contact_events <- tryCatch({
  ga_data(
    propertyId = PROPERTY_ID,
    date_range = c(START_DATE, END_DATE),
    metrics = c("eventCount"),
    dimensions = c("eventName", "pagePath"),
    dim_filters = ga_data_filter(
      eventName %contains% "form" | 
        eventName %contains% "submit" | 
        eventName %contains% "contact" |
        pagePath %contains% "contact"
    ),
    limit = 50
  )
}, error = function(e) {
  cat("Note: No contact-related events found\n")
  NULL
})

if (!is.null(contact_events) && nrow(contact_events) > 0) {
  cat("✓ Retrieved", nrow(contact_events), "contact-related events\n")
  print(contact_events[order(-contact_events$eventCount), ])
} else {
  cat("No contact-related events found\n")
  cat("Note: Form submissions require custom event tracking in GA4\n")
}
cat("\n")

# ============================================================================
# SECTION 9: REAL-TIME DATA
# ============================================================================

cat("============================================================================\n")
cat("SECTION 9: REAL-TIME DATA (Last 30 minutes)\n")
cat("============================================================================\n\n")

cat("9.1: Current Active Users...\n")
realtime_data <- tryCatch({
  ga_data(
    propertyId = PROPERTY_ID,
    date_range = c(Sys.Date(), Sys.Date()),
    metrics = c("activeUsers"),
    dimensions = c("city", "country", "deviceCategory"),
    limit = 20
  )
}, error = function(e) {
  cat("Note: No real-time data available (may require recent activity)\n")
  NULL
})

if (!is.null(realtime_data) && nrow(realtime_data) > 0) {
  cat("✓ Currently active users:", sum(realtime_data$activeUsers), "\n")
  cat("Active locations:\n")
  print(realtime_data[order(-realtime_data$activeUsers), ])
} else {
  cat("No current active users or real-time data unavailable\n")
}
cat("\n")

# ============================================================================
# SECTION 10: AVAILABLE DIMENSIONS & METRICS
# ============================================================================

cat("============================================================================\n")
cat("SECTION 10: AVAILABLE DIMENSIONS & METRICS FOR THIS PROPERTY\n")
cat("============================================================================\n\n")

cat("Fetching metadata...\n")
metadata <- tryCatch({
  ga_meta("data", propertyId = PROPERTY_ID)
}, error = function(e) {
  cat("Note: Could not retrieve metadata\n")
  NULL
})

if (!is.null(metadata)) {
  cat("\n✓ Available Metrics (", nrow(metadata[metadata$type == "METRIC", ]), "):\n", sep = "")
  metrics_list <- metadata[metadata$type == "METRIC", "apiName"]
  cat(paste(head(metrics_list, 20), collapse = ", "), "\n")
  if (length(metrics_list) > 20) {
    cat("... and", length(metrics_list) - 20, "more\n")
  }
  
  cat("\n✓ Available Dimensions (", nrow(metadata[metadata$type == "DIMENSION", ]), "):\n", sep = "")
  dimensions_list <- metadata[metadata$type == "DIMENSION", "apiName"]
  cat(paste(head(dimensions_list, 20), collapse = ", "), "\n")
  if (length(dimensions_list) > 20) {
    cat("... and", length(dimensions_list) - 20, "more\n")
  }
}
cat("\n")

# ============================================================================
# SECTION 11: DATA STRUCTURE SUMMARY
# ============================================================================

cat("============================================================================\n")
cat("SECTION 11: DATA STRUCTURE SUMMARY\n")
cat("============================================================================\n\n")

# Create summary of all datasets
datasets_summary <- data.frame(
  Dataset = c(
    "Overview Data",
    "Geographic Data",
    "Device Data",
    "Source/Medium Data",
    "Channel Data",
    "Page Data",
    "Landing Pages",
    "User Type Data",
    "Hourly Data",
    "Day of Week Data",
    "Event Data",
    "Event-Page Data",
    "Contact Page Data",
    "Contact Events",
    "Real-time Data"
  ),
  Rows = c(
    nrow(overview_data),
    nrow(geo_data),
    nrow(device_data),
    nrow(source_medium_data),
    nrow(channel_data),
    nrow(page_data),
    nrow(landing_page_data),
    nrow(user_type_data),
    nrow(hourly_data),
    nrow(dow_data),
    nrow(event_data),
    nrow(event_params_data),
    if(!is.null(contact_page_data)) nrow(contact_page_data) else 0,
    if(!is.null(contact_events)) nrow(contact_events) else 0,
    if(!is.null(realtime_data)) nrow(realtime_data) else 0
  ),
  Available = c(
    nrow(overview_data) > 0,
    nrow(geo_data) > 0,
    nrow(device_data) > 0,
    nrow(source_medium_data) > 0,
    nrow(channel_data) > 0,
    nrow(page_data) > 0,
    nrow(landing_page_data) > 0,
    nrow(user_type_data) > 0,
    nrow(hourly_data) > 0,
    nrow(dow_data) > 0,
    nrow(event_data) > 0,
    nrow(event_params_data) > 0,
    if(!is.null(contact_page_data)) nrow(contact_page_data) > 0 else FALSE,
    if(!is.null(contact_events)) nrow(contact_events) > 0 else FALSE,
    if(!is.null(realtime_data)) nrow(realtime_data) > 0 else FALSE
  )
)

print(datasets_summary)
cat("\n")

# ============================================================================
# SECTION 12: RECOMMENDATIONS FOR SHINY APP
# ============================================================================

cat("============================================================================\n")
cat("SECTION 12: RECOMMENDATIONS FOR SHINY APP REDESIGN\n")
cat("============================================================================\n\n")

cat("VERIFIED AVAILABLE DATA:\n")
cat("----------------------------------------\n")
if (nrow(overview_data) > 0) cat("✓ Daily traffic metrics (users, sessions, pageviews, duration, bounce rate)\n")
if (nrow(geo_data) > 0) cat("✓ Geographic distribution (country, city, region)\n")
if (nrow(device_data) > 0) cat("✓ Device & browser breakdown\n")
if (nrow(channel_data) > 0) cat("✓ Traffic channels (organic, direct, social, etc.)\n")
if (nrow(page_data) > 0) cat("✓ Page performance metrics\n")
if (nrow(user_type_data) > 0) cat("✓ New vs returning users\n")
if (nrow(hourly_data) > 0) cat("✓ Hourly traffic patterns\n")
if (nrow(dow_data) > 0) cat("✓ Day of week patterns\n")
if (nrow(event_data) > 0) cat("✓ Event tracking (", nrow(event_data), " event types)\n", sep = "")

cat("\nLIMITED OR UNAVAILABLE DATA:\n")
cat("----------------------------------------\n")
cat("⚠ Session duration distribution (no built-in dimension)\n")
cat("⚠ Click tracking (requires custom events)\n")
cat("⚠ Scroll depth (requires custom events)\n")
cat("⚠ Form completion time (requires custom events)\n")
cat("⚠ User flow / Sankey diagrams (requires path analysis)\n")
if (is.null(contact_events) || nrow(contact_events) == 0) {
  cat("⚠ Contact form submissions (requires custom event setup)\n")
}

cat("\nKEY INSIGHTS:\n")
cat("----------------------------------------\n")
cat("• GA4 uses different metrics than Universal Analytics\n")
cat("• Most custom behaviors require event tracking setup on the website\n")
cat("• Real-time data depends on current website activity\n")
cat("• Contact form tracking requires custom event implementation\n")

cat("\nRECOMMENDED SHINY APP STRUCTURE:\n")
cat("----------------------------------------\n")
cat("1. OVERVIEW TAB: Use daily overview_data for trends\n")
cat("2. VISITOR TAB: Use user_type_data, hourly_data, dow_data\n")
cat("3. TRAFFIC TAB: Use channel_data, source_medium_data, geo_data\n")
cat("4. PAGES TAB: Use page_data, landing_page_data\n")
cat("5. TECHNOLOGY TAB: Use device_data for devices/browsers\n")
cat("6. EVENTS TAB: Use event_data if custom events are configured\n")
cat("7. REAL-TIME TAB: Use realtime_data (when available)\n")

cat("\n")

# ============================================================================
# SAVE DATA TO CSV FOR FURTHER ANALYSIS
# ============================================================================

cat("============================================================================\n")
cat("SAVING DATA TO CSV FILES\n")
cat("============================================================================\n\n")

# Create output directory
output_dir <- "ga4_data_export"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# Save all datasets
write.csv(overview_data, file.path(output_dir, "01_overview_data.csv"), row.names = FALSE)
write.csv(geo_data, file.path(output_dir, "02_geographic_data.csv"), row.names = FALSE)
write.csv(device_data, file.path(output_dir, "03_device_data.csv"), row.names = FALSE)
write.csv(source_medium_data, file.path(output_dir, "04_source_medium_data.csv"), row.names = FALSE)
write.csv(channel_data, file.path(output_dir, "05_channel_data.csv"), row.names = FALSE)
write.csv(page_data, file.path(output_dir, "06_page_data.csv"), row.names = FALSE)
write.csv(landing_page_data, file.path(output_dir, "07_landing_pages.csv"), row.names = FALSE)
write.csv(user_type_data, file.path(output_dir, "08_user_type_data.csv"), row.names = FALSE)
write.csv(hourly_data, file.path(output_dir, "09_hourly_data.csv"), row.names = FALSE)
write.csv(dow_data, file.path(output_dir, "10_day_of_week_data.csv"), row.names = FALSE)
write.csv(event_data, file.path(output_dir, "11_event_data.csv"), row.names = FALSE)
write.csv(event_params_data, file.path(output_dir, "12_event_page_data.csv"), row.names = FALSE)

if (!is.null(contact_page_data) && nrow(contact_page_data) > 0) {
  write.csv(contact_page_data, file.path(output_dir, "13_contact_page_data.csv"), row.names = FALSE)
}
if (!is.null(contact_events) && nrow(contact_events) > 0) {
  write.csv(contact_events, file.path(output_dir, "14_contact_events.csv"), row.names = FALSE)
}
if (!is.null(realtime_data) && nrow(realtime_data) > 0) {
  write.csv(realtime_data, file.path(output_dir, "15_realtime_data.csv"), row.names = FALSE)
}

cat("✓ All data exported to '", output_dir, "' folder\n", sep = "")
cat("\n")

# ============================================================================
# FINAL SUMMARY
# ============================================================================

cat("============================================================================\n")
cat("DATA EXPLORATION COMPLETE\n")
cat("============================================================================\n\n")

cat("EXECUTION SUMMARY:\n")
cat("Property ID:", PROPERTY_ID, "\n")
cat("Date Range:", START_DATE, "to", END_DATE, "\n")
cat("Total Days:", as.numeric(END_DATE - START_DATE), "\n")
cat("Datasets Created:", nrow(datasets_summary[datasets_summary$Available, ]), "/", nrow(datasets_summary), "\n")
cat("Export Location:", output_dir, "\n")
cat("\nNext Steps:\n")
cat("1. Review the CSV files in the '", output_dir, "' folder\n", sep = "")
cat("2. Identify which metrics are most important for your dashboard\n")
cat("3. Consider implementing custom events for advanced tracking\n")
cat("4. Redesign Shiny app to use the verified available data\n")

cat("\n============================================================================\n")
cat("END OF REPORT\n")
cat("============================================================================\n")
