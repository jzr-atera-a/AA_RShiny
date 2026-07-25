# Add Single Entry Module

## Description
Manually add one schedule row (Location, Transport, or Summary) directly to
BigQuery, without going through Claude generation. Useful for quick fixes or
adding a stop Claude missed.

## Dependencies
- shiny
- shinydashboard

## Inputs
- `schedule_date`, `day_type_select` (+ Country/City for Travel days), `trip_details`
- `row_type`, `location_name`, `location_details`, `opening_hours`, `recommended_time`, `observations`

## Outputs
- `status`: Submission status

## Usage
1. Authenticate with BigQuery first
2. Pick the date and Type of Day this row belongs to
3. Choose Row Type (Location / Transport / Summary) and fill in the details
4. Click "Submit Entry"

## Notes
- `row_sequence` is auto-incremented based on existing rows for that date
- Triggers `api_manager$trigger_state_update()` after insert so Browse/Visualizations refresh
