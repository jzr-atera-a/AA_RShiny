# Visualizations Module

## Description
Rich itinerary timeline visualization for a single planned day, plus a
time-allocation chart across its stops.

## Dependencies
- DT
- plotly
- shiny
- shinydashboard

## Inputs
- `viz_day_type` -> `viz_country` -> `select_date`: cascading filters to find the day
- `filter_row_type`: optional Location/Transport/Summary filter

## Outputs
- `day_header`, value boxes (Locations, Transport Legs, Total Day Time, Total Entries)
- `timeline_html`: full itinerary as a single card with each row as a section
- `time_chart`: bar chart of estimated minutes per stop (best-effort duration parsing)

## Usage
1. Authenticate with BigQuery first
2. Filter by Type of Day -> Country -> Date
3. Click "Load Visualizations"

## Notes
- Reuses the app's existing `.viz-card` / `.section-tag` / `.metric-box` / `.reference-box`
  CSS classes exactly as defined in `www/css/global.css` - no new styling added
- Refreshes its Day Type/Country/Date dropdowns whenever `api_manager$state_trigger()` fires
