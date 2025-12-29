# Gantt to Tickets Converter - Modular Architecture

## Overview

A modular R Shiny application that converts Gantt chart data from Excel files into tickets for project management platforms (Trello, Jira) with email notification capabilities and contact management.

## Architecture

This application uses a **modular architecture** where each feature is implemented as a separate, independent module. This provides:

- **Easy Maintenance**: Each module is self-contained
- **Flexible Configuration**: Enable/disable modules via registry
- **Clean Separation**: UI and server logic separated
- **Scalability**: Easy to add new modules

## Features

### 1. API Configuration
- Configure Trello API credentials
- Configure Jira API credentials
- Test connections before use

### 2. Email Configuration  
- SMTP email setup (Gmail, Outlook, Custom)
- Email template customization
- Test email functionality

### 3. Upload Gantt Chart
- Upload Excel files (.xlsx, .xls)
- Preview imported data
- Download template file

### 4. Review & Edit Tasks
- Edit tasks in interactive table
- Add additional notes and labels
- Update task details

### 5. Submit to Boards
- Submit tasks to Trello boards
- Submit tasks to Jira projects
- View submission results

### 6. Send Email Notifications
- Send emails to task assignees
- Group emails by assignee
- Preview before sending

### 7. Manage Contacts
- Add individual contacts
- Upload contact lists
- Download contact database
- Delete contacts

### 8. Email Contacts
- Filter contacts by country/city/organization
- Select multiple recipients
- Personalize emails with templates
- Send bulk emails

## Installation

### Prerequisites

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "R6",
  "yaml",
  "purrr",
  "readxl",
  "writexl",
  "DT",
  "httr",
  "jsonlite",
  "dplyr",
  "lubridate",
  "blastula",
  "openssl"
))
```

### Running the Application

```r
# Set working directory to app folder
setwd("/path/to/gantt_modular")

# Run the app
shiny::runApp()
```

## Project Structure

```
gantt_modular/
├── app.R                          # Main entry point
├── global.R                       # Global configuration & UI/server factories
├── R/
│   ├── module_loader.R           # R6 class for module management
│   ├── utils_api.R               # API management (Trello, Jira, Email)
│   └── utils_common.R            # Common utility functions
├── modules/
│   ├── _module_registry.yml      # Central module registry
│   ├── api_configuration/        # Trello & Jira API setup
│   ├── email_configuration/      # SMTP email setup
│   ├── upload_gantt/             # Excel file upload
│   ├── review_edit/              # Task review & editing
│   ├── submit_boards/            # Submit to Trello/Jira
│   ├── email_send/               # Email notifications
│   ├── manage_contacts/          # Contact management
│   └── email_contacts/           # Bulk email contacts
└── www/
    └── css/
        └── global.css            # Application styling
```

### Module Structure

Each module contains:
- `manifest.yml` - Module metadata and dependencies
- `ui.R` - User interface definition
- `server.R` - Server-side logic

## Configuration

### Module Registry (`modules/_module_registry.yml`)

Enable or disable modules by changing `enabled: true/false`:

```yaml
modules:
  api_configuration:
    enabled: true
    priority: 1
    
  email_configuration:
    enabled: true
    priority: 2
    
  # ... etc
```

Priority determines loading order (lower = earlier).

### API Credentials

**Trello:**
1. Get API Key: https://trello.com/app-key
2. Generate Token: Click "Token" link on same page
3. Find Board ID: In board URL `trello.com/b/BOARD_ID/name`

**Jira:**
1. URL: Your Jira instance (e.g., `https://yourcompany.atlassian.net`)
2. Email: Your Jira account email
3. API Token: Create at https://id.atlassian.com/manage-profile/security/api-tokens
4. Project Key: Found in project settings

**Email (Gmail):**
1. SMTP Server: `smtp.gmail.com`
2. Port: `587`
3. Enable 2FA on Google account
4. Generate App Password: https://myaccount.google.com/apppasswords
5. Use App Password (not regular password)

## Usage

1. **Configure APIs** (Tab 1 & 2)
   - Set up Trello/Jira credentials
   - Configure email SMTP settings
   - Test connections

2. **Upload Data** (Tab 3)
   - Download template or upload your Excel file
   - Preview imported tasks

3. **Review Tasks** (Tab 4)
   - Edit tasks as needed
   - Add notes and labels

4. **Submit** (Tab 5)
   - Choose Trello list or Jira project
   - Submit all tasks

5. **Send Notifications** (Tab 6)
   - Preview emails
   - Send to assignees

6. **Manage Contacts** (Tab 7 & 8)
   - Add/upload contacts
   - Send bulk emails

## Excel File Format

Required columns:
- `Task_Name` - Name of task (required)
- `Description` - Task description
- `Start_Date` - Start date (YYYY-MM-DD)
- `End_Date` - End date (YYYY-MM-DD)
- `Duration_Days` - Duration in days
- `Assignee` - Person assigned (name or email)
- `Priority` - High/Medium/Low
- `Status` - To Do/In Progress/Done
- `Labels` - Comma-separated tags

## Customization

### Adding New Modules

1. Create module directory: `modules/new_module/`
2. Add `manifest.yml`, `ui.R`, `server.R`
3. Register in `modules/_module_registry.yml`
4. Follow naming convention: `{module_id}_ui()` and `{module_id}_server()`

### Modifying CSS

Edit `www/css/global.css` to customize appearance.

### API Manager

The `APIManager` R6 class (`R/utils_api.R`) manages:
- Trello API calls
- Jira API calls
- SMTP email sending
- Data storage (gantt_data, contacts_data)
- Reactive state updates across modules

## Troubleshooting

**Module not loading:**
- Check `manifest.yml` syntax
- Verify module is enabled in registry
- Ensure UI/server functions follow naming convention

**API connection fails:**
- Verify credentials are correct
- Check network/firewall settings
- Test with provided test buttons

**Email not sending:**
- Confirm SMTP settings
- Use App Password for Gmail
- Check email provider requirements

## License

This project is open source and available for modification and distribution.

## Support

For issues or questions, please refer to the documentation or contact the development team.
