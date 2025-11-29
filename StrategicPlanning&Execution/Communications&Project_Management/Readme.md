# Gantt Chart to Trello/Jira Converter

An R Shiny application that converts Excel-based Gantt charts into Trello cards or Jira issues.

## Features

- **API Authentication**: Securely connect to both Trello and Jira APIs
- **Email Integration**: Send task notifications directly to assignees via email (reduces unnecessary platform notifications)
- **Excel Import**: Upload Gantt charts from Excel with flexible formatting
- **Interactive Editing**: Review and modify tasks before submission
- **Multi-Platform Support**: Submit to Trello, Jira, or send via email
- **Batch Processing**: Create multiple tickets or send multiple emails at once
- **Progress Tracking**: Real-time feedback during submission
- **Customizable Email Templates**: Personalize email notifications with dynamic content

## Installation

### Prerequisites

Install R (version 4.0 or higher) from [CRAN](https://cran.r-project.org/)

### Required R Packages

Run the following command in R to install all dependencies:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "readxl",
  "writexl",
  "DT",
  "httr",
  "jsonlite",
  "dplyr",
  "lubridate",
  "openssl",
  "blastula",
  "glue"
))
```

## Running the App

1. Save the `gantt_to_tickets_app.R` file
2. Open R or RStudio
3. Run:

```r
shiny::runApp("gantt_to_tickets_app.R")
```

The app will open in your default web browser.

## Usage Guide

### Tab 1: API Configuration

#### Trello Setup
1. **Get API Key**: Visit https://trello.com/app-key
2. **Get Token**: Click the "Token" link on the same page and authorize
3. **Get Board ID**: 
   - Open your Trello board
   - Look at the URL: `https://trello.com/b/BOARD_ID/board-name`
   - Copy the `BOARD_ID` portion
4. Click "Test Connection" to verify

#### Jira Setup
1. **Jira URL**: Your Jira instance (e.g., `https://yourcompany.atlassian.net`)
2. **Email**: Your Jira account email
3. **API Token**: 
   - Go to https://id.atlassian.com/manage-profile/security/api-tokens
   - Click "Create API token"
   - Copy the token
4. **Project Key**: Find this in your Jira project settings (e.g., "PROJ", "DEV")
5. Click "Test Connection" to verify

### Tab 2: Email Configuration

**Why use email instead of Trello/Jira notifications?**
- Reduces notification fatigue from multiple platforms
- Allows non-platform users to receive task assignments
- Centralizes communication in email inbox
- Provides a paper trail without requiring platform access

#### Email Setup

**For Gmail:**
1. **SMTP Server**: `smtp.gmail.com`
2. **Port**: `587` (TLS) or `465` (SSL)
3. **Enable 2-Factor Authentication** on your Google account
4. **Generate App Password**:
   - Go to https://myaccount.google.com/apppasswords
   - Select "Mail" and your device
   - Copy the 16-character password
5. **Use the App Password** (not your regular Gmail password)
6. Click "Test Email Connection"

**For Outlook/Office 365:**
1. **SMTP Server**: `smtp-mail.outlook.com` or `smtp.office365.com`
2. **Port**: `587`
3. **Username**: Your full Outlook email address
4. **Password**: Your Outlook password (or app-specific password if using 2FA)
5. Click "Test Email Connection"

**Custom SMTP:**
- Contact your email provider for SMTP settings
- Common ports: 25, 465 (SSL), 587 (TLS), 2525

#### Email Template Customization

Customize the email subject and body templates using placeholders:
- `{Task_Name}` - Task title
- `{Description}` - Task description
- `{Assignee}` - Person assigned
- `{Start_Date}` - Start date
- `{End_Date}` - End date
- `{Priority}` - Task priority
- `{Status}` - Task status
- `{Labels}` - Task labels

**Example Subject:** `New Task Assignment: {Task_Name}`

**Example Body:**
```
Hello {Assignee},

You have been assigned a new task:

Task: {Task_Name}
Description: {Description}
Start Date: {Start_Date}
End Date: {End_Date}
Priority: {Priority}

Please review and confirm.

Best regards
```

### Tab 3: Upload Gantt Chart

#### Excel Format

Your Excel file should include these columns (see template for example):

| Column | Required | Description | Example |
|--------|----------|-------------|---------|
| Task_Name | Yes | Name of the task | "Development Sprint 1" |
| Description | No | Detailed description | "Implement core features" |
| Start_Date | No | Start date | "2025-01-15" or "01/15/2025" |
| End_Date | No | End date | "2025-02-15" |
| Duration_Days | No | Duration in days | 30 |
| Assignee | No | Person assigned (use email format for email notifications) | "John Doe <john@example.com>" or "john@example.com" |
| Priority | No | Task priority | "High", "Medium", "Low" |
| Status | No | Current status | "To Do", "In Progress", "Done" |
| Labels | No | Comma-separated tags | "development,sprint,backend" |

**Note for Email Notifications:** Format assignees as either:
- `john@example.com` (email only)
- `John Doe <john@example.com>` (name and email)

**Download the template** from the app to see the exact format.

### Tab 4: Review & Edit Tasks

