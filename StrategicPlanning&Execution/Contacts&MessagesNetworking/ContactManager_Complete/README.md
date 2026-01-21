# Business Contact Manager - Modular Shiny App

## Overview
AI-powered contact management system with:
- OpenAI LLM integration for contact extraction
- BigQuery cloud database storage
- SMTP email integration
- Personalized communication generation

## Module Architecture
All functionality is split into 7 independent modules:

1. **api_config** - OpenAI API configuration
2. **bq_config** - BigQuery database setup
3. **smtp_config** - Email SMTP configuration
4. **process_contact** - Extract contact info from documents using LLM
5. **explore_contacts** - Browse and manage contact database
6. **customise_communication** - Generate personalized messages with LLM
7. **send_email** - Send emails with attachments

## Installation
```r
# Install required packages
install.packages(c("shiny", "shinydashboard", "shinyjs", "R6", "yaml", "purrr",
                   "httr", "jsonlite", "DT", "pdftools", "readtext", "uuid",
                   "bigrquery", "DBI", "glue", "shinyWidgets", "base64enc"))
```

## Running the App
```r
shiny::runApp("ContactManager")
```

## Configuration
1. Configure OpenAI API key in API Configuration tab
2. Set up BigQuery credentials in BigQuery Settings tab  
3. Configure SMTP settings in SMTP Configuration tab
4. Start adding and managing contacts!

## Features
- **Smart Contact Extraction**: Upload documents (PDF, DOCX, TXT) and extract contact information using LLM
- **Cloud Storage**: All contacts stored in BigQuery for reliability and scalability
- **Communication History**: Track all interactions with each contact
- **AI-Powered Messages**: Generate personalized communications based on context
- **Email Integration**: Send emails directly from the app with attachments

