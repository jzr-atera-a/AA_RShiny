# ============================================================================
# GOOGLE ANALYTICS PROPERTY VERIFICATION SCRIPT
# ============================================================================
# Purpose: Verify we're analyzing www.atera-analytics.co.uk
# ============================================================================

library(googleAnalyticsR)
library(dplyr)

# ============================================================================
# CONFIGURATION
# ============================================================================

# **MODIFY THIS PATH** to point to your service account JSON file
JSON_FILE_PATH <- "C:/111_SecA/atera_gcp/atera-analytics-service for google analytics/atera-2-50bf5c013456.json"


# Property ID
PROPERTY_ID <- "515710306"

# Date range
START_DATE <- Sys.Date() - 30
END_DATE <- Sys.Date()

# ============================================================================
# AUTHENTICATION
# ============================================================================

cat("============================================================================\n")
cat("GOOGLE ANALYTICS PROPERTY VERIFICATION\n")
cat("============================================================================\n\n")

cat("Authenticating...\n")
ga_auth(json_file = JSON_FILE_PATH)
cat("✓ Authenticated\n\n")

# ============================================================================
# STEP 1: GET ACCOUNT INFORMATION
# ============================================================================

cat("============================================================================\n")
cat("STEP 1: PROPERTY INFORMATION\n")
cat("============================================================================\n\n")

account_list <- ga_account_list(type = "ga4")

cat("All accessible GA4 properties:\n")
cat("----------------------------------------\n")
print(account_list)
cat("\n")

# Find our property
our_property <- account_list[account_list[, grep("property.*id", names(account_list), ignore.case = TRUE)[1]] == PROPERTY_ID, ]

if (nrow(our_property) == 0) {
  cat("✗ ERROR: Property", PROPERTY_ID, "not found!\n")
  cat("Available property IDs:", paste(account_list[[grep("property.*id", names(account_list), ignore.case = TRUE)[1]]], collapse = ", "), "\n")
  stop("Property not found")
}

cat("✓ Found Property:", PROPERTY_ID, "\n")
cat("Property Details:\n")
print(our_property)
cat("\n")

# ============================================================================
# STEP 2: GET PROPERTY METADATA
# ============================================================================

cat("============================================================================\n")
cat("STEP 2: PROPERTY METADATA\n")
cat("============================================================================\n\n")

# Try to get metadata about the property
cat("Attempting to retrieve property metadata...\n")

metadata <- tryCatch({
  ga_meta("data", propertyId = PROPERTY_ID)
}, error = function(e) {
  cat("Note: Could not retrieve detailed metadata\n")
  NULL
})

if (!is.null(metadata)) {
  cat("✓ Metadata retrieved successfully\n\n")
} else {
  cat("⚠ Metadata not available through API\n\n")
}

# ============================================================================
# STEP 3: ANALYZE PAGE PATHS TO VERIFY WEBSITE
# ============================================================================

cat("============================================================================\n")
cat("STEP 3: PAGE PATH ANALYSIS (WEBSITE VERIFICATION)\n")
cat("============================================================================\n\n")

cat("Pulling page data to verify this is www.atera-analytics.co.uk...\n")

page_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("screenPageViews", "activeUsers"),
  dimensions = c("pagePath", "pageTitle", "hostName"),
  limit = 50
)

cat("✓ Retrieved", nrow(page_data), "pages\n\n")

cat("HOSTNAME VERIFICATION:\n")
cat("----------------------------------------\n")
if ("hostName" %in% names(page_data)) {
  hostnames <- unique(page_data$hostName)
  cat("Website hostnames found in data:\n")
  for (hostname in hostnames) {
    page_count <- sum(page_data$hostName == hostname)
    cat("  •", hostname, "(", page_count, "pages )\n")
  }
  
  if ("www.atera-analytics.co.uk" %in% hostnames || "atera-analytics.co.uk" %in% hostnames) {
    cat("\n✓✓✓ VERIFIED: This IS www.atera-analytics.co.uk data! ✓✓✓\n\n")
  } else {
    cat("\n✗✗✗ WARNING: www.atera-analytics.co.uk NOT found in hostnames! ✗✗✗\n")
    cat("This might be data from a different website!\n\n")
  }
} else {
  cat("⚠ Hostname dimension not available in data\n\n")
}

cat("TOP 20 PAGES FROM THIS PROPERTY:\n")
cat("----------------------------------------\n")
page_summary <- page_data %>%
  arrange(desc(screenPageViews)) %>%
  head(20)

for (i in 1:nrow(page_summary)) {
  cat(sprintf("%2d. %s\n", i, page_summary$pagePath[i]))
  cat(sprintf("    Title: %s\n", page_summary$pageTitle[i]))
  if ("hostName" %in% names(page_summary)) {
    cat(sprintf("    Host: %s\n", page_summary$hostName[i]))
  }
  cat(sprintf("    Views: %d | Users: %d\n", 
              page_summary$screenPageViews[i], 
              page_summary$activeUsers[i]))
  cat("\n")
}

