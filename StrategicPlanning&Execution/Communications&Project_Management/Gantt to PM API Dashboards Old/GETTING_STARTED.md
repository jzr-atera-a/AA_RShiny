# Getting Started - Gantt to Tickets Converter with Email

## 🎯 What This App Does

Converts Excel-based Gantt charts into:
1. **Trello cards** - Visual project boards
2. **Jira issues** - Agile project tracking
3. **📧 Email notifications** - Direct task assignments to team members' inboxes

**Why Email?** Reduces platform notification fatigue and allows anyone with email to receive assignments, even without Trello/Jira accounts.

## 📦 Files Included

| File | Purpose |
|------|---------|
| `gantt_to_tickets_app.R` | Main Shiny application |
| `install_packages.R` | One-click package installer |
| `create_template.R` | Generate sample Excel templates |
| `README.md` | Complete documentation |
| `QUICK_REFERENCE.md` | Quick setup guide |
| `EMAIL_SETUP_GUIDE.md` | Email configuration help |
| `DECISION_GUIDE.md` | When to use email vs platforms |

## 🚀 Quick Start (5 Minutes)

### Step 1: Install R Packages (One Time Only)
```r
# Run this once
source("install_packages.R")
```

### Step 2: Create Sample Template
```r
# Generate example Excel file
source("create_template.R")
```
This creates `gantt_template_with_emails_[DATE].xlsx`

### Step 3: Run the App
```r
# Start the application
shiny::runApp("gantt_to_tickets_app.R")
```

### Step 4: Configure (First Time)
1. **Tab 1**: Enter your SMTP email settings (see below)
2. Test email connection
3. (Optional) Enter Trello/Jira credentials

### Step 5: Upload & Send
1. **Tab 2**: Upload your Excel file
2. **Tab 3**: Review and edit tasks
3. **Tab 5**: Send email notifications!

## 📧 Email Setup (Most Important!)

### For Gmail Users (Recommended for Testing)
```
SMTP Server: smtp.gmail.com
Port: 587
Security: STARTTLS
Username: your-email@gmail.com
Password: [App Password - NOT your regular password]
```

**Get Gmail App Password:**
1. Go to: https://myaccount.google.com/apppasswords
2. Enable 2-Factor Authentication first if not enabled
3. Generate an "App Password" for "Mail"
4. Copy the 16-character password
5. Use THIS password in the app (not your Gmail password)

### For Outlook Users
```
SMTP Server: smtp-mail.outlook.com
Port: 587
Security: STARTTLS
Username: your-email@outlook.com
Password: Your Outlook password
```

### Test Your Setup
Click "Send Test Email" in Tab 1 to verify your configuration works!

## 📊 Excel Format Requirements

### Minimum Required Columns
- `Task_Name` - What the task is called
- `Assignee` - **MUST include email in one of these formats:**
  - `John Doe (john@company.com)` ✅ Recommended
  - `john@company.com` ✅ Works
  - `John Doe <john@company.com>` ✅ Works
  - `John Doe` ❌ Won't work (no email)

### Optional But Recommended Columns
- `Description` - Task details
- `Start_Date` - When task begins
- `End_Date` - When task should complete
- `Priority` - High/Medium/Low
- `Status` - To Do/In Progress/Done
- `Labels` - Comma-separated tags

### Example Excel Data
```
Task_Name              | Assignee                        | Priority | Start_Date  | End_Date
-----------------------|---------------------------------|----------|-------------|-------------
Setup Dev Environment  | John Doe (john@company.com)    | High     | 2025-01-15  | 2025-01-20
API Development        | Jane Smith (jane@company.com)  | High     | 2025-01-21  | 2025-02-05
UI Design              | designer@company.com            | Medium   | 2025-01-18  | 2025-01-30
```

## 🎛️ App Tabs Overview

### Tab 1: API Configuration
- **Email (SMTP)**: Configure email settings ⭐ Start here!
- **Trello**: Optional - for creating Trello cards
- **Jira**: Optional - for creating Jira issues

### Tab 2: Upload Gantt Chart
- Upload your Excel file
- Preview the data
- Download template if needed

### Tab 3: Review & Edit Tasks
- View all tasks in editable table
- Make changes before sending
- Add additional notes or labels

### Tab 4: Submit to Boards
- Create Trello cards
- Create Jira issues
- Monitor progress

### Tab 5: Email Notifications ⭐
- **Preview emails** before sending
- **Group by assignee** - One email per person with all their tasks
- **Individual emails** - Separate email for each task
- **Customize** subject, header, footer
- **Send** to all assignees at once

## 🔄 Typical Workflow

### Option A: Email Only (Simplest)
1. Configure email settings (Tab 1)
2. Upload Excel with email-formatted assignees (Tab 2)
3. Review tasks (Tab 3)
4. Send email notifications (Tab 5)
✅ Done! Team gets emails with assignments

### Option B: Email + Trello/Jira
1. Configure email + Trello/Jira settings (Tab 1)
2. Upload Excel file (Tab 2)
3. Review tasks (Tab 3)
4. Submit to Trello/Jira (Tab 4) - Creates tickets
5. Send email notifications (Tab 5) - Notifies team
✅ Done! Tasks tracked in platform + team gets emails

