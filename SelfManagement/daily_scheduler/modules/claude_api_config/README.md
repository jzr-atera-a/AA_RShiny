# Claude API Config Module

## Description
Manages Anthropic Claude API credentials used by Generate Schedule.

## Dependencies
- httr
- jsonlite
- shiny
- shinydashboard

## Inputs
- `api_key`: Anthropic API key
- `model`: Claude model to use
- `max_tokens`, `timeout`: Request tuning parameters

## Outputs
- `status`: Connection/save status

## Usage
1. Enter your Anthropic API key
2. Choose a model (Claude Sonnet 4.6 recommended)
3. Click "Test Connection" to verify, then "Save Credentials"

## Notes
- Credentials are stored in memory only for the session, never persisted or logged
