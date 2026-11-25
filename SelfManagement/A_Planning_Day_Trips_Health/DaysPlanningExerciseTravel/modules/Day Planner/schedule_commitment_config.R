# modules/Day Planner/schedule_commitment_config.R
# ---- module ----------------------------------------------
# id:           schedule_commitment_config
# name:         Commitment Trello Config
# icon:         key
# description:  Trello API credentials for pushing commitments to a board, local to this feature
# packages:     shiny, shinydashboard, httr, jsonlite
# -----------------------------------------------------------

# ---- UI ----
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

# ---- Server ----
schedule_commitment_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$test_trello, {
      req(input$trello_key, input$trello_token)
      tryCatch({
        api_manager$set_commitment_trello_credentials(input$trello_key, input$trello_token, input$trello_board_id)
        api_manager$test_commitment_trello_connection()
        output$trello_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Trello connected successfully!")
        })
        showNotification("✓ Trello connected!", type = "message")
      }, error = function(e) {
        output$trello_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Connection failed: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$trello_status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
