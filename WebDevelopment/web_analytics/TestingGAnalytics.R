library(googleAnalyticsR)

# Replace with YOUR JSON file path
ga_auth(json_file = "C:/111_SecA/atera_gcp/atera-analytics-service for google analytics/atera-2-50bf5c013456.json")

# Try to get account list
accounts <- ga_account_list()

# Print the results
print(accounts)






# Use ga_account_list for GA4
ga4_accounts <- ga_account_list(type = "ga4")
print(ga4_accounts)

# Or try this
all_accounts <- ga_account_list()
print(str(all_accounts))