# modules/Online Collaboration/slack_connection/ui.R

slack_connection_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Slack Connection", status = "primary", solidHeader = TRUE, width = 12,
          p("Connect the app to your company's ", tags$strong("internal Slack app"), " with its ",
            tags$strong("Bot User OAuth Token"), " (it starts with ", tags$code("xoxb-"), "). ",
            "The token is kept in this app's server memory only: it is not written to disk, not shown after ",
            "you connect, and not logged."),
          passwordInput(ns("token"), "Bot User OAuth Token", placeholder = "xoxb-..."),
          uiOutput(ns("env_note")),
          fluidRow(
            column(4, actionButton(ns("test_connection"), "Test connection",
                                   icon = icon("plug"), class = "btn-primary", style = "width: 100%;")),
            column(4, actionButton(ns("disconnect"), "Disconnect",
                                   icon = icon("unlink"), class = "btn-danger", style = "width: 100%;"))
          ),
          htmlOutput(ns("status"))
      )
    ),
    fluidRow(
      box(title = "Permissions (scopes)", status = "info", solidHeader = TRUE, width = 12,
          p("What the token is allowed to do. Missing ones are shown in red; the app tells you which one when ",
            "an action needs it."),
          DT::DTOutput(ns("scopes_tbl"))
      )
    ),
    fluidRow(
      box(title = "First-time setup checklist", status = "warning", solidHeader = TRUE, width = 12, collapsible = TRUE,
          collapsed = TRUE,
          tags$ol(
            tags$li("At ", tags$code("api.slack.com/apps"), " choose ", tags$strong("Create New App > From scratch"),
                    " and pick the company workspace."),
            tags$li("Under ", tags$strong("OAuth & Permissions > Bot Token Scopes"), " add: ",
                    tags$code("channels:read"), ", ", tags$code("groups:read"), ", ", tags$code("channels:history"), ", ",
                    tags$code("groups:history"), ", ", tags$code("chat:write"), ", ", tags$code("users:read"),
                    ". Optional: ", tags$code("channels:join"), ", ", tags$code("team:read"), "."),
            tags$li("Choose ", tags$strong("Install to Workspace"), " and copy the ", tags$strong("Bot User OAuth Token"), "."),
            tags$li("Leave public distribution OFF: an internal app keeps the normal rate limits."),
            tags$li("Invite the app to each private channel it should read: ", tags$code("/invite @AppName"),
                    ". Public channels can be joined from the Slack Channels tab (needs ", tags$code("channels:join"), ")."),
            tags$li("Optional: set the environment variable ", tags$code("SLACK_BOT_TOKEN"),
                    " (for example in ", tags$code("~/.Renviron"), ") so you do not have to paste the token each time.")
          ),
          p(tags$small("Direct messages are not included: they need a personal (user) token and extra permissions."))
      )
    ),
    fluidRow(
      box(title = "Log", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE,
          p(tags$small("Every Slack call: method, result and time taken. The token never appears here.")),
          verbatimTextOutput(ns("log"))
      )
    )
  )
}
