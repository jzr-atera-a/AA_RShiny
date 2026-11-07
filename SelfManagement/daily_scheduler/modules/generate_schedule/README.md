# Generate Schedule Module

## Description
AI-powered day schedule generation using Claude API. Plans an optimal route of
locations and transport legs for a single day, minimizing travel time/distance
while respecting opening hours.

## Dependencies
- httr
- jsonlite
- shinyjs
- shiny
- shinydashboard

## Inputs
- `schedule_date`: The date being planned
- `day_type_select` / `new_day_type_text`: Type of Day (Travel/Work/Conference/Research/custom)
- `country_select` / `city_select` (+ "add new" variants): Location, for Travel days
- `trip_details`: Free text - places to visit, start/end point, preferences

## Outputs
- `schedule_text`: Generated schedule text
- `status`: Generation status

## Usage
1. Configure Claude API credentials first
2. Pick a date and Type of Day
3. For Travel days, select or enter Country and City
4. Add any additional details (start/end point, must-visit places, preferences)
5. Click "Plan Schedule"
6. Wait for AI generation (usually 30-90 seconds)
7. Options:
   - Copy to Bulk Import tab
   - Parse & Upload Direct to BigQuery
   - Download as text file

## Schedule Format
Generated schedules follow this structure:
- Day metadata (date, day type, country, city, trip context)
- Alternating Location / Transport rows
- One closing Summary row with total day time and key insights

## Notes
- Requires Claude API authentication
- Uses Claude Sonnet 4.6 by default
- 8,000 token limit (configurable)
- Structured output optimized for parsing
