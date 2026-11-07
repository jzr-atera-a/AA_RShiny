-- =============================================================================
-- BigQuery Table Schema — day_scheduler
-- =============================================================================
-- This matches exactly what R/utils_api.R's authenticate_bigquery() creates
-- automatically (CREATE TABLE IF NOT EXISTS) the first time you connect.
-- Run this manually only if you want to pre-create the table yourself, or on
-- a different project/dataset than the app's defaults (atera-2.business_strategy).
-- =============================================================================

CREATE TABLE IF NOT EXISTS `atera-2.business_strategy.day_scheduler` (
  id INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),

  -- Day-level metadata (same for every row belonging to one planned day)
  schedule_date STRING,      -- the date this schedule is for, e.g. "2026-07-10"
  day_type STRING,           -- "Travel" | "Work" | "Conference" | "Research" | custom
  country STRING,            -- populated when day_type = "Travel"; "N/A" otherwise
  city STRING,               -- populated when day_type = "Travel"; "N/A" otherwise
  trip_details STRING,       -- free text: places to visit, start point, end point, preferences

  -- Row-level fields (one row per location, one row per transport leg,
  -- and one final Summary row per day)
  row_type STRING,           -- "Location" | "Transport" | "Summary"
  row_sequence INTEGER,      -- order within the day (1, 2, 3, ...)
  location_name STRING,      -- place name / transport leg label / "Day Summary"
  location_details STRING,   -- address+description / route+mode / day title
  opening_hours STRING,      -- Location rows only; "N/A" for Transport/Summary

  -- Reused columns (meaning depends on row_type - see the About tab for details):
  --   Location  -> time window & duration spent there
  --   Transport -> expected travel time for that leg
  --   Summary   -> total time for the whole day
  recommended_time STRING,

  --   Location  -> what to expect / look for at this place
  --   Transport -> practical directions for taking this transport
  --   Summary   -> key insights about the day as a whole
  observations STRING
);

-- =============================================================================
-- Useful queries for development / debugging
-- =============================================================================

-- Full itinerary for one day, in order
-- SELECT row_sequence, row_type, location_name, recommended_time, opening_hours, observations
-- FROM `atera-2.business_strategy.day_scheduler`
-- WHERE schedule_date = '2026-07-10'
-- ORDER BY row_sequence;

-- Latest planned days (one row per day, via the Summary row)
-- SELECT schedule_date, day_type, country, city,
--        observations AS day_summary, recommended_time AS total_time
-- FROM `atera-2.business_strategy.day_scheduler`
-- WHERE row_type = 'Summary'
-- ORDER BY created_at DESC LIMIT 20;

-- Distinct day types / countries / cities (powers the app's cascading dropdowns)
-- SELECT DISTINCT day_type, country, city, schedule_date
-- FROM `atera-2.business_strategy.day_scheduler`
-- ORDER BY day_type, country, schedule_date;
