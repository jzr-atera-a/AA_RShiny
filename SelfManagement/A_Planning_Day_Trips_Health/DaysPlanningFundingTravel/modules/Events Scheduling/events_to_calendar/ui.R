# modules/Events Scheduling/events_to_calendar/ui.R

events_to_calendar_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Titan Calendar", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(7, htmlOutput(ns("conn_status"))),
            column(5, uiOutput(ns("calendar_ui")))
          )
      )
    ),
    fluidRow(
      column(12,
        tabsetPanel(
          id = ns("etc_tabs"), type = "tabs",

          # ---------------- New events ----------------
          tabPanel("New events", value = "new",
            br(),
            fluidRow(
              column(5,
                box(title = "Event details", status = "info", solidHeader = TRUE, width = 12,
                    textInput(ns("title"), "Title", ""),
                    fluidRow(
                      column(6, dateInput(ns("date"), "Date", Sys.Date(), weekstart = 1)),
                      column(6, textInput(ns("start"), "Start (HH:MM)", titan_next_slot()))
                    ),
                    selectInput(ns("form_tz"), "Time zone of this event", TITAN_TIMEZONES, selected = TITAN_DEFAULT_TZ),
                    uiOutput(ns("invite_note")),
                    fluidRow(
                      column(6, numericInput(ns("duration"), "Duration (minutes)", 60, min = 5, step = 5)),
                      column(6, br(), checkboxInput(ns("all_day"), "All-day event", FALSE))
                    ),
                    textInput(ns("location"), "Location", ""),
                    textAreaInput(ns("description"), "Notes", "", rows = 2),
                    checkboxGroupInput(ns("reminders"), "Notify me before the event",
                                       TITAN_REMINDERS, selected = 10, inline = TRUE),
                    numericInput(ns("custom_rem"), "Extra reminder (minutes before, optional)",
                                 NA, min = 0, step = 5),
                    p(tags$small("Reminders are written into the event as VALARMs. Titan may discard them on its ",
                                 "server; if so, set the calendar's default notification in the Titan website ",
                                 "(calendar menu > Settings and sharing).")),
                    fluidRow(
                      column(6, actionButton(ns("add"), "Add to list", icon = icon("plus"),
                                             class = "btn-info", style = "width: 100%;")),
                      column(6, actionButton(ns("save_one"), "Save to Titan now", icon = icon("cloud-upload-alt"),
                                             class = "btn-primary", style = "width: 100%;"))
                    )
                )
              ),
              column(7,
                box(title = "Events to save", status = "success", solidHeader = TRUE, width = 12,
                    selectInput(ns("tz"), "Time zone for these events", TITAN_TIMEZONES,
                                selected = TITAN_DEFAULT_TZ),
                    p(tags$small("Times are entered, shown and sent in this zone (saved to Titan as UTC). ",
                                 "Every event keeps the zone it was created or saved with (see the Zone column). This dropdown follows the ",
                                 "Time zone in Event details, and is the zone for events that have none.")),
                    DT::DTOutput(ns("queue_tbl")),
                    br(),
                    checkboxInput(ns("overwrite_queue"), "Replace events that already exist (same UID)", FALSE),
                    fluidRow(
                      column(4, actionButton(ns("remove"), "Remove selected", icon = icon("trash"),
                                             class = "btn-danger", style = "width: 100%;")),
                      column(4, downloadButton(ns("download"), "Download .ics",
                                               class = "btn-info", style = "width: 100%;")),
                      column(4, actionButton(ns("save_all"), "Save all to Titan", icon = icon("cloud-upload-alt"),
                                             class = "btn-primary", style = "width: 100%;"))
                    )
                )
              )
            )
          ),

          # ---------------- Import .ics file ----------------
          tabPanel("Import .ics file", value = "import",
            br(),
            box(title = "Import .ics file", status = "info", solidHeader = TRUE, width = 12,
                p("Upload an existing .ics file. Each event in it is saved to the selected Titan calendar, ",
                  "reminders (VALARM) included. A calendar sent from a Visualisation tab with ",
                  tags$strong(".ics load to calendar"), " appears here automatically."),
                fluidRow(
                  column(6, fileInput(ns("ics_file"), NULL, accept = c(".ics", "text/calendar"),
                                      buttonLabel = "Browse...", placeholder = "No .ics file selected")),
                  column(6, selectInput(ns("import_tz"), "Time zone of times in the file that have none",
                                        choices = TITAN_TIMEZONES, selected = TITAN_DEFAULT_TZ))
                ),
                htmlOutput(ns("import_source")),
                DT::DTOutput(ns("import_tbl")),
                br(),
                checkboxInput(ns("overwrite"), "Replace events that already exist (same UID)", FALSE),
                actionButton(ns("save_import"), "Save these events to Titan", icon = icon("cloud-upload-alt"),
                             class = "btn-primary")
            )
          ),

          # ---------------- Upcoming events ----------------
          tabPanel("Upcoming events", value = "upcoming",
            br(),
            box(title = "Upcoming events", status = "info", solidHeader = TRUE, width = 12,
                fluidRow(
                  column(6, dateRangeInput(ns("range"), "Show events between", Sys.Date(), Sys.Date() + 30,
                                           weekstart = 1)),
                  column(3, br(), actionButton(ns("refresh"), "Refresh", icon = icon("sync"),
                                               class = "btn-primary", style = "width: 100%;"))
                ),
                p(tags$small("Events are loaded only when you press Refresh.")),
                DT::DTOutput(ns("events_tbl")),
                br(),
                fluidRow(
                  column(4, actionButton(ns("show_raw"), "Show raw event data", icon = icon("code"),
                                         class = "btn-info", style = "width: 100%;")),
                  column(4, actionButton(ns("delete"), "Delete selected from Titan", icon = icon("trash"),
                                         class = "btn-danger", style = "width: 100%;"))
                )
            )
          ),

          # ---------------- Log ----------------
          tabPanel("Log", value = "log",
            br(),
            box(title = "Log", status = "info", solidHeader = TRUE, width = 12,
                p(tags$small("Newest first: connection tests, saves, loads and failures. Passwords are never logged.")),
                verbatimTextOutput(ns("log"))
            )
          )
        )
      )
    )
  )
}
