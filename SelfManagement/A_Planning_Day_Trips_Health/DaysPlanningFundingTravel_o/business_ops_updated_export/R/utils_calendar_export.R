# R/utils_calendar_export.R
# Shared Calendar Export Utility for All Modules
# Generates RFC 5545 iCalendar (.ics) format files for import into Outlook, Google Calendar, Apple Calendar, etc.

# ==================
# MAIN EXPORT FUNCTION
# ==================

generate_calendar_ics <- function(
  title,                    # Event/item title
  items = NULL,             # Data frame with date/time columns
  date_col = "date",        # Column name for date
  time_col = NULL,          # Column name for time (optional)
  duration_minutes = 60,    # Default event duration
  description = "",         # Event description
  location = "",            # Location (optional)
  item_col = "name"         # Column containing item names
) {
  
  # ==================
  # HELPER: Convert 12-hour to 24-hour format
  # ==================
  convert_to_24hr <- function(time_str) {
    time_str <- trimws(time_str)
    if (is.na(time_str) || time_str == "") return("090000")
    
    is_pm <- grepl("PM|pm", time_str)
    time_clean <- gsub("[APap][Mm]", "", time_str)
    parts <- strsplit(time_clean, ":")[[1]]
    
    if (length(parts) >= 2) {
      hour <- as.numeric(parts[1])
      min <- as.numeric(parts[2])
      
      if (is_pm && hour != 12) {
        hour <- hour + 12
      } else if (!is_pm && hour == 12) {
        hour <- 0
      }
      
      return(sprintf("%02d%02d", hour, min))
    }
    return("090000")
  }
  
  # ==================
  # HELPER: Add minutes to time
  # ==================
  add_minutes_to_time <- function(time_str, minutes) {
    hour <- as.numeric(substr(time_str, 1, 2))
    min <- as.numeric(substr(time_str, 3, 4))
    
    total_min <- hour * 60 + min + minutes
    new_hour <- (total_min %/% 60) %% 24
    new_min <- total_min %% 60
    
    sprintf("%02d%02d", new_hour, new_min)
  }
  
  # ==================
  # HELPER: Escape special characters for iCalendar
  # ==================
  escape_ical <- function(text) {
    text <- as.character(text)
    text <- gsub("\\\\", "\\\\\\\\", text)
    text <- gsub("\n", "\\\\n", text)
    text <- gsub(",", "\\\\,", text)
    text <- gsub(";", "\\\\;", text)
    return(text)
  }
  
  # ==================
  # BUILD CALENDAR
  # ==================
  
  ics_lines <- c(
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Business Operations Suite//Calendar Export//EN",
    "CALSCALE:GREGORIAN",
    paste0("X-WR-CALNAME:", title),
    paste0("X-WR-TIMEZONE:UTC"),
    "METHOD:PUBLISH",
    ""
  )
  
  # Handle different input types
  if (is.null(items)) {
    # Single event mode
    event_date <- format(Sys.Date(), "%Y%m%d")
    event_start <- paste0(event_date, "T090000Z")
    event_end <- paste0(event_date, "T100000Z")
    
    ics_lines <- c(
      ics_lines,
      "BEGIN:VEVENT",
      paste0("UID:", paste0("event-", format(Sys.time(), "%Y%m%d%H%M%S")), "@biz-ops.local"),
      paste0("DTSTAMP:", format(Sys.time(), "%Y%m%dT%H%M%SZ")),
      paste0("DTSTART:", event_start),
      paste0("DTEND:", event_end),
      paste0("SUMMARY:", escape_ical(title)),
      paste0("DESCRIPTION:", escape_ical(description)),
      if (location != "") paste0("LOCATION:", escape_ical(location)) else NULL,
      "STATUS:CONFIRMED",
      "END:VEVENT",
      "END:VCALENDAR"
    )
  } else {
    # Multiple items mode
    if (!is.data.frame(items)) {
      items <- as.data.frame(items)
    }
    
    # Validate required columns
    if (!date_col %in% names(items)) {
      stop(paste("Date column", date_col, "not found in data"))
    }
    
    # Create event for each item
    for (i in seq_len(nrow(items))) {
      event_date <- items[[i, date_col]]
      
      # Handle various date formats
      if (inherits(event_date, "Date")) {
        event_date <- format(event_date, "%Y%m%d")
      } else if (inherits(event_date, "POSIXct") || inherits(event_date, "POSIXlt")) {
        event_date <- format(event_date, "%Y%m%d")
      } else {
        event_date <- gsub("-", "", as.character(event_date))
      }
      
      # Get time if provided
      event_time <- "090000"
      if (!is.null(time_col) && time_col %in% names(items)) {
        event_time <- convert_to_24hr(items[[i, time_col]])
      }
      
      event_start <- paste0(event_date, "T", event_time, "Z")
      event_end <- paste0(event_date, "T", add_minutes_to_time(event_time, duration_minutes), "Z")
      
      # Get item name
      item_name <- if (item_col %in% names(items)) {
        escape_ical(items[[i, item_col]])
      } else {
        paste0(title, " - Item ", i)
      }
      
      # Get item description
      item_desc <- if (description != "") {
        escape_ical(description)
      } else {
        paste0(title, " scheduled for ", event_date)
      }
      
      ics_lines <- c(
        ics_lines,
        "BEGIN:VEVENT",
        paste0("UID:", paste0("event-", i, "-", format(Sys.time(), "%Y%m%d%H%M%S")), "@biz-ops.local"),
        paste0("DTSTAMP:", format(Sys.time(), "%Y%m%dT%H%M%SZ")),
        paste0("DTSTART:", event_start),
        paste0("DTEND:", event_end),
        paste0("SUMMARY:", item_name),
        paste0("DESCRIPTION:", item_desc),
        if (location != "") paste0("LOCATION:", escape_ical(location)) else NULL,
        "STATUS:CONFIRMED",
        "SEQUENCE:0",
        "END:VEVENT"
      )
    }
    
    ics_lines <- c(ics_lines, "END:VCALENDAR")
  }
  
  # Remove NULL entries
  ics_lines <- ics_lines[!sapply(ics_lines, is.null)]
  
  return(ics_lines)
}

