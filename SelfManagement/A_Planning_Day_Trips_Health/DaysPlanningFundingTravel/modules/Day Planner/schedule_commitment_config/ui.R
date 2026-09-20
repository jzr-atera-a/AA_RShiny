# modules/Day Planner/schedule_commitment_config/ui.R
# A SEPARATE Trello connection, local to Commitments only - deliberately
# not shared with Gantt to Tickets' own Trello credentials (see
# utils_api.R field-declaration comment for why).

schedule_commitment_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Trello API Credentials for Commitments", status = "primary", solidHeader = TRUE, width = 12,
          div(class = "alert alert-info",
              tags$strong("Note:"), " This is a separate Trello connection from the one used by Gantt to Tickets - ",
              "point it at whichever board you track monthly commitments on, which may be a different board/account."),
          textInput(ns("trello_key"), "API Key:", ""),
          textInput(ns("trello_token"), "API Token:", ""),
          textInput(ns("trello_board_id"), "Board ID:", ""),
          actionButton(ns("test_trello"), "Test Connection", class = "btn-success"),
          br(), br(),
          htmlOutput(ns("trello_status"))
      )
    ),
    fluidRow(
      box(title = "How to get your Trello credentials", status = "warning", width = 12,
          HTML("<ul>
               <li>API Key: <a href='https://trello.com/app-key' target='_blank'>https://trello.com/app-key</a></li>
               <li>Token: click 'Token' on the same page and authorize</li>
               <li>Board ID: open your board, it's in the URL: trello.com/b/<strong>BOARD_ID</strong>/board-name</li>
               </ul>")
      )
    )
  )
}
