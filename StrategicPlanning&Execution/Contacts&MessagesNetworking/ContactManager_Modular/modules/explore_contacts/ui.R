# modules/explore_contacts/ui.R
explore_contacts_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Filter Contacts", status = "info", solidHeader = TRUE, width = 12,
        fluidRow(
          column(2, selectInput(ns("filter_industry"), "Industry:", choices = c("All" = ""), selected = "")),
          column(2, selectInput(ns("filter_country"), "Country:", choices = c("All" = ""), selected = "")),
          column(2, selectInput(ns("filter_location"), "Location:", choices = c("All" = ""), selected = "")),
          column(2, selectInput(ns("filter_university"), "University:", choices = c("All" = ""), selected = "")),
          column(2, selectInput(ns("filter_company"), "Company:", choices = c("All" = ""), selected = "")),
          column(2, br(), actionButton(ns("refresh_data"), "Refresh Data", class = "btn-info", 
                                       icon = icon("sync"), style = "width: 100%;"))
        ),
        br(),
        actionButton(ns("apply_filters"), "Apply Filters", class = "btn-primary", icon = icon("filter")),
        actionButton(ns("clear_filters"), "Clear Filters", class = "btn-warning", icon = icon("times"))
      )
    ),
    fluidRow(
      box(title = "Contacts Table", status = "primary", solidHeader = TRUE, width = 12,
        p("Click on a row to select it. Double-click a cell to edit inline."),
        DT::dataTableOutput(ns("contacts_table")),
        br(),
        htmlOutput(ns("table_status"))
      )
    ),
    fluidRow(
      box(title = "Actions for Selected Contact", status = "success", solidHeader = TRUE, width = 12,
        p("Select a contact and choose an action below."),
        fluidRow(
          column(4, actionButton(ns("customise_comm"), "Customise Communication", 
                                class = "btn-primary", icon = icon("comments"), style = "width: 100%;")),
          column(4, actionButton(ns("update_record"), "Update Modified Record", 
                                class = "btn-success", icon = icon("save"), style = "width: 100%;")),
          column(4, actionButton(ns("delete_record"), "Delete Selected Record", 
                                class = "btn-danger", icon = icon("trash"), style = "width: 100%;"))
        ),
        br(),
        htmlOutput(ns("update_status"))
      )
    )
  )
}
