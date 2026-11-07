# modules/Day Planner/schedule_add_commitment/ui.R

schedule_add_commitment_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Log a Monthly Commitment", status = "primary", solidHeader = TRUE, width = 12,

          fluidRow(
            column(4, commitment_category_dropdown_ui(ns)),
            column(4, commitment_sector_dropdown_ui(ns)),
            column(4, commitment_topic_dropdown_ui(ns))
          ),

          fluidRow(
            column(6, dateInput(ns("commitment_date"), "Day of Commitment:", value = Sys.Date())),
            column(6, dateInput(ns("deadline"), "Defined Deadline:", value = Sys.Date() + 30))
          ),

          textAreaInput(ns("description"), "Describe the Commitment:", rows = 4,
                       placeholder = "What exactly are we committing to deliver?"),
          textAreaInput(ns("stakeholders"), "Stakeholders:", rows = 2,
                       placeholder = "Who is involved or affected - internal teams, clients, partners..."),
          textAreaInput(ns("value_of_delivery"), "Value of Delivering This Commitment:", rows = 3,
                       placeholder = "What do we gain by delivering this on time?"),
          textAreaInput(ns("consequences_of_failure"), "Consequences of Not Delivering:", rows = 3,
                       placeholder = "What's at risk if we miss this?"),

          br(),
          actionButton(ns("btn_save"), "Save Commitment", class = "btn-success btn-lg", icon = icon("save"), style = "width: 100%;"),
          br(), br(),
          htmlOutput(ns("save_status"))
      )
    ),

    fluidRow(
      box(title = "Push to Trello (optional)", status = "info", solidHeader = TRUE, width = 12,
          p("Save the commitment first, then optionally push it as a card to your Trello board."),
          fluidRow(
            column(6, actionButton(ns("load_trello_lists"), "Load Trello Lists", class = "btn-info")),
            column(6, selectInput(ns("trello_list"), "Trello List:", choices = NULL))
          ),
          actionButton(ns("btn_push_trello"), "Push Last Saved Commitment to Trello", class = "btn-primary", icon = icon("trello")),
          br(), br(),
          htmlOutput(ns("trello_push_status"))
      )
    )
  )
}
