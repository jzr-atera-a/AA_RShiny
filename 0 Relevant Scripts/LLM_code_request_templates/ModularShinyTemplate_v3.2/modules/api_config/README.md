# API Configuration Module

## Description
Provides a user interface for configuring API credentials and connection settings.

## Features
- Secure API key storage (session-only)
- Configurable request timeout
- Connection testing
- Configuration status display

## Dependencies
- shiny
- shinydashboard

## Usage
1. Enter your API key
2. Adjust timeout if needed
3. Click "Save Configuration"
4. Test connection to verify

## Inputs
- `api_key`: API authentication key
- `timeout`: Request timeout in seconds (60-600)

## Outputs
- `status`: Configuration status messages
- `config_summary`: Current configuration display

## Notes
- Credentials are stored in session memory only
- Not persisted between app restarts
- For production, consider using environment variables or secure vaults
