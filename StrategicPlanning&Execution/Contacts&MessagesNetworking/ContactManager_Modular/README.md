# Business Contact Manager - Modular Shiny Application

## Overview
A fully modularized AI-powered contact management system with integrated BigQuery storage, SMTP email capabilities, and LLM-driven personalized communication generation.

## Architecture
This application follows a modular architecture where each feature is self-contained in its own module directory.

### Directory Structure
```
ContactManager_Modular/
├── app.R                    # Main entry point
├── global.R                 # Global configuration and UI/Server factories
├── R/
│   ├── module_loader.R      # R6 class for dynamic module loading
│   └── utils_contact_manager.R  # R6 ContactManager class + utilities
├── modules/
│   ├── _module_registry.yml # Central module configuration
│   ├── api_config/          # OpenAI API configuration
│   ├── bq_config/           # BigQuery setup and authentication
│   ├── smtp_config/         # SMTP email configuration
│   ├── process_contact/     # Contact information extraction with LLM
│   ├── explore_contacts/    # Browse, filter, and manage contacts
│   ├── customise_communication/  # Generate personalized messages
│   └── send_email/          # Email sending with attachments
└── www/
    └── css/
        └── global.css       # Application-wide styling

```

## Module Structure
Each module contains:
- `manifest.yml` - Module metadata (name, dependencies, menu info)
- `ui.R` - User interface definition
- `server.R` - Server-side logic

## Features

### 1. API Configuration (`api_config`)
- Configure OpenAI API credentials
- Select GPT model (GPT-4, GPT-4-turbo, GPT-4o, GPT-3.5-turbo)
- Test API connection

### 2. BigQuery Settings (`bq_config`)
- Configure Google Cloud BigQuery connection
- Authenticate with JSON key or ADC
- Automatic table creation
- Load existing contacts and communications

### 3. SMTP Configuration (`smtp_config`)
- GoDaddy SMTP setup (customizable for other providers)
- Connection testing
- Secure credential storage

### 4. Process Contact (`process_contact`)
- Upload files (PDF, DOCX, PPTX, TXT) or paste text
- LLM-powered extraction of contact information
- Editable data preview
- Add personal notes and interaction dates
- Send to BigQuery

### 5. Explore Contacts (`explore_contacts`)
- View all contacts in interactive DataTable
- Filter by industry, country, location, university, company
- Inline editing of contact details
- Update or delete contacts
- Navigate to communication customization

### 6. Customise Communication (`customise_communication`)
- View selected contact profile
- Load recent communication history
- LLM-generated communication summary
- Generate personalized messages
- Customize by channel (LinkedIn, Email, WhatsApp)
- Set purpose, language, and length
- Save messages to BigQuery
- Copy to clipboard
- **Send directly to email tab** (when channel is Email)

### 7. Send Email (`send_email`)
- Compose emails with rich formatting
- Multiple recipients support
- File attachments
- Pre-populated from customise_communication
- Secure SMTP sending via curl

## Technology Stack

### Core
- **Shiny**: Web framework
- **shinydashboard**: Dashboard UI components
- **shinyjs**: JavaScript integration
- **R6**: Object-oriented programming

### Data & APIs
- **bigrquery**: Google BigQuery interface
- **DBI**: Database interface
- **httr**: HTTP requests for OpenAI API
- **jsonlite**: JSON handling

### Document Processing
- **pdftools**: PDF text extraction
- **readtext**: DOCX/PPTX reading
- **base64enc**: File encoding for email attachments

### UI Components
- **DT**: Interactive DataTables
- **shinyWidgets**: Enhanced UI widgets

## Installation

### 1. R Packages
```r
install.packages(c(
  "shiny", "shinydashboard", "shinyjs", "R6", "yaml", "purrr",
  "httr", "jsonlite", "DT", "pdftools", "readtext", "uuid",
  "bigrquery", "DBI", "glue", "shinyWidgets", "base64enc"
))
```

### 2. System Requirements
- **curl**: Required for SMTP email sending
  ```bash
  # Ubuntu/Debian
  sudo apt-get install curl
  
  # macOS (usually pre-installed)
  brew install curl
  ```

### 3. Google Cloud Setup
- Create a GCP project
- Enable BigQuery API
- Create service account and download JSON key
- Set up dataset and tables (or let app create them)

### 4. OpenAI API Key
- Sign up at https://platform.openai.com/
- Generate an API key
- Add credits to your account

## Running the Application

### Launch
```r
# Navigate to application directory
setwd("path/to/ContactManager_Modular")

# Run the app
shiny::runApp()
```

### Initial Setup Sequence
1. **API Configuration**: Enter OpenAI API key and select model
2. **BigQuery Settings**: Configure GCP connection and authenticate
3. **SMTP Configuration**: Set up email server credentials
4. **Process Contact**: Add your first contact
5. **Explore & Communicate**: Manage and communicate with contacts

## Module Management

### Enable/Disable Modules
Edit `modules/_module_registry.yml`:
```yaml
modules:
  api_config:
    enabled: true  # Set to false to disable
    priority: 1
```

### Module Priority
Lower numbers load first. Configuration modules (1-3) load before feature modules (10-13).

## Customization

### Styling
All CSS is in `www/css/global.css`. The theme uses a blue gradient corporate color scheme:
- Deep Blue: #0a1128
- Dark Blue: #1e3c72
- Medium Blue: #2a5298
- Bright Blue: #4a90e2
- Light Blue: #7ec8e3

### Adding New Modules
1. Create directory in `modules/`
2. Add `manifest.yml`, `ui.R`, `server.R`
3. Register in `modules/_module_registry.yml`
4. Reload app - module auto-discovered

## Data Schema

### Contacts Table (`business_contacts`)
- contact_id (STRING, PK)
- full_name (STRING)
- industry (STRING)
- company (STRING)
- job_title (STRING)
- location (STRING)
- country (STRING)
- email (STRING)
- phone (STRING)
- linkedin (STRING)
- areas_of_interest (STRING)
- university (STRING)
- academic_background (STRING)
- user_notes (STRING)
- last_interaction_date (DATE)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)

### Communications Table (`contact_communications`)
- message_id (STRING, PK)
- contact_id (STRING, FK)
- channel_type (STRING)
- communication_purpose (STRING)
- language (STRING)
- message_length (STRING)
- message_content (STRING)
- created_at (TIMESTAMP)

## Security Notes
- API keys stored in memory only (session-based)
- BigQuery credentials via service account JSON
- SMTP passwords not persisted
- No client-side storage of sensitive data

## Troubleshooting

### BigQuery Connection Issues
- Verify JSON key permissions
- Ensure BigQuery API is enabled
- Check project/dataset names match

### Email Sending Fails
- Test SMTP connection first
- Verify credentials correct
- Check firewall/port 465 access
- Ensure curl is installed

### LLM Extraction Errors
- Verify API key is valid
- Check OpenAI account has credits
- Try different GPT model
- Review input text format

## License
Proprietary - Contact Manager Team

## Version
1.0.0 - Full Production Release

## Support
For issues or questions, please contact the development team.
