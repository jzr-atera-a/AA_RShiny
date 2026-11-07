# modules/Exercise Tracker/muscle_programme/ui.R

muscle_programme_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "Programme settings (male muscle building)", status = "primary", solidHeader = TRUE, width = 12,
          uiOutput(ns("claude_note")),
          fluidRow(
            column(3, dateInput(ns("start"), "Programme start (Monday of week 1)", value = muscle_monday()),
                      dateInput(ns("plan_date"), "Plan for date", value = Sys.Date())),
            column(3, selectInput(ns("days"), "Training days per week", choices = 3:6, selected = 4),
                      selectInput(ns("level"), "Level", choices = c("Beginner", "Intermediate", "Advanced"), selected = "Intermediate")),
            column(3, selectInput(ns("day_no"), "Day to plan", choices = "1"),
                      numericInput(ns("home_db"), "Home: heaviest dumbbell (kg)", value = 20, min = 2, max = 60, step = 2)),
            column(3, textInput(ns("gym_notes"), "Gym notes (optional)", "", placeholder = "e.g. no hack squat, has Smith machine"),
                      textInput(ns("home_notes"), "Home kit notes (optional)", "", placeholder = "e.g. 3 bands, adjustable bench"))
          ),
          textAreaInput(ns("injuries"), "Recent injury or issue (optional - Claude will work around it in all three options)", "",
                        width = "100%", height = "60px", placeholder = "e.g. mild left shoulder pain on overhead pressing"),
          uiOutput(ns("week_info")),
          fluidRow(
            column(4, actionButton(ns("gen_day"), "Plan this day (3 options)", icon = icon("dumbbell"), class = "btn-primary btn-lg", style = "width:100%")),
            column(4, actionButton(ns("gen_week"), "Plan the whole week", icon = icon("calendar-week"), class = "btn-info btn-lg", style = "width:100%")),
            column(4, actionButton(ns("save"), "Save this day to BigQuery", icon = icon("cloud-upload-alt"), class = "btn-success btn-lg", style = "width:100%"))
          ),
          htmlOutput(ns("status"))
      )
    ),
    fluidRow(
      box(title = "This day - choose the option that fits where you train", status = "success", solidHeader = TRUE, width = 12,
          uiOutput(ns("day_header")),
          tabsetPanel(id = ns("opt_tabs"),
            tabPanel("Gym", value = "gym", uiOutput(ns("opt_gym"))),
            tabPanel("No equipment", value = "bodyweight", uiOutput(ns("opt_bodyweight"))),
            tabPanel("Home kit", value = "home", uiOutput(ns("opt_home")))
          ))
    ),
    fluidRow(
      box(title = "This week's programme (saved)", status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE,
          actionButton(ns("reload"), "Reload from BigQuery", icon = icon("sync"), class = "btn-sm"),
          DT::dataTableOutput(ns("week_table")))
    )
  )
}
