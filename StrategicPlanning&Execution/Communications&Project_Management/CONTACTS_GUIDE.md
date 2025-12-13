# Contact Management Features - Quick Guide

## New Tabs Added

### Tab 7: Manage Contacts
Add and manage your contact database locally

### Tab 8: Email Contacts  
Filter and send emails to your contacts

## Tab 7: Manage Contacts

### Adding Contacts

**Input Fields:**
  - Country (e.g., USA, UK, Germany)
- City (e.g., New York, London, Berlin)
- Organization (e.g., Acme Corp, Tech Solutions Inc)
- Full Name (e.g., John Doe)
- Email (Required - e.g., john@example.com)
- Phone Number (e.g., +1-555-0123)
- LinkedIn Profile (e.g., https://linkedin.com/in/johndoe)

**Actions:**
  - Click "Add Contact" - Saves new contact to Excel file
- Click "Clear Form" - Resets all input fields

### Managing Contacts Database

**View All Contacts:**
  - Table shows all saved contacts
- Sortable and searchable
- Shows date added for each contact

**Buttons:**
  - **Refresh List** - Reload from Excel file
- **Download Excel** - Export your contacts database
- **Upload Contacts File** - Import contacts from Excel
- **Clear All** - Delete all contacts (with confirmation)

### Storage

- Contacts saved to: `contacts_database.xlsx`
- File stored in app directory
- Automatically created on first contact add
- Persists between app sessions

## Tab 8: Email Contacts

### Step 1: Filter Contacts

**Filter Options:**
  - Country - Select specific country
- City - Select specific city
- Organization - Select specific organization
- "All" option shows all contacts

Click **"Apply Filters"** to filter the contacts table

### Step 2: Select Recipients

**Contact Selection:**
  - Click on rows to select individual contacts
- Click "Select All" to select all filtered contacts
- Click "Deselect All" to clear selection
- Counter shows number of selected contacts

### Step 3: Compose Email

**Email Fields:**
  - **Subject** - Email subject line
- **Body** - Email message content

**Personalization Options:**
  - ☑ Personalize with name - Use `{NAME}` in body
- ☑ Include organization - Use `{ORG}` in body

**Example:**
  ```
Subject: Partnership Opportunity with {ORG}

Body:
  Dear {NAME},

I hope this email finds you well. I'm reaching out regarding 
a potential partnership between our organizations.

{ORG} has been identified as a leader in your industry...

Best regards
```

### Step 4: Send Emails

Click **"Send Emails to Selected Contacts"** button

**Progress:**
- Progress bar shows sending status
- Results display:
  - ✓ Successfully sent emails
  - ✗ Failed emails with error messages
- Summary notification shows success rate

## Data Format for Upload

If uploading contacts via Excel, use this format:

| Country | City | Organization | Full_Name | LinkedIn | Email | Phone | Date_Added |
|---------|------|--------------|-----------|----------|-------|-------|------------|
| USA | New York | Acme Corp | John Doe | linkedin.com/in/johndoe | john@example.com | +1-555-0123 | 2025-01-15 |
| UK | London | Tech Ltd | Jane Smith | linkedin.com/in/janesmith | jane@techltd.com | +44-20-1234 | 2025-01-15 |

**Required Columns:**
- Country
- City  
- Organization
- Full_Name
- Email

**Optional Columns:**
- LinkedIn
- Phone
- Date_Added (auto-generated if not provided)

## Use Cases

### Use Case 1: Business Development
1. Add prospects to contacts database
2. Filter by country/city for regional outreach
3. Compose personalized emails
4. Send bulk emails to selected prospects

### Use Case 2: Event Invitations
1. Upload attendee list
2. Filter by organization
3. Send event invitations with personalization
4. Track contacts in database for future events

### Use Case 3: Newsletter Distribution
1. Maintain subscriber list in contacts
2. Filter by relevant criteria
3. Send newsletter to selected audience
4. Download list for external use

### Use Case 4: Follow-up Campaigns
1. Import contacts from previous event
2. Filter by specific criteria
3. Send targeted follow-up emails
4. Keep contact history for future reference

## Email Configuration

**Important:** Before using Email Contacts feature:
1. Go to "Email Configuration" tab (Tab 2)
2. Enter your SMTP settings
3. Click "Test Email Connection"
4. Verify test email received

**Uses Same Credentials:**
- Email Contacts uses the same SMTP configuration
- One-time setup for all email features
- No need to re-enter credentials

## Tips & Best Practices

### Contact Management
✅ **DO:**
- Add contacts immediately after meetings
- Keep organization names consistent
- Include LinkedIn for networking
- Update contacts regularly

❌ **DON'T:**
  - Forget to include email addresses
- Use inconsistent country/city names
- Skip phone numbers if available

### Email Campaigns
✅ **DO:**
  - Test with yourself first
- Use personalization tags
- Filter before selecting
- Review selected count
- Check results after sending

❌ **DON'T:**
- Send to all contacts without filtering
- Forget to personalize subject/body
- Skip preview before sending
- Send during off-hours

### Data Management
✅ **DO:**
- Download backup regularly
- Remove duplicate emails
- Keep database organized
- Use clear organization names

❌ **DON'T:**
  - Delete all without backup
- Let duplicates accumulate
- Use vague organization names

## Troubleshooting

### "Email Configuration Not Set"
**Problem:** Trying to send without SMTP config
**Solution:** 
  1. Go to "Email Configuration" tab
2. Enter SMTP settings
3. Test connection
4. Return to Email Contacts tab

### "No Contacts Selected"
**Problem:** Clicking send without selecting contacts
**Solution:**
  1. Click on contact rows in table
2. Or use "Select All" button
3. Verify counter shows selection
4. Then click send

### "Invalid Email Format"
**Problem:** Email field doesn't contain @
**Solution:**
1. Ensure email has format: name@domain.com
2. Check for typos
3. Remove any spaces

### "Duplicate Emails"
**Problem:** Same contact added multiple times
**Solution:**
1. Upload feature automatically removes duplicates
2. Or manually check database table
3. Delete duplicates before exporting

### Filters Not Working
**Problem:** Filter dropdowns empty
**Solution:**
1. Ensure contacts database has data
2. Click "Refresh List"
3. Check that Country/City/Org fields are filled
4. Apply filters again

## Advanced Features

### Batch Import
```r
# Create contacts Excel file
contacts <- data.frame(
  Country = c("USA", "UK", "Germany"),
  City = c("New York", "London", "Berlin"),
  Organization = c("Acme Corp", "Tech Ltd", "Innovation GmbH"),
  Full_Name = c("John Doe", "Jane Smith", "Hans Mueller"),
  Email = c("john@acme.com", "jane@tech.com", "hans@innovation.de"),
  LinkedIn = c("linkedin.com/in/johndoe", "linkedin.com/in/janesmith", "linkedin.com/in/hansm"),
  Phone = c("+1-555-0123", "+44-20-1234", "+49-30-5678"),
  Date_Added = rep(Sys.Date(), 3)
)

writexl::write_xlsx(contacts, "my_contacts.xlsx")
# Then upload via "Upload Contacts File" button
```

### Personalization Examples

**Example 1: Name Only**
```
Subject: Hello {NAME}

Body:
Dear {NAME},

I wanted to reach out personally...
```

**Example 2: Organization Only**
```
Subject: Partnership with {ORG}

Body:
Hello,

I've been following {ORG}'s work and...
```

**Example 3: Both**
```
Subject: {NAME} - Collaboration Opportunity

Body:
Hi {NAME},

I'm impressed with {ORG}'s recent achievements...
```

## Integration with Task Management

**Combined Workflow:**
1. **Gantt Tab** - Plan project tasks
2. **Contacts Tab** - Add stakeholders
3. **Email Contacts** - Send project updates
4. **Submit to Boards** - Track in Trello/Jira
5. **Email Notifications** - Notify team members

**Example:**
1. Create project plan in Excel
2. Upload to Gantt tab
3. Submit tasks to Trello
4. Add external stakeholders to Contacts
5. Email them project overview from Email Contacts
6. Email internal team from Email Notifications

## FAQ

**Q: Where are contacts stored?**
A: In `contacts_database.xlsx` in the app directory

**Q: Can I edit contacts after adding?**
A: Yes, download Excel, edit, and re-upload (duplicates auto-removed)

**Q: What's the maximum number of contacts?**
  A: Limited only by Excel file size (65,536 rows max)

**Q: Can I send attachments?**
  A: Not currently, but you can include links in email body

**Q: Do contacts sync with Trello/Jira?**
  A: No, contacts are separate - use for external stakeholders

**Q: Can I export to CSV?**
  A: Download as Excel, then open and save as CSV

**Q: Rate limits for email sending?**
  A: Depends on SMTP provider:
  - Gmail: ~500/day
- Outlook: ~300/day

**Q: Can I schedule emails?**
  A: Not built-in, but you can use R's task scheduler

## Example Session

```r
# 1. Run app
shiny::runApp("gantt_to_tickets_app.R")

# 2. Add contacts
# Tab 7: Manage Contacts
# - Enter: Country, City, Org, Name, Email
# - Click "Add Contact"
# - Repeat for all contacts

# 3. Send campaign
# Tab 8: Email Contacts
# - Filter by Country: "USA"
# - Click "Apply Filters"
# - Click "Select All"
# - Subject: "Q1 Newsletter"
# - Body: "Dear {NAME},\n\nWelcome to our Q1 update..."
# - Click "Send Emails"
# - Check results

# 4. Download backup
# Tab 7: Click "Download Excel"
```

## Quick Reference

### Tab 7 Workflow
```
Add Contact → Fill Fields → Click "Add Contact" → Saved!
```

### Tab 8 Workflow
```
Filter → Select → Compose → Send → Review Results
```

### Personalization Tags
```
{NAME} = Full_Name from database
{ORG}  = Organization from database
```

## Support

For issues:
1. Check Email Configuration is set
2. Verify contacts have valid emails
3. Test with single contact first
4. Check SMTP rate limits
5. Review error messages in results

Happy networking! 📧📇