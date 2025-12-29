# Generate Summary Module

## Description
AI-powered book summary generation using Claude API.

## Dependencies
- httr
- jsonlite
- shinyjs
- shiny
- shinydashboard

## Inputs
- `book_title`: Book title
- `book_author`: Author name
- `book_genre`: Genre/category (optional)
- `book_topic`: Topic description (optional)

## Outputs
- `summary_text`: Generated summary text
- `status`: Generation status

## Usage
1. Configure Claude API credentials first
2. Enter book title and author
3. Optionally add genre and topic
4. Click "Generate Summary"
5. Wait for AI generation (may take 1-2 minutes)
6. Options:
   - Copy to Bulk Import tab
   - Parse & Upload Direct to BigQuery
   - Download as text file

## Summary Format
Generated summaries follow this structure:
- Book metadata (title, author, genre, topic)
- Chapter-by-chapter breakdown
- Sections within chapters
- Formulas with explanations
- Reference URLs
- Numeric metrics

## Notes
- Requires Claude API authentication
- Uses Claude Sonnet 4.5 by default
- 16,000 token limit (configurable)
- Structured output optimized for parsing
