# Bulk Import Module

## Description
Parse pasted or generated programme text (one or more entries) and upload to
BigQuery in bulk.

## Dependencies
- DT
- shiny
- shinydashboard

## Inputs
- `programme_text`: Pasted or auto-filled programme text (one or more flat entry blocks)

## Usage
1. Paste programme text (or arrive here via "Copy to Bulk Import" from Find Programmes)
2. Click "Parse Programmes" to validate and preview
3. Review the parsed rows
4. Click "Upload to BigQuery"

## Notes
- Supports multiple programme entries in a single paste, separated by a blank line
- Automatically receives text pushed from Find Programmes via `api_manager$pending_bulk_text`
- Triggers `api_manager$trigger_state_update()` after upload so Browse/Visualizations refresh