# ==================
# EXPORT TO FILE FUNCTION
# ==================

export_calendar_file <- function(ics_lines, file) {
  writeLines(ics_lines, file)
}

# ==================
# CREATE DOWNLOAD HANDLER FOR MODULES
# ==================

create_calendar_download_handler <- function(ns, input, module_name, items_reactive) {
  
  downloadHandler(
    filename = function() {
      timestamp <- format(Sys.Date(), "%Y%m%d")
      paste0(module_name, "_", timestamp, ".ics")
    },
    content = function(file) {
      tryCatch({
        items <- items_reactive()
        
        ics_content <- generate_calendar_ics(
          title = module_name,
          items = items,
          date_col = "date",
          time_col = "time",
          duration_minutes = 60,
          description = paste0(module_name, " - Exported from Business Operations Suite"),
          item_col = "name"
        )
        
        export_calendar_file(ics_content, file)
        
      }, error = function(e) {
        # Fallback: create simple calendar
        simple_ics <- c(
          "BEGIN:VCALENDAR",
          "VERSION:2.0",
          "PRODID:-//Business Operations Suite//EN",
          paste0("X-WR-CALNAME:", module_name),
          "BEGIN:VEVENT",
          paste0("UID:event-", format(Sys.time(), "%Y%m%d%H%M%S"), "@biz-ops.local"),
          paste0("DTSTAMP:", format(Sys.time(), "%Y%m%dT%H%M%SZ")),
          paste0("DTSTART:", format(Sys.Date(), "%Y%m%d"), "T090000Z"),
          paste0("DTEND:", format(Sys.Date(), "%Y%m%d"), "T170000Z"),
          paste0("SUMMARY:", module_name, " Export"),
          "DESCRIPTION:Calendar export from Business Operations Suite",
          "STATUS:CONFIRMED",
          "END:VEVENT",
          "END:VCALENDAR"
        )
        
        export_calendar_file(simple_ics, file)
      })
    }
  )
}

# ==================
# HELPER: Format event data for calendar
# ==================

format_for_calendar <- function(data, date_col, name_col, time_col = NULL) {
  
  if (!is.data.frame(data)) {
    data <- as.data.frame(data)
  }
  
  # Ensure required columns exist
  if (!date_col %in% names(data) || !name_col %in% names(data)) {
    return(data.frame(
      date = Sys.Date(),
      name = "Sample Event",
      time = "09:00 AM"
    ))
  }
  
  # Build calendar data frame
  cal_data <- data.frame(
    date = data[[date_col]],
    name = data[[name_col]],
    stringsAsFactors = FALSE
  )
  
  # Add time if available
  if (!is.null(time_col) && time_col %in% names(data)) {
    cal_data$time <- data[[time_col]]
  } else {
    cal_data$time <- "09:00 AM"
  }
  
  return(cal_data)
}

# ==================
# CALENDAR IMPORT INSTRUCTIONS
# ==================

get_calendar_import_instructions <- function() {
  
  instructions <- HTML("
    <div style='background: #f0f7ff; border-left: 4px solid #2196F3; padding: 20px; border-radius: 4px; margin: 15px 0;'>
      <h4 style='color: #1976D2; margin-top: 0;'>📅 How to Import Calendar Files</h4>
      
      <div style='margin-top: 15px;'>
        <h5 style='color: #1565C0;'>For Outlook (Windows/Web/Mobile):</h5>
        <ol style='margin-left: 20px;'>
          <li>Download the .ics file</li>
          <li><strong>Windows Outlook:</strong> File → Open & Export → Import a file → Select the .ics file → Choose calendar → Import</li>
          <li><strong>Outlook Web:</strong> Settings → Import calendar → Select the .ics file → Import</li>
          <li><strong>Outlook Mobile:</strong> Double-tap the .ics file → Select calendar → Import</li>
        </ol>
      </div>
      
      <div style='margin-top: 15px;'>
        <h5 style='color: #1565C0;'>For Android Calendar:</h5>
        <ol style='margin-left: 20px;'>
          <li>Download the .ics file to your device</li>
          <li>Open file manager and find the file</li>
          <li>Tap the .ics file → Select Calendar app</li>
          <li>Choose which calendar to import to</li>
          <li>Tap Import/Add</li>
          <li><strong>Alternative:</strong> Open Google Calendar app → + button → Import events → Select file → Import</li>
        </ol>
      </div>
      
      <div style='margin-top: 15px; padding: 10px; background: #fff3cd; border-left: 3px solid #ffc107; border-radius: 3px;'>
        <strong>💡 Tip:</strong> Events will appear on their scheduled dates in your calendar. Set reminders within your calendar app as needed.
      </div>
    </div>
  ")
  
  return(instructions)
}
