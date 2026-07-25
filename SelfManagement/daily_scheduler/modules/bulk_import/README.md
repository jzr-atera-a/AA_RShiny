# Bulk Import Module

## Description
Parse pasted or generated day-schedule text and upload it to BigQuery in bulk.

## Dependencies
- DT
- shiny
- shinydashboard

## Inputs
- `schedule_text`: Pasted or auto-filled schedule text (5-line header + row entries)

## Outputs
- `status`: Parse/upload status
- `parse_info`: Summary of the parsed schedule
- `preview_table`: DT preview of parsed rows

## Usage
1. Paste schedule text (or arrive here via "Copy to Bulk Import" from Generate Schedule)
2. Click "Parse Schedule" to validate and preview
3. Review the parsed rows in the table
4. Click "Upload to BigQuery"

## Notes
- Automatically receives text pushed from Generate Schedule via `api_manager$pending_bulk_text`
- Triggers `api_manager$trigger_state_update()` after upload so Browse/Visualizations refresh
