-- =============================================================================
-- BigQuery Table Schema — funding_programmes
-- =============================================================================
-- This matches exactly what R/utils_api.R's authenticate_bigquery() creates
-- automatically (CREATE TABLE IF NOT EXISTS) the first time you connect.
-- Run this manually only if you want to pre-create the table yourself.
--
-- NOTE: If using the BigQuery Console's "Create Table" UI schema editor
-- instead of the Query editor, that box does NOT accept SQL comments (--) or
-- full DDL syntax — use the JSON schema at the bottom of this file instead.
-- =============================================================================

CREATE TABLE IF NOT EXISTS `atera-2.business_strategy.funding_programmes` (
  id INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),

  category STRING,                     -- "Grant" | "Incubator" | "Accelerator" | "Competition" | custom
  country STRING,
  city_region STRING,                  -- defaults to "All" when a programme isn't region-specific

  programme_name STRING,               -- official name of the grant/incubator/competition
  amount_of_money STRING,              -- e.g. "Up to EUR 2.5 million" (kept as text - amounts vary widely in format)
  conditions STRING,                   -- key eligibility conditions
  key_sponsors STRING,                 -- who funds/sponsors the programme
  key_organiser_profiles STRING,       -- names/roles of key people who run it
  areas_of_application STRING,         -- sectors/fields this programme applies to

  start_date_for_applying STRING,      -- YYYY-MM-DD when known, else descriptive text (e.g. "Rolling basis")
  deadline STRING,                     -- YYYY-MM-DD when known, else descriptive text

  recommendations_for_applying STRING, -- practical tips for a strong application
  verified_urls STRING                 -- one or more URLs, comma-separated
);

-- =============================================================================
-- Useful queries
-- =============================================================================

-- All programmes with an upcoming deadline in the next 90 days
-- (works correctly for well-formed YYYY-MM-DD deadlines; text like "Rolling
--  basis" sorts after any date string and is naturally excluded)
-- SELECT programme_name, category, country, city_region, deadline
-- FROM `atera-2.business_strategy.funding_programmes`
-- WHERE deadline BETWEEN FORMAT_DATE('%Y-%m-%d', CURRENT_DATE())
--                    AND FORMAT_DATE('%Y-%m-%d', DATE_ADD(CURRENT_DATE(), INTERVAL 90 DAY))
-- ORDER BY deadline ASC;

-- Distinct categories / countries / city_regions (powers the app's cascading dropdowns)
-- SELECT DISTINCT category, country, city_region
-- FROM `atera-2.business_strategy.funding_programmes`
-- ORDER BY category, country, city_region;

-- Programme count by category
-- SELECT category, COUNT(*) as n
-- FROM `atera-2.business_strategy.funding_programmes`
-- GROUP BY category ORDER BY n DESC;

-- =============================================================================
-- Alternative: JSON schema for the BigQuery Console "Create Table" UI
-- (paste into the "Edit as text" schema box — comments not supported there)
-- =============================================================================
--
-- [
--   {"name": "id", "type": "INTEGER", "mode": "NULLABLE"},
--   {"name": "created_at", "type": "TIMESTAMP", "mode": "NULLABLE"},
--   {"name": "category", "type": "STRING", "mode": "NULLABLE"},
--   {"name": "country", "type": "STRING", "mode": "NULLABLE"},
--   {"name": "city_region", "type": "STRING", "mode": "NULLABLE"},
--   {"name": "programme_name", "type": "STRING", "mode": "NULLABLE"},
--   {"name": "amount_of_money", "type": "STRING", "mode": "NULLABLE"},
--   {"name": "conditions", "type": "STRING", "mode": "NULLABLE"},
--   {"name": "key_sponsors", "type": "STRING", "mode": "NULLABLE"},
--   {"name": "key_organiser_profiles", "type": "STRING", "mode": "NULLABLE"},
--   {"name": "areas_of_application", "type": "STRING", "mode": "NULLABLE"},
--   {"name": "start_date_for_applying", "type": "STRING", "mode": "NULLABLE"},
--   {"name": "deadline", "type": "STRING", "mode": "NULLABLE"},
--   {"name": "recommendations_for_applying", "type": "STRING", "mode": "NULLABLE"},
--   {"name": "verified_urls", "type": "STRING", "mode": "NULLABLE"}
-- ]
