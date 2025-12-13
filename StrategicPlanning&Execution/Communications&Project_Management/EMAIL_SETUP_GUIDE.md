# Quick Email Setup Guide

## Why Email Notifications?

Instead of creating tickets in Trello or Jira (which generates platform notifications that people might ignore), you can send direct email notifications to task assignees. This is especially useful for:

- **External stakeholders** who don't have Trello/Jira access
- **Reducing notification fatigue** from multiple platforms
- **Important assignments** that need direct attention
- **Creating email trails** for accountability
- **Teams that prefer email** over project management platforms

## Quick Setup (Gmail)

1. **Enable 2-Factor Authentication** on your Google account
   - Go to: https://myaccount.google.com/security

2. **Generate App Password**
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and your device
   - Copy the 16-character password (format: xxxx xxxx xxxx xxxx)

3. **Configure in the App**
   - Tab 2: Email Configuration
   - Email Provider: Gmail
   - SMTP Server: smtp.gmail.com (auto-filled)
   - Port: 587 (auto-filled)
   - Email Address: your.email@gmail.com
   - Password: [paste the 16-character app password]
   - SSL/TLS: Checked
   - Click "Test Email Connection"

4. **You should receive a test email!**

## Quick Setup (Outlook/Office 365)

1. **Configure in the App**
   - Tab 2: Email Configuration
   - Email Provider: Outlook/Office365
   - SMTP Server: smtp-mail.outlook.com (auto-filled)
   - Port: 587 (auto-filled)
   - Email Address: your.email@outlook.com
   - Password: Your Outlook password
   - SSL/TLS: Checked
   - Click "Test Email Connection"

2. **If using 2FA**, you may need an app-specific password:
   - Go to: https://account.live.com/proofs/manage
   - Create app password for "Mail"

## Formatting Assignees for Email

In your Excel file, format the "Assignee" column properly:

**Option 1: Email only**
```
john@example.com
```

**Option 2: Name and Email (Recommended)**
```
John Doe <john@example.com>
```

**Example Excel:**
```
Task_Name           | Assignee
--------------------|---------------------------
Setup Database      | John Smith <john@example.com>
Design UI           | sarah@example.com
Write Tests         | Mike Jones <mike@example.com>
```

## Sending Emails

### Tab 6: Send Email Notifications

1. **Preview who will receive emails**
   - The app shows all tasks with assignees
   - Displays summary of emails to send

2. **Choose email mode:**
   - ✅ **Group by assignee** (Recommended): One email per person with all their tasks
   - ⬜ **Individual**: One email per task (can be overwhelming)

3. **Add CC recipients** (optional):
   ```
   manager@example.com, pm@example.com
   ```

4. **Test first:**
   - Click "Send Test Email to Myself"
   - Check your inbox to see how it looks

5. **Send all emails:**
   - Click "Send All Emails"
   - Monitor progress bar
   - Review results

## Email Template Customization

### Default Template

**Subject:**
```
New Task Assignment: {Task_Name}
```

**Body:**
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

### Available Placeholders

- `{Task_Name}` - Task title
- `{Description}` - Task description
- `{Assignee}` - Person assigned
- `{Start_Date}` - Start date
- `{End_Date}` - End date
- `{Duration_Days}` - Duration in days
- `{Priority}` - Priority level
- `{Status}` - Task status
- `{Labels}` - Task labels

### Custom Template Examples

**Professional Style:**
```
Subject: Action Required: {Task_Name}

Dear {Assignee},

This is to inform you that you have been assigned the following task:

PROJECT TASK DETAILS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Task Name: {Task_Name}
Description: {Description}
Timeline: {Start_Date} to {End_Date}
Priority Level: {Priority}
Labels: {Labels}

Please acknowledge receipt and confirm your availability to complete this task by the specified deadline.

Should you have any questions or concerns, please reach out immediately.

Best regards,
Project Management Team
```

**Casual Style:**
```
Subject: New task for you: {Task_Name}

Hey {Assignee}! 👋

You've got a new task:

📋 {Task_Name}
📝 {Description}
📅 Due: {End_Date}
⭐ Priority: {Priority}

Let me know if you have any questions!

Thanks!
```

## Email Results

When emails are sent, you'll see results like:

**Grouped by assignee:**
```
✓ Sent to John Smith <john@example.com> - 3 tasks
✓ Sent to Sarah Lee <sarah@example.com> - 2 tasks
✓ Sent to Mike Jones <mike@example.com> - 1 task
```

**Individual emails:**
```
✓ Setup Database -> John Smith
✓ Design UI -> Sarah Lee
✓ Write Tests -> Mike Jones
```

## Common Issues & Solutions

### "Authentication failed"
- ❌ Using regular Gmail password
- ✅ Use App Password from https://myaccount.google.com/apppasswords

### "Connection timeout"
- Check SMTP server and port
- Verify internet connection
- Try different port (465 for SSL, 587 for TLS)

### "Invalid email address"
- Format: `john@example.com` or `John <john@example.com>`
- Remove extra spaces
- Ensure @ and domain present

### "Emails not received"
- Check spam/junk folders
- Verify assignee emails are correct
- Send test email to yourself first

### "SSL/TLS error"
- Try toggling the "Use SSL/TLS" checkbox
- Gmail: usually Port 587 with SSL
- Outlook: Port 587 with SSL

## Best Practices

1. ✅ **Always test first** - Send test email before bulk sending
2. ✅ **Group by assignee** - Reduce email clutter
3. ✅ **Use name+email format** - `John <john@example.com>` is clearer
4. ✅ **Add context to templates** - Include project name or context
5. ✅ **CC relevant people** - Keep managers/PMs in the loop
6. ✅ **Start with small batches** - Test with 2-3 emails first
7. ❌ **Don't send duplicates** - Check if tasks already sent
8. ❌ **Don't spam** - Use "group by assignee" for multiple tasks

## Workflow Examples

### Example 1: Sprint Planning
```
1. Upload sprint tasks Excel file
2. Review tasks in Tab 4
3. Configure Gmail in Tab 2
4. Customize template: "Sprint {Labels} - New Assignment: {Task_Name}"
5. Send grouped emails to all team members
6. Also submit to Jira for tracking
```

### Example 2: External Contractors
```
1. Upload project tasks
2. Filter tasks for external people (who don't have Jira access)
3. Send emails to contractors
4. Submit internal tasks to Jira for team
```

### Example 3: Quarterly Planning
```
1. Upload Q1 goals and tasks
2. Customize formal email template
3. CC senior management
4. Send grouped emails by department lead
5. Archive email confirmations
```

## Security Notes

- ✅ App passwords are safer than regular passwords
- ✅ Credentials stored in memory only (not saved to disk)
- ✅ Use TLS/SSL for encrypted email transmission
- ❌ Never share your app password
- ❌ Don't use regular password for Gmail

## Need Help?

**Gmail Issues:**
- https://support.google.com/mail/answer/7126229 (App Passwords)
- https://support.google.com/accounts/answer/185833 (2FA)

**Outlook Issues:**
- https://support.microsoft.com/en-us/account-billing/

**SMTP Settings:**
- Contact your email provider's support

---

**Pro Tip:** Create different email templates for different types of tasks (urgent, routine, review, etc.) and save them in a text file for easy copy-paste!
