# Claude API Connection Module

## Description
Manages connection to Anthropic's Claude API. Allows users to configure API credentials, select models, and test the connection.

## Dependencies
- shiny
- shinydashboard
- httr (>= 1.4.0)
- jsonlite

## Inputs
- `api_key`: Claude API key (password field)
- `model_select`: Model selection dropdown
- `connect_claude`: Connection button
- `test_prompt`: Test prompt input
- `test_claude`: Test API button

## Outputs
- `connection_status`: HTML status display
- `test_output`: API test response text

## Functionality
1. Accept and validate Claude API key
2. Select Claude model version
3. Test connection with simple prompt
4. Store credentials in api_manager
5. Enable/disable based on connection status
6. Provide user-friendly error messages

## Usage
1. Get API key from https://console.anthropic.com/
2. Enter API key in password field
3. Select desired Claude model
4. Click "Connect to Claude"
5. Optionally test with custom prompt

## Security
- API key stored in memory only (not persisted)
- Uses password input field (hidden text)
- Credentials stored in api_manager R6 object