# ============================================================================
# STEP 4: VERIFY GEOGRAPHIC DATA
# ============================================================================

cat("============================================================================\n")
cat("STEP 4: GEOGRAPHIC DATA VERIFICATION\n")
cat("============================================================================\n\n")

cat("Pulling geographic data...\n")

geo_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("activeUsers", "sessions", "screenPageViews"),
  dimensions = c("country", "city", "region"),
  limit = 100
)

cat("✓ Retrieved", nrow(geo_data), "geographic locations\n\n")

cat("GEOGRAPHIC DISTRIBUTION:\n")
cat("----------------------------------------\n")

# Country summary
country_summary <- geo_data %>%
  group_by(country) %>%
  summarise(
    users = sum(activeUsers, na.rm = TRUE),
    sessions = sum(sessions, na.rm = TRUE),
    pageviews = sum(screenPageViews, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(users))

cat("BY COUNTRY:\n")
print(country_summary)
cat("\n")

# City summary
city_summary <- geo_data %>%
  group_by(city, country) %>%
  summarise(
    users = sum(activeUsers, na.rm = TRUE),
    sessions = sum(sessions, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(users)) %>%
  head(20)

cat("TOP 20 CITIES:\n")
print(city_summary)
cat("\n")

# Check if UK traffic exists (expected for UK-based site)
uk_traffic <- geo_data %>%
  filter(country == "United Kingdom") %>%
  summarise(
    users = sum(activeUsers, na.rm = TRUE),
    sessions = sum(sessions, na.rm = TRUE)
  )

cat("UK TRAFFIC CHECK:\n")
cat("----------------------------------------\n")
if (nrow(uk_traffic) > 0 && uk_traffic$users > 0) {
  cat("✓ UK traffic detected:", uk_traffic$users, "users,", uk_traffic$sessions, "sessions\n")
  cat("This is consistent with www.atera-analytics.co.uk\n\n")
} else {
  cat("⚠ No UK traffic detected in this period\n")
  cat("This might indicate very limited traffic or data collection issues\n\n")
}

# ============================================================================
# STEP 5: TRAFFIC SOURCE VERIFICATION
# ============================================================================

cat("============================================================================\n")
cat("STEP 5: TRAFFIC SOURCE ANALYSIS\n")
cat("============================================================================\n\n")

cat("Pulling traffic source data...\n")

source_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("activeUsers", "sessions"),
  dimensions = c("sessionSource", "sessionMedium"),
  limit = 50
)

cat("✓ Retrieved", nrow(source_data), "traffic sources\n\n")

cat("TOP TRAFFIC SOURCES:\n")
cat("----------------------------------------\n")

source_summary <- source_data %>%
  arrange(desc(sessions)) %>%
  head(15)

for (i in 1:nrow(source_summary)) {
  cat(sprintf("%2d. Source: %s / Medium: %s\n", 
              i, 
              source_summary$sessionSource[i], 
              source_summary$sessionMedium[i]))
  cat(sprintf("    Users: %d | Sessions: %d\n\n", 
              source_summary$activeUsers[i], 
              source_summary$sessions[i]))
}

# ============================================================================
# STEP 6: OVERALL TRAFFIC SUMMARY
# ============================================================================

cat("============================================================================\n")
cat("STEP 6: OVERALL TRAFFIC SUMMARY\n")
cat("============================================================================\n\n")

overview_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(START_DATE, END_DATE),
  metrics = c("activeUsers", "newUsers", "sessions", "screenPageViews", "eventCount"),
  dimensions = c("date"),
  limit = -1
)

cat("Date Range:", START_DATE, "to", END_DATE, "\n")
cat("Days of data:", nrow(overview_data), "\n\n")

cat("TOTALS:\n")
cat("----------------------------------------\n")
cat("Total Active Users:", formatC(sum(overview_data$activeUsers, na.rm = TRUE), format = "d", big.mark = ","), "\n")
cat("Total New Users:", formatC(sum(overview_data$newUsers, na.rm = TRUE), format = "d", big.mark = ","), "\n")
cat("Total Sessions:", formatC(sum(overview_data$sessions, na.rm = TRUE), format = "d", big.mark = ","), "\n")
cat("Total Pageviews:", formatC(sum(overview_data$screenPageViews, na.rm = TRUE), format = "d", big.mark = ","), "\n")
cat("Total Events:", formatC(sum(overview_data$eventCount, na.rm = TRUE), format = "d", big.mark = ","), "\n\n")

cat("AVERAGES:\n")
cat("----------------------------------------\n")
cat("Avg Users per Day:", round(mean(overview_data$activeUsers, na.rm = TRUE), 1), "\n")
cat("Avg Sessions per Day:", round(mean(overview_data$sessions, na.rm = TRUE), 1), "\n")
cat("Avg Pageviews per Day:", round(mean(overview_data$screenPageViews, na.rm = TRUE), 1), "\n\n")

