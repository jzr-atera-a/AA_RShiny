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
2. Select Claude model (Sonnet 4.6 recommended)
3. Set max tokens (16,000 default)
4. Click "Test Connection" to verify
5. Click "Save Credentials" to store

## Models Available
- Claude Sonnet 4.6 (claude-sonnet-4-6) - Recommended
- Claude Opus 4.8 (claude-opus-4-8) - Most capable
- Claude Haiku 4.5 (claude-haiku-4-5-20251001) - Fastest

Note: Anthropic periodically retires older model snapshots. If you see
a 404 error on Test Connection, check
https://platform.claude.com/docs/en/about-claude/model-deprecations
and update the model IDs in `ui.R` and `R/utils_api.R` accordingly. See
`MODEL_DEPRECATION_FIX.md` in the project root for details.

## Reactive Triggers
On successful authentication, triggers `api_manager$state_trigger()` to notify all other modules.
