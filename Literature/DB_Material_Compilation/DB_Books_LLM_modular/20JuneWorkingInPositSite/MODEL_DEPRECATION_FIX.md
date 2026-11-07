# Fix: Claude API 404 Errors (Model Retired)

## Symptom

Claude API Config tab shows:

```
Error: Claude connection failed. Status: 404
```

This happens even with a valid, newly-generated API key, and even though
the same key works fine in other apps.

## Root Cause

The model dropdown hardcoded three specific dated model snapshots:

- `claude-sonnet-4-20250514` (was the default/selected option)
- `claude-3-5-sonnet-20241022`
- `claude-3-opus-20240229`

Anthropic periodically retires older model snapshots. Once a model is
retired, every request naming it returns HTTP 404, regardless of API
key validity. Per Anthropic's official release notes (as of this fix):

| Model ID | Status |
|---|---|
| `claude-sonnet-4-20250514` | Retired June 15, 2026 |
| `claude-3-5-sonnet-20241022` | Retired October 28, 2025 |
| `claude-3-opus-20240229` | Retired January 5, 2026 |

All three options in the dropdown were retired - including the default
one, which is why the error appeared even on a fresh install with a
brand-new key. The request format itself (endpoint, headers,
`anthropic-version: 2023-06-01`, body shape) is unaffected by this and
required no changes.

## Fix

Updated the model choices in `modules/claude_api_config/ui.R` and the
default in `R/utils_api.R` to current, supported model IDs:

- `claude-sonnet-4-6` (Claude Sonnet 4.6) - default/recommended
- `claude-opus-4-8` (Claude Opus 4.8) - most capable
- `claude-haiku-4-5-20251001` (Claude Haiku 4.5) - fastest/cheapest

## This Will Happen Again

Anthropic deprecates and retires model snapshots on an ongoing basis
(typically several months' notice between deprecation announcement and
retirement). There is no code change that prevents this permanently -
any hardcoded model ID will eventually be retired.

If this error recurs in the future:

1. Check the current model list and any deprecation notices at
   https://platform.claude.com/docs/en/about-claude/models/overview
   and https://platform.claude.com/docs/en/about-claude/model-deprecations
2. Update the `choices` in `modules/claude_api_config/ui.R` and the
   `claude_model` default in `R/utils_api.R` to a currently-supported
   model ID.

A more permanent option, if you want to avoid manual updates going
forward, is to call Anthropic's Models API (`GET /v1/models`) at
startup or on demand to populate the dropdown with whatever models are
currently available, instead of hardcoding IDs. Not implemented here,
but worth considering if this becomes a recurring maintenance burden.
