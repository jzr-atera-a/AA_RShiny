# Claude API Configuration Module

## Description
Configure Claude API credentials for AI-powered book summary generation.

## Dependencies
- httr
- jsonlite
- shiny
- shinydashboard

## Inputs
- `api_key`: Anthropic API key
- `model`: Claude model selection
- `max_tokens`: Maximum tokens for generation

## Outputs
- `status`: Connection status display

## Usage
1. Enter your Anthropic API key
2. Select Claude model (Sonnet 4.5 recommended)
3. Set max tokens (16,000 default)
4. Click "Test Connection" to verify
5. Click "Save Credentials" to store

## Models Available
- Claude Sonnet 4.5 (claude-sonnet-4-20250514) - Recommended
- Claude Sonnet 3.5 (claude-3-5-sonnet-20241022)
- Claude Opus 3 (claude-3-opus-20240229)

## Reactive Triggers
On successful authentication, triggers `api_manager$state_trigger()` to notify all other modules.
