-- deploy_apps: registry of shinyapps.io apps used by Shiny Deploy Master.
-- Run once in the BigQuery console (project atera-2). Safe to re-run:
-- CREATE TABLE IF NOT EXISTS never alters an existing table; the INSERT runs only if the table is empty.
-- The app performs the same steps automatically on every BigQuery connect.

CREATE TABLE IF NOT EXISTS `atera-2.business_strategy.deploy_apps` (
  title_of_app STRING NOT NULL,
  active_url   STRING,
  Updated_Date DATE,
  status       STRING
);

INSERT INTO `atera-2.business_strategy.deploy_apps` (title_of_app, active_url, Updated_Date, status)
SELECT * FROM (
  SELECT * FROM UNNEST([STRUCT<title_of_app STRING, active_url STRING, Updated_Date DATE, status STRING>
      ('booksnetworksstrategysixs', 'https://atera-analytics.shinyapps.io/booksnetworksstrategysixs/', DATE('2026-10-13'), 'Active'),
      ('businessoperationssuite', 'https://atera-analytics.shinyapps.io/businessoperationssuite/', DATE('2026-10-13'), 'Active'),
      ('david_cleevely_serendipity', 'https://atera-analytics.shinyapps.io/david_cleevely_serendipity/', DATE('2026-10-13'), 'Active'),
      ('daysplanningfundingtravel', 'https://atera-analytics.shinyapps.io/daysplanningfundingtravel/', DATE('2026-10-13'), 'Active'),
      ('drivesafe_suite_with_osa_road_risk', 'https://atera-analytics.shinyapps.io/drivesafe_suite_with_osa_road_risk/', DATE('2026-10-13'), 'Active'),
      ('mat_health_intelligence_poc', 'https://atera-analytics.shinyapps.io/mat_health_intelligence_poc/', DATE('2026-10-13'), 'Active'),
      ('simon_hall_cc', 'https://atera-analytics.shinyapps.io/simon_hall_cc/', DATE('2026-10-13'), 'Active'),
      ('trading_analysis_f1', 'https://atera-analytics.shinyapps.io/trading_analysis_f1/', DATE('2026-10-13'), 'Active'),
      ('trading_analysis_lat_2026_u3', 'https://atera-analytics.shinyapps.io/trading_analysis_lat_2026_u3/', DATE('2026-10-13'), 'Active'),
      ('ventureanalysis', 'https://atera-analytics.shinyapps.io/ventureanalysis/', DATE('2026-10-13'), 'Active')
  ])
) AS seed
WHERE NOT EXISTS (SELECT 1 FROM `atera-2.business_strategy.deploy_apps`);
