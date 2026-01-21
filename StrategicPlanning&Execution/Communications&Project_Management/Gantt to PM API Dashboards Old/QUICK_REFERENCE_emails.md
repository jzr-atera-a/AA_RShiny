# Quick Reference: Excel Format for Email Notifications

## Recommended Excel Column Format

| Column Name | Required | Format | Example |
|-------------|----------|--------|---------|
| **Task_Name** | ✅ Yes | Text | "Setup Development Environment" |
| **Description** | ❌ No | Text | "Configure Docker and local environment" |
| **Start_Date** | ❌ No | Date | "2025-01-15" or "01/15/2025" |
| **End_Date** | ❌ No | Date | "2025-01-20" |
| **Duration_Days** | ❌ No | Number | 5 |
| **Assignee** | ✅ For Email | Email Format | See formats below |
| **Priority** | ❌ No | Text | "High" / "Medium" / "Low" |
| **Status** | ❌ No | Text | "To Do" / "In Progress" / "Done" |
| **Labels** | ❌ No | Comma-separated | "development,setup,docker" |

## Assignee Email Formats (Choose One)

### ✅ Format 1: Name with Email in Parentheses (RECOMMENDED)
```
John Doe (john@company.com)
Jane Smith (jane@company.com)
```
**Why?** Easy to read, professional, automatically parsed by app

### ✅ Format 2: Email Only
```
john@company.com
jane@company.com
```
**Why?** Simplest format, clean

### ✅ Format 3: Standard Email Format
```
John Doe <john@company.com>
Jane Smith <jane@company.com>
```
**Why?** Standard email format, familiar

### ❌ Format to Avoid
```
John Doe
Jane Smith
```
**Why?** No email address = can't send email

## Sample Excel Data

```csv
Task_Name,Description,Start_Date,End_Date,Duration_Days,Assignee,Priority,Status,Labels
Setup Dev Environment,Configure Docker and dependencies,2025-01-15,2025-01-17,3,John Doe (john@company.com),High,To Do,"setup,docker"
API Development,Create REST endpoints,2025-01-18,2025-01-25,8,Jane Smith (jane@company.com),High,To Do,"api,backend"
Database Schema,Design database structure,2025-01-18,2025-01-22,5,John Doe (john@company.com),Medium,To Do,"database,design"
UI Mockups,Create dashboard mockups,2025-01-20,2025-01-27,8,Sarah Lee (sarah@company.com),Medium,To Do,"ui,design"
Testing Plan,Develop QA testing strategy,2025-01-28,2025-02-03,7,Mike Johnson (mike@company.com),High,To Do,"testing,qa"
```

## Quick Setup Checklist

### Before Using Email Feature
- [ ] Configure SMTP settings in Tab 1 (API Configuration)
- [ ] Test email connection
- [ ] Format assignee emails correctly in Excel
- [ ] Customize email subject and body templates
- [ ] Preview email for one assignee

### Sending Emails
- [ ] Upload Excel file with email-formatted assignees
- [ ] Review tasks in Tab 3
- [ ] Go to Tab 5 (Email Notifications)
- [ ] Choose email type (grouped or individual)
- [ ] Preview email content
- [ ] Click "Send All Emails"
- [ ] Verify results

## Common SMTP Settings

| Provider | SMTP Server | Port | Security |
|----------|-------------|------|----------|
| **Gmail** | smtp.gmail.com | 587 | STARTTLS |
| **Outlook** | smtp-mail.outlook.com | 587 | STARTTLS |
| **Office 365** | smtp.office365.com | 587 | STARTTLS |
| **Yahoo** | smtp.mail.yahoo.com | 587 | STARTTLS |

### Gmail Special Instructions
1. Enable 2-Factor Authentication
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use App Password (NOT your regular Gmail password)

## Email Options in App

### Tab 5: Email Notifications

**Grouped by Assignee (Recommended)**
- One email per person
- Contains all their tasks
- Reduces email clutter
- Best for regular updates

**Individual Task Emails**
- One email per task
- Good for urgent/high-priority tasks
- Better for tasks going to different people
- More email volume

### Customization Options
- ✅ Include/exclude dates
- ✅ Include/exclude priority
- ✅ Include/exclude descriptions
- ✅ Include/exclude labels
- ✅ Custom subject line
- ✅ Custom email header/footer

## Troubleshooting Quick Fixes

| Problem | Quick Fix |
|---------|-----------|
| Authentication failed | Use App Password for Gmail |
| Connection timeout | Check firewall, try port 587 |
| Email not received | Check spam folder |
| Invalid email format | Must include @ symbol |
| Rate limit exceeded | Send in smaller batches |

## Sample Email Output

**Subject:** Task Assignment: Please Review Your Tasks

**Body:**
```
Hello,

You have been assigned the following tasks. Please review and confirm.

=== YOUR ASSIGNED TASKS ===

Task 1: Setup Dev Environment
Description: Configure Docker and dependencies
Start Date: 2025-01-15
End Date: 2025-01-17
Priority: High
Labels: setup, docker

Task 2: Database Schema
Description: Design database structure
Start Date: 2025-01-18
End Date: 2025-01-22
Priority: Medium
Labels: database, design

Please let me know if you have any questions.

Best regards
```

## Pro Tips

💡 **Test First**: Always send test email to yourself before sending to team

💡 **Batch Send**: For large teams, send in batches to avoid rate limits

💡 **Preview**: Use preview feature to see exactly what recipients will receive

💡 **Timing**: Send emails during business hours for better response rates

💡 **Combine**: Use email + Trello/Jira for both direct notification and platform tracking

💡 **Template**: Save your email templates for consistency across projects

## Need Help?

1. Check EMAIL_GUIDE.md for detailed documentation
2. Check README.md for complete app instructions
3. Use "Test Email Connection" button to verify SMTP setup
4. Use "Preview Email" to see what will be sent
5. Start with small test batch (2-3 people)

## Quick Command to Run App

```r
# Install packages (first time only)
source("install_packages.R")

# Run app
shiny::runApp("gantt_to_tickets_app.R")
```