# BigQuery Connection Module

Authenticates with Google BigQuery and loads EV charging point data.

## Features
- Service account JSON key authentication
- Connection testing and validation
- Automatic data loading
- Data preview and statistics

## Configuration
**IMPORTANT:** This module uses YOUR specific BigQuery configuration:

- **Project ID:** `atera-2`
- **Dataset ID:** `EVs_Infrastructure`
- **Table ID:** `Charge_Points_UK_EVs`

These values are pre-configured in the UI and should match your actual BigQuery setup.

## Usage
1. Upload service account JSON key file
2. Verify project/dataset/table IDs (pre-filled)
3. Click "Test Connection"
4. Wait for data to load

## Dependencies
- bigrquery
- dplyr  
- sf

## To Disable
In `modules/_module_registry.yml`:
```yaml
bigquery_connection:
  enabled: false
```
