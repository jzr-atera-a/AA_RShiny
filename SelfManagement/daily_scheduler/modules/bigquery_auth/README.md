# BigQuery Authentication Module

## Description
Authenticate to Google BigQuery for cloud database storage of planned schedules.

## Dependencies
- bigrquery (>= 1.4.0)
- jsonlite
- shiny
- shinydashboard

## Inputs
- `json_file`: Service account JSON key file upload
- `json_text`: Service account JSON pasted as text (alternative to file upload)
- `project_id`, `dataset_id`, `table_id`: BigQuery location of the day_scheduler table

## Outputs
- `auth_status`: Connection status
- `test_status` / `test_table`: Results of a top-5-rows test query

## Usage
1. Upload your GCP service account JSON key, or paste its contents
2. Confirm or edit Project ID / Dataset ID / Table ID
3. Click "Connect to BigQuery"
4. Optionally click "Test Query" to confirm the table is reachable

## Notes
- Creates the `day_scheduler` table automatically if it doesn't exist yet
- Credentials are stored in memory only for the session
