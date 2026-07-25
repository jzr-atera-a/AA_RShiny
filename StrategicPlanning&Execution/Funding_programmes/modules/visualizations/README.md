# Visualizations Module

## Description
Filterable view of all saved funding programmes: filter by Category, Country,
City/Region, and optional date ranges on Start Date for Applying and Deadline.

## Dependencies
- DT
- plotly
- shiny
- shinydashboard

## Inputs
- `viz_category`, `viz_country` -> `viz_cityregion`: location/category filters (default "All")
- `filter_start_date` + `start_date_range`: optional date-range filter
- `filter_deadline` + `deadline_range`: optional date-range filter

## Outputs
- Value boxes: Programmes, Categories, Countries, Upcoming Deadlines
- `category_chart`: bar chart of programme count by category
- `programme_cards`: one card per programme (reuses `.viz-card` / `.section-tag` /
  `.metric-box` / `.reference-box` / `.formula-box` exactly as defined in the app's CSS)

## Notes
- Date fields are STRING in BigQuery (to allow "Rolling basis" style values), so
  date-range filters use a string BETWEEN comparison, which works correctly for
  well-formed YYYY-MM-DD values and naturally excludes non-date text
- Refreshes its filter dropdowns whenever `api_manager$state_trigger()` fires