### Option C: Platform Only (No Email)
1. Configure Trello/Jira settings (Tab 1)
2. Upload Excel file (Tab 2)
3. Review tasks (Tab 3)
4. Submit to platform (Tab 4)
✅ Done! Rely on platform notifications

## 💡 Pro Tips

### Email Best Practices
✅ **DO:**
- Test with yourself first
- Use grouped emails (one per person)
- Send during business hours
- Preview before sending all
- Include clear subject lines

❌ **DON'T:**
- Send hundreds of emails at once (rate limits!)
- Use your regular Gmail password (use App Password!)
- Forget to test connection first
- Skip the preview step

### Excel Best Practices
✅ **DO:**
- Use the provided template as starting point
- Format emails correctly: `Name (email@domain.com)`
- Include all relevant details
- Keep task names concise

❌ **DON'T:**
- Leave Assignee empty if using email feature
- Use spaces in column names (use underscores)
- Mix date formats in same column

### Platform Integration
✅ **DO:**
- Use email for initial assignments
- Use platforms for ongoing discussion
- Combine both for maximum visibility

❌ **DON'T:**
- Rely solely on platform notifications (people miss them)
- Send duplicate notifications from multiple sources

## 🆘 Troubleshooting

### "Authentication Failed"
**Problem:** Email settings incorrect
**Solution:** 
1. For Gmail: Use App Password, not regular password
2. Verify SMTP server and port
3. Check username is full email address

### "No Email Address Found"
**Problem:** Assignee column doesn't have email format
**Solution:** 
1. Update Excel: `John Doe (john@email.com)`
2. Or just: `john@email.com`

### "Connection Timeout"
**Problem:** Network/firewall blocking SMTP
**Solution:**
1. Try port 587 (or 465 for SSL)
2. Check firewall settings
3. Contact IT if using corporate network

### "Rate Limit Exceeded"
**Problem:** Too many emails sent too quickly
**Solution:**
1. Send in smaller batches
2. Gmail limit: ~500/day
3. Outlook limit: ~300/day

## 📚 Additional Resources

- **README.md** - Complete detailed documentation
- **QUICK_REFERENCE.md** - Excel format quick guide
- **EMAIL_SETUP_GUIDE.md** - Detailed email configuration
- **DECISION_GUIDE.md** - Email vs platform notifications

## 🎬 Example Session

```r
# 1. Install (first time only)
source("install_packages.R")

# 2. Generate sample data
source("create_template.R")
# Creates: gantt_template_with_emails_2025-11-11.xlsx

# 3. Run app
shiny::runApp("gantt_to_tickets_app.R")

# 4. In the app:
#    - Tab 1: Enter Gmail settings + App Password
#    - Tab 1: Click "Send Test Email"
#    - Tab 2: Upload gantt_template_with_emails_2025-11-11.xlsx
#    - Tab 3: Review the 12 sample tasks
#    - Tab 5: Preview email for one assignee
#    - Tab 5: Click "Send All Emails"
#    - Tab 5: Check results - should see ✓ for each email

# 5. Check your inbox and team members' inboxes!
```

## ✨ Key Features

### Why This App Is Useful

**Problem:** 
- Creating dozens of Trello/Jira tickets manually takes hours
- Team members miss platform notifications
- External stakeholders can't access Trello/Jira
- Planning in Excel but tracking elsewhere is disconnected

**Solution:**
- ✅ Convert entire Gantt chart to tickets in seconds
- ✅ Send direct email notifications to everyone
- ✅ Include people without platform accounts
- ✅ Reduce notification fatigue
- ✅ Keep planning and execution connected

### Email vs Platform Notifications

**Use Email When:**
- Initial task assignments
- High-priority tasks needing attention
- External stakeholders involved
- Team members don't check platform daily
- You want paper trail in email

**Use Platform Notifications When:**
- Day-to-day updates
- Team discussions
- Status changes
- Internal collaboration only

**Use Both When:**
- You want maximum visibility
- Important project milestones
- Mix of internal and external people

## 🎯 Next Steps

1. ✅ Install packages (`install_packages.R`)
2. ✅ Generate sample template (`create_template.R`)
3. ✅ Run app (`shiny::runApp("gantt_to_tickets_app.R")`)
4. ✅ Configure email settings (Tab 1)
5. ✅ Test with sample data
6. ✅ Customize for your project
7. ✅ Send to your team!

## 🤝 Support

If you get stuck:
1. Check QUICK_REFERENCE.md for formatting help
2. Check EMAIL_SETUP_GUIDE.md for email issues
3. Use "Test Email Connection" button
4. Use "Preview Email" before sending
5. Start with 2-3 people as test

## 🎉 Ready to Go!

You now have everything you need to:
- Convert your Gantt chart to actionable tickets
- Send professional email notifications
- Integrate with Trello/Jira if desired
- Keep your team informed and organized

**Start with email notifications - it's the easiest and most universal option!**

Happy project managing! 🚀
