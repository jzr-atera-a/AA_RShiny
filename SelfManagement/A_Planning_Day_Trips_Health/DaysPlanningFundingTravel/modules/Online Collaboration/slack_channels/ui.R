# modules/Online Collaboration/slack_channels/ui.R

slack_channels_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Channels", status = "primary", solidHeader = TRUE, width = 12,
          uiOutput(ns("conn_note")),
          fluidRow(
            column(3, actionButton(ns("load_channels"), "Load channels", icon = icon("sync"),
                                   class = "btn-primary", style = "width: 100%;")),
            column(5, textInput(ns("chan_filter"), NULL, placeholder = "Filter by name...")),
            column(4, checkboxInput(ns("only_member"), "Only channels the app is in", value = FALSE))
          ),
          htmlOutput(ns("channels_status")),
          DT::DTOutput(ns("channels_tbl")),
          br(),
          fluidRow(
            column(4, actionButton(ns("join_channel"), "Join selected channel", icon = icon("sign-in-alt"),
                                   class = "btn-info", style = "width: 100%;")),
            column(8, p(class = "text-muted", style = "font-size: 0.85em;",
                        "Public channels can be joined from here (needs the channels:join permission). ",
                        "For a private channel, invite the app in Slack: /invite @AppName."))
          )
      )
    ),
    fluidRow(
      box(title = "Messages", status = "info", solidHeader = TRUE, width = 12,
          htmlOutput(ns("selected_channel")),
          fluidRow(
            column(3, selectInput(ns("period"), "Period",
                                  c("Today" = "today", "Last 7 days" = "7", "Last 30 days" = "30", "Custom range" = "custom"),
                                  selected = "7")),
            column(3, bos_tz_dropdown_ui(ns, label = "Show times in:",
                                         help = "Message times are displayed in this zone.")),
            column(6, conditionalPanel(sprintf("input['%s'] == 'custom'", ns("period")),
                                       dateRangeInput(ns("range"), "From - to", start = Sys.Date() - 7, end = Sys.Date())))
          ),
          fluidRow(
            column(3, actionButton(ns("load_messages"), "Load messages", icon = icon("download"),
                                   class = "btn-primary", style = "width: 100%;")),
            column(3, actionButton(ns("load_older"), "Load older messages", icon = icon("history"),
                                   class = "btn-default", style = "width: 100%;")),
            column(3, downloadButton(ns("download_csv"), "Download CSV", class = "btn-success", style = "width: 100%;"))
          ),
          htmlOutput(ns("messages_status")),
          DT::DTOutput(ns("messages_tbl"))
      )
    ),
    fluidRow(
      box(title = "Thread", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE,
          p(class = "text-muted", style = "font-size: 0.85em;",
            "Select a message that has replies to read its thread."),
          htmlOutput(ns("thread_status")),
          DT::DTOutput(ns("thread_tbl"))
      )
    ),
    fluidRow(
      box(title = "Post an update", status = "warning", solidHeader = TRUE, width = 12,
          textAreaInput(ns("post_text"), NULL, rows = 4, width = "100%",
                        placeholder = "Write the update to post in the selected channel..."),
          checkboxInput(ns("post_in_thread"), "Reply in the selected thread instead of the channel", value = FALSE),
          fluidRow(
            column(3, actionButton(ns("send_post"), "Send", icon = icon("paper-plane"),
                                   class = "btn-success", style = "width: 100%;"))
          ),
          htmlOutput(ns("post_status"))
      )
    )
  )
}
