# BigQuery Authentication Module

## Description
Authenticates to Google Cloud Platform BigQuery for cloud database storage of book summaries.

## Dependencies
- bigrquery (>= 1.4.0)
- jsonlite
- shiny
- shinydashboard

## Inputs
- `json_file`: Service account JSON file upload
- `json_text`: Service account JSON text (paste)
- `project_id`: GCP Project ID
- `dataset_id`: BigQuery Dataset ID
- `table_id`: BigQuery Table ID

## Outputs
- `auth_status`: Authentication status display
- `test_status`: Test query status
- `test_table`: Test query results table

## Usage
1. Enter your GCP project details (or use defaults)
2. Upload service account JSON file OR paste JSON content
3. Click "Connect to BigQuery"
4. Test connection with "Test Query" button

## Data Schema
Table: atera-2.Wonderfulp_March.book_summaries_test3

Fields:
- id (INTEGER)
- created_at (TIMESTAMP)
- book_name (STRING)
- author (STRING)
- genre (STRING)
- topic (STRING)
- chapter (STRING)
- section (STRING)
- main_details (STRING)
- formula (STRING)
- formula_explanation (STRING)
- reference_url (STRING)
- reference_description (STRING)
- numeric_data (STRING)
- numeric_data_description (STRING)

## Reactive Triggers
On successful authentication, triggers `api_manager$state_trigger()` to notify all other modules.
