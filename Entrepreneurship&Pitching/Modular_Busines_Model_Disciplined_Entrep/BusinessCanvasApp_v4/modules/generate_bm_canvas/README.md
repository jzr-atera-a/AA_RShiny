# Generate Business Model Canvas Module

## Description
AI-powered generation of Business Model Canvas using Claude API. Generates comprehensive, structured content for all 9 building blocks based on user-provided business description.

## Dependencies
- shiny
- shinydashboard
- httr (>= 1.4.0)
- jsonlite
- stringr
- bigrquery (for submission)

## Required APIs
- Claude API (must be connected first)
- BigQuery (optional, for submission)

## Functionality

### 1. Content Generation
- Accepts business details (area, project, focus, description)
- Sends prompt to Claude API
- Generates all 9 Business Model Canvas sections
- Displays generated content in editable text area

### 2. Content Parsing
- Parses text format with [Section Name] headers
- Validates all 9 sections are present
- Extracts content for each section
- Shows preview of parsed data

### 3. BigQuery Submission
- Creates unique canvas_id
- Uploads to BigQuery table
- Handles errors gracefully
- Confirms successful submission

### 4. Field Management
- Clear all inputs and outputs
- Reset module state
- Prepare for new generation

## Usage Flow
1. Connect to Claude API (in claude_auth module)
2. Enter business details and description
3. Click "Generate with Claude"
4. Review and edit generated content
5. Click "Parse Canvas Data" to validate
6. Click "Submit to BigQuery" to save
7. Use "Clear All" to reset

## Data Format
Expects text format:
```
[Key Partners]
Content here...

[Key Activities]
Content here...

...
```

All 9 sections required:
- Key Partners
- Key Activities
- Key Resources
- Value Propositions
- Customer Relationships
- Channels
- Customer Segments
- Cost Structure
- Revenue Streams
