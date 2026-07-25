# BigQuery Authentication Module

## Description
Authenticate to Google BigQuery for cloud database storage of funding programmes.

## Dependencies
- bigrquery (>= 1.4.0)
- jsonlite
- shiny
- shinydashboard

## Inputs
- `json_file` / `json_text`: Service account credentials (file upload or pasted text)
- `project_id`, `dataset_id`, `table_id`: BigQuery location of the funding_programmes table

## Usage
1. Upload your GCP service account JSON key, or paste its contents
2. Confirm or edit Project ID / Dataset ID / Table ID
3. Click "Connect to BigQuery"
4. Optionally click "Test Query" to confirm the table is reachable

## Notes
- Creates the `funding_programmes` table automatically if it doesn't exist yet
