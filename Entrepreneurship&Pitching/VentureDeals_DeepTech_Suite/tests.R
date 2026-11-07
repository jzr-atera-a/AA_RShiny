rm(list = ls())
source("R/sheets_backend.R")

Sys.setenv(
  GOOGLE_SHEETS_ID = "1zDiIDQqOglIWGXgwfJCV-FcHeCUoJbbt",
  ADMIN_EMAILS     = "joseph.zr@atera-analytics.co.uk"
)

.sheets_env$connected <- FALSE
sheets_connect()

⚠ Sheets: Connection failed: Bad Request (HTTP 400). — using file fallback
[1] FALSE

library(googlesheets4)
library(googledrive)

library(gargle)

source("C:/101_Code/R/Entrepreneurship&Pitching/VentureDeals_DeepTech_Suite/VentureDeals/R/sheets_backend.R")
sheets_connect()

gs4_auth(path = "C:/101_Code/R/Entrepreneurship&Pitching/VentureDeals_DeepTech_Suite/VentureDeals/auth/google_service_account.json")

