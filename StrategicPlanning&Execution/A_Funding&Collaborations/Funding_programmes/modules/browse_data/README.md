# Browse Data Module

## Description
Browse all planned schedule rows stored in BigQuery, with CSV export.

## Dependencies
- DT
- shiny
- shinydashboard

## Inputs
- `max_rows`: Row limit for the query

## Outputs
- `status`: Load status
- `table`: DT table of all rows, ordered by schedule_date desc, row_sequence asc

## Usage
1. Authenticate with BigQuery first
2. Click "Refresh Data"
3. Optionally "Download CSV"

## Notes
- Manual refresh only (click "Refresh Data"); does not auto-poll
