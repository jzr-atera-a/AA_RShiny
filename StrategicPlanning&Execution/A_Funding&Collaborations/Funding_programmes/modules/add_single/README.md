# Add Single Entry Module

## Description
Manually add one funding programme directly to BigQuery, without going through
Claude generation.

## Dependencies
- shiny
- shinydashboard

## Inputs
- `category_select`, `country_select` / `cityregion_select` (+ "add new" variants)
- `programme_name`, `amount_of_money`, `conditions`, `key_sponsors`,
  `key_organiser_profiles`, `areas_of_application`, `start_date_for_applying`,
  `deadline`, `recommendations_for_applying`, `verified_urls`

## Usage
1. Authenticate with BigQuery first
2. Choose Category and Country (City/Region optional, defaults to "All")
3. Fill in the programme details
4. Click "Submit Entry"

## Notes
- Date fields are free text (not a strict date picker) since values like
  "Rolling basis" or "Not confirmed" are common for these programmes
- Triggers `api_manager$trigger_state_update()` after insert so Browse/Visualizations refresh
