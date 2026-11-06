# Generate Programme Module

## Description
AI-assisted discovery of grants, incubators, accelerators, and competitions using
the Claude API. Can return several matching programmes in a single search, each
becoming one row.

## Dependencies
- httr
- jsonlite
- shinyjs
- shiny
- shinydashboard

## Inputs
- `category_select` / `new_category_text`: Grant/Incubator/Accelerator/Competition/custom
- `country_select` / `cityregion_select` (+ "add new" variants): Location (City/Region defaults to "All")
- `search_focus`: Optional free text to narrow results (sector, stage, funding type)
- `n_results`: How many programmes to ask Claude for (1-8)

## Outputs
- `programme_text`: Generated programme text (one or more entries)
- `status`: Generation status

## Usage
1. Configure Claude API credentials first
2. Select Category and Country (City/Region optional, defaults to "All")
3. Optionally add a search focus and choose how many results to find
4. Click "Find Programmes"
5. Options: Copy to Bulk Import, Parse & Upload Direct, or Download as text

## Important accuracy note
Claude generates results from training data, which may be outdated or incomplete
for programmes that change yearly. Dates, amounts, and URLs should always be
manually verified before being relied upon. The prompt explicitly instructs
Claude to flag uncertain fields rather than inventing precise-looking values.