1. View all uploaded tasks in an editable table
2. Click any cell to edit directly
3. Select individual tasks to add:
   - Additional notes
   - Extra labels
4. Click "Update Task" to save changes

### Tab 5: Submit to Boards

#### Trello Submission
1. Click "Load Lists from Board" to fetch available lists
2. Select the target list (e.g., "To Do", "Backlog")
3. Click "Submit to Trello"
4. Monitor progress and results

Each task becomes a Trello card with:
- Title = Task_Name
- Description includes all task details
- Labels (if provided)

#### Jira Submission
1. Select Issue Type (Task, Story, Bug, Epic)
2. Click "Submit to Jira"
3. Monitor progress and results

Each task becomes a Jira issue with:
- Summary = Task_Name
- Description includes all task details
- Priority (if provided)
- Labels (if provided)
- Issue type of your choice

### Tab 6: Send Email Notifications

**Benefits of email notifications:**
- Reduces platform notification spam
- Allows non-platform users to receive assignments
- Creates email record of task assignments
- More personal and direct communication

#### Sending Emails

1. **Preview emails**: Review who will receive notifications
2. **Email options**:
   - **Group by assignee**: Send one email per person with all their tasks (recommended)
   - **One email per task**: Send individual emails for each task
   - **CC recipients**: Add managers or stakeholders to be copied
3. **Test first**: Click "Send Test Email to Myself" to preview
4. **Send all**: Click "Send All Emails" to deliver notifications

**Email Format Examples:**

*Grouped by assignee:*
```
To: john@example.com
Subject: New Task Assignments

Hello John Doe,

You have been assigned 3 task(s):

--- Task 1 ---
Task: Development Sprint 1
Description: Core features
Start Date: 2025-01-15
...

--- Task 2 ---
...
```

*Individual emails:*
```
To: john@example.com
Subject: New Task Assignment: Development Sprint 1

Hello John Doe,

Task: Development Sprint 1
Description: Core features
Start Date: 2025-01-15
...
```

## Excel Template Example

```
Task_Name              | Description                    | Start_Date  | End_Date    | Duration_Days | Assignee    | Priority | Status  | Labels
-----------------------|--------------------------------|-------------|-------------|---------------|-------------|----------|---------|-------------------
Project Setup          | Initial configuration          | 2025-01-15  | 2025-01-19  | 5             | John Doe    | High     | To Do   | setup,planning
Research Phase         | Market research                | 2025-01-20  | 2025-01-31  | 12            | Jane Smith  | High     | To Do   | research
Development Sprint 1   | Core feature development       | 2025-02-01  | 2025-02-19  | 19            | Dev Team    | Medium   | To Do   | development,sprint
Testing                | QA testing and bug fixes       | 2025-02-20  | 2025-02-28  | 9             | QA Team     | High     | To Do   | testing,qa
Deployment             | Production deployment          | 2025-03-01  | 2025-03-05  | 5             | DevOps      | High     | To Do   | deployment
```

## Troubleshooting

### Connection Issues

**Trello:**
- Verify API key and token are correct
- Ensure token has not expired
- Check board ID is valid

**Jira:**
- Verify URL format (include https://)
- Ensure API token is valid
- Check project key exists
- Verify you have permission to create issues

**Email:**
- **Gmail "Less secure app" error**: Use App Password, not regular password
- **Authentication failed**: Double-check username and password
- **Connection timeout**: Verify SMTP server and port
- **SSL/TLS errors**: Try toggling the SSL checkbox
- **Emails not received**: Check spam/junk folders
- **"Invalid email address"**: Format assignees as `name@domain.com` or `Name <name@domain.com>`

### Upload Issues

- Ensure Excel file has correct column names (use template)
- Check date formats are consistent
- Verify file is .xlsx or .xls format

### Submission Issues

- **"403 Forbidden"**: Check API permissions
- **"404 Not Found"**: Verify board/project IDs
- **Rate Limit**: Wait a few minutes between large submissions

## Tips

1. **Test with small batches**: Upload 2-3 tasks first to verify everything works
2. **Use the template**: Download and modify the provided template to ensure proper formatting
3. **Save your credentials**: The app doesn't save credentials between sessions for security
4. **Choose your notification method**: Use email for external stakeholders, Trello/Jira for team members actively using those platforms
5. **Email format for assignees**: Use `Name <email@domain.com>` format for clearer email notifications
6. **Group emails by assignee**: Enable this option to reduce email clutter
7. **Test emails first**: Always send a test email to yourself before bulk sending
8. **Review before submitting**: Use Tab 4 to verify all data looks correct

## Security Notes

- API credentials are stored in memory only during the session
- Credentials are not saved to disk
- Always keep your API tokens secure
- Use environment variables for automated deployments

## Limitations

- Maximum 1000 tasks per upload recommended (API rate limits)
- Trello: Cannot assign users automatically (must do manually in Trello)
- Jira: Some custom fields may not be supported
- Date formats must be consistent within the Excel file

## Support

For issues with:
- **Trello API**: https://developer.atlassian.com/cloud/trello/
- **Jira API**: https://developer.atlassian.com/cloud/jira/platform/

## License

MIT License - Feel free to modify and use for your projects!