# ============================================================================
# STEP 7: RECENT ACTIVITY CHECK
# ============================================================================

cat("============================================================================\n")
cat("STEP 7: RECENT ACTIVITY (LAST 7 DAYS)\n")
cat("============================================================================\n\n")

recent_data <- ga_data(
  propertyId = PROPERTY_ID,
  date_range = c(Sys.Date() - 7, Sys.Date()),
  metrics = c("activeUsers", "sessions", "screenPageViews"),
  dimensions = c("date"),
  limit = -1
)

cat("Recent traffic (last 7 days):\n")
cat("----------------------------------------\n")
print(recent_data)
cat("\n")

if (sum(recent_data$activeUsers, na.rm = TRUE) > 0) {
  cat("✓ Recent activity detected\n")
  cat("Last 7 days total users:", sum(recent_data$activeUsers, na.rm = TRUE), "\n\n")
} else {
  cat("⚠ No activity in last 7 days\n")
  cat("This might indicate:\n")
  cat("  • Very low traffic to the website\n")
  cat("  • GA4 tracking not properly installed\n")
  cat("  • Wrong property being analyzed\n\n")
}

# ============================================================================
# FINAL VERIFICATION SUMMARY
# ============================================================================

cat("============================================================================\n")
cat("FINAL VERIFICATION SUMMARY\n")
cat("============================================================================\n\n")

cat("Property ID: ", PROPERTY_ID, "\n")
cat("Date Range Analyzed: ", START_DATE, " to ", END_DATE, "\n\n")

# Verification checklist
verification_checks <- list()

# Check 1: Property exists
verification_checks$property_found <- nrow(our_property) > 0

# Check 2: Hostname matches
if ("hostName" %in% names(page_data)) {
  hostnames <- unique(page_data$hostName)
  verification_checks$correct_hostname <- 
    "www.atera-analytics.co.uk" %in% hostnames || 
    "atera-analytics.co.uk" %in% hostnames
} else {
  verification_checks$correct_hostname <- NA
}

# Check 3: Has data
verification_checks$has_data <- sum(overview_data$activeUsers, na.rm = TRUE) > 0

# Check 4: Recent activity
verification_checks$has_recent_activity <- sum(recent_data$activeUsers, na.rm = TRUE) > 0

# Check 5: UK traffic (expected for UK site)
verification_checks$has_uk_traffic <- 
  nrow(uk_traffic) > 0 && uk_traffic$users > 0

cat("VERIFICATION CHECKLIST:\n")
cat("----------------------------------------\n")
cat(sprintf("✓ Property Found: %s\n", 
            ifelse(verification_checks$property_found, "YES", "NO")))
cat(sprintf("%s Correct Hostname: %s\n", 
            ifelse(is.na(verification_checks$correct_hostname), "?", 
                   ifelse(verification_checks$correct_hostname, "✓", "✗")),
            ifelse(is.na(verification_checks$correct_hostname), "UNKNOWN", 
                   ifelse(verification_checks$correct_hostname, "YES", "NO"))))
cat(sprintf("✓ Has Data: %s\n", 
            ifelse(verification_checks$has_data, "YES", "NO")))
cat(sprintf("%s Has Recent Activity: %s\n", 
            ifelse(verification_checks$has_recent_activity, "✓", "⚠"),
            ifelse(verification_checks$has_recent_activity, "YES", "NO")))
cat(sprintf("%s UK Traffic Present: %s\n", 
            ifelse(verification_checks$has_uk_traffic, "✓", "⚠"),
            ifelse(verification_checks$has_uk_traffic, "YES", "NO")))
cat("\n")

# Final verdict
if (verification_checks$property_found && 
    (is.na(verification_checks$correct_hostname) || verification_checks$correct_hostname) &&
    verification_checks$has_data) {
  
  cat("════════════════════════════════════════════════════════════\n")
  cat("✓✓✓ VERIFICATION PASSED ✓✓✓\n")
  cat("════════════════════════════════════════════════════════════\n")
  cat("This property appears to be www.atera-analytics.co.uk\n")
  cat("You can proceed with confidence!\n")
  cat("════════════════════════════════════════════════════════════\n\n")
  
  if (!verification_checks$has_recent_activity) {
    cat("⚠ NOTE: Low or no recent traffic detected\n")
    cat("Consider:\n")
    cat("  • Checking if website is live and accessible\n")
    cat("  • Verifying GA4 tracking code is installed correctly\n")
    cat("  • Checking if website has genuine traffic\n\n")
  }
  
} else {
  cat("════════════════════════════════════════════════════════════\n")
  cat("✗✗✗ VERIFICATION FAILED ✗✗✗\n")
  cat("════════════════════════════════════════════════════════════\n")
  cat("This might NOT be www.atera-analytics.co.uk!\n")
  cat("Please review the page paths and hostnames above.\n")
  cat("════════════════════════════════════════════════════════════\n\n")
}

cat("============================================================================\n")
cat("END OF VERIFICATION REPORT\n")
cat("============================================================================\n")