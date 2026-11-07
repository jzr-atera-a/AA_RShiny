# Titan Events (R Shiny)

Create calendar events, with reminders, and save them straight into your Titan Mail
calendar. The app talks to Titan's CalDAV server, so you don't need to open the Titan
app or the Titan calendar website.

## Set up

```r
install.packages(c("shiny", "bslib", "DT", "httr2", "xml2", "uuid"))
shiny::runApp("titan-events")   # the folder containing app.R and caldav.R
```

Optional: put your login in `~/.Renviron` so it's prefilled (restart R afterwards):

```
TITAN_EMAIL=you@yourdomain.com
TITAN_PASSWORD=your-titan-password
```

## Use

1. **Connect** (left panel): leave the server on **Auto-detect**, enter the full email
   address and the *mailbox* password (the one used for webmail and the Titan app, not the
   GoDaddy account password), and select **Connect**. Pick the calendar to save to.
   - Accounts bought through GoDaddy ("Professional Email powered by Titan", SMTP host
     `smtpout.secureserver.net`) use `dav.myprofessionalmail.com`, which Auto-detect tries first.
   - Direct Titan accounts use `dav.titan.email` (or `dav-eu.titan.email` in the EU).
   - If it still fails, the **Log** tab lists every address tried and what the server
     answered. If calendars are found nowhere, paste the calendar's CalDAV URL under
     "Calendar URL manually".
2. **New events**: fill in the form and choose **Save to Titan now**, or **Add to list**
   several events and then **Save all to Titan**. **Download .ics** exports the list.
3. **Import .ics file**: upload any .ics file; every event in it is saved to Titan,
   reminders included.
4. **Upcoming events**: check what's in the calendar and delete events.
5. **Log**: the result of every save.

## Notes

- Times are entered in the chosen time zone (default Europe/London) and stored in UTC,
  so British Summer Time is handled automatically.
- Each reminder is saved as a `VALARM`. Check one event in the Titan app the first time
  to confirm Titan shows it under "Notify me".
- Saving never overwrites an existing event unless you tick "Replace events that already
  exist" on the import tab.
- Your password is only held in memory while the app runs. Run the app on your own
  machine; don't deploy it to a shared server with a password in `.Renviron`.
