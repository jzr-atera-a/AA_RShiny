# FINAL DIAGNOSTIC - Data Stream Exists, Still 404
# ==================================================
# Something unusual is happening. Let's try everything.

library(googleAnalyticsR)
library(httr)

cat("\n")
cat("==================================================\n")
cat("  EXHAUSTIVE PROPERTY TEST\n")
cat("==================================================\n\n")

json_path <- "C:/111_SecA/atera_gcp/atera-analytics-service for google analytics/atera-2-50bf5c013456.json"

cat("\n[1] Authenticating...\n")
ga_auth(json_file = json_path)
cat("    ✓ Done\n")

cat("\n[2] Getting properties with type='ga4'...\n")
props <- ga_account_list(type = "ga4")
cat("    Found:", nrow(props), "properties\n")
print(props)

if (nrow(props) == 0) {
  stop("No properties found!")
}

# Get the exact property ID from the list
actual_prop_id <- props$propertyId[1]
cat("\n[3] Property from list:", actual_prop_id, "\n")
cat("    Class:", class(actual_prop_id), "\n")
cat("    Raw value: '", actual_prop_id, "'\n", sep = "")
cat("    Length:", nchar(actual_prop_id), "characters\n")

# Test different formats
cat("\n[4] Testing 6 different property ID formats...\n\n")

test_formats <- list(
  list(desc = "From list as-is", id = actual_prop_id),
  list(desc = "With properties/ prefix", id = paste0("properties/", actual_prop_id)),
  list(desc = "Trimmed with prefix", id = paste0("properties/", trimws(actual_prop_id))),
  list(desc = "Hardcoded 515710306", id = "515710306"),
  list(desc = "Hardcoded properties/515710306", id = "properties/515710306"),
  list(desc = "As character", id = as.character(paste0("properties/", actual_prop_id)))
)

working_format <- NULL

for (i in seq_along(test_formats)) {
  test <- test_formats[[i]]
  cat(sprintf("Test %d: %s\n", i, test$desc))
  cat(sprintf("        ID: '%s'\n", test$id))
  
  result <- tryCatch({
    data <- ga_data(
      propertyId = test$id,
      date_range = c("2024-01-01", "2024-12-09"),
      metrics = "activeUsers",
      dimensions = "date",
      limit = 3
    )
    
    cat("        ✓✓✓ SUCCESS!\n")
    cat("        Rows:", nrow(data), "\n")
    if (nrow(data) > 0) {
      cat("        Total users:", sum(data$activeUsers, na.rm = TRUE), "\n")
    }
    working_format <- test$id
    list(success = TRUE, data = data)
  }, error = function(e) {
    cat("        ✗ Failed:", e$message, "\n")
    list(success = FALSE, error = e$message)
  })
  
  cat("\n")
  
  if (result$success) {
    cat("==================================================\n")
    cat("  ✅ FOUND WORKING FORMAT!\n")
    cat("==================================================\n\n")
    cat("Use this EXACT format in your app:\n")
    cat("  propertyId = \"", working_format, "\"\n\n", sep = "")
    
    cat("Sample data:\n")
    print(head(result$data))
    
    break
  }
}

if (is.null(working_format)) {
  cat("\n==================================================\n")
  cat("  ❌ ALL FORMATS FAILED\n")
  cat("==================================================\n\n")
  
  cat("[5] Testing with different date ranges...\n\n")
  
  date_ranges <- list(
    list(desc = "Last 7 days", dates = c(Sys.Date() - 7, Sys.Date())),
    list(desc = "Last 30 days", dates = c(Sys.Date() - 30, Sys.Date())),
    list(desc = "Last 90 days", dates = c(Sys.Date() - 90, Sys.Date())),
    list(desc = "Year 2024", dates = c("2024-01-01", "2024-12-09")),
    list(desc = "Yesterday only", dates = c(Sys.Date() - 1, Sys.Date() - 1))
  )
  
  property_id <- paste0("properties/", actual_prop_id)
  
  for (dr in date_ranges) {
    cat(sprintf("  Testing: %s\n", dr$desc))
    cat(sprintf("  Dates: %s to %s\n", dr$dates[1], dr$dates[2]))
    
    result <- tryCatch({
      data <- ga_data(
        propertyId = property_id,
        date_range = dr$dates,
        metrics = "activeUsers",
        limit = 3
      )
      cat("  ✓ Success! Rows:", nrow(data), "\n\n")
      working_format <- property_id
      TRUE
    }, error = function(e) {
      cat("  ✗ Failed:", e$message, "\n\n")
      FALSE
    })
    
    if (result) break
  }
}

if (is.null(working_format)) {
  cat("\n[6] Testing with different metrics...\n\n")
  
  metrics_to_test <- c("sessions", "totalUsers", "screenPageViews", 
                       "newUsers", "engagementRate")
  
  property_id <- paste0("properties/", actual_prop_id)
  
  for (metric in metrics_to_test) {
    cat(sprintf("  Testing metric: %s\n", metric))
    
    result <- tryCatch({
      data <- ga_data(
        propertyId = property_id,
        date_range = c(Sys.Date() - 30, Sys.Date()),
        metrics = metric,
        limit = 1
      )
      cat("  ✓ Success!\n\n")
      working_format <- property_id
      TRUE
    }, error = function(e) {
      cat("  ✗ Failed:", e$message, "\n\n")
      FALSE
    })
    
    if (result) break
  }
}

if (is.null(working_format)) {
  cat("\n[7] Making raw HTTP request to see exact error...\n\n")
  
  property_id <- paste0("properties/", actual_prop_id)
  
  # Get the current token
  token <- ga_token()
  
  cat("  Property ID:", property_id, "\n")
  cat("  Making raw API call...\n\n")
  
  # Try direct HTTP call
  response <- tryCatch({
    POST(
      url = sprintf("https://analyticsdata.googleapis.com/v1beta/%s:runReport", property_id),
      config = config(token = token),
      body = list(
        dateRanges = list(list(startDate = "2024-01-01", endDate = "2024-12-09")),
        metrics = list(list(name = "activeUsers"))
      ),
      encode = "json",
      verbose()
    )
  }, error = function(e) {
    cat("  Error making request:", e$message, "\n")
    NULL
  })
  
  if (!is.null(response)) {
    cat("\n  HTTP Status:", status_code(response), "\n")
    cat("  Response:\n")
    print(content(response))
  }
}

if (!is.null(working_format)) {
  cat("\n==================================================\n")
  cat("  ✅ SUCCESS - PROBLEM SOLVED!\n")
  cat("==================================================\n\n")
  cat("Working property ID format:\n")
  cat("  ", working_format, "\n\n")
  cat("Update your app to use this exact format.\n\n")
} else {
  cat("\n==================================================\n")
  cat("  ❌ STILL FAILING - DEEPER ISSUE\n")
  cat("==================================================\n\n")
  cat("Possible causes:\n")
  cat("1. Property was just created (wait 24-48 hours)\n")
  cat("2. Data API has different permissions than Admin API\n")
  cat("3. Property is in a different Google Cloud organization\n")
  cat("4. There's a Google API issue\n\n")
  cat("Next steps:\n")
  cat("1. Try Google's API Explorer:\n")
  cat("   https://developers.google.com/analytics/devguides/reporting/data/v1/rest/v1beta/properties/runReport\n")
  cat("2. Contact Google Analytics support\n")
  cat("3. Try with a different GA4 property to isolate the issue\n\n")
}

cat("==================================================\n\n")