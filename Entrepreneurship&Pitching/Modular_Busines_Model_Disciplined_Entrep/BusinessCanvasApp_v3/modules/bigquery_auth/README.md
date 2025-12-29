# BigQuery Authentication Module

## Description
Handles Google Cloud Platform BigQuery authentication using service account credentials. Supports both JSON file upload and manual JSON text input.

## Dependencies
- shiny
- shinydashboard
- bigrquery (>= 1.4.0)
- jsonlite

## Inputs
- `json_file`: File input for service account JSON
- `json_text`: Text area for manual JSON paste
- `project_id`: GCP Project ID
- `dataset_id`: BigQuery Dataset ID
- `table_id`: BigQuery Table name
- `authenticate`: Button to trigger authentication

## Outputs
- `auth_status`: HTML display of authentication status
- `package_info`: Package version information

## Functionality
1. Clears existing authentication
2. Accepts JSON credentials via file or text
3. Validates JSON structure
4. Authenticates with BigQuery
5. Tests connection
6. Creates tables if they don't exist
7. Stores credentials in api_manager

## Usage
1. Obtain service account JSON from Google Cloud Console
2. Either upload the JSON file or paste its contents
3. Provide Project ID, Dataset ID, and Table ID
4. Click "Connect to BigQuery"
5. Verify successful connection in status display

## Data Storage
Credentials and connection details stored in `api_manager`:
- `bq_authenticated`: Boolean flag
- `bq_project_id`: Project ID
- `bq_dataset_id`: Dataset ID
- `bq_table_id`: Table name
- `bq_full_table_id`: Complete table path
- `bq_temp_file_path`: Path to temporary JSON file (if used)